import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../theme/admin_theme.dart';
import '../providers/admin_providers.dart';

class DriversManagementScreen extends ConsumerStatefulWidget {
  const DriversManagementScreen({super.key});

  @override
  ConsumerState<DriversManagementScreen> createState() =>
      _DriversManagementScreenState();
}

class _DriversManagementScreenState
    extends ConsumerState<DriversManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(adminDriversProvider);
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
                      'Driver & Crew Registry',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verified school bus drivers and active license credentials',
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text(
                    'Register Driver',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showRegisterDriverDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Search Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by driver name or license number...',
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

            // Drivers Table Card
            Expanded(
              child: Card(
                child: SizedBox(
                  width: double.infinity,
                  child: driversAsync.when(
                    data: (drivers) {
                      final filtered = drivers.where((d) {
                        final profile = d['profiles'] as Map<String, dynamic>?;
                        final name = (profile?['name'] as String? ?? '').toLowerCase();
                        final license =
                            (d['license_number'] as String? ?? '').toLowerCase();
                        return name.contains(_searchQuery) ||
                            license.contains(_searchQuery);
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.badge_outlined,
                                  size: 48,
                                  color: AdminColors.textSecondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No drivers registered in system.'
                                      : 'No drivers matching "$_searchQuery".',
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
                                  DataColumn(label: Text('Driver Name')),
                                  DataColumn(label: Text('Username')),
                                  DataColumn(label: Text('License Number')),
                                  DataColumn(label: Text('Email')),
                                  DataColumn(label: Text('Phone')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: filtered.map((d) {
                                  final profile =
                                      d['profiles'] as Map<String, dynamic>?;
                                  final name = profile?['name'] as String? ?? 'Driver';
                                  final username = profile?['username'] as String? ?? '—';
                                  final email = profile?['email'] as String? ?? 'N/A';
                                  final phone = profile?['phone'] as String? ?? 'N/A';
                                  final license =
                                      d['license_number'] as String? ?? 'Pending';
                                  final driverId = d['id'] as String;
                                  final profileId = d['profile_id'] as String? ?? profile?['id'] as String?;

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundColor: AdminColors.blueLight,
                                              child: Text(
                                                name.isNotEmpty
                                                    ? name[0].toUpperCase()
                                                    : 'D',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AdminColors.blue,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(Text(username)),
                                      DataCell(Text(license)),
                                      DataCell(Text(email)),
                                      DataCell(Text(phone)),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AdminColors.safetyGreen
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'VERIFIED',
                                            style: TextStyle(
                                              color: AdminColors.safetyGreen,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert_rounded,
                                              color: AdminColors.textSecondary,
                                              size: 20),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8)),
                                          onSelected: (val) {
                                            if (val == 'edit') {
                                              _showEditDriverDialog(
                                                context,
                                                driverId: driverId,
                                                currentName: name,
                                                currentPhone: phone == 'N/A' ? '' : phone,
                                                currentEmail: email == 'N/A' ? '' : email,
                                                currentLicense: license == 'Pending' ? '' : license,
                                              );
                                            } else if (val == 'password' && profileId != null) {
                                              _showResetPasswordDialog(
                                                context,
                                                userId: profileId,
                                                userName: name,
                                              );
                                            } else if (val == 'assign_bus') {
                                              _showAssignBusDialog(
                                                context,
                                                driverId: driverId,
                                                driverName: name,
                                              );
                                            }
                                          },
                                          itemBuilder: (_) => [
                                            const PopupMenuItem(
                                              value: 'assign_bus',
                                              child: Row(children: [
                                                Icon(Icons.directions_bus_rounded,
                                                    size: 16,
                                                    color: AdminColors.blue),
                                                SizedBox(width: 8),
                                                Text('Assign to Bus / Route'),
                                              ]),
                                            ),
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(children: [
                                                Icon(Icons.edit_rounded,
                                                    size: 16,
                                                    color: AdminColors.deepNavy),
                                                SizedBox(width: 8),
                                                Text('Edit Details'),
                                              ]),
                                            ),
                                            const PopupMenuItem(
                                              value: 'password',
                                              child: Row(children: [
                                                Icon(Icons.lock_reset_rounded,
                                                    size: 16,
                                                    color: AdminColors.deepNavy),
                                                SizedBox(width: 8),
                                                Text('Reset Password'),
                                              ]),
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
                      child: Text('Failed to load drivers: $e'),
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

  void _showRegisterDriverDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final licenseCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool saving = false;
    bool obscure = true;

    final orgId = ref.read(currentAdminOrgIdProvider);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.badge_rounded, color: AdminColors.deepNavy),
              SizedBox(width: 10),
              Text(
                'Register Bus Driver',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AdminColors.textPrimary,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Driver Full Name *',
                        prefixIcon: Icon(Icons.person_rounded),
                        hintText: 'e.g. Ramesh Kumar',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: usernameCtrl,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Username *',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                              hintText: 'e.g. driver_ramesh',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Username required';
                              }
                              if (v.trim().length < 4) {
                                return 'Min 4 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: licenseCtrl,
                            decoration: const InputDecoration(
                              labelText: 'License Number *',
                              prefixIcon: Icon(Icons.card_membership_rounded),
                              hintText: 'e.g. DL-0420110012345',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'License is required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone_rounded),
                              hintText: '+919876543210',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address *',
                              prefixIcon: Icon(Icons.email_outlined),
                              hintText: 'driver@school.edu',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!v.contains('@')) return 'Invalid email';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: passCtrl,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'Driver Password *',
                        prefixIcon: const Icon(Icons.lock_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setDialogState(() => obscure = !obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password required';
                        if (v.length < 6) return 'Min 6 characters';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
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
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      try {
                        await SupabaseService.client.rpc(
                          'create_driver_account',
                          params: {
                            'p_name': nameCtrl.text.trim(),
                            'p_username':
                                usernameCtrl.text.trim().toLowerCase(),
                            'p_phone': phoneCtrl.text.trim(),
                            'p_email': emailCtrl.text.trim().toLowerCase(),
                            'p_password': passCtrl.text,
                            'p_license_number': licenseCtrl.text.trim(),
                            'p_org_id': orgId,
                          },
                        );

                        ref.invalidate(adminDriversProvider);
                        ref.invalidate(organizationStatsProvider);

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '✅ Driver "${nameCtrl.text.trim()}" registered! Login: ${usernameCtrl.text.trim()}'),
                              backgroundColor: AdminColors.safetyGreen,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AdminColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Register Driver',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDriverDialog(
    BuildContext context, {
    required String driverId,
    required String currentName,
    required String currentPhone,
    required String currentEmail,
    required String currentLicense,
  }) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: currentName);
    final phoneCtrl = TextEditingController(text: currentPhone);
    final emailCtrl = TextEditingController(text: currentEmail);
    final licenseCtrl = TextEditingController(text: currentLicense);
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.edit_rounded, color: AdminColors.deepNavy),
              SizedBox(width: 10),
              Text(
                'Edit Driver Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AdminColors.textPrimary,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Driver Full Name *',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: licenseCtrl,
                      decoration: const InputDecoration(
                        labelText: 'License Number *',
                        prefixIcon: Icon(Icons.card_membership_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'License is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address *',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
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
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      try {
                        await SupabaseService.client.rpc(
                          'update_driver_details',
                          params: {
                            'p_driver_id': driverId,
                            'p_name': nameCtrl.text.trim(),
                            'p_phone': phoneCtrl.text.trim(),
                            'p_email': emailCtrl.text.trim().toLowerCase(),
                            'p_license_number': licenseCtrl.text.trim(),
                          },
                        );

                        ref.invalidate(adminDriversProvider);

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '✅ Driver "${nameCtrl.text.trim()}" updated successfully!'),
                              backgroundColor: AdminColors.safetyGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AdminColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(
    BuildContext context, {
    required String userId,
    required String userName,
  }) {
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(Icons.lock_reset_rounded, color: AdminColors.deepNavy),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Reset Password — $userName',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AdminColors.textPrimary,
                        fontSize: 15)),
              ),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: Form(
              key: formKey,
              child: TextFormField(
                controller: passCtrl,
                obscureText: obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'New Password *',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password required';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.deepNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => saving = true);
                      try {
                        await SupabaseService.client.rpc('update_user_password',
                            params: {
                              'p_user_id': userId,
                              'p_new_password': passCtrl.text,
                            });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Password reset successfully'),
                              backgroundColor: AdminColors.safetyGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AdminColors.error),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Reset Password',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignBusDialog(
    BuildContext context, {
    required String driverId,
    required String driverName,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final busesAsync = ref.watch(adminBusesProvider);

          String? selectedBusId;
          bool initialized = false;
          bool saving = false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              final buses = busesAsync.value ?? [];
              final currentBus = buses.cast<Bus?>().firstWhere(
                    (b) => b?.currentDriverId == driverId,
                    orElse: () => null,
                  );
              if (!initialized) {
                selectedBusId = currentBus?.id;
                initialized = true;
              }

              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                title: Row(
                  children: [
                    const Icon(Icons.directions_bus_rounded,
                        color: AdminColors.deepNavy),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Assign Bus to $driverName',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AdminColors.textPrimary,
                              fontSize: 16)),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select the primary school bus and route for this driver:',
                        style: TextStyle(
                            fontSize: 13, color: AdminColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      busesAsync.when(
                        data: (busesList) {
                          return DropdownButtonFormField<String?>(
                            decoration: const InputDecoration(
                              labelText: 'Assigned Bus / Route',
                              prefixIcon: Icon(Icons.route_rounded),
                            ),
                            value: selectedBusId,
                            hint: const Text('Choose a bus from fleet'),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('No bus assigned (Unassigned)'),
                              ),
                              ...busesList.map((b) => DropdownMenuItem<String?>(
                                    value: b.id,
                                    child: Text(
                                      '${b.busNumber} (${b.registrationNumber ?? 'No Plate'})',
                                    ),
                                  )),
                            ],
                            onChanged: (v) =>
                                setDialogState(() => selectedBusId = v),
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Failed to load buses: $e'),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving ? null : () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.deepNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            setDialogState(() => saving = true);
                            try {
                              // If previously assigned to another bus, unassign first
                              if (currentBus != null &&
                                  currentBus.id != selectedBusId) {
                                await ref
                                    .read(adminRepositoryProvider)
                                    .upsertBus(
                                      currentBus.copyWith(
                                        currentDriverId: null,
                                        updatedAt: DateTime.now(),
                                      ),
                                    );
                              }

                              // Assign to newly selected bus
                              if (selectedBusId != null) {
                                final targetBus = buses.firstWhere(
                                    (b) => b.id == selectedBusId);
                                await ref
                                    .read(adminRepositoryProvider)
                                    .upsertBus(
                                      targetBus.copyWith(
                                        currentDriverId: driverId,
                                        updatedAt: DateTime.now(),
                                      ),
                                    );
                              }

                              ref.invalidate(adminBusesProvider);
                              ref.invalidate(adminDriversProvider);
                              ref.invalidate(organizationStatsProvider);

                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        '✅ Driver bus assignment updated successfully!'),
                                    backgroundColor: AdminColors.safetyGreen,
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() => saving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: AdminColors.error),
                                );
                              }
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Save Assignment',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

