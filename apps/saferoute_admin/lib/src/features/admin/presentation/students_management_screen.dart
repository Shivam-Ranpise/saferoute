import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import 'package:uuid/uuid.dart';
import '../../../theme/admin_theme.dart';
import '../providers/admin_providers.dart';

class StudentsManagementScreen extends ConsumerStatefulWidget {
  const StudentsManagementScreen({super.key});

  @override
  ConsumerState<StudentsManagementScreen> createState() =>
      _StudentsManagementScreenState();
}

class _StudentsManagementScreenState
    extends ConsumerState<StudentsManagementScreen> {
  String _searchQuery = '';

  void _showStudentDialog([Child? existingStudent]) {
    final isEditing = existingStudent != null;
    final orgId = ref.read(currentAdminOrgIdProvider);
    if (orgId == null) return;

    final nameController =
        TextEditingController(text: existingStudent?.name ?? '');
    final stopNameController =
        TextEditingController(text: existingStudent?.pickupName ?? '');
    final addressController =
        TextEditingController(text: existingStudent?.pickupAddress ?? '');
    String? selectedParentId = existingStudent?.parentId;
    String? selectedBusId = existingStudent?.busId;

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          final busesAsync = ref.watch(adminBusesProvider);
          final parentsAsync = ref.watch(adminParentsProvider);

          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  const Icon(Icons.school_rounded, color: AdminColors.deepNavy),
                  const SizedBox(width: 10),
                  Text(
                    isEditing ? 'Edit Student' : 'Register Student to Roster',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Student Name
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Student Full Name *',
                          prefixIcon: Icon(Icons.person_outline),
                          hintText: 'e.g. Aarav Sharma',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Assign Parent
                      parentsAsync.when(
                        data: (parents) => DropdownButtonFormField<String?>(
                          decoration: const InputDecoration(
                            labelText: 'Assign Parent / Guardian',
                            prefixIcon: Icon(Icons.people_alt_outlined),
                          ),
                          value: selectedParentId,
                          hint: const Text('Select a parent (optional)'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('No parent assigned yet'),
                            ),
                            ...parents.map((p) {
                              final profile =
                                  p['profiles'] as Map<String, dynamic>?;
                              final parentName =
                                  profile?['name'] as String? ?? 'Parent';
                              final phone =
                                  profile?['phone'] as String? ?? '';
                              return DropdownMenuItem<String?>(
                                value: p['id'] as String,
                                child: Text(
                                  phone.isNotEmpty
                                      ? '$parentName ($phone)'
                                      : parentName,
                                ),
                              );
                            }),
                          ],
                          onChanged: (v) =>
                              setDialogState(() => selectedParentId = v),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) =>
                            const Text('Failed to load parents list'),
                      ),
                      const SizedBox(height: 14),

                      // Assign Bus
                      busesAsync.when(
                        data: (buses) => DropdownButtonFormField<String?>(
                          decoration: const InputDecoration(
                            labelText: 'Assign School Bus',
                            prefixIcon: Icon(Icons.directions_bus_outlined),
                          ),
                          value: selectedBusId,
                          hint: const Text('Select a bus route (optional)'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('No bus assigned yet'),
                            ),
                            ...buses.map((b) => DropdownMenuItem<String?>(
                                  value: b.id,
                                  child: Text(
                                    '${b.busNumber} (${b.registrationNumber ?? "No Plate"})',
                                  ),
                                )),
                          ],
                          onChanged: (v) =>
                              setDialogState(() => selectedBusId = v),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) =>
                            const Text('Failed to load buses list'),
                      ),
                      const SizedBox(height: 14),

                      // Designated Stop Name
                      TextField(
                        controller: stopNameController,
                        decoration: const InputDecoration(
                          labelText: 'Designated Stop Name',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          hintText: 'e.g. Indiranagar Club Stop',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Pickup Address
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Pickup Address',
                          prefixIcon: Icon(Icons.home_outlined),
                          hintText: 'e.g. 100ft Rd, Indiranagar, Bangalore',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.deepNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final stopName = stopNameController.text.trim();
                    final address = addressController.text.trim();

                    if (name.isEmpty) return;

                    final child = Child(
                      id: existingStudent?.id ?? const Uuid().v4(),
                      organizationId: orgId,
                      parentId: selectedParentId,
                      name: name,
                      pickupName: stopName.isNotEmpty ? stopName : null,
                      pickupAddress: address.isNotEmpty ? address : null,
                      pickupLatitude:
                          existingStudent?.pickupLatitude ?? 12.9716,
                      pickupLongitude:
                          existingStudent?.pickupLongitude ?? 77.5946,
                      busId: selectedBusId,
                      isActive: true,
                      createdAt: existingStudent?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    final result = await ref
                        .read(adminRepositoryProvider)
                        .upsertChild(child);

                    if (result != null) {
                      ref.invalidate(adminStudentsProvider);
                      ref.invalidate(organizationStatsProvider);
                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEditing
                                ? '✅ Student updated successfully'
                                : '✅ Student "$name" registered successfully'),
                            backgroundColor: AdminColors.safetyGreen,
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                '❌ Failed to save student. Please try again.'),
                            backgroundColor: AdminColors.error,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Register Student'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(adminStudentsProvider);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: AdminColors.background,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 14 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Roster & Stop Management',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage enrolled students and designated pickup geofence locations',
                      style: TextStyle(
                        fontSize: isMobile ? 11.5 : 13,
                        color: AdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.deepNavy,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 14 : 20, vertical: isMobile ? 10 : 14),
                  ),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text(
                    'Register Student',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showStudentDialog(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Search Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by student name or stop name...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.toLowerCase());
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Students Table Card
            Expanded(
              child: Card(
                child: SizedBox(
                  width: double.infinity,
                  child: studentsAsync.when(
                    data: (students) {
                      final filtered = students.where((s) {
                        final matchName = s.name.toLowerCase().contains(_searchQuery);
                        final matchStop =
                            (s.pickupName ?? '').toLowerCase().contains(_searchQuery);
                        return matchName || matchStop;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.school_outlined,
                                  size: 48,
                                  color: AdminColors.textSecondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No students registered in roster yet.'
                                      : 'No students matching "$_searchQuery".',
                                  style: const TextStyle(
                                      color: AdminColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                                columnSpacing: 32,
                                columns: const [
                                  DataColumn(label: Text('Student Name')),
                                  DataColumn(label: Text('Designated Stop')),
                                  DataColumn(label: Text('Pickup Address')),
                                  DataColumn(label: Text('Pickup Geofence')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: filtered.map((s) {
                                  final hasCoords = s.hasPickupLocation;

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundColor: AdminColors.yellow
                                                  .withValues(alpha: 0.3),
                                              child: Text(
                                                s.name.isNotEmpty
                                                    ? s.name[0].toUpperCase()
                                                    : 'S',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AdminColors.deepNavy,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              s.name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(Text(s.pickupName ?? 'Main Stop')),
                                      DataCell(Text(s.pickupAddress ?? 'Address Not Set')),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: hasCoords
                                                ? AdminColors.safetyGreen
                                                    .withValues(alpha: 0.15)
                                                : AdminColors.warning
                                                    .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            hasCoords ? 'SET' : 'PENDING',
                                            style: TextStyle(
                                              color: hasCoords
                                                  ? AdminColors.safetyGreen
                                                  : AdminColors.warning,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_rounded,
                                                  size: 18),
                                              tooltip: 'Edit',
                                              onPressed: () => _showStudentDialog(s),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 18,
                                                  color: AdminColors.error),
                                              tooltip: 'Delete',
                                              onPressed: () async {
                                                await ref
                                                    .read(adminRepositoryProvider)
                                                    .deleteChild(s.id);
                                                ref.invalidate(adminStudentsProvider);
                                                ref.invalidate(
                                                    organizationStatsProvider);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AdminColors.yellow),
                    ),
                    error: (e, _) => Center(
                      child: Text('Failed to load students: $e'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
