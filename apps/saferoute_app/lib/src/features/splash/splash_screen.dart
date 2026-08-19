import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Splash screen — checks session, resolves role, routes accordingly.
/// Shows the SafeRoute logo and brand identity during initialization.
/// This screen auto-navigates via GoRouter redirect once auth state resolves.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B3E), // deepNavy
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Hero(
              tag: 'saferoute_logo',
              child: Image.asset(
                'assets/images/saferoute_logo.png',
                width: 200,
                height: 160,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if logo not found
                  return const Column(
                    children: [
                      Icon(Icons.directions_bus,
                          color: Colors.yellow, size: 80),
                      SizedBox(height: 12),
                      Text(
                        'SafeRoute',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'SafeRoute',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Every Child. Every Mile. Safely.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 64),
            // Loading indicator
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: Color(0xFFFFC107), // yellow
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
