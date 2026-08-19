/// SafeRoute Core Package
/// Exports all shared models, services, utils, and constants.
library saferoute_core;

// Constants & Config
export 'src/constants/app_constants.dart';
export 'src/constants/app_config.dart';
export 'src/constants/enums.dart';

// Models
export 'src/models/organization.dart';
export 'src/models/profile.dart';
export 'src/models/parent.dart';
export 'src/models/driver.dart';
export 'src/models/bus.dart';
export 'src/models/child.dart';
export 'src/models/trip.dart';
export 'src/models/trip_location_history.dart';
export 'src/models/trip_child_proximity_state.dart';
export 'src/models/device_token.dart';
export 'src/models/notification_preferences.dart';
export 'src/models/notification_event_settings.dart';
export 'src/models/notification_event.dart';
export 'src/models/notification_delivery.dart';
export 'src/models/notification_template.dart';
export 'src/models/provider_settings.dart';
export 'src/models/audit_log.dart';

// Services & Repositories
export 'src/services/supabase_service.dart';
export 'src/services/auth_service.dart';
export 'src/services/location_service.dart';
export 'src/services/notification_service.dart';
export 'src/services/tenant_context.dart';
export 'src/services/offline_sync_queue.dart';
export 'src/repositories/parent_repository.dart';
export 'src/repositories/trip_repository.dart';
export 'src/repositories/driver_repository.dart';
export 'src/repositories/notification_repository.dart';
export 'src/repositories/admin_repository.dart';

// Utils
export 'src/utils/haversine.dart';
export 'src/utils/kalman_filter.dart';
export 'src/utils/adaptive_throttler.dart';
export 'src/utils/telemetry_compactor.dart';
export 'src/utils/route_simulator.dart';
export 'src/utils/demo_credentials.dart';
export 'src/utils/validators.dart';
export 'src/utils/logger.dart';
// Localization
export 'src/localization/app_localizations.dart';
