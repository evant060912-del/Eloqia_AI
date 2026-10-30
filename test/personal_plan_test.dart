import 'package:eloqia_ai/core/storage/local_storage.dart';
import 'package:eloqia_ai/features/home/widgets/personal_plan_card.dart';
import 'package:eloqia_ai/features/lessons/engine/lesson_engine.dart';
import 'package:eloqia_ai/features/lessons/models/lesson_models.dart';
import 'package:eloqia_ai/models/learning_profile.dart';
import 'package:eloqia_ai/services/learning/personal_plan.dart';
import 'package:eloqia_ai/services/learning/personal_plan_service.dart';
import 'package:eloqia_ai/services/progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

LearningProfile _traveller() => LearningProfile(
  currentLevel: 'B1',
  primaryGoal: 'travel',
  difficulties: <String>['grammar', 'confidence'],
  secondaryGoals: <String>['vocabulary'],
  strengths: <String>['listening'],
  learningPace: 'relaxed',
  interests: <String>['technology', 'music'],
);

void main() {
  group('plan', () {
    test('focus areas follow difficulties, goals and strengths', () {
      final PersonalPlan plan = PersonalPlan.from(_traveller());
      expect(plan.focus.map((PlanFocus f) => f.area), <PlanArea>[
        PlanArea.speaking,
        PlanArea.grammar,
        PlanArea.vocabulary,
      ]);
      expect(
        plan.focus.first.reason,
        'You said confidence when speaking is hard for you.',
      );
      expect(plan.dailyMinutes, 10);
      expect(plan.lessonTags, <String>{'travel', 'technology', 'culture'});
      expect(plan.examPrep, isFalse);
      expect(plan.bonusFor(PlanArea.speaking), 2);
      expect(plan.bonusFor(PlanArea.grammar), 1);
      expect(plan.bonusFor(PlanArea.listening), 0);
    });

    test('an empty profile gives an empty plan and a default goal', () {
      final PersonalPlan plan = PersonalPlan.from(LearningProfile());
      expect(plan.isEmpty, isTrue);
      expect(plan.dailyMinutes, 15);
    });

    test('academic goals suggest exam practice', () {
      final PersonalPlan plan = PersonalPlan.from(
        LearningProfile(
          primaryGoal: 'academic',
          strengths: <String>['writing'],
        ),
      );
      expect(plan.examPrep, isTrue);
      expect(plan.focus.map((PlanFocus f) => f.area), <PlanArea>[
        PlanArea.reading,
      ]);
    });

    test('recommendations start with a focus skill and say why', () {
      final LessonChoice choice = LessonEngine.recommend(profile: _traveller());
      expect(choice.lesson.skill, LessonSkill.grammar);
      expect(choice.reason, startsWith('You said grammar is hard for you.'));
    });
  });

  group('daily goal', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await LocalStorage.delete(PersonalPlanService.appliedKey);
    });

    test('follows the pace once, then never overwrites it', () async {
      final PersonalPlan plan = PersonalPlan.from(_traveller());
      expect(await PersonalPlanService.applyDailyGoalOnce(plan), isTrue);
      expect((await ProgressService.getSnapshot()).dailyGoal, 10);
      await ProgressService.setDailyGoal(25);
      expect(await PersonalPlanService.applyDailyGoalOnce(plan), isFalse);
      expect((await ProgressService.getSnapshot()).dailyGoal, 25);
    });

    test('nothing happens before the pace is chosen', () async {
      expect(
        await PersonalPlanService.applyDailyGoalOnce(
          PersonalPlan.from(LearningProfile()),
        ),
        isFalse,
      );
    });
  });

  testWidgets('the plan card shows each area with its reason', (
    WidgetTester tester,
  ) async {
    PlanArea? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PersonalPlanCard(
              plan: PersonalPlan.from(_traveller()),
              onOpen: (PlanArea area) => opened = area,
            ),
          ),
        ),
      ),
    );
    expect(find.text('YOUR PLAN'), findsOneWidget);
    expect(
      find.text('Daily goal: 10 minutes (pace: relaxed).'),
      findsOneWidget,
    );
    expect(find.text('You said grammar is hard for you.'), findsOneWidget);
    await tester.tap(find.text('Grammar'));
    expect(opened, PlanArea.grammar);
  });
}
