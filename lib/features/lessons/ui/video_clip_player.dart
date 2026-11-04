import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../theme/app_colors.dart';
import '../models/lesson_models.dart';

enum VideoLoadState { loading, ready, failed }

/// The video of one lesson, kept for the whole lesson: moving to the next
/// question keeps the video where it is instead of reloading it.
class VideoClipSession {
  VideoClipSession(this.clip);

  final VideoClip clip;
  final ValueNotifier<VideoLoadState> state = ValueNotifier<VideoLoadState>(
    VideoLoadState.loading,
  );
  VideoPlayerController? _video;
  YoutubePlayerController? _youtube;
  Timer? _timeout;
  bool _started = false;
  bool _disposed = false;

  /// How long to wait for a video before saying it could not load.
  static Duration loadTimeout = const Duration(seconds: 25);

  VideoPlayerController? get video => _video;
  YoutubePlayerController? get youtube => _youtube;

  void start() {
    if (_started) return;
    _started = true;
    if (clip.isYoutube) {
      _youtube = YoutubePlayerController.fromVideoId(
        videoId: clip.youtubeId!,
        startSeconds: clip.startSeconds.toDouble(),
        endSeconds: clip.endSeconds?.toDouble(),
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          enableCaption: true,
          captionLanguage: 'en',
          strictRelatedVideos: true,
        ),
      );
      state.value = VideoLoadState.ready;
      return;
    }
    unawaited(_initMp4(clip.url!));
  }

  Future<void> _initMp4(String url) async {
    final VideoPlayerController controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
    );
    _video = controller;
    _timeout = Timer(loadTimeout, () {
      if (state.value == VideoLoadState.loading) _fail('timeout');
    });
    try {
      await controller.initialize();
      if (_disposed) return;
      await controller.setVolume(1);
      controller.addListener(_watch);
      if (state.value == VideoLoadState.loading) {
        state.value = VideoLoadState.ready;
      }
    } on Object catch (error) {
      _fail(error);
    } finally {
      _timeout?.cancel();
    }
  }

  void _watch() {
    final VideoPlayerController? c = _video;
    if (c != null && c.value.hasError) _fail(c.value.errorDescription);
  }

  void _fail(Object? reason) {
    debugPrint('Video failed: $reason');
    if (!_disposed) state.value = VideoLoadState.failed;
  }

  void dispose() {
    _disposed = true;
    _timeout?.cancel();
    final VideoPlayerController? video = _video;
    if (video != null) {
      video.removeListener(_watch);
      unawaited(video.dispose().catchError((Object _) {}));
    }
    final YoutubePlayerController? youtube = _youtube;
    if (youtube != null) unawaited(youtube.close().catchError((Object _) {}));
    state.dispose();
  }
}

/// Plays the real video of a listening lesson: a public-domain MP4 (VOA
/// Learning English) or a YouTube video in YouTube's official player. The
/// transcript, when it may be shown, appears once the learner has answered.
class VideoClipPlayer extends StatefulWidget {
  const VideoClipPlayer({
    super.key,
    required this.clip,
    this.session,
    this.transcript = const <AudioLine>[],
    this.showTranscript = false,
  });

  final VideoClip clip;

  /// Shared by the lesson so the video survives question changes; without
  /// it the player owns its own.
  final VideoClipSession? session;
  final List<AudioLine> transcript;
  final bool showTranscript;

  @override
  State<VideoClipPlayer> createState() => _VideoClipPlayerState();
}

class _VideoClipPlayerState extends State<VideoClipPlayer> {
  late final VideoClipSession _session =
      widget.session ?? VideoClipSession(widget.clip);
  bool get _owned => widget.session == null;
  bool _transcriptOpen = false;

  @override
  void initState() {
    super.initState();
    _session.start();
  }

  @override
  void dispose() {
    if (_owned) _session.dispose();
    super.dispose();
  }

  Future<void> _openSource() async {
    final Uri uri = Uri.parse(widget.clip.sourcePage);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object catch (error) {
      debugPrint('Could not open $uri: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.white08),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ValueListenableBuilder<VideoLoadState>(
            valueListenable: _session.state,
            builder: (BuildContext context, VideoLoadState state, _) =>
                switch (state) {
                  VideoLoadState.loading => const AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  VideoLoadState.failed => _failure(),
                  VideoLoadState.ready => _player(),
                },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.clip.credit,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                  ),
                ),
                if (widget.showTranscript &&
                    widget.transcript.isNotEmpty) ...<Widget>[
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () =>
                        setState(() => _transcriptOpen = !_transcriptOpen),
                    icon: Icon(
                      _transcriptOpen
                          ? Icons.expand_less_rounded
                          : Icons.subtitles_outlined,
                      size: 18,
                    ),
                    label: Text(
                      _transcriptOpen ? 'Hide transcript' : 'Show transcript',
                    ),
                  ),
                  if (_transcriptOpen)
                    for (final AudioLine line in widget.transcript)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text.rich(
                          TextSpan(
                            children: <TextSpan>[
                              TextSpan(
                                text: '${line.speaker}: ',
                                style: const TextStyle(
                                  color: AppColors.electricBlue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(text: line.text),
                            ],
                          ),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _failure() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.textMuted,
                size: 30,
              ),
              const SizedBox(height: 8),
              const Text(
                'The video could not load. Check the internet connection, or '
                'watch it on the original website.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('video-open-source'),
                onPressed: _openSource,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Open the original video'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _player() {
    final YoutubePlayerController? youtube = _session.youtube;
    if (youtube != null) {
      return YoutubePlayer(controller: youtube, aspectRatio: 16 / 9);
    }
    final VideoPlayerController c = _session.video!;
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: c,
      builder: (BuildContext context, VideoPlayerValue value, _) {
        final bool notStarted =
            !value.isPlaying && value.position == Duration.zero;
        return Column(
          children: <Widget>[
            AspectRatio(
              aspectRatio: value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio,
              child: GestureDetector(
                onTap: () => _toggle(c),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    VideoPlayer(c),
                    if (notStarted)
                      Container(
                        color: Colors.black38,
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.play_circle_fill_rounded,
                              color: Colors.white,
                              size: 64,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Tap to play · sound on',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            VideoProgressIndicator(
              c,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppColors.primary,
                bufferedColor: AppColors.white18,
                backgroundColor: AppColors.white08,
              ),
            ),
            Row(
              children: <Widget>[
                IconButton(
                  tooltip: value.isPlaying ? 'Pause' : 'Play',
                  onPressed: () => _toggle(c),
                  icon: Icon(
                    value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  color: AppColors.textPrimary,
                ),
                IconButton(
                  tooltip: 'Back 10 seconds',
                  onPressed: () => _back10(c),
                  icon: const Icon(Icons.replay_10_rounded),
                  color: AppColors.textPrimary,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Text(
                    '${_clock(value.position)} / ${_clock(value.duration)}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggle(VideoPlayerController c) async {
    if (c.value.isPlaying) {
      await c.pause();
      return;
    }
    if (c.value.position >= c.value.duration) await c.seekTo(Duration.zero);
    await c.play();
  }

  Future<void> _back10(VideoPlayerController c) async {
    final Duration target = c.value.position - const Duration(seconds: 10);
    await c.seekTo(target.isNegative ? Duration.zero : target);
  }

  static String _clock(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}
