import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AdminAuthState {
  final Profile? profile;
  final bool isLoading;
  final String? errorMessage;

  const AdminAuthState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => profile != null;
  bool get isAdmin => profile?.role == UserRole.admin || profile?.role == UserRole.superAdmin;

  AdminAuthState copyWith({
    Profile? profile,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AdminAuthState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  AdminAuthNotifier() : super(const AdminAuthState(isLoading: true)) {
    _init();
  }

  void _init() async {
    await _resolveCurrentSession();
    SupabaseService.authStateStream.listen(_handleAuthStateChange);
  }

  Future<void> _resolveCurrentSession() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await AuthService.getCurrentProfile();
      if (profile != null && (profile.role == UserRole.admin || profile.role == UserRole.superAdmin)) {
        state = AdminAuthState(isLoading: false, profile: profile);
      } else {
        state = const AdminAuthState(isLoading: false);
      }
    } catch (e) {
      state = const AdminAuthState(isLoading: false);
    }
  }

  void _handleAuthStateChange(supabase.AuthState authState) async {
    if (authState.event == supabase.AuthChangeEvent.signedIn ||
        authState.event == supabase.AuthChangeEvent.tokenRefreshed) {
      await _resolveCurrentSession();
    } else if (authState.event == supabase.AuthChangeEvent.signedOut) {
      state = const AdminAuthState(isLoading: false);
    }
  }

  Future<void> signInWithIdentifier(String identifier, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await AuthService.signInWithIdentifier(
        identifier: identifier,
        password: password,
      );
      if (profile.role != UserRole.admin && profile.role != UserRole.superAdmin) {
        await AuthService.signOut();
        state = const AdminAuthState(
          isLoading: false,
          errorMessage: 'Access denied. Administrator privileges required.',
        );
        return;
      }
      state = AdminAuthState(isLoading: false, profile: profile);
    } catch (e) {
      state = AdminAuthState(
        isLoading: false,
        errorMessage: 'Invalid credentials. Check your username or email.',
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await AuthService.signOut();
    state = const AdminAuthState(isLoading: false);
  }
}

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  return AdminAuthNotifier();
});

final currentAdminProfileProvider = Provider<Profile?>((ref) {
  return ref.watch(adminAuthProvider).profile;
});
