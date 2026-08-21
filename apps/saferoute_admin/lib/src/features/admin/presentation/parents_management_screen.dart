import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../theme/admin_theme.dart';
import '../providers/admin_providers.dart';

class ParentsManagementScreen extends ConsumerStatefulWidget {
  const ParentsManagementScreen({super.key});

  @override
  ConsumerState<ParentsManagementScreen> createState() =>
      _ParentsManagementScreenState();
}

class _ParentsManagementScreenState
    extends ConsumerState<ParentsManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final parentsAsync = ref.watch(adminParentsProvider);
    final orgId = ref.watch(currentAdminOrgIdProvider);
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
                      'Parents & Guardians Directory',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Registered parents, contact credentials, and linked student accounts',
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
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text(
                    'Register Parent',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showRegisterParentDialog(context, orgId),
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
                      hintText: 'Search by parent name, phone, or email...',
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

            // Parents Table Card
            Expanded(
              child: Card(
                child: SizedBox(
                  width: double.infinity,
                  child: parentsAsync.when(
                    data: (parents) {
                      final filtered = parents.where((p) {
                        final profile = p['profiles'] as Map<String, dynamic>?;
                        final name = (profile?['name'] as String? ?? '').toLowerCase();
                        final phone = (profile?['phone'] as String? ?? '').toLowerCase();
                        final email = (profile?['email'] as String? ?? '').toLowerCase();
                        final username = (profile?['username'] as String? ?? '').toLowerCase();

                        return name.contains(_searchQuery) ||
                            phone.contains(_searchQuery) ||
                            email.contains(_searchQuery) ||
                            username.contains(_searchQuery);
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.people_outline_rounded,
                                  size: 48,
                                  color: AdminColors.textSecondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No parents registered in system yet.'
                                      : 'No parents matching "$_searchQuery".',
                                  style: const TextStyle(
                                      color: AdminColors.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Click "Register Parent" to create an account for a student\'s guardian.',
                                  style: TextStyle(
                                      fontSize: 12, color: AdminColors.textSecondary),
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
                                  DataColumn(label: Text('Parent Name')),
                                  DataColumn(label: Text('Username')),
                                  DataColumn(label: Text('Phone')),
                                  DataColumn(label: Text('Email')),
                                  DataColumn(label: Text('Linked Students')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: filtered.map((p) {
                                  final profile =
                                      p['profiles'] as Map<String, dynamic>?;
                                  final name = profile?['name'] as String? ?? 'Parent';
                                  final username = profile?['username'] as String? ?? '—';
                                  final email = profile?['email'] as String? ?? 'N/A';
                                  final phone = profile?['phone'] as String? ?? 'N/A';
                                  final children = (p['children'] as List?) ?? [];
                                  final parentId = p['id'] as String;
                                  final profileId = p['profile_id'] as String? ?? profile?['id'] as String?;

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundColor: AdminColors.yellow.withValues(alpha: 0.2),
                                              child: Text(
                                                name.isNotEmpty
                                                    ? name[0].toUpperCase()
                                                    : 'P',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AdminColors.deepNavy,
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
                                      DataCell(Text(phone)),
                                      DataCell(Text(email)),
                                      DataCell(
                                        Text(
                                          children.isEmpty
                                              ? 'No students linked'
                                              : children
                                                  .map((c) => c['name'] as String? ?? '')
                                                  .join(', '),
                                          style: TextStyle(
                                            color: children.isEmpty
                                                ? AdminColors.textSecondary
                                                : AdminColors.textPrimary,
                                            fontStyle: children.isEmpty
                                                ? FontStyle.italic
                                                : FontStyle.normal,
                                          ),
                                        ),
                                      ),
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
                                            'ACTIVE',
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
                                              _showEditParentDialog(
                                                context,
                                                parentId: parentId,
                                                currentName: name,
                                                currentPhone: phone == 'N/A' ? '' : phone,
                                                currentEmail: email == 'N/A' ? '' : email,
                                              );
                                            } else if (val == 'password' && profileId != null) {
                                              _showResetPasswordDialog(
                                                context,
                                                userId: profileId,
                                                userName: name,
                                              );
                                            }
                                          },
                                          itemBuilder: (_) => [
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
                      child: Text('Failed to load parents: $e'),
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

  void _showRegisterParentDialog(BuildContext context, String? orgId) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool saving = false;
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: AdminColors.deepNavy),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Register Parent',
                  style: TextStyle(
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
                        labelText: 'Parent / Guardian Full Name *',
                        prefixIcon: Icon(Icons.person_rounded),
                        hintText: 'e.g. Priya Sharma',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: usernameCtrl,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Username *',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                        hintText: 'e.g. parent_priya',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Username is required';
                        }
                        if (v.trim().length < 4) {
                          return 'Min 4 characters';
                        }
                        return null;
                      },
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
                              hintText: 'parent@example.com',
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
                        labelText: 'Parent Password *',
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
                        if (v == null || v.isEmpty) return 'Password is required';
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
                          'create_parent_account',
                          params: {
                            'p_name': nameCtrl.text.trim(),
                            'p_username':
                                usernameCtrl.text.trim().toLowerCase(),
                            'p_phone': phoneCtrl.text.trim(),
                            'p_email': emailCtrl.text.trim().toLowerCase(),
                            'p_password': passCtrl.text,
                            'p_org_id': orgId,
                          },
                        );

                        ref.invalidate(adminParentsProvider);

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '✅ Parent "${nameCtrl.text.trim()}" registered! Login: ${usernameCtrl.text.trim()}'),
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
                      'Register Parent',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditParentDialog(
    BuildContext context, {
    required String parentId,
    required String currentName,
    required String currentPhone,
    required String currentEmail,
  }) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: currentName);
    final phoneCtrl = TextEditingController(text: currentPhone);
    final emailCtrl = TextEditingController(text: currentEmail);
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
              Expanded(
                child: Text(
                  'Edit Parent Details',
                  style: TextStyle(
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
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Parent Full Name *',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
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
                          'update_parent_details',
                          params: {
                            'p_parent_id': parentId,
                            'p_name': nameCtrl.text.trim(),
                            'p_phone': phoneCtrl.text.trim(),
                            'p_email': emailCtrl.text.trim().toLowerCase(),
                          },
                        );

                        ref.invalidate(adminParentsProvider);

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '✅ Parent "${nameCtrl.text.trim()}" updated successfully!'),
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
}
