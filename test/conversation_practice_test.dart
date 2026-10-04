import 'package:eloqia_ai/features/learning/sessions/conversation_session_screen.dart';
import 'package:eloqia_ai/models/learning_profile.dart';
import 'package:eloqia_ai/services/learning/learning_progress_service.dart';
import 'package:eloqia_ai/services/learning/learning_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'writing practice gives local feedback and records a completed session',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.binding.setSurfaceSize(const Size(430, 980));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationSessionScreen(
            profile: LearningProfile(name: 'Sam', currentLevel: 'B1'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1000));

      for (int challenge = 0; challenge < 3; challenge++) {
        final Finder response = find.byType(TextField);
        await tester.ensureVisible(response);
        await tester.enterText(
          response,
          'I enjoy learning English because it helps me connect with people. '
          'What do you enjoy learning?',
        );
        await tester.pump();
        await tester.ensureVisible(find.text('Submit response'));
        await tester.tap(find.text('Submit response'));
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.text('Local practice check'), findsOneWidget);
        expect(find.textContaining('words written'), findsOneWidget);
        expect(
          find.textContaining('no grammar score or AI review'),
          findsOneWidget,
        );

        final String nextLabel = challenge == 2
            ? 'Complete session'
            : 'Continue';
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.ensureVisible(find.text(nextLabel));
        await tester.tap(find.text(nextLabel));
        await tester.pump(const Duration(milliseconds: 300));
      }

      for (int attempt = 0; attempt < 10; attempt++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (find.text('Session recorded').evaluate().isNotEmpty) {
          break;
        }
      }
      expect(find.text('Session recorded'), findsOneWidget);

      final sessions = await LearningSessionService.getHistory();
      expect(sessions, hasLength(1));
      expect(sessions.single.completed, isTrue);
      expect(sessions.single.activityType.name, 'writing');
      expect(sessions.single.xpEarned, 10);
      expect((await LearningProgressService.getProgress()).xp, 10);
    },
  );
}
