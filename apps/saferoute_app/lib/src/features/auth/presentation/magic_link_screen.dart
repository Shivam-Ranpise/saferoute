import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../providers/auth_provider.dart';

/// Magic link callback handler screen.
/// Deep link: io.saferoute.app://login-callback
class MagicLinkScreen extends ConsumerWidget {
  const MagicLinkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B3E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (authState.isLoading) ...[
                const CircularProgressIndicator(
                  color: Color(0xFFFFC107),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Signing you in...',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ] else if (authState.isAuthenticated) ...[
                const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Signed in successfully!',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ] else ...[
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'The magic link has expired or is invalid.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go(AppConstants.routeLogin),
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(color: Color(0xFFFFC107)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
