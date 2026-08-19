import '../constants/app_config.dart';

/// Input validators for SafeRoute form fields and business rules.
class Validators {
  Validators._();

  // ─────────────────────────────────────────────
  // Auth Validators
  // ─────────────────────────────────────────────

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required.';
    }
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  // ─────────────────────────────────────────────
  // Profile Validators
  // ─────────────────────────────────────────────

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required.';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters.';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Please enter a valid phone number.';
    }
    return null;
  }

  // ─────────────────────────────────────────────
  // Notification Distance Validators
  // ─────────────────────────────────────────────

  static String? validateNotificationDistance(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a notification distance.';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Please enter a valid number.';
    }
    if (parsed < AppConfig.notificationDistanceMin) {
      return 'Minimum distance is ${AppConfig.notificationDistanceMin} meters.';
    }
    if (parsed > AppConfig.notificationDistanceMax) {
      return 'Maximum distance is ${AppConfig.notificationDistanceMax} meters.';
    }
    return null;
  }

  // ─────────────────────────────────────────────
  // Retention Validators
  // ─────────────────────────────────────────────

  static String? validateRetentionDays(String? value, {String label = 'Retention'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label days is required.';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Please enter a valid number.';
    }
    if (parsed < AppConfig.retentionMinDays) {
      return 'Minimum retention is ${AppConfig.retentionMinDays} day.';
    }
    if (parsed > AppConfig.retentionMaxDays) {
      return 'Maximum retention is ${AppConfig.retentionMaxDays} days (10 years).';
    }
    return null;
  }

  // ─────────────────────────────────────────────
  // Bus / Child Validators
  // ─────────────────────────────────────────────

  static String? validateBusNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bus number is required.';
    }
    return null;
  }

  static String? validateChildName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Child name is required.';
    }
    return null;
  }

  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  // ─────────────────────────────────────────────
  // Location Validators
  // ─────────────────────────────────────────────

  static bool isValidLatitude(double? lat) {
    if (lat == null) return false;
    return lat >= -90 && lat <= 90;
  }

  static bool isValidLongitude(double? lon) {
    if (lon == null) return false;
    return lon >= -180 && lon <= 180;
  }

  static bool isValidGpsCoordinate(double? lat, double? lon) {
    return isValidLatitude(lat) && isValidLongitude(lon);
  }

  // ─────────────────────────────────────────────
  // Alert Message Validators
  // ─────────────────────────────────────────────

  static String? validateAlertMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Alert message is required.';
    }
    if (value.trim().length > 500) {
      return 'Message must be under 500 characters.';
    }
    return null;
  }
}
