class Child {
  final String id;
  final String organizationId;
  final String? parentId;
  final String name;
  final String? photoUrl;
  final String? busId;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? pickupName;
  final String? pickupAddress;
  final int notificationDistanceMeters;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Child({
    required this.id,
    required this.organizationId,
    this.parentId,
    required this.name,
    this.photoUrl,
    this.busId,
    this.pickupLatitude,
    this.pickupLongitude,
    this.pickupName,
    this.pickupAddress,
    this.notificationDistanceMeters = 500,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Child.fromJson(Map<String, dynamic> json) => Child(
        id: json['id'] as String,
        organizationId: json['organization_id'] as String,
        parentId: json['parent_id'] as String?,
        name: json['name'] as String,
        photoUrl: json['photo_url'] as String?,
        busId: json['bus_id'] as String?,
        pickupLatitude: (json['pickup_latitude'] as num?)?.toDouble(),
        pickupLongitude: (json['pickup_longitude'] as num?)?.toDouble(),
        pickupName: json['pickup_name'] as String?,
        pickupAddress: json['pickup_address'] as String?,
        notificationDistanceMeters:
            json['notification_distance_meters'] as int? ?? 500,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'organization_id': organizationId,
        if (parentId != null) 'parent_id': parentId,
        'name': name,
        'photo_url': photoUrl,
        'bus_id': busId,
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'pickup_name': pickupName,
        'pickup_address': pickupAddress,
        'notification_distance_meters': notificationDistanceMeters,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Child copyWith({
    String? id,
    String? organizationId,
    String? parentId,
    String? name,
    String? photoUrl,
    String? busId,
    double? pickupLatitude,
    double? pickupLongitude,
    String? pickupName,
    String? pickupAddress,
    int? notificationDistanceMeters,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Child(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        parentId: parentId ?? this.parentId,
        name: name ?? this.name,
        photoUrl: photoUrl ?? this.photoUrl,
        busId: busId ?? this.busId,
        pickupLatitude: pickupLatitude ?? this.pickupLatitude,
        pickupLongitude: pickupLongitude ?? this.pickupLongitude,
        pickupName: pickupName ?? this.pickupName,
        pickupAddress: pickupAddress ?? this.pickupAddress,
        notificationDistanceMeters:
            notificationDistanceMeters ?? this.notificationDistanceMeters,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  bool get hasPickupLocation =>
      pickupLatitude != null && pickupLongitude != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Child &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
