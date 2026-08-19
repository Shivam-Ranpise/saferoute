import 'package:flutter/foundation.dart';

/// SafeRoute structured logger.
/// SECURITY: Never logs passwords, API keys, tokens, or provider secrets.
/// In production, this would pipe to a structured logging service.
class AppLogger {
  AppLogger._();

  static bool _verbose = false;

  static void setVerbose(bool verbose) => _verbose = verbose;

  static void info(String message, {String? context, Object? extra}) {
    if (kDebugMode) {
      final prefix = context != null ? '[$context] ' : '';
      debugPrint('ℹ️  SafeRoute | $prefix$message');
    }
    // In production, send to structured logging (e.g., Sentry breadcrumb)
  }

  static void warning(String message, {String? context, Object? extra}) {
    if (kDebugMode) {
      final prefix = context != null ? '[$context] ' : '';
      debugPrint('⚠️  SafeRoute | $prefix$message');
    }
  }

  static void error(
    String message, {
    String? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      final prefix = context != null ? '[$context] ' : '';
      debugPrint('❌ SafeRoute | $prefix$message');
      if (error != null) debugPrint('   Error: $error');
      if (stackTrace != null && _verbose) debugPrint('   Stack: $stackTrace');
    }
    // In production, send to error tracking (e.g., Sentry.captureException)
    // NEVER log: passwords, API keys, tokens, secrets
  }

  static void gps(String message, {double? lat, double? lon, double? accuracy}) {
    if (kDebugMode) {
      final location = (lat != null && lon != null)
          ? ' @ (${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)})'
          : '';
      final acc = accuracy != null ? ' ±${accuracy.toStringAsFixed(0)}m' : '';
      debugPrint('📍 SafeRoute | [GPS] $message$location$acc');
    }
  }

  static void notification(String message, {String? eventType, String? channel}) {
    if (kDebugMode) {
      final ctx = [eventType, channel].whereType<String>().join('/');
      final prefix = ctx.isNotEmpty ? '[$ctx] ' : '';
      debugPrint('🔔 SafeRoute | [Notification] $prefix$message');
    }
  }

  static void auth(String message, {String? userId}) {
    if (kDebugMode) {
      // Never log the actual user ID in production logs
      debugPrint('🔐 SafeRoute | [Auth] $message');
    }
  }

  static void trip(String message, {String? tripId, String? status}) {
    if (kDebugMode) {
      final ctx = status != null ? '[$status] ' : '';
      debugPrint('🚌 SafeRoute | [Trip] $ctx$message');
    }
  }
}
