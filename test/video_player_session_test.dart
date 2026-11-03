import 'package:eloqia_ai/features/lessons/models/lesson_models.dart';
import 'package:eloqia_ai/features/lessons/ui/video_clip_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const VideoClip _clip = VideoClip.mp4(
  url: 'https://example.com/video.mp4',
  credit: 'Test video. Public domain.',
  sourcePage: 'https://example.com/page.html',
);

void main() {
  setUp(() => VideoClipSession.loadTimeout = const Duration(milliseconds: 1));
  tearDown(() => VideoClipSession.loadTimeout = const Duration(seconds: 25));

  testWidgets('a video that cannot load offers the original page', (
    WidgetTester tester,
  ) async {
    final VideoClipSession session = VideoClipSession(_clip);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VideoClipPlayer(clip: _clip, session: session),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 10));
    expect(session.state.value, VideoLoadState.failed);
    expect(find.byKey(const Key('video-open-source')), findsOneWidget);
    expect(find.textContaining('Public domain'), findsOneWidget);

    // The lesson owns the session: removing the player keeps it usable.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    session.state.value = VideoLoadState.loading;
    expect(session.state.value, VideoLoadState.loading);
    session.dispose();
  });
}
