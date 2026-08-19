import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../theme/admin_theme.dart';
import 'super_admin_orgs_screen.dart' show allOrgsProvider;

// ─── Providers ───────────────────────────────────────────────────────────────

final allAdminUsersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final result =
      await SupabaseService.client.rpc('get_all_admin_users');
  return List<Map<String, dynamic>>.from(result as List);
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class SuperAdminUsersScreen extends ConsumerWidget {
  const SuperAdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allAdminUsersProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action Bar
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'School Admin Accounts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Each school admin manages their own school\'s buses, drivers, parents and students.',
                      style: TextStyle(
                          fontSize: 12, color: AdminColors.textSecondary),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.deepNavy,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Create Admin',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onPressed: () => _showCreateUserDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // List
          Expanded(
            child: usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.manage_accounts_rounded,
                            size: 56,
                            color: AdminColors.textSecondary
                                .withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        const Text('No admin accounts yet.',
                            style: TextStyle(
                                fontSize: 16, color: AdminColors.textSecondary)),
                        const SizedBox(height: 8),
                        const Text(
                            'First create a school, then create an admin for it.',
                            style: TextStyle(
                                fontSize: 13,
                                color: AdminColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final u = users[i];
                    final isActive = u['user_is_active'] as bool? ?? true;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: AdminColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              backgroundColor: isActive
                                  ? AdminColors.blue.withValues(alpha: 0.12)
                                  : AdminColors.textSecondary
                                      .withValues(alpha: 0.1),
                              radius: 20,
                              child: Text(
                                (u['user_name'] as String? ?? 'A')[0].toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? AdminColors.blue
                                      : AdminColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    u['user_name'] as String? ?? '—',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AdminColors.textPrimary),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      if (u['user_username'] != null) ...[
                                        const Icon(Icons.alternate_email_rounded,
                                            size: 11,
                                            color: AdminColors.textSecondary),
                                        const SizedBox(width: 3),
                                        Text(u['user_username'] as String,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AdminColors.textSecondary)),
                                        const SizedBox(width: 10),
                                      ],
                                      const Icon(Icons.corporate_fare_rounded,
                                          size: 11,
                                          color: AdminColors.textSecondary),
                                      const SizedBox(width: 3),
                                      Text(
                                        u['org_name'] as String? ?? '—',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AdminColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Status + actions
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AdminColors.safetyGreen
                                            .withValues(alpha: 0.1)
                                        : AdminColors.error
                                            .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isActive
                                            ? AdminColors.safetyGreen
                                            : AdminColors.error),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded,
                                      color: AdminColors.textSecondary,
                                      size: 20),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  onSelected: (val) async {
                                    if (val == 'toggle') {
                                      await _toggleActive(context, ref,
                                          u['user_id'] as String, !isActive);
                                    } else if (val == 'password') {
                                      _showResetPasswordDialog(
                                          context, ref, u['user_id'] as String,
                                          u['user_name'] as String? ?? '');
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'password',
                                      child: Row(children: [
                                        const Icon(Icons.lock_reset_rounded,
                                            size: 16,
                                            color: AdminColors.deepNavy),
                                        const SizedBox(width: 8),
                                        const Text('Reset Password'),
                                      ]),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Row(children: [
                                        Icon(
                                          isActive
                                              ? Icons.block_rounded
                                              : Icons.check_circle_rounded,
                                          size: 16,
                                          color: isActive
                                              ? AdminColors.error
                                              : AdminColors.safetyGreen,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                            isActive ? 'Deactivate' : 'Activate'),
                                      ]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AdminColors.deepNavy)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: AdminColors.error))),
            ),
          ),
        ],
      ),
    );
  }

  // ── Create Admin Dialog ────────────────────────────────────────────────────

  void _showCreateUserDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String? selectedOrgId;
    bool saving = false;
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) => StatefulBuilder(
          builder: (ctx, setState) {
            final orgsAsync = ref.watch(allOrgsProvider);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: const Row(
                children: [
                  Icon(Icons.person_add_rounded, color: AdminColors.deepNavy),
                  SizedBox(width: 10),
                  Text('Create School Admin',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AdminColors.textPrimary)),
                ],
              ),
            content: SizedBox(
              width: 480,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Assign to school
                      orgsAsync.when(
                        data: (orgs) {
                          if (orgs.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AdminColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AdminColors.warning.withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: AdminColors.warning, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'No schools found! Please add a school under the "Organizations" tab first before creating an admin.',
                                      style: TextStyle(
                                          color: AdminColors.textPrimary,
                                          fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Assign to School *',
                              prefixIcon: Icon(Icons.corporate_fare_rounded),
                            ),
                            value: selectedOrgId,
                            hint: const Text('Select a school'),
                            items: orgs
                                .map((o) => DropdownMenuItem(
                                      value: o['org_id'] as String,
                                      child: Text(o['org_name'] as String),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => selectedOrgId = v),
                            validator: (v) => v == null
                                ? 'Please select a school'
                                : null,
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AdminColors.deepNavy),
                                ),
                                SizedBox(width: 10),
                                Text('Loading schools list...',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AdminColors.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                        error: (err, _) => Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AdminColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Failed to load schools: $err',
                              style: const TextStyle(
                                  color: AdminColors.error, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Full name
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      Row(children: [
                        // Username
                        Expanded(
                          child: TextFormField(
                            controller: usernameCtrl,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Username *',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                              hintText: 'e.g. dpsadmin',
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
                        // Phone
                        Expanded(
                          child: TextFormField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              prefixIcon: Icon(Icons.phone_rounded),
                              hintText: '+919876543210',
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),

                      // Email
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: 'admin@school.edu',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email required';
                          }
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Password
                      TextFormField(
                        controller: passCtrl,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => obscure = !obscure),
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
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setState(() => saving = true);
                        try {
                          await SupabaseService.client.rpc(
                            'create_user_account',
                            params: {
                              'p_name': nameCtrl.text.trim(),
                              'p_username':
                                  usernameCtrl.text.trim().toLowerCase(),
                              'p_phone': phoneCtrl.text.trim(),
                              'p_email': emailCtrl.text.trim().toLowerCase(),
                              'p_password': passCtrl.text,
                              'p_role': 'ADMIN',
                              'p_org_id': selectedOrgId,
                            },
                          );
                          ref.invalidate(allAdminUsersProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '✅ Admin "${nameCtrl.text.trim()}" created! They can log in with username: ${usernameCtrl.text.trim()}'),
                                backgroundColor: AdminColors.safetyGreen,
                                duration: const Duration(seconds: 5),
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
                    : const Text('Create Admin',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    ),
  );
}

  // ── Toggle Active ──────────────────────────────────────────────────────────

  Future<void> _toggleActive(BuildContext context, WidgetRef ref,
      String userId, bool newActive) async {
    try {
      await SupabaseService.client.rpc('set_user_active',
          params: {'p_user_id': userId, 'p_is_active': newActive});
      ref.invalidate(allAdminUsersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newActive
                ? '✅ Account activated'
                : '⛔ Account deactivated'),
            backgroundColor:
                newActive ? AdminColors.safetyGreen : AdminColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.error));
      }
    }
  }

  // ── Reset Password Dialog ──────────────────────────────────────────────────

  void _showResetPasswordDialog(
      BuildContext context, WidgetRef ref, String userId, String userName) {
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
                        await SupabaseService.client.rpc('reset_user_password',
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
