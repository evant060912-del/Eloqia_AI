import 'package:eloqia_ai/app/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('AppShell opens each implemented navigation tab', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('ELOQIA AI'), findsOneWidget);

    await tester.tap(find.text('Talk'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('YOUR AI ENGLISH TUTOR'), findsOneWidget);

    await tester.tap(find.text('Learn'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Recommended next step'), findsOneWidget);

    await tester.tap(find.text('Progress'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Progress').first, findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Learning DNA'), findsOneWidget);
  });
}
