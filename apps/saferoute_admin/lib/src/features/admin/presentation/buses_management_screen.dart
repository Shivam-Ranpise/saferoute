import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import 'package:uuid/uuid.dart';
import '../../../theme/admin_theme.dart';
import '../providers/admin_providers.dart';

class BusesManagementScreen extends ConsumerStatefulWidget {
  const BusesManagementScreen({super.key});

  @override
  ConsumerState<BusesManagementScreen> createState() =>
      _BusesManagementScreenState();
}

class _BusesManagementScreenState extends ConsumerState<BusesManagementScreen> {
  String _searchQuery = '';

  void _showBusDialog([Bus? existingBus]) {
    final isEditing = existingBus != null;
    final orgId = ref.read(currentAdminOrgIdProvider);
    if (orgId == null) return;

    final numberController =
        TextEditingController(text: existingBus?.busNumber ?? '');
    final regController =
        TextEditingController(text: existingBus?.registrationNumber ?? '');
    final capacityController =
        TextEditingController(text: existingBus?.capacity.toString() ?? '35');
    String? selectedDriverId = existingBus?.currentDriverId;
    bool isActive = existingBus?.isActive ?? true;

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          final driversAsync = ref.watch(adminDriversProvider);

          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  const Icon(Icons.directions_bus_rounded, color: AdminColors.deepNavy),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Bus / Route' : 'Add New Bus',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AdminColors.textPrimary,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: numberController,
                        decoration: const InputDecoration(
                          labelText: 'Route Name *',
                          prefixIcon: Icon(Icons.route_rounded),
                          hintText: 'e.g. North Route 12-A',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: regController,
                        decoration: const InputDecoration(
                          labelText: 'Number Plate *',
                          prefixIcon: Icon(Icons.card_membership_rounded),
                          hintText: 'e.g. MH-09-AB-1234',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Assign Driver Dropdown
                      driversAsync.when(
                        data: (drivers) => DropdownButtonFormField<String?>(
                          decoration: const InputDecoration(
                            labelText: 'Assign Primary Driver',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          value: selectedDriverId,
                          hint: const Text('Select a driver (optional)'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('No driver assigned yet'),
                            ),
                            ...drivers.map((d) {
                              final profile =
                                  d['profiles'] as Map<String, dynamic>?;
                              final driverName =
                                  profile?['name'] as String? ?? 'Driver';
                              final phone =
                                  profile?['phone'] as String? ?? '';
                              final driverId = d['id'] as String;

                              return DropdownMenuItem<String?>(
                                value: driverId,
                                child: Text(
                                  phone.isNotEmpty
                                      ? '$driverName ($phone)'
                                      : driverName,
                                ),
                              );
                            }),
                          ],
                          onChanged: (v) =>
                              setDialogState(() => selectedDriverId = v),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) =>
                            const Text('Failed to load drivers list'),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: capacityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Seating Capacity',
                          prefixIcon: Icon(Icons.event_seat_outlined),
                          hintText: 'e.g. 35',
                        ),
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile(
                        title: const Text('Active for Daily Routes'),
                        value: isActive,
                        activeTrackColor: AdminColors.safetyGreen,
                        onChanged: (val) {
                          setDialogState(() => isActive = val);
                        },
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
                    final busNumber = numberController.text.trim();
                    final registrationNumber = regController.text.trim();
                    final capacity =
                        int.tryParse(capacityController.text.trim()) ?? 30;

                    if (busNumber.isEmpty || registrationNumber.isEmpty) {
                      return;
                    }

                    final bus = Bus(
                      id: existingBus?.id ?? const Uuid().v4(),
                      organizationId: orgId,
                      busNumber: busNumber,
                      registrationNumber: registrationNumber,
                      capacity: capacity,
                      currentDriverId: selectedDriverId,
                      isActive: isActive,
                      createdAt: existingBus?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    await ref.read(adminRepositoryProvider).upsertBus(bus);
                    ref.invalidate(adminBusesProvider);
                    ref.invalidate(organizationStatsProvider);

                    if (context.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing
                              ? '✅ Bus "$busNumber" updated successfully!'
                              : '✅ Bus "$busNumber" created and assigned!'),
                          backgroundColor: AdminColors.safetyGreen,
                        ),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Create Bus'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteBus(Bus b) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AdminColors.error),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Delete Bus',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete bus "${b.busNumber}" (${b.registrationNumber})?\n\nAny assigned students and drivers will be unassigned automatically.',
          style: const TextStyle(fontSize: 14, color: AdminColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Bus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(adminRepositoryProvider).deleteBus(b.id);
      ref.invalidate(adminBusesProvider);
      ref.invalidate(organizationStatsProvider);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Bus "${b.busNumber}" deleted successfully!'),
              backgroundColor: AdminColors.deepNavy,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete bus. Please try again.'),
              backgroundColor: AdminColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busesAsync = ref.watch(adminBusesProvider);
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
                      'Bus Fleet Management',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Register, configure, and assign school transport vehicles',
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
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Add New Bus',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showBusDialog(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Search Bar & Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by bus number or registration plate...',
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

            // Buses Table Card
            Expanded(
              child: Card(
                child: SizedBox(
                  width: double.infinity,
                  child: busesAsync.when(
                    data: (buses) {
                      final filtered = buses.where((b) {
                        final matchNumber =
                            b.busNumber.toLowerCase().contains(_searchQuery);
                        final matchReg = (b.registrationNumber ?? '')
                            .toLowerCase()
                            .contains(_searchQuery);
                        return matchNumber || matchReg;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.directions_bus_outlined,
                                  size: 48,
                                  color: AdminColors.textSecondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No buses registered yet. Click "Add New Bus" to get started.'
                                      : 'No buses matching "$_searchQuery".',
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
                                  DataColumn(label: Text('Bus Number / Route')),
                                  DataColumn(label: Text('License Plate')),
                                  DataColumn(label: Text('Assigned Driver')),
                                  DataColumn(label: Text('Capacity')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: filtered.map((b) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.directions_bus_rounded,
                                                color: AdminColors.deepNavy, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              b.busNumber,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(Text(b.registrationNumber ?? 'N/A')),
                                      DataCell(
                                        Consumer(
                                          builder: (context, ref, _) {
                                            final drivers = ref.watch(adminDriversProvider).value ?? [];
                                            if (b.currentDriverId == null) {
                                              return const Text(
                                                'Unassigned',
                                                style: TextStyle(
                                                  color: AdminColors.textSecondary,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              );
                                            }
                                            final driverMap = drivers.cast<Map<String, dynamic>?>().firstWhere(
                                                  (d) => d?['id'] == b.currentDriverId,
                                                  orElse: () => null,
                                                );
                                            final profile = driverMap?['profiles'] as Map<String, dynamic>?;
                                            final dName = profile?['name'] as String? ?? 'Assigned Driver';
                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.person_pin_circle_rounded,
                                                    size: 16, color: AdminColors.blue),
                                                const SizedBox(width: 6),
                                                Text(
                                                  dName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: AdminColors.textPrimary,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                      DataCell(Text('${b.capacity} Seats')),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: b.isActive
                                                ? AdminColors.safetyGreen
                                                    .withValues(alpha: 0.15)
                                                : AdminColors.error
                                                    .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            b.isActive ? 'ACTIVE' : 'INACTIVE',
                                            style: TextStyle(
                                              color: b.isActive
                                                  ? AdminColors.safetyGreen
                                                  : AdminColors.error,
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
                                              onPressed: () => _showBusDialog(b),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 18,
                                                  color: AdminColors.error),
                                              tooltip: 'Delete Bus',
                                              onPressed: () => _confirmDeleteBus(b),
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
                      child: Text('Failed to load bus fleet: $e'),
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
