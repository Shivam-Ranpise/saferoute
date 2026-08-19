class TripLocationHistory {
  final String id;
  final String organizationId;
  final String tripId;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final double? accuracy;
  final DateTime recordedAt;
  final DateTime createdAt;

  const TripLocationHistory({
    required this.id,
    required this.organizationId,
    required this.tripId,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    this.accuracy,
    required this.recordedAt,
    required this.createdAt,
  });

  factory TripLocationHistory.fromJson(Map<String, dynamic> json) =>
      TripLocationHistory(
        id: json['id'] as String,
        organizationId: json['organization_id'] as String,
        tripId: json['trip_id'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        speed: (json['speed'] as num?)?.toDouble(),
        heading: (json['heading'] as num?)?.toDouble(),
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        recordedAt: DateTime.parse(json['recorded_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'organization_id': organizationId,
        'trip_id': tripId,
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'heading': heading,
        'accuracy': accuracy,
        'recorded_at': recordedAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  TripLocationHistory copyWith({
    String? id,
    String? organizationId,
    String? tripId,
    double? latitude,
    double? longitude,
    double? speed,
    double? heading,
    double? accuracy,
    DateTime? recordedAt,
    DateTime? createdAt,
  }) =>
      TripLocationHistory(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        tripId: tripId ?? this.tripId,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        speed: speed ?? this.speed,
        heading: heading ?? this.heading,
        accuracy: accuracy ?? this.accuracy,
        recordedAt: recordedAt ?? this.recordedAt,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripLocationHistory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
