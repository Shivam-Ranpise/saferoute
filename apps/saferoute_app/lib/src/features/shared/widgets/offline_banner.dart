import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final bool isOffline;
  final int queuedCount;
  final bool isSyncing;

  const OfflineBanner({
    super.key,
    required this.isOffline,
    required this.queuedCount,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline && queuedCount == 0 && !isSyncing) {
      return const SizedBox.shrink();
    }

    final isWarning = isOffline;
    final bgColor = isWarning
        ? const Color(0xFFD97706) // Amber 600
        : const Color(0xFF2563EB); // Blue 600

    final text = isSyncing
        ? 'Syncing $queuedCount buffered records...'
        : isOffline
            ? 'Offline Mode — Buffering telemetry ($queuedCount in queue)'
            : 'Synchronizing with fleet servers...';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSyncing
                ? Icons.sync_rounded
                : isOffline
                    ? Icons.cloud_off_rounded
                    : Icons.cloud_queue_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
