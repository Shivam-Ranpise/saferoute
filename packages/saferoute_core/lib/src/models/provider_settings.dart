import '../constants/enums.dart';

class ProviderSettings {
  final String id;
  final String organizationId;
  final ProviderType provider;
  final bool isEnabled;
  final Map<String, dynamic> config;
  final List<String> configSecretKeyNames;
  final DateTime? lastTestedAt;
  final String? testStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProviderSettings({
    required this.id,
    required this.organizationId,
    required this.provider,
    this.isEnabled = false,
    this.config = const {},
    this.configSecretKeyNames = const [],
    this.lastTestedAt,
    this.testStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProviderSettings.fromJson(Map<String, dynamic> json) =>
      ProviderSettings(
        id: json['id'] as String,
        organizationId: json['organization_id'] as String,
        provider: ProviderType.fromString(json['provider'] as String),
        isEnabled: json['is_enabled'] as bool? ?? false,
        config: json['config'] as Map<String, dynamic>? ?? const {},
        configSecretKeyNames:
            (json['config_secret_key_names'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                const [],
        lastTestedAt: json['last_tested_at'] != null
            ? DateTime.parse(json['last_tested_at'] as String)
            : null,
        testStatus: json['test_status'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'organization_id': organizationId,
        'provider': provider.toDbValue(),
        'is_enabled': isEnabled,
        'config': config,
        'config_secret_key_names': configSecretKeyNames,
        'last_tested_at': lastTestedAt?.toIso8601String(),
        'test_status': testStatus,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  ProviderSettings copyWith({
    String? id,
    String? organizationId,
    ProviderType? provider,
    bool? isEnabled,
    Map<String, dynamic>? config,
    List<String>? configSecretKeyNames,
    DateTime? lastTestedAt,
    String? testStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ProviderSettings(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        provider: provider ?? this.provider,
        isEnabled: isEnabled ?? this.isEnabled,
        config: config ?? this.config,
        configSecretKeyNames: configSecretKeyNames ?? this.configSecretKeyNames,
        lastTestedAt: lastTestedAt ?? this.lastTestedAt,
        testStatus: testStatus ?? this.testStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  bool get isConfigured => isEnabled && testStatus == 'SUCCESS';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderSettings &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
