import '../../models/learning_memory.dart';
import '../learning/learning_memory_service.dart';
import 'mia_chat_client.dart';

/// Pedagogical notes Mia uses between sessions.
///
/// Built on top of the app's existing learning memory ([MemoryService]):
/// there is no second storage. Notes written from Mia's chat are tagged
/// [tag]; lesson weaknesses recorded by `LessonResultService` (also tutor
/// "mia") are read too, so conversations can revisit lesson difficulties.
///
/// Privacy choices:
/// - no conversation transcripts, only short skill notes
///   ("grammar: "I goed" -> "I went"");
/// - chat notes expire after [retention];
/// - [clear] deletes every chat note.
class MiaLearningNotes {
  MiaLearningNotes({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const String tag = 'mia-chat';
  static const String tutorId = 'mia';
  static const Duration retention = Duration(days: 30);
  static const int maxForMia = 8;

  final DateTime Function() _clock;

  /// Active notes from Mia's chat (most recently updated first).
  Future<List<LearningMemory>> load() async {
    final List<LearningMemory> notes = (await MemoryService.getByTag(
      tag,
    )).where((LearningMemory m) => m.isUsable && !_expired(m)).toList();
    notes.sort(
      (LearningMemory a, LearningMemory b) =>
          b.updatedAt.compareTo(a.updatedAt),
    );
    return notes;
  }

  bool _expired(LearningMemory memory) {
    final DateTime? expiry = memory.expiresAt;
    return expiry != null && !expiry.isAfter(_clock().toUtc());
  }

  /// Short difficulty notes sent to Mia: chat notes and lesson weaknesses.
  Future<List<String>> difficultiesForMia() async {
    final List<LearningMemory> chat = await load();
    final List<LearningMemory> lessons =
        (await MemoryService.getRelevantMemoriesForTutor(tutorId, limit: 40))
            .where(
              (LearningMemory m) =>
                  m.isUsable &&
                  !_expired(m) &&
                  m.type == LearningMemoryType.weakness &&
                  !m.tags.contains(tag),
            )
            .toList()
          ..sort(
            (LearningMemory a, LearningMemory b) =>
                b.importance.compareTo(a.importance),
          );

    final List<String> result = <String>[];
    for (final LearningMemory m in <LearningMemory>[...chat, ...lessons]) {
      final String text = m.content.length > 120
          ? m.content.substring(0, 120)
          : m.content;
      if (!result.contains(text)) result.add(text);
      if (result.length == maxForMia) break;
    }
    return result;
  }

  /// Keeps the useful parts of one of Mia's replies.
  Future<void> rememberFrom(MiaChatReply reply, {String? sessionId}) async {
    if (reply.safetyRedirect) return;

    final List<(String, LearningMemoryType)> fresh =
        <(String, LearningMemoryType)>[
          for (final MiaCorrection c in reply.corrections)
            if (c.original.isNotEmpty && c.suggestion.isNotEmpty)
              (
                '${c.category}: "${c.original}" -> "${c.suggestion}"',
                _typeFor(c.category),
              ),
          for (final MiaSkillObservation o in reply.observations)
            if (o.observation.isNotEmpty)
              ('${o.skill}: ${o.observation}', LearningMemoryType.observation),
        ];

    final DateTime now = _clock().toUtc();
    for (final (String raw, LearningMemoryType type) in fresh) {
      final String text = raw.length > 120 ? raw.substring(0, 120) : raw;
      final String id = 'mia-chat-${_slug(text)}';
      final LearningMemory? existing = await MemoryService.getMemory(id);
      if (existing != null) {
        await MemoryService.saveMemory(
          existing
              .reinforce(confidenceBoost: 6, importanceBoost: 4, at: now)
              .copyWith(active: true, expiresAt: now.add(retention)),
        );
      } else {
        await MemoryService.createMemory(
          id: id,
          type: type,
          source: LearningMemorySource.ai,
          content: text,
          tutorId: tutorId,
          sourceSessionId: sessionId,
          tags: const <String>[tag],
          confidence: 45,
          importance: type == LearningMemoryType.observation ? 40 : 55,
          createdAt: now,
          expiresAt: now.add(retention),
        );
      }
    }
  }

  /// Deletes every note written from Mia's chat.
  Future<void> clear() async {
    for (final LearningMemory m in await MemoryService.getByTag(tag)) {
      await MemoryService.deleteMemory(m.id);
    }
  }

  static LearningMemoryType _typeFor(String category) => switch (category) {
    'grammar' => LearningMemoryType.grammar,
    'vocabulary' => LearningMemoryType.vocabulary,
    _ => LearningMemoryType.weakness,
  };

  static String _slug(String text) {
    final String slug = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final String short = slug.length > 60 ? slug.substring(0, 60) : slug;
    return '$short-${_fnv1a(text).toRadixString(16)}';
  }

  /// Stable 32-bit hash (String.hashCode may differ between runs).
  static int _fnv1a(String text) {
    int hash = 0x811c9dc5;
    for (final int unit in text.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
