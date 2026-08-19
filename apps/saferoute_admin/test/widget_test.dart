import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import 'package:saferoute_admin/main.dart';
import 'package:saferoute_admin/src/providers/auth_provider.dart';

class MockAdminAuthNotifier extends StateNotifier<AdminAuthState>
    implements AdminAuthNotifier {
  MockAdminAuthNotifier()
      : super(
          AdminAuthState(
            isLoading: false,
            profile: Profile(
              id: 'admin-1',
              organizationId: 'org-1',
              email: 'admin@school.com',
              name: 'School Admin',
              role: UserRole.admin,
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        );

  @override
  Future<void> signInWithIdentifier(String identifier, String password) async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('SafeRouteAdminApp smoke test', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminAuthProvider.overrideWith((ref) => MockAdminAuthNotifier()),
        ],
        child: const SafeRouteAdminApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(SafeRouteAdminApp), findsOneWidget);
  });
}
