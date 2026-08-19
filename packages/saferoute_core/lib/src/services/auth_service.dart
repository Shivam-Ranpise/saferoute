import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../constants/enums.dart';
import '../models/profile.dart';
import 'supabase_service.dart';
import '../utils/logger.dart';

/// SafeRoute Authentication Service.
///
/// SECURITY RULES:
/// - Role is ALWAYS resolved from the database (profiles table), never from JWT claims.
/// - After login, profile is fetched server-side and cached in secure storage.
/// - No role information is trusted from the client side.
/// - Magic link is supported for passwordless login.
///
/// All privileged operations are performed via Edge Functions using the service role.
class AuthService {
  AuthService._();

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ─────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────

  /// Sign in with username, mobile number, or email + password.
  /// Resolves the identifier to an email using the DB lookup function,
  /// then authenticates via Supabase Auth. User never needs to type an email.
  static Future<Profile> signInWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    try {
      String? email;

      // If looks like an email, use directly
      if (identifier.contains('@')) {
        email = identifier.trim().toLowerCase();
      } else {
        // Lookup email by username or phone via DB function (anon RPC call)
        final result = await SupabaseService.client.rpc(
          'lookup_email_by_identifier',
          params: {'p_identifier': identifier.trim()},
        );
        email = result as String?;
      }

      if (email == null || email.isEmpty) {
        throw const AuthException(
            'Account not found. Check your username, mobile number, or email.');
      }

      return await signInWithPassword(email: email, password: password);
    } on AuthException {
      rethrow;
    } catch (e) {
      AppLogger.error('Identifier sign in error', error: e, context: 'AuthService');
      throw const AuthException('Login failed. Please try again.');
    }
  }

  /// Sign in with email and password.
  /// Returns the user's profile after resolving role from the database.
  /// Throws [AuthException] on failure.
  static Future<Profile> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (response.user == null) {
        throw const AuthException(
            'Login failed. Please check your credentials.');
      }

      final profile = await _resolveAndCacheProfile(response.user!.id);
      AppLogger.info('User signed in: ${profile.role.name}',
          context: 'AuthService');
      return profile;
    } on AuthException {
      rethrow;
    } catch (e) {
      AppLogger.error('Sign in error', error: e, context: 'AuthService');
      throw const AuthException('Login failed. Please try again.');
    }
  }


  /// Send a magic link to the given email address.
  static Future<void> sendMagicLink(String email) async {
    try {
      await SupabaseService.client.auth.signInWithOtp(
        email: email.trim().toLowerCase(),
        emailRedirectTo: 'io.saferoute.app://login-callback',
      );
      AppLogger.info('Magic link sent to $email', context: 'AuthService');
    } catch (e) {
      AppLogger.error('Magic link send error',
          error: e, context: 'AuthService');
      throw const AuthException(
          'Failed to send magic link. Please try again.');
    }
  }

  /// Sign out the current user. Clears all cached credentials.
  static Future<void> signOut() async {
    try {
      await SupabaseService.client.auth.signOut();
      await _clearCachedCredentials();
      AppLogger.info('User signed out', context: 'AuthService');
    } catch (e) {
      AppLogger.error('Sign out error', error: e, context: 'AuthService');
      // Still clear local credentials even if server signout fails
      await _clearCachedCredentials();
    }
  }

  /// Get the current user's profile from the database.
  /// SECURITY: Role is resolved from DB, never from JWT claims.
  /// Returns null if not authenticated.
  static Future<Profile?> getCurrentProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;

    try {
      return await _fetchProfileFromDb(user.id);
    } catch (e) {
      AppLogger.error('Error fetching current profile',
          error: e, context: 'AuthService');
      // Try to return cached profile if available
      return await _getCachedProfile();
    }
  }

  /// Get the cached role (from secure storage).
  /// Use this ONLY for UI routing decisions — always verify against DB for sensitive operations.
  static Future<UserRole?> getCachedRole() async {
    try {
      final roleStr =
          await _secureStorage.read(key: AppConstants.storageKeyUserRole);
      if (roleStr == null) return null;
      return UserRole.fromString(roleStr);
    } catch (e) {
      return null;
    }
  }

  /// Get the cached organization ID (from secure storage).
  static Future<String?> getCachedOrgId() async {
    try {
      return await _secureStorage.read(key: AppConstants.storageKeyOrgId);
    } catch (e) {
      return null;
    }
  }

  /// Check if a session exists and is valid.
  static bool get hasValidSession {
    final session = SupabaseService.currentSession;
    if (session == null) return false;
    // Check if session is expired
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return true;
    return DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000)
        .isAfter(DateTime.now());
  }

  /// Stream of auth state changes.
  static Stream<AuthState> get authStateStream =>
      SupabaseService.authStateStream;

  // ─────────────────────────────────────────────
  // Private Helpers
  // ─────────────────────────────────────────────

  /// Fetch profile from Supabase DB and cache credentials.
  /// SECURITY: This is the ONLY place where role is determined — from DB, not JWT.
  static Future<Profile> _resolveAndCacheProfile(String userId) async {
    final profile = await _fetchProfileFromDb(userId);
    await _cacheProfile(profile);
    return profile;
  }

  static Future<Profile> _fetchProfileFromDb(String userId) async {
    final response = await SupabaseService.client
        .from(AppConstants.tableProfiles)
        .select()
        .eq('id', userId)
        .single();

    final profile = Profile.fromJson(response);

    if (!profile.isActive) {
      throw const AuthException(
        'Your account has been deactivated. Please contact your school administrator.',
      );
    }

    return profile;
  }

  static Future<void> _cacheProfile(Profile profile) async {
    await Future.wait([
      _secureStorage.write(
        key: AppConstants.storageKeyUserId,
        value: profile.id,
      ),
      _secureStorage.write(
        key: AppConstants.storageKeyUserRole,
        value: profile.role.toDbValue(),
      ),
      _secureStorage.write(
        key: AppConstants.storageKeyOrgId,
        value: profile.organizationId,
      ),
    ]);
  }

  static Future<Profile?> _getCachedProfile() async {
    // We can't reconstruct a full profile from secure storage alone —
    // just return null and let the UI show an offline/retry state.
    return null;
  }

  static Future<void> _clearCachedCredentials() async {
    await Future.wait([
      _secureStorage.delete(key: AppConstants.storageKeySessionToken),
      _secureStorage.delete(key: AppConstants.storageKeyRefreshToken),
      _secureStorage.delete(key: AppConstants.storageKeyUserId),
      _secureStorage.delete(key: AppConstants.storageKeyUserRole),
      _secureStorage.delete(key: AppConstants.storageKeyOrgId),
    ]);
  }
}
