import '../../models/learning_profile.dart';
import '../../services/mia/mia_chat_client.dart';
import '../../services/mia/mia_learning_notes.dart';
import '../../services/mia/mia_session_recorder.dart';
import '../../services/mia/writing_review.dart';
import '../../services/voice/voice_output_provider.dart' show MiaSpeechStyle;
import 'writing_catalog.dart';
import 'writing_checks.dart';

/// Connects a finished text to the app's existing progress systems.
///
/// XP rule: a task counts once per day ([sessionIdFor]) and only when the
/// text reaches [WritingTask.countedWords]. Resubmitting or revising the same
/// task on the same day never awards XP twice.
class WritingRewards {
  WritingRewards._();

  static const MiaSessionRecord nothing = MiaSessionRecord(
    saved: false,
    xpAwarded: 0,
    newAchievements: [],
  );

  static String sessionIdFor(WritingTask task, DateTime day) {
    final DateTime d = day.toLocal();
    final String date =
        '${d.year}${d.month.toString().padLeft(2, '0')}'
        '${d.day.toString().padLeft(2, '0')}';
    return 'writing-${task.id}-$date';
  }

  static bool counts(WritingTask task, String text) =>
      countWords(text) >= task.countedWords;

  static Future<MiaSessionRecord> record({
    required WritingTask task,
    required String text,
    required LearningProfile profile,
    required Duration duration,
    WritingReview? review,
  }) async {
    if (!counts(task, text) || (review?.safetyRedirect ?? false)) {
      return nothing;
    }
    return MiaSessionRecorder.record(
      sessionId: sessionIdFor(task, DateTime.now()),
      mode: MiaChatMode.writing,
      history: <MiaChatTurn>[MiaChatTurn(fromLearner: true, text: text)],
      profile: profile,
      duration: duration,
      summary: review == null ? null : _asSummary(task, review),
    );
  }

  /// Keeps the real mistakes (not style options) in Mia's learning memory,
  /// so later conversations and reviews can come back to them.
  static Future<void> remember(
    WritingReview review, {
    required String sessionId,
    MiaLearningNotes? notes,
  }) async {
    if (review.safetyRedirect) return;
    final List<MiaCorrection> mistakes = <MiaCorrection>[
      for (final WritingCorrection c in review.corrections)
        if (c.certainty.isMistake &&
            c.priority != CorrectionPriority.optional &&
            c.suggestion.isNotEmpty)
          MiaCorrection(
            original: c.original,
            suggestion: c.suggestion,
            explanation: c.explanation,
            category: c.category == 'vocabulary' ? 'vocabulary' : 'grammar',
          ),
    ];
    if (mistakes.isEmpty) return;
    await (notes ?? MiaLearningNotes()).rememberFrom(
      MiaChatReply(
        reply: review.overall,
        tone: MiaSpeechStyle.warm,
        corrections: mistakes.take(5).toList(),
      ),
      sessionId: sessionId,
    );
  }

  static MiaSessionSummary _asSummary(WritingTask task, WritingReview review) =>
      MiaSessionSummary(
        summary: review.overall,
        practiced: <String>[task.genre.label, task.title],
        strengths: review.strengths,
        improvements: <MiaEvidenceItem>[
          for (final WritingCorrection c in review.corrections)
            if (c.certainty.isMistake)
              MiaEvidenceItem(
                evidence: c.original,
                suggestion: c.suggestion,
                explanation: c.explanation,
              ),
        ],
      );
}
