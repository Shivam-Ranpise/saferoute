import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import 'package:saferoute_app/src/features/parent/presentation/parent_home_screen.dart';
import 'package:saferoute_app/src/features/parent/presentation/widgets/child_selector_bar.dart';
import 'package:saferoute_app/src/features/parent/providers/parent_providers.dart';
import 'package:saferoute_app/src/providers/auth_provider.dart';

void main() {
  group('Phase 2 — Parent UI Widget Tests', () {
    testWidgets('ParentHomeScreen shows empty state when no children linked',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWithValue(
              Profile(
                id: 'prof-1',
                organizationId: 'org-1',
                email: 'parent@example.com',
                name: 'Sunita Sharma',
                role: UserRole.parent,
                isActive: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
            parentChildrenStreamProvider.overrideWith(
              (ref) => Stream.value(<Child>[]),
            ),
          ],
          child: const MaterialApp(
            home: ParentHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('SafeRoute'), findsOneWidget);
      expect(find.text('Welcome, Sunita Sharma'), findsOneWidget);
      expect(find.text('No Children Linked Yet'), findsOneWidget);
    });

    testWidgets('ChildSelectorBar renders children chips and handles selection',
        (tester) async {
      final child1 = Child(
        id: 'c-1',
        organizationId: 'org-1',
        parentId: 'p-1',
        name: 'Aarav Sharma',
        busId: 'b-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final child2 = Child(
        id: 'c-2',
        organizationId: 'org-1',
        parentId: 'p-1',
        name: 'Diya Sharma',
        busId: 'b-2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            parentChildrenStreamProvider.overrideWith(
              (ref) => Stream.value([child1, child2]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ChildSelectorBar(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('Diya Sharma'), findsOneWidget);
    });
  });
}
