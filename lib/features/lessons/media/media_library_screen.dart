import 'package:flutter/material.dart';

import '../../../services/voice/accent_preference.dart';
import '../../../services/voice/listening_accents.dart';
import '../../../theme/app_colors.dart';
import '../../onboarding/assessment/level_assessment_data.dart';
import '../engine/lesson_engine.dart';
import '../lesson_launcher.dart';
import '../models/lesson_models.dart';
import 'media_catalog.dart';

String accentFlag(ListeningAccent accent) => switch (accent) {
  ListeningAccent.american => '🇺🇸',
  ListeningAccent.british => '🇬🇧',
  ListeningAccent.australian => '🇦🇺',
};

/// Real videos and recordings by accent, level, category and track.
class MediaLibraryScreen extends StatefulWidget {
  const MediaLibraryScreen({super.key, this.loader, this.lessons});

  /// Injected in tests; [LessonContext.load] otherwise.
  final Future<LessonContext> Function()? loader;

  /// Injected in tests; [MediaCatalog.lessons] otherwise.
  final List<Lesson>? lessons;

  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends State<MediaLibraryScreen> {
  LessonContext? _data;
  bool _loading = true;
  ListeningAccent? _accent;
  int? _level;
  ContentCategory? _category;
  ContentTrack? _track;

  List<Lesson> get _all => widget.lessons ?? MediaCatalog.lessons;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    LessonContext? data;
    ListeningAccent? accent;
    try {
      accent = await AccentPreference.load();
      data = await (widget.loader ?? LessonContext.load)();
    } on Object {
      // The library still works without the learner's context.
    }
    if (!mounted) return;
    setState(() {
      _data = data;
      _accent = accent;
      _loading = false;
    });
  }

  Future<void> _chooseAccent(ListeningAccent? accent) async {
    setState(() => _accent = accent);
    await AccentPreference.save(accent);
  }

  int get _learnerLevel {
    final LessonContext? data = _data;
    if (data == null) return 2;
    return LessonEngine.effectiveLevel(
      profile: data.profile,
      assessment: data.assessment,
    ).index;
  }

  Set<String> get _done {
    final LessonContext? data = _data;
    return data == null
        ? <String>{}
        : LessonEngine.completedLessonIds(data.sessions);
  }

  Future<void> _open(Lesson lesson) async {
    final LessonContext? data = _data;
    if (data == null) return;
    await LessonLauncher.openLesson(
      context,
      LessonChoice(
        lesson: lesson,
        reason: 'You chose this ${lesson.level} video from the library.',
      ),
      data,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final MediaFilter filter = MediaFilter(
      accent: _accent,
      levelIndex: _level,
      category: _category,
      track: _track,
    );
    final List<Lesson> shown = <Lesson>[
      for (final Lesson l in _all)
        if (filter.matches(l.media!, l.levelIndex)) l,
    ]..sort((Lesson a, Lesson b) => a.levelIndex.compareTo(b.levelIndex));
    final Lesson? next = shown.isEmpty
        ? null
        : MediaCatalog.recommend(
            levelIndex: _learnerLevel,
            accent: _accent,
            done: _done,
            from: shown,
          );
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Real English videos',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    children: <Widget>[
                      _title('Accent you want to work on'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: <Widget>[
                          ChoiceChip(
                            label: const Text('Any accent'),
                            selected: _accent == null,
                            onSelected: (_) => _chooseAccent(null),
                          ),
                          for (final ListeningAccent a
                              in ListeningAccent.values)
                            ChoiceChip(
                              key: Key('accent-${a.name}'),
                              label: Text('${accentFlag(a)} ${a.label}'),
                              selected: _accent == a,
                              onSelected: (_) => _chooseAccent(a),
                            ),
                        ],
                      ),
                      _title('Level'),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          ChoiceChip(
                            label: const Text('All'),
                            selected: _level == null,
                            onSelected: (_) => setState(() => _level = null),
                          ),
                          for (int i = 0; i < assessmentLevels.length; i++)
                            ChoiceChip(
                              label: Text(assessmentLevels[i]),
                              selected: _level == i,
                              onSelected: (_) => setState(() => _level = i),
                            ),
                        ],
                      ),
                      if (_level != null) _levelInfo(levelDescriptors[_level!]),
                      _title('Track'),
                      Wrap(
                        spacing: 8,
                        children: <Widget>[
                          ChoiceChip(
                            label: const Text('All'),
                            selected: _track == null,
                            onSelected: (_) => setState(() => _track = null),
                          ),
                          for (final ContentTrack t in ContentTrack.values)
                            ChoiceChip(
                              label: Text(t.label),
                              selected: _track == t,
                              onSelected: (_) => setState(() => _track = t),
                            ),
                        ],
                      ),
                      _title('Category'),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          ChoiceChip(
                            label: const Text('All'),
                            selected: _category == null,
                            onSelected: (_) => setState(() => _category = null),
                          ),
                          for (final ContentCategory c
                              in ContentCategory.values)
                            ChoiceChip(
                              label: Text('${c.emoji} ${c.label}'),
                              selected: _category == c,
                              onSelected: (_) => setState(() => _category = c),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (next != null) ...<Widget>[
                        _title('Recommended for you'),
                        _VideoTile(
                          lesson: next,
                          done: _done.contains(next.id),
                          highlighted: true,
                          onTap: () => _open(next),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _title(
                        '${shown.length} video${shown.length == 1 ? '' : 's'}',
                      ),
                      if (shown.isEmpty)
                        const Padding(
                          key: Key('media-empty'),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No video yet for this choice. New real videos '
                            'are added with each content update; try another '
                            'level or category meanwhile.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ),
                      for (final Lesson lesson in shown)
                        if (lesson.id != next?.id)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _VideoTile(
                              lesson: lesson,
                              done: _done.contains(lesson.id),
                              onTap: () => _open(lesson),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  Widget _levelInfo(LevelDescriptor d) => Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.white08),
    ),
    child: Text(
      '${d.code} · ${d.name}\n'
      'Speech: ${d.speech} (about ${d.minWpm}–${d.maxWpm} words/min)\n'
      'Vocabulary: ${d.vocabulary}\n'
      'Grammar: ${d.grammar}\n'
      'Topics: ${d.topics}',
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12.5,
        height: 1.45,
      ),
    ),
  );
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({
    required this.lesson,
    required this.done,
    required this.onTap,
    this.highlighted = false,
  });

  final Lesson lesson;
  final bool done;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final MediaInfo media = lesson.media!;
    return Material(
      color: highlighted
          ? AppColors.primary.withValues(alpha: 0.1)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: Key('media-${lesson.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Text(media.category.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${lesson.level} · ${accentFlag(media.accent)} '
                      '${media.accent.label} · ${media.category.label}'
                      '${media.track == ContentTrack.academic ? ' · Academic' : ''}'
                      ' · ${media.creator}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                done
                    ? Icons.check_circle_rounded
                    : Icons.play_circle_outline_rounded,
                color: done ? AppColors.success : AppColors.primaryBright,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
