import '../constants/enums.dart';

class Trip {
  final String id;
  final String organizationId;
  final String busId;
  final String driverId;
  final TripStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final double? currentLatitude;
  final double? currentLongitude;
  final double? currentSpeed;
  final double? currentHeading;
  final double? currentAccuracy;
  final DateTime? lastLocationAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Trip({
    required this.id,
    required this.organizationId,
    required this.busId,
    required this.driverId,
    this.status = TripStatus.idle,
    this.startedAt,
    this.endedAt,
    this.currentLatitude,
    this.currentLongitude,
    this.currentSpeed,
    this.currentHeading,
    this.currentAccuracy,
    this.lastLocationAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] as String,
        organizationId: json['organization_id'] as String,
        busId: json['bus_id'] as String,
        driverId: json['driver_id'] as String,
        status: json['status'] != null
            ? TripStatus.fromString(json['status'] as String)
            : TripStatus.idle,
        startedAt: json['started_at'] != null
            ? DateTime.parse(json['started_at'] as String)
            : null,
        endedAt: json['ended_at'] != null
            ? DateTime.parse(json['ended_at'] as String)
            : null,
        currentLatitude: (json['current_latitude'] as num?)?.toDouble(),
        currentLongitude: (json['current_longitude'] as num?)?.toDouble(),
        currentSpeed: (json['current_speed'] as num?)?.toDouble(),
        currentHeading: (json['current_heading'] as num?)?.toDouble(),
        currentAccuracy: (json['current_accuracy'] as num?)?.toDouble(),
        lastLocationAt: json['last_location_at'] != null
            ? DateTime.parse(json['last_location_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'organization_id': organizationId,
        'bus_id': busId,
        'driver_id': driverId,
        'status': status.toDbValue(),
        'started_at': startedAt?.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'current_latitude': currentLatitude,
        'current_longitude': currentLongitude,
        'current_speed': currentSpeed,
        'current_heading': currentHeading,
        'current_accuracy': currentAccuracy,
        'last_location_at': lastLocationAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Trip copyWith({
    String? id,
    String? organizationId,
    String? busId,
    String? driverId,
    TripStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
    double? currentLatitude,
    double? currentLongitude,
    double? currentSpeed,
    double? currentHeading,
    double? currentAccuracy,
    DateTime? lastLocationAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Trip(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        busId: busId ?? this.busId,
        driverId: driverId ?? this.driverId,
        status: status ?? this.status,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        currentLatitude: currentLatitude ?? this.currentLatitude,
        currentLongitude: currentLongitude ?? this.currentLongitude,
        currentSpeed: currentSpeed ?? this.currentSpeed,
        currentHeading: currentHeading ?? this.currentHeading,
        currentAccuracy: currentAccuracy ?? this.currentAccuracy,
        lastLocationAt: lastLocationAt ?? this.lastLocationAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  TripStatus get tripStatus => status;
  bool get hasLocation => currentLatitude != null && currentLongitude != null;
  bool get isOngoing => status.isOngoing;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Trip &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
