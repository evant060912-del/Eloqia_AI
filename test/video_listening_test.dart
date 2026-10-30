import 'package:eloqia_ai/features/lessons/content/video_listening_content.dart';
import 'package:eloqia_ai/features/lessons/engine/lesson_engine.dart';
import 'package:eloqia_ai/features/lessons/models/lesson_models.dart';
import 'package:eloqia_ai/features/lessons/ui/video_clip_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('video lessons point to legal sources and are in the catalog', () {
    expect(videoListeningLessons, isNotEmpty);
    for (final Lesson lesson in videoListeningLessons) {
      final VideoClip clip = lesson.video!;
      expect(LessonCatalog.byId(lesson.id), isNotNull);
      expect(lesson.skill, LessonSkill.listening);
      expect(clip.credit, isNotEmpty);
      expect(clip.sourcePage, startsWith('https://'));
      if (clip.isYoutube) {
        expect(lesson.audio, isEmpty, reason: 'no copied YouTube transcript');
      } else {
        expect(clip.url, startsWith('https://'));
        expect(clip.publicDomain, isTrue);
        expect(lesson.audio, isNotEmpty);
      }
    }
  });

  test('YouTube clips keep their id and extract', () {
    const VideoClip clip = VideoClip.youtube(
      id: 'AbCdEf12345',
      startSeconds: 30,
      endSeconds: 150,
      credit: 'Channel, title (YouTube).',
      sourcePage: 'https://www.youtube.com/watch?v=AbCdEf12345',
    );
    expect(clip.isYoutube, isTrue);
    expect(clip.publicDomain, isFalse);
    expect(clip.endSeconds, 150);
  });

  testWidgets('the credit and the transcript are shown', (
    WidgetTester tester,
  ) async {
    final Lesson lesson = LessonCatalog.byId('video-voa-welcome')!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VideoClipPlayer(
              clip: lesson.video!,
              transcript: lesson.audio,
              showTranscript: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Public domain'), findsOneWidget);
    await tester.tap(find.text('Show transcript'));
    await tester.pump();
    expect(find.textContaining('Are you Anna?'), findsOneWidget);
  });
}
