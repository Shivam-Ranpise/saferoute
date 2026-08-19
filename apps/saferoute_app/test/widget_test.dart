import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_app/src/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('SplashScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    expect(find.text('SafeRoute'), findsWidgets);
    expect(find.text('Every Child. Every Mile. Safely.'), findsOneWidget);
  });
}
