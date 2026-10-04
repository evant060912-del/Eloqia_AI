import 'package:eloqia_ai/features/onboarding/assessment/level_assessment_screen.dart';
import 'package:eloqia_ai/models/learning_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('assessment shows contextual Mia feedback before advancing', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: LevelAssessmentScreen(
          profile: LearningProfile(currentLevel: 'A1'),
          onFinished: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('START ASSESSMENT'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('She ___ a student.'), findsOneWidget);
    await tester.tap(find.text('are'));
    await tester.pump();
    await tester.tap(find.text('CHECK ANSWER'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('MIA / GENTLE CORRECTION'), findsOneWidget);
    expect(find.text('Almost.'), findsOneWidget);
    expect(find.textContaining('singular subject'), findsOneWidget);
    expect(find.text('Where can you buy bread?'), findsNothing);

    await tester.tap(find.text('CONTINUE'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Where can you buy bread?'), findsOneWidget);
  });
}
