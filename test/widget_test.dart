import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundsense/app.dart';
import 'package:soundsense/core/database/sonic_database.dart';
import 'package:soundsense/core/providers/app_providers.dart';
import 'package:soundsense/features/navigation/app_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SonicDatabase db;

  setUp(() {
    db = SonicDatabase.inMemory();
  });

  tearDown(() {
    db.dispose();
  });

  testWidgets('SonicApp renders Onboarding flow', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const SonicApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sound Awareness for Everyone'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Tap Next
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Teach Sonic Your World'), findsOneWidget);
  });

  testWidgets('AppScaffold renders bottom navigation bar and tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          home: AppScaffold(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Verify 4 bottom navigation items
    expect(find.text('Live Monitor'), findsOneWidget);
    expect(find.text('Teach Sound'), findsOneWidget);
    expect(find.text('Alert History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify listening active badge is rendered
    expect(find.text('● LISTENING FOR CRITICAL SOUNDS'), findsOneWidget);

    // Tap Teach Sound tab
    await tester.tap(find.text('Teach Sound'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('1. Name Your Sound'), findsOneWidget);

    // Tap Alert History tab
    await tester.tap(find.text('Alert History'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('No Alerts Recorded Yet'), findsOneWidget);

    // Tap Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Manage Taught Sounds'), findsOneWidget);
    expect(find.text('Continuous Background Listening'), findsOneWidget);
  });
}
