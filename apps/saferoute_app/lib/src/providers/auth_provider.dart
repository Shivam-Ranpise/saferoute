import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../features/notifications/services/app_notification_service.dart';

/// Auth state — tracks current user session and profile.
@immutable
class SafeRouteAuthState {
  final bool isLoading;
  final Profile? profile;
  final String? error;

  const SafeRouteAuthState({
    this.isLoading = true,
    this.profile,
    this.error,
  });

  bool get isAuthenticated => profile != null;
  UserRole? get role => profile?.role;

  SafeRouteAuthState copyWith({
    bool? isLoading,
    Profile? profile,
    String? error,
    bool clearError = false,
    bool clearProfile = false,
  }) {
    return SafeRouteAuthState(
      isLoading: isLoading ?? this.isLoading,
      profile: clearProfile ? null : (profile ?? this.profile),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Auth state notifier — manages sign-in, sign-out, role resolution.
/// Hand-written (no code gen) to avoid riverpod_generator/SDK incompatibility.
class AuthNotifier extends StateNotifier<SafeRouteAuthState> {
  AuthNotifier() : super(const SafeRouteAuthState(isLoading: true)) {
    _init();
  }

  void _init() async {
    // Initialize from current session
    await _resolveCurrentSession();

    // Listen to Supabase auth state changes
    SupabaseService.authStateStream.listen(_handleAuthStateChange);
  }

  Future<void> _resolveCurrentSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await AuthService.getCurrentProfile();
      state = SafeRouteAuthState(isLoading: false, profile: profile);
      if (profile != null) {
        AppNotificationHelper.registerDevicePushToken(profile.id);
      }
    } catch (e) {
      AppLogger.auth('Session initialization failed: ${e.runtimeType}');
      state = const SafeRouteAuthState(isLoading: false);
    }
  }

  void _handleAuthStateChange(supabase.AuthState authState) async {
    switch (authState.event) {
      case supabase.AuthChangeEvent.signedIn:
      case supabase.AuthChangeEvent.tokenRefreshed:
        if (authState.session?.user != null) {
          state = state.copyWith(isLoading: true, clearError: true);
          try {
            final profile = await AuthService.getCurrentProfile();
            state = SafeRouteAuthState(isLoading: false, profile: profile);
            if (profile != null) {
              AppNotificationHelper.registerDevicePushToken(profile.id);
            }
          } catch (e) {
            state = const SafeRouteAuthState(
              isLoading: false,
              error: AppConstants.errGeneric,
            );
          }
        }
        break;
      case supabase.AuthChangeEvent.signedOut:
        state = const SafeRouteAuthState(isLoading: false);
        break;
      default:
        break;
    }
  }

  Future<void> signInWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await AuthService.signInWithIdentifier(
        identifier: identifier,
        password: password,
      );
      state = SafeRouteAuthState(isLoading: false, profile: profile);
      if (profile != null) {
        AppNotificationHelper.registerDevicePushToken(profile.id);
      }
    } on supabase.AuthException catch (e) {
      AppLogger.auth('Sign in failed: ${e.message}');
      state = SafeRouteAuthState(
        isLoading: false,
        error: _humanizeAuthError(e.message),
      );
    } catch (e) {
      AppLogger.error('Sign in unexpected error', error: e);
      state = SafeRouteAuthState(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', '').replaceFirst('AuthException: ', ''),
      );
    }
  }


  Future<bool> sendMagicLink(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await AuthService.sendMagicLink(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = const SafeRouteAuthState(
        isLoading: false,
        error: 'Failed to send magic link. Please check your email and try again.',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await AppNotificationHelper.unregisterDevicePushToken();
    await AuthService.signOut();
    state = const SafeRouteAuthState(isLoading: false);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _humanizeAuthError(String message) {
    if (message.contains('Invalid login credentials') ||
        message.contains('invalid_credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Please verify your email address before logging in.';
    }
    if (message.contains('Too many requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return AppConstants.errGeneric;
  }
}

/// Main auth provider — hand-written StateNotifierProvider (no code gen needed)
final authProvider =
    StateNotifierProvider<AuthNotifier, SafeRouteAuthState>((ref) {
  return AuthNotifier();
});

/// Convenience provider for just the current profile.
final currentProfileProvider = Provider<Profile?>((ref) {
  return ref.watch(authProvider).profile;
});

/// Convenience provider for the current user's role.
final currentRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(authProvider).role;
});
