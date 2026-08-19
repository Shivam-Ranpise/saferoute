import '../constants/enums.dart';

class TripChildProximityState {
  final String id;
  final String tripId;
  final String childId;
  final ProximityState state;
  final double? lastDistanceMeters;
  final DateTime? lastEvaluatedAt;
  final DateTime? notifiedAt;
  final DateTime updatedAt;

  const TripChildProximityState({
    required this.id,
    required this.tripId,
    required this.childId,
    this.state = ProximityState.outside,
    this.lastDistanceMeters,
    this.lastEvaluatedAt,
    this.notifiedAt,
    required this.updatedAt,
  });

  factory TripChildProximityState.fromJson(Map<String, dynamic> json) =>
      TripChildProximityState(
        id: json['id'] as String,
        tripId: json['trip_id'] as String,
        childId: json['child_id'] as String,
        state: json['state'] != null
            ? ProximityState.fromString(json['state'] as String)
            : ProximityState.outside,
        lastDistanceMeters: (json['last_distance_meters'] as num?)?.toDouble(),
        lastEvaluatedAt: json['last_evaluated_at'] != null
            ? DateTime.parse(json['last_evaluated_at'] as String)
            : null,
        notifiedAt: json['notified_at'] != null
            ? DateTime.parse(json['notified_at'] as String)
            : null,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'trip_id': tripId,
        'child_id': childId,
        'state': state.toDbValue(),
        'last_distance_meters': lastDistanceMeters,
        'last_evaluated_at': lastEvaluatedAt?.toIso8601String(),
        'notified_at': notifiedAt?.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  TripChildProximityState copyWith({
    String? id,
    String? tripId,
    String? childId,
    ProximityState? state,
    double? lastDistanceMeters,
    DateTime? lastEvaluatedAt,
    DateTime? notifiedAt,
    DateTime? updatedAt,
  }) =>
      TripChildProximityState(
        id: id ?? this.id,
        tripId: tripId ?? this.tripId,
        childId: childId ?? this.childId,
        state: state ?? this.state,
        lastDistanceMeters: lastDistanceMeters ?? this.lastDistanceMeters,
        lastEvaluatedAt: lastEvaluatedAt ?? this.lastEvaluatedAt,
        notifiedAt: notifiedAt ?? this.notifiedAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  ProximityState get proximityStatus => state;
  bool get isNotificationSent => state.isNotificationSent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripChildProximityState &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
