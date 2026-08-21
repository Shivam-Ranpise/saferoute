import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../theme/admin_theme.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final allOrgsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final result =
        await SupabaseService.client.rpc('get_all_organizations');
    return List<Map<String, dynamic>>.from(result as List);
  },
);

// ─── Screen ──────────────────────────────────────────────────────────────────

class SuperAdminOrgsScreen extends ConsumerWidget {
  const SuperAdminOrgsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgsAsync = ref.watch(allOrgsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action Bar
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'School Organizations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Each organization is a separate school with its own admin, drivers, and parents.',
                    style: TextStyle(
                        fontSize: 12, color: AdminColors.textSecondary),
                  ),
                ],
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
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add School',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onPressed: () => _showCreateOrgDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // List
          Expanded(
            child: orgsAsync.when(
              data: (orgs) {
                if (orgs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.corporate_fare_rounded,
                            size: 56,
                            color:
                                AdminColors.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        const Text('No schools yet.',
                            style: TextStyle(
                                fontSize: 16, color: AdminColors.textSecondary)),
                        const SizedBox(height: 8),
                        const Text('Click "Add School" to create the first one.',
                            style: TextStyle(
                                fontSize: 13, color: AdminColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: orgs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final org = orgs[index];
                    final isActive = org['org_is_active'] as bool? ?? true;
                    final adminCount = org['admin_count'] ?? 0;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: AdminColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AdminColors.safetyGreen.withValues(alpha: 0.1)
                                    : AdminColors.textSecondary
                                        .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.school_rounded,
                                color: isActive
                                    ? AdminColors.safetyGreen
                                    : AdminColors.textSecondary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    org['org_name'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AdminColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.schedule_rounded,
                                          size: 12,
                                          color: AdminColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        org['org_timezone'] as String? ??
                                            'Asia/Kolkata',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AdminColors.textSecondary),
                                      ),
                                      const SizedBox(width: 14),
                                      Icon(Icons.person_rounded,
                                          size: 12,
                                          color: AdminColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$adminCount admin${adminCount != 1 ? "s" : ""}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AdminColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Status badge & Actions
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AdminColors.safetyGreen.withValues(alpha: 0.1)
                                        : AdminColors.error.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isActive
                                          ? AdminColors.safetyGreen
                                          : AdminColors.error,
                                    ),
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
                                    if (val == 'edit') {
                                      _showEditOrgDialog(
                                        context,
                                        ref,
                                        org['org_id'] as String,
                                        org['org_name'] as String? ?? '',
                                        org['org_timezone'] as String? ?? 'Asia/Kolkata',
                                      );
                                    } else if (val == 'toggle') {
                                      await _toggleOrgActive(
                                        context,
                                        ref,
                                        org['org_id'] as String,
                                        !isActive,
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
                                        Text('Edit School'),
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
                                        SizedBox(width: 8),
                                        Text(isActive ? 'Deactivate' : 'Activate'),
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

  void _showCreateOrgDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final tzCtrl = TextEditingController(text: 'Asia/Kolkata');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.corporate_fare_rounded, color: AdminColors.deepNavy),
              SizedBox(width: 10),
              Text('Add New School',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'School Name *',
                      hintText: 'e.g. Delhi Public School Noida',
                      prefixIcon: Icon(Icons.school_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'School name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: tzCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Timezone',
                      hintText: 'Asia/Kolkata',
                      prefixIcon: Icon(Icons.schedule_rounded),
                    ),
                  ),
                ],
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
                          'create_organization',
                          params: {
                            'p_name': nameCtrl.text.trim(),
                            'p_timezone': tzCtrl.text.trim().isEmpty
                                ? 'Asia/Kolkata'
                                : tzCtrl.text.trim(),
                          },
                        );
                        ref.invalidate(allOrgsProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '✅ School "${nameCtrl.text.trim()}" created successfully!'),
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
                  : const Text('Create School',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit School Dialog ───────────────────────────────────────────────────

  void _showEditOrgDialog(
    BuildContext context,
    WidgetRef ref,
    String orgId,
    String currentName,
    String currentTimezone,
  ) {
    final nameCtrl = TextEditingController(text: currentName);
    final tzCtrl = TextEditingController(text: currentTimezone);
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.edit_rounded, color: AdminColors.deepNavy),
              SizedBox(width: 10),
              Text('Edit School',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'School Name *',
                      prefixIcon: Icon(Icons.school_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'School name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: tzCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Timezone',
                      hintText: 'Asia/Kolkata',
                      prefixIcon: Icon(Icons.schedule_rounded),
                    ),
                  ),
                ],
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
                          'update_organization_by_superadmin',
                          params: {
                            'p_org_id': orgId,
                            'p_name': nameCtrl.text.trim(),
                            'p_timezone': tzCtrl.text.trim().isEmpty
                                ? 'Asia/Kolkata'
                                : tzCtrl.text.trim(),
                          },
                        );
                        ref.invalidate(allOrgsProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '✅ School "${nameCtrl.text.trim()}" updated successfully!'),
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
                  : const Text('Save Changes',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Toggle Active Organization ───────────────────────────────────────────

  Future<void> _toggleOrgActive(
    BuildContext context,
    WidgetRef ref,
    String orgId,
    bool newActive,
  ) async {
    try {
      await SupabaseService.client.rpc(
        'set_organization_active',
        params: {
          'p_org_id': orgId,
          'p_is_active': newActive,
        },
      );
      ref.invalidate(allOrgsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newActive
                ? '✅ School activated'
                : '⛔ School deactivated'),
            backgroundColor:
                newActive ? AdminColors.safetyGreen : AdminColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AdminColors.error,
          ),
        );
      }
    }
  }
}
