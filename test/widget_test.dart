import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eloqia_ai/main.dart';
import 'package:eloqia_ai/features/onboarding/mia_welcome_screen.dart';
import 'package:eloqia_ai/features/onboarding/onboarding_screen.dart';
import 'package:eloqia_ai/features/tutors/mia/mia_screen.dart';

void main() {
  testWidgets('Eloqia AI application starts successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EloqiaApp());

    await tester.pump(const Duration(milliseconds: 500));

    // Vérifie que MaterialApp existe
    expect(find.byType(MaterialApp), findsOneWidget);

    final Finder logo = find.byKey(const ValueKey<String>('eloqia-logo-full'));
    expect(logo, findsOneWidget);
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey<String>('splash-logo-visible')),
          )
          .opacity,
      greaterThan(0),
    );
    expect(
      find.ancestor(of: logo, matching: find.byType(ClipOval)),
      findsOneWidget,
    );
  });

  testWidgets(
    'Mia welcome is a standalone screen that continues to onboarding',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 920));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: MiaWelcomeScreen()));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(MiaWelcomeScreen), findsOneWidget);
      expect(find.text("Hi, I'm Mia."), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);

      final Finder continueButton = find.widgetWithText(
        FilledButton,
        "Let's begin",
      );
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.byType(OnboardingScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Mia reports missing secure voice configuration without starting a session',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(430, 920));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: MiaScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('CONFIGURATION REQUIRED'), findsOneWidget);
      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('Voice session consent'), findsNothing);
      expect(find.text('Writing Studio'), findsOneWidget);
    },
  );
}
