import 'package:flutter/material.dart';

import '../../models/progress.dart';
import '../../models/learning_session.dart';
import '../../features/lessons/engine/achievement_engine.dart';
import '../../services/learning/learning_progress_service.dart';
import '../../services/learning/learning_session_service.dart';
import '../../services/voice/voice_output_provider.dart';
import '../../theme/app_colors.dart';
import '../tutors/mia/widgets/mia_presence.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _loading = true;
  Object? _error;
  Progress? _progress;
  List<LearningSession> _sessions = const <LearningSession>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final progress = await LearningProgressService.getProgress();
      final List<LearningSession> sessions =
          await LearningSessionService.getHistory();
      if (!mounted) return;
      setState(() {
        _progress = progress;
        _sessions = sessions
            .where((LearningSession session) => session.completed)
            .toList(growable: false);
        _loading = false;
        _error = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _error != null
            ? _ErrorState(onRetry: _load)
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
                  children: <Widget>[
                    const _Eyebrow('YOUR EVOLUTION'),
                    const SizedBox(height: 8),
                    const Text(
                      'Progress',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _MiaProgressInsight(
                      sessions: _sessions,
                      progress: _progress!,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _Metric(
                            label: 'TOTAL XP',
                            value: '${_progress?.xp ?? 0}',
                            icon: Icons.bolt_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Metric(
                            label: 'STREAK',
                            value: '${_progress?.currentStreak ?? 0} days',
                            icon: Icons.local_fire_department_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _Metric(
                            label: 'SESSIONS',
                            value:
                                '${_progress?.statistics.completedLessons ?? 0}',
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Metric(
                            label: 'LEARNING TIME',
                            value:
                                '${_progress?.statistics.learningMinutes ?? 0} min',
                            icon: Icons.schedule_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const _SectionHeading('Measured skills'),
                    const SizedBox(height: 12),
                    _MeasuredSkills(progress: _progress!),
                    const SizedBox(height: 24),
                    const _SectionHeading('Achievements'),
                    const SizedBox(height: 12),
                    _Achievements(sessions: _sessions, progress: _progress!),
                    const SizedBox(height: 24),
                    const _SectionHeading('Completed sessions'),
                    const SizedBox(height: 12),
                    if (_sessions.isEmpty)
                      const _EmptyHistory()
                    else
                      for (final LearningSession session in _sessions.take(6))
                        _SessionRow(session: session),
                    const SizedBox(height: 16),
                    const Text(
                      'Totals come from locally recorded completed sessions. '
                      'No speaking score is inferred.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _MiaProgressInsight extends StatelessWidget {
  const _MiaProgressInsight({required this.sessions, required this.progress});

  final List<LearningSession> sessions;
  final Progress progress;

  String get _message {
    if (sessions.isEmpty) {
      return 'No completed sessions are recorded yet. Your progress will appear here as you practice.';
    }
    final int measuredSkills = progress.skills.values
        .where((double value) => value > 0)
        .length;
    final int minutes = progress.statistics.learningMinutes;
    return 'You have completed ${sessions.length} sessions and logged $minutes minutes.'
        '${measuredSkills == 0 ? ' Skill mastery has not been measured yet.' : ' $measuredSkills skills have recorded mastery.'}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: <Widget>[
          const MiaPresence(
            size: 58,
            showLabel: false,
            state: MiaPresenceState.encouraging,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'MIA’S PROGRESS NOTES',
                  style: TextStyle(
                    color: AppColors.primaryBright,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Hear Mia',
            onPressed: () => MiaVoice.provider.speak(_message),
            icon: const Icon(Icons.volume_up_rounded),
          ),
        ],
      ),
    );
  }
}

class _MeasuredSkills extends StatelessWidget {
  const _MeasuredSkills({required this.progress});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, double>> measured = progress.skills.entries
        .where((MapEntry<String, double> skill) => skill.value > 0)
        .toList(growable: false);
    if (measured.isEmpty) {
      return const Text(
        'Skill mastery appears here after a lesson records an evaluation.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      );
    }
    return Column(
      children: <Widget>[
        for (final MapEntry<String, double> skill in measured)
          _SkillRow(skill: skill),
      ],
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.skill});
  final MapEntry<String, double> skill;

  @override
  Widget build(BuildContext context) {
    final String name = skill.key[0].toUpperCase() + skill.key.substring(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
              Text(
                '${skill.value.round()}%',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (skill.value / 100).clamp(0.0, 1.0),
            minHeight: 5,
            borderRadius: BorderRadius.circular(5),
            backgroundColor: AppColors.surfaceElevated,
            color: AppColors.primaryBright,
          ),
        ],
      ),
    );
  }
}

class _Achievements extends StatelessWidget {
  const _Achievements({required this.sessions, required this.progress});
  final List<LearningSession> sessions;
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final Set<String> unlocked = AchievementEngine.unlocked(
      sessions: sessions,
      progress: progress,
    );
    return Column(
      children: <Widget>[
        for (final Achievement achievement in AchievementEngine.all)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  unlocked.contains(achievement.id)
                      ? Icons.emoji_events_rounded
                      : Icons.lock_outline_rounded,
                  color: unlocked.contains(achievement.id)
                      ? AppColors.xp
                      : AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        achievement.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        achievement.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  unlocked.contains(achievement.id) ? 'EARNED' : 'LOCKED',
                  style: TextStyle(
                    color: unlocked.contains(achievement.id)
                        ? AppColors.xp
                        : AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: AppColors.primary,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.8,
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: AppColors.textPrimary,
      fontSize: 17,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 105),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppColors.primary, size: 19),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});
  final LearningSession session;

  @override
  Widget build(BuildContext context) {
    final String title = session.tutorName == 'Mia'
        ? 'Mia guided writing practice'
        : session.activityType.name[0].toUpperCase() +
              session.activityType.name.substring(1);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${session.activeDuration.inMinutes} min',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 20),
    child: Text(
      'Completed practice sessions will appear here.',
      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text('Progress is unavailable right now.'),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
