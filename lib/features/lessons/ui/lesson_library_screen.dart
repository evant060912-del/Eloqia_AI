import 'package:flutter/material.dart';

import '../../../services/voice/listening_accents.dart';
import '../../../theme/app_colors.dart';
import '../../onboarding/assessment/level_assessment_data.dart';
import '../engine/lesson_engine.dart';
import '../lesson_launcher.dart';
import '../media/media_library_screen.dart';
import '../models/lesson_models.dart';
import '../../../services/voice/accent_preference.dart';

/// Every lesson of one skill, by level, with the recommended one first.
class LessonLibraryScreen extends StatefulWidget {
  const LessonLibraryScreen({super.key, required this.skill, this.loader});

  final LessonSkill skill;

  /// Injected in tests; [LessonContext.load] otherwise.
  final Future<LessonContext> Function()? loader;

  @override
  State<LessonLibraryScreen> createState() => _LessonLibraryScreenState();
}

class _LessonLibraryScreenState extends State<LessonLibraryScreen> {
  LessonContext? _data;
  Object? _error;

  /// Listening only: show lessons with this accent (null = all).
  ListeningAccent? _accent;

  /// Listening only: show only lessons with a real video.
  bool _videosOnly = false;

  /// Accent the learner chose to work on: its lessons come first.
  ListeningAccent? _preferred;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final LessonContext data = await (widget.loader ?? LessonContext.load)();
      final ListeningAccent? preferred = await AccentPreference.load();
      if (!mounted) return;
      setState(() {
        _data = data;
        _preferred = preferred;
        _error = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  /// 0 for lessons in the preferred accent, 1 otherwise.
  int _accentRank(Lesson lesson) {
    final ListeningAccent? preferred = _preferred;
    if (preferred == null) return 0;
    final bool heard =
        lesson.media?.accent == preferred || lesson.accents.contains(preferred);
    return heard ? 0 : 1;
  }

  Future<void> _open(LessonChoice choice) async {
    final LessonContext? data = _data;
    if (data == null) return;
    await LessonLauncher.openLesson(context, choice, data);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final LessonContext? data = _data;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          widget.skill.label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _error != null
          ? Center(
              child: TextButton(onPressed: _load, child: const Text('Retry')),
            )
          : data == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _list(data),
    );
  }

  Widget _list(LessonContext data) {
    final LessonChoice recommended = data.select(widget.skill);
    final Set<String> done = LessonEngine.completedLessonIds(data.sessions);
    final bool listening = widget.skill == LessonSkill.listening;
    final List<Lesson> all = LessonCatalog.forSkill(widget.skill)
      ..sort((Lesson a, Lesson b) => a.levelIndex.compareTo(b.levelIndex));
    final ListeningAccent? accent = _accent;
    final List<Lesson> lessons =
        all
            .where(
              (Lesson l) =>
                  (accent == null || l.accents.contains(accent)) &&
                  (!_videosOnly || l.video != null),
            )
            .toList()
          // Real videos first within each level.
          ..sort((Lesson a, Lesson b) {
            final int byLevel = a.levelIndex.compareTo(b.levelIndex);
            if (byLevel != 0) return byLevel;
            final int byVideo = (a.video == null ? 1 : 0).compareTo(
              b.video == null ? 1 : 0,
            );
            if (byVideo != 0) return byVideo;
            return _accentRank(a).compareTo(_accentRank(b));
          });
    final List<int> levels = lessons
        .map((Lesson l) => l.levelIndex)
        .toSet()
        .toList();
    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: <Widget>[
              Text(
                '${all.length} lessons, ${done.where((String id) => all.any((Lesson l) => l.id == id)).length} completed.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              if (listening) ...<Widget>[
                const SizedBox(height: 12),
                _MediaLibraryCard(
                  onOpen: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const MediaLibraryScreen(),
                      ),
                    );
                    await _load();
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilterChip(
                      avatar: const Icon(Icons.videocam_outlined, size: 18),
                      label: const Text('Real videos'),
                      selected: _videosOnly,
                      onSelected: (bool on) => setState(() => _videosOnly = on),
                    ),
                    ChoiceChip(
                      label: const Text('All accents'),
                      selected: accent == null,
                      onSelected: (_) => setState(() => _accent = null),
                    ),
                    for (final ListeningAccent a in ListeningAccent.values)
                      ChoiceChip(
                        label: Text(a.label),
                        selected: accent == a,
                        onSelected: (_) => setState(() => _accent = a),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              if (accent == null && !_videosOnly)
                _RecommendedCard(
                  choice: recommended,
                  onStart: () => _open(recommended),
                ),
              for (final int level in levels) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
                  child: Text(
                    'Level ${assessmentLevels[level]}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                for (final Lesson lesson in lessons.where(
                  (Lesson l) => l.levelIndex == level,
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LessonTile(
                      lesson: lesson,
                      done: done.contains(lesson.id),
                      recommended: lesson.id == recommended.lesson.id,
                      onTap: () => _open(
                        LessonChoice(
                          lesson: lesson,
                          reason:
                              'You chose this ${lesson.level} lesson from '
                              'the library.',
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaLibraryCard extends StatelessWidget {
  const _MediaLibraryCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.electricBlue.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: const Key('open-media-library'),
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.smart_display_outlined,
                color: AppColors.electricBlue,
                size: 30,
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Real English videos',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Real people by accent, level A1–C2 and topic, with '
                      'vocabulary and expressions.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.choice, required this.onStart});

  final LessonChoice choice;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final Lesson lesson = choice.lesson;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'RECOMMENDED FOR YOU',
            style: TextStyle(
              color: AppColors.primaryBright,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lesson.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${lesson.level} · ${lesson.estimatedMinutes} min · '
            '${lesson.xpReward} XP',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 8),
          Text(
            choice.reason,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: onStart,
              child: const Text(
                'Start',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.done,
    required this.recommended,
    required this.onTap,
  });

  final Lesson lesson;
  final bool done;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.white08),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lesson.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${lesson.estimatedMinutes} min · ${lesson.xpReward} XP'
                      '${lesson.video != null ? ' · Real video' : ''}'
                      '${lesson.accents.isEmpty ? '' : ' · ${lesson.accents.map((ListeningAccent a) => a.label).join(', ')}'}'
                      '${recommended ? ' · Recommended' : ''}',
                      style: TextStyle(
                        color: recommended
                            ? AppColors.primaryBright
                            : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                done ? Icons.check_circle_rounded : Icons.play_circle_outline,
                color: done ? AppColors.success : AppColors.textMuted,
                semanticLabel: done ? 'Completed' : 'Not completed yet',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
