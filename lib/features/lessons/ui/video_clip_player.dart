import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../theme/app_colors.dart';
import '../models/lesson_models.dart';

/// Plays the real video of a listening lesson: a public-domain MP4 (VOA
/// Learning English) or a YouTube video in YouTube's official player. The
/// transcript, when it may be shown, appears once the learner has answered.
class VideoClipPlayer extends StatefulWidget {
  const VideoClipPlayer({
    super.key,
    required this.clip,
    this.transcript = const <AudioLine>[],
    this.showTranscript = false,
  });

  final VideoClip clip;
  final List<AudioLine> transcript;
  final bool showTranscript;

  @override
  State<VideoClipPlayer> createState() => _VideoClipPlayerState();
}

class _VideoClipPlayerState extends State<VideoClipPlayer> {
  VideoPlayerController? _video;
  YoutubePlayerController? _youtube;
  bool _failed = false;
  bool _transcriptOpen = false;

  @override
  void initState() {
    super.initState();
    final VideoClip clip = widget.clip;
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
    } else {
      unawaited(_initVideo(clip.url!));
    }
  }

  Future<void> _initVideo(String url) async {
    final VideoPlayerController controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
    );
    _video = controller;
    try {
      await controller.initialize();
      controller.addListener(_onTick);
      if (mounted) setState(() {});
    } on Object catch (error) {
      debugPrint('Video failed to load: $error');
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    final VideoPlayerController? video = _video;
    if (video != null) {
      video.removeListener(_onTick);
      unawaited(video.dispose().catchError((Object _) {}));
    }
    final YoutubePlayerController? youtube = _youtube;
    if (youtube != null) unawaited(youtube.close().catchError((Object _) {}));
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final VideoPlayerController? c = _video;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      if (c.value.position >= c.value.duration) {
        await c.seekTo(Duration.zero);
      }
      await c.play();
    }
  }

  Future<void> _back10() async {
    final VideoPlayerController? c = _video;
    if (c == null || !c.value.isInitialized) return;
    final Duration target = c.value.position - const Duration(seconds: 10);
    await c.seekTo(target.isNegative ? Duration.zero : target);
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
          _player(),
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

  Widget _player() {
    final YoutubePlayerController? youtube = _youtube;
    if (youtube != null) {
      return YoutubePlayer(controller: youtube, aspectRatio: 16 / 9);
    }
    final VideoPlayerController? c = _video;
    if (_failed) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'The video could not load. Check the internet connection and '
              'try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }
    if (c == null || !c.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return Column(
      children: <Widget>[
        AspectRatio(
          aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
          child: GestureDetector(onTap: _togglePlay, child: VideoPlayer(c)),
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
              tooltip: c.value.isPlaying ? 'Pause' : 'Play',
              onPressed: _togglePlay,
              icon: Icon(
                c.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
              color: AppColors.textPrimary,
            ),
            IconButton(
              tooltip: 'Back 10 seconds',
              onPressed: _back10,
              icon: const Icon(Icons.replay_10_rounded),
              color: AppColors.textPrimary,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                '${_clock(c.value.position)} / ${_clock(c.value.duration)}',
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
  }

  static String _clock(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}
