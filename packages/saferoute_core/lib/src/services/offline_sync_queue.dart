import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../utils/logger.dart';

enum OfflineItemType { telemetry, manifestUpdate }

class QueuedSyncItem {
  final String id;
  final OfflineItemType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int retryCount;

  QueuedSyncItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
      };
}

/// Thread-safe Offline Sync Queue for cellular dead-zone telemetry buffering
class OfflineSyncQueue {
  OfflineSyncQueue._();
  static final OfflineSyncQueue instance = OfflineSyncQueue._();

  final List<QueuedSyncItem> _queue = [];
  bool _isOnline = true;
  bool _isSyncing = false;

  final _statusController = StreamController<int>.broadcast();

  /// Stream of pending queue item count
  Stream<int> get queueCountStream => _statusController.stream;

  /// Current number of items buffered in memory
  int get queueLength => _queue.length;

  /// Online connectivity status
  bool get isOnline => _isOnline;

  /// Syncing in-progress flag
  bool get isSyncing => _isSyncing;

  /// Sets connectivity status
  void setOnlineStatus(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      AppLogger.info(
        'Network status changed: ${_isOnline ? "ONLINE" : "OFFLINE"}',
        context: 'OfflineSyncQueue',
      );
      if (_isOnline && _queue.isNotEmpty) {
        flushQueue();
      }
    }
  }

  /// Adds a telemetry breadcrumb to the offline queue
  void enqueueTelemetry({
    required String tripId,
    required String organizationId,
    required double latitude,
    required double longitude,
    required double speed,
    required double heading,
    required double accuracy,
    required DateTime recordedAt,
  }) {
    final item = QueuedSyncItem(
      id: '${tripId}_${recordedAt.millisecondsSinceEpoch}',
      type: OfflineItemType.telemetry,
      payload: {
        'trip_id': tripId,
        'organization_id': organizationId,
        'latitude': latitude,
        'longitude': longitude,
        'speed_kmh': speed,
        'heading': heading,
        'accuracy_meters': accuracy,
        'recorded_at': recordedAt.toIso8601String(),
      },
      createdAt: DateTime.now(),
    );

    _queue.add(item);
    _statusController.add(_queue.length);
    AppLogger.info(
      'Buffered offline telemetry item (Queue size: ${_queue.length})',
      context: 'OfflineSyncQueue',
    );
  }

  /// Adds a passenger roll-call status update to the offline queue
  void enqueueManifestUpdate({
    required String manifestId,
    required String status,
    required DateTime updatedTime,
  }) {
    final item = QueuedSyncItem(
      id: '${manifestId}_${updatedTime.millisecondsSinceEpoch}',
      type: OfflineItemType.manifestUpdate,
      payload: {
        'id': manifestId,
        'status': status,
        'boarded_at': updatedTime.toIso8601String(),
      },
      createdAt: DateTime.now(),
    );

    _queue.add(item);
    _statusController.add(_queue.length);
    AppLogger.info(
      'Buffered offline manifest update (Queue size: ${_queue.length})',
      context: 'OfflineSyncQueue',
    );
  }

  /// Flushes queued records in chronological batches to Supabase
  Future<int> flushQueue([SupabaseClient? client]) async {
    if (_isSyncing || _queue.isEmpty || !_isOnline) {
      return 0;
    }

    _isSyncing = true;
    int syncedCount = 0;
    final db = client ?? SupabaseService.client;

    final itemsToSync = List<QueuedSyncItem>.from(_queue);

    for (final item in itemsToSync) {
      try {
        if (item.type == OfflineItemType.telemetry) {
          await db.from('trip_location_history').insert(item.payload);
        } else if (item.type == OfflineItemType.manifestUpdate) {
          await db.from('trip_passengers').update({
            'status': item.payload['status'],
            'boarded_at': item.payload['boarded_at'],
          }).eq('id', item.payload['id']);
        }

        _queue.remove(item);
        syncedCount++;
      } catch (e) {
        item.retryCount++;
        AppLogger.warning(
          'Failed to sync item ${item.id}, retry count: ${item.retryCount}',
          context: 'OfflineSyncQueue',
        );
        // Break on network error to preserve chronological ordering
        break;
      }
    }

    _isSyncing = false;
    _statusController.add(_queue.length);
    AppLogger.info(
      'Flush completed: $syncedCount items synced, ${_queue.length} remaining',
      context: 'OfflineSyncQueue',
    );
    return syncedCount;
  }

  /// Clears in-memory buffer (for testing and teardown)
  void clearQueue() {
    _queue.clear();
    _statusController.add(0);
  }
}
