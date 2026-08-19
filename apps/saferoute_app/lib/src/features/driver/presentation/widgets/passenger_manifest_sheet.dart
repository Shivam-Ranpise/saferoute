import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/locale_provider.dart';
import '../../../../theme/app_theme.dart';
import '../../providers/driver_providers.dart';

class PassengerManifestSheet extends ConsumerWidget {
  const PassengerManifestSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(driverStudentsProvider);
    final statusMap = ref.watch(passengerStatusProvider);
    final loc = ref.watch(appLocalizationsProvider);

    return studentsAsync.when(
      data: (students) {
        if (students.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline,
                      color: SafeRouteColors.onSurfaceVariant, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    loc.translate('no_children_title'),
                    style: const TextStyle(color: SafeRouteColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        final boardedCount = statusMap.values.where((s) => s == 'boarded').length;
        final droppedCount = statusMap.values.where((s) => s == 'dropped_off').length;
        final absentCount = statusMap.values.where((s) => s == 'absent').length;

        return Column(
          children: [
            // Roster Summary Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: SafeRouteColors.surfaceVariant,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${loc.manifestTitle}: ${students.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: SafeRouteColors.deepNavy,
                    ),
                  ),
                  Row(
                    children: [
                      _buildCountBadge('$boardedCount ${loc.boarded}', SafeRouteColors.safetyGreen),
                      const SizedBox(width: 6),
                      _buildCountBadge('$droppedCount ${loc.dropped}', SafeRouteColors.blue),
                      const SizedBox(width: 6),
                      _buildCountBadge('$absentCount ${loc.absent}', SafeRouteColors.error),
                    ],
                  ),
                ],
              ),
            ),

            // Student List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: students.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final student = students[index];
                  final currentStatus = statusMap[student.id] ?? 'pending';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _getStatusColor(currentStatus).withValues(alpha: 0.2),
                          foregroundColor: _getStatusColor(currentStatus),
                          child: Text(
                            student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: SafeRouteColors.deepNavy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                student.pickupName ?? student.pickupAddress ?? 'Stop not configured',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: SafeRouteColors.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Status Toggle Dropdown / Popup
                        PopupMenuButton<String>(
                          initialValue: currentStatus,
                          tooltip: 'Update Student Status',
                          onSelected: (newStatus) {
                            ref
                                .read(passengerStatusProvider.notifier)
                                .setStatus(student.id, newStatus);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'boarded',
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: SafeRouteColors.safetyGreen, size: 18),
                                  const SizedBox(width: 8),
                                  Text(loc.boarded),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'dropped_off',
                              child: Row(
                                children: [
                                  const Icon(Icons.home, color: SafeRouteColors.blue, size: 18),
                                  const SizedBox(width: 8),
                                  Text(loc.dropped),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'absent',
                              child: Row(
                                children: [
                                  const Icon(Icons.cancel, color: SafeRouteColors.error, size: 18),
                                  const SizedBox(width: 8),
                                  Text(loc.absent),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'pending',
                              child: Row(
                                children: [
                                  const Icon(Icons.schedule, color: SafeRouteColors.disabled, size: 18),
                                  const SizedBox(width: 8),
                                  Text(loc.pending),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(currentStatus).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getStatusColor(currentStatus),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatStatusLabel(currentStatus, loc),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(currentStatus),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_drop_down,
                                    size: 16, color: _getStatusColor(currentStatus)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: SafeRouteColors.yellow),
      ),
      error: (e, _) => Center(
        child: Text('Failed to load roster: $e'),
      ),
    );
  }

  static Widget _buildCountBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static Color _getStatusColor(String status) {
    switch (status) {
      case 'boarded':
        return SafeRouteColors.safetyGreen;
      case 'dropped_off':
        return SafeRouteColors.blue;
      case 'absent':
        return SafeRouteColors.error;
      default:
        return SafeRouteColors.onSurfaceVariant;
    }
  }

  static String _formatStatusLabel(String status, dynamic loc) {
    switch (status) {
      case 'boarded':
        return loc.boarded;
      case 'dropped_off':
        return loc.dropped;
      case 'absent':
        return loc.absent;
      default:
        return loc.pending;
    }
  }
}

