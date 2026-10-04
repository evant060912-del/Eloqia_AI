import 'package:flutter/material.dart';

import '../../features/onboarding/assessment/level_assessment_result.dart';
import '../../services/learning/learning_dna_service.dart';
import '../../services/voice/voice_output_provider.dart';
import '../../theme/app_colors.dart';
import '../tutors/mia/widgets/mia_presence.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<LearningDNA> _dna;

  @override
  void initState() {
    super.initState();
    _dna = LearningDNAService.load();
  }

  void _reload() => setState(() => _dna = LearningDNAService.load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<LearningDNA>(
          future: _dna,
          builder: (BuildContext context, AsyncSnapshot<LearningDNA> snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: TextButton(
                  onPressed: _reload,
                  child: const Text('Retry'),
                ),
              );
            }

            final LearningDNA dna = snapshot.data!;
            final String name = dna.profile.name.trim().isEmpty
                ? 'Learner'
                : dna.profile.name.trim();
            final LevelAssessmentResult? assessment = dna.assessment;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
                children: <Widget>[
                  const Text(
                    'YOUR LEARNING PROFILE',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _MiaProfileNotes(dna: dna),
                  const SizedBox(height: 14),
                  _Section(
                    title: 'Learning DNA',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _FactRow(
                          label: 'Declared level',
                          value: _value(dna.profile.currentLevel),
                        ),
                        const SizedBox(height: 10),
                        _FactRow(
                          label: 'Assessment estimate',
                          value:
                              assessment?.assessedLevel ??
                              (assessment?.skipped == true
                                  ? 'Skipped'
                                  : 'Not taken'),
                        ),
                        if (assessment?.assessedLevel != null) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            'Confidence ${(assessment!.confidence * 100).round()}% · '
                            'estimate only, not a certificate',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        _FactRow(
                          label: 'Primary goal',
                          value: _value(dna.profile.primaryGoal),
                        ),
                        const SizedBox(height: 10),
                        _FactRow(
                          label: 'Correction preference',
                          value: _value(dna.profile.preferredCorrectionStyle),
                        ),
                        const SizedBox(height: 10),
                        _FactRow(
                          label: 'Learning pace',
                          value: _value(dna.profile.learningPace),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: 'Recorded activity',
                    child: Column(
                      children: <Widget>[
                        _FactRow(
                          label: 'Completed sessions',
                          value: '${dna.completedSessions}',
                        ),
                        const SizedBox(height: 10),
                        _FactRow(
                          label: 'Learning time',
                          value: '${dna.minutesLearned} minutes',
                        ),
                        const SizedBox(height: 10),
                        _FactRow(
                          label: 'Active saved memories',
                          value: '${dna.activeMemories}',
                        ),
                        if (dna.strongestPracticeSkill != null) ...<Widget>[
                          const SizedBox(height: 10),
                          _FactRow(
                            label: 'Most practiced',
                            value: dna.strongestPracticeSkill!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: 'Preferences and focus',
                    child: Text(
                      _profileSummary(dna),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Built from your declared profile, optional level check, '
                    'local session history and active saved memories. This is '
                    'a transparent summary, not an AI diagnosis.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static String _value(String value) =>
      value.trim().isEmpty ? 'Not specified' : value.trim();

  static String _profileSummary(LearningDNA dna) {
    final List<String> lines = <String>[];
    if (dna.profile.difficulties.isNotEmpty) {
      lines.add('Focus areas: ${dna.profile.difficulties.join(', ')}.');
    }
    if (dna.profile.strengths.isNotEmpty) {
      lines.add('Strengths you selected: ${dna.profile.strengths.join(', ')}.');
    }
    if (dna.profile.learningPreferences.isNotEmpty) {
      lines.add(
        'Preferred learning: ${dna.profile.learningPreferences.join(', ')}.',
      );
    }
    if (dna.profile.interests.isNotEmpty) {
      lines.add('Interests: ${dna.profile.interests.join(', ')}.');
    }
    return lines.isEmpty
        ? 'No learning preferences have been recorded yet.'
        : lines.join('\n');
  }
}

class _MiaProfileNotes extends StatelessWidget {
  const _MiaProfileNotes({required this.dna});
  final LearningDNA dna;

  String get _message {
    final List<String> facts = <String>[
      if (dna.profile.primaryGoal.trim().isNotEmpty)
        'Your goal is ${dna.profile.primaryGoal.trim()}',
      if (dna.profile.learningPreferences.isNotEmpty)
        'you prefer ${dna.profile.learningPreferences.join(', ')}',
      if (dna.profile.interests.isNotEmpty)
        'you are interested in ${dna.profile.interests.join(', ')}',
    ];
    if (facts.isEmpty) {
      return 'I do not have learning preferences to reflect on yet. You can add them to your profile during onboarding.';
    }
    return 'From the profile you shared: ${facts.join('; ')}. I will use those details when choosing lesson examples.';
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
                  'MIA’S NOTES',
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.glassBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SizedBox(
        width: 132,
        child: Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
