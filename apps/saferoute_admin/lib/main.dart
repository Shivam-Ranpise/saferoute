import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import 'src/theme/admin_theme.dart';
import 'src/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase backend for Admin
  await SupabaseService.initialize();

  runApp(
    const ProviderScope(
      child: SafeRouteAdminApp(),
    ),
  );
}

class SafeRouteAdminApp extends ConsumerWidget {
  const SafeRouteAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'SafeRoute Admin — Fleet Command Center',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.lightTheme,
      routerConfig: router,
    );
  }
}
