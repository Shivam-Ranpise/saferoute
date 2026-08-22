class Organization {
  final String id;
  final String name;
  final String? logoUrl;
  final String timezone;
  final bool isActive;

  // Driver permission flags
  final bool driverCanBroadcastOrgWide;
  final bool driverCanSendEmergencyAlerts;
  final bool driverCanSendCustomAlerts;
  final bool emergencyOverrideEnabled;

  // Data retention (days)
  final int gpsHistoryRetentionDays;
  final int notificationLogRetentionDays;
  final int emergencyAlertRetentionDays;
  final int tripHistoryRetentionDays;
  final int deviceTokenRetentionDays;
  final int auditLogRetentionDays;

  final String? address;
  final double? latitude;
  final double? longitude;
  final int geofenceRadiusMeters;
  final Map<String, dynamic> notificationSettings;
  final Map<String, dynamic> apiParameters;
  final Map<String, dynamic> schoolSchedule;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Organization({
    required this.id,
    required this.name,
    this.logoUrl,
    this.timezone = 'UTC',
    this.isActive = true,
    this.driverCanBroadcastOrgWide = false,
    this.driverCanSendEmergencyAlerts = true,
    this.driverCanSendCustomAlerts = true,
    this.emergencyOverrideEnabled = false,
    this.gpsHistoryRetentionDays = 30,
    this.notificationLogRetentionDays = 90,
    this.emergencyAlertRetentionDays = 180,
    this.tripHistoryRetentionDays = 365,
    this.deviceTokenRetentionDays = 60,
    this.auditLogRetentionDays = 365,
    this.address,
    this.latitude,
    this.longitude,
    this.geofenceRadiusMeters = 200,
    this.notificationSettings = const {},
    this.apiParameters = const {},
    this.schoolSchedule = const {
      'start_time': '10:00',
      'end_time': '17:00',
      'working_days': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
    },
    required this.createdAt,
    required this.updatedAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) => Organization(
        id: json['id'] as String,
        name: json['name'] as String,
        logoUrl: json['logo_url'] as String?,
        timezone: json['timezone'] as String? ?? 'UTC',
        isActive: json['is_active'] as bool? ?? true,
        driverCanBroadcastOrgWide:
            json['driver_can_broadcast_org_wide'] as bool? ?? false,
        driverCanSendEmergencyAlerts:
            json['driver_can_send_emergency_alerts'] as bool? ?? true,
        driverCanSendCustomAlerts:
            json['driver_can_send_custom_alerts'] as bool? ?? true,
        emergencyOverrideEnabled:
            json['emergency_override_enabled'] as bool? ?? false,
        gpsHistoryRetentionDays:
            json['gps_history_retention_days'] as int? ?? 30,
        notificationLogRetentionDays:
            json['notification_log_retention_days'] as int? ?? 90,
        emergencyAlertRetentionDays:
            json['emergency_alert_retention_days'] as int? ?? 180,
        tripHistoryRetentionDays:
            json['trip_history_retention_days'] as int? ?? 365,
        deviceTokenRetentionDays:
            json['device_token_retention_days'] as int? ?? 60,
        auditLogRetentionDays: json['audit_log_retention_days'] as int? ?? 365,
        address: json['address'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        geofenceRadiusMeters: json['geofence_radius_meters'] as int? ?? 200,
        notificationSettings:
            (json['notification_settings'] as Map<String, dynamic>?) ?? const {},
        apiParameters:
            (json['api_parameters'] as Map<String, dynamic>?) ?? const {},
        schoolSchedule: (json['school_schedule'] as Map<String, dynamic>?) ??
            (json['api_parameters'] is Map &&
                    (json['api_parameters'] as Map)['school_schedule'] is Map
                ? Map<String, dynamic>.from(
                    (json['api_parameters'] as Map)['school_schedule'] as Map)
                : const {
                    'start_time': '10:00',
                    'end_time': '17:00',
                    'working_days': [
                      'Monday',
                      'Tuesday',
                      'Wednesday',
                      'Thursday',
                      'Friday'
                    ]
                  }),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logo_url': logoUrl,
        'timezone': timezone,
        'is_active': isActive,
        'driver_can_broadcast_org_wide': driverCanBroadcastOrgWide,
        'driver_can_send_emergency_alerts': driverCanSendEmergencyAlerts,
        'driver_can_send_custom_alerts': driverCanSendCustomAlerts,
        'emergency_override_enabled': emergencyOverrideEnabled,
        'gps_history_retention_days': gpsHistoryRetentionDays,
        'notification_log_retention_days': notificationLogRetentionDays,
        'emergency_alert_retention_days': emergencyAlertRetentionDays,
        'trip_history_retention_days': tripHistoryRetentionDays,
        'device_token_retention_days': deviceTokenRetentionDays,
        'audit_log_retention_days': auditLogRetentionDays,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'geofence_radius_meters': geofenceRadiusMeters,
        'notification_settings': notificationSettings,
        'api_parameters': apiParameters,
        'school_schedule': schoolSchedule,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Organization copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? timezone,
    bool? isActive,
    bool? driverCanBroadcastOrgWide,
    bool? driverCanSendEmergencyAlerts,
    bool? driverCanSendCustomAlerts,
    bool? emergencyOverrideEnabled,
    int? gpsHistoryRetentionDays,
    int? notificationLogRetentionDays,
    int? emergencyAlertRetentionDays,
    int? tripHistoryRetentionDays,
    int? deviceTokenRetentionDays,
    int? auditLogRetentionDays,
    String? address,
    double? latitude,
    double? longitude,
    int? geofenceRadiusMeters,
    Map<String, dynamic>? notificationSettings,
    Map<String, dynamic>? apiParameters,
    Map<String, dynamic>? schoolSchedule,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Organization(
        id: id ?? this.id,
        name: name ?? this.name,
        logoUrl: logoUrl ?? this.logoUrl,
        timezone: timezone ?? this.timezone,
        isActive: isActive ?? this.isActive,
        driverCanBroadcastOrgWide:
            driverCanBroadcastOrgWide ?? this.driverCanBroadcastOrgWide,
        driverCanSendEmergencyAlerts:
            driverCanSendEmergencyAlerts ?? this.driverCanSendEmergencyAlerts,
        driverCanSendCustomAlerts:
            driverCanSendCustomAlerts ?? this.driverCanSendCustomAlerts,
        emergencyOverrideEnabled:
            emergencyOverrideEnabled ?? this.emergencyOverrideEnabled,
        gpsHistoryRetentionDays:
            gpsHistoryRetentionDays ?? this.gpsHistoryRetentionDays,
        notificationLogRetentionDays:
            notificationLogRetentionDays ?? this.notificationLogRetentionDays,
        emergencyAlertRetentionDays:
            emergencyAlertRetentionDays ?? this.emergencyAlertRetentionDays,
        tripHistoryRetentionDays:
            tripHistoryRetentionDays ?? this.tripHistoryRetentionDays,
        deviceTokenRetentionDays:
            deviceTokenRetentionDays ?? this.deviceTokenRetentionDays,
        auditLogRetentionDays:
            auditLogRetentionDays ?? this.auditLogRetentionDays,
        address: address ?? this.address,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        geofenceRadiusMeters:
            geofenceRadiusMeters ?? this.geofenceRadiusMeters,
        notificationSettings:
            notificationSettings ?? this.notificationSettings,
        apiParameters: apiParameters ?? this.apiParameters,
        schoolSchedule: schoolSchedule ?? this.schoolSchedule,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Organization &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
