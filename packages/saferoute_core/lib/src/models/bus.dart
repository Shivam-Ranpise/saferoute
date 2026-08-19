class Bus {
  final String id;
  final String organizationId;
  final String busNumber;
  final String? registrationNumber;
  final int? capacity;
  final bool isActive;
  final String? currentDriverId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Bus({
    required this.id,
    required this.organizationId,
    required this.busNumber,
    this.registrationNumber,
    this.capacity,
    this.isActive = true,
    this.currentDriverId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Bus.fromJson(Map<String, dynamic> json) => Bus(
        id: json['id'] as String,
        organizationId: json['organization_id'] as String,
        busNumber: json['bus_number'] as String,
        registrationNumber: json['registration_number'] as String?,
        capacity: json['capacity'] as int?,
        isActive: json['is_active'] as bool? ?? true,
        currentDriverId: json['current_driver_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'organization_id': organizationId,
        'bus_number': busNumber,
        'registration_number': registrationNumber,
        'capacity': capacity,
        'is_active': isActive,
        'current_driver_id': currentDriverId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Bus copyWith({
    String? id,
    String? organizationId,
    String? busNumber,
    String? registrationNumber,
    int? capacity,
    bool? isActive,
    String? currentDriverId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Bus(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        busNumber: busNumber ?? this.busNumber,
        registrationNumber: registrationNumber ?? this.registrationNumber,
        capacity: capacity ?? this.capacity,
        isActive: isActive ?? this.isActive,
        currentDriverId: currentDriverId ?? this.currentDriverId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bus &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
