import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'mia_chat_client.dart';

/// Short pedagogical notes Mia keeps between sessions, on the device only.
///
/// Privacy choices:
/// - no conversation transcripts are stored, only short skill notes
///   ("Irregular past tense: goed -> went");
/// - at most [maxNotes] notes, each expiring after [retention];
/// - the learner can erase everything with [clear].
class MiaLearningNotes {
  MiaLearningNotes({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const String storageKey = 'mia_learning_notes_v1';
  static const int maxNotes = 12;
  static const Duration retention = Duration(days: 30);

  final DateTime Function() _clock;

  Future<List<MiaLearningNote>> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return <MiaLearningNote>[];

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return <MiaLearningNote>[];
      final DateTime limit = _clock().subtract(retention);
      return decoded
          .whereType<Map>()
          .map(
            (Map m) => MiaLearningNote.fromJson(Map<String, dynamic>.from(m)),
          )
          .whereType<MiaLearningNote>()
          .where((MiaLearningNote n) => n.updatedAt.isAfter(limit))
          .toList();
    } on FormatException {
      return <MiaLearningNote>[];
    }
  }

  /// The notes sent to Mia (most recent first, max 8 on the server side).
  Future<List<String>> difficultiesForMia() async {
    final List<MiaLearningNote> notes = await load();
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes.take(8).map((MiaLearningNote n) => n.text).toList();
  }

  /// Keeps the useful parts of one of Mia's replies.
  Future<void> rememberFrom(MiaChatReply reply) async {
    if (reply.safetyRedirect) return;

    final List<String> fresh = <String>[
      for (final MiaCorrection c in reply.corrections)
        if (c.original.isNotEmpty && c.suggestion.isNotEmpty)
          '${c.category}: "${c.original}" -> "${c.suggestion}"',
      for (final MiaSkillObservation o in reply.observations)
        if (o.observation.isNotEmpty) '${o.skill}: ${o.observation}',
    ];
    if (fresh.isEmpty) return;

    final List<MiaLearningNote> notes = await load();
    final DateTime now = _clock();
    for (final String text in fresh) {
      final String clipped = text.length > 120 ? text.substring(0, 120) : text;
      final int existing = notes.indexWhere(
        (MiaLearningNote n) => n.text == clipped,
      );
      if (existing >= 0) {
        final MiaLearningNote old = notes.removeAt(existing);
        notes.add(MiaLearningNote(clipped, now, old.count + 1));
      } else {
        notes.add(MiaLearningNote(clipped, now, 1));
      }
    }

    // Keep the most recent ones.
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final List<MiaLearningNote> kept = notes.take(maxNotes).toList();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(kept.map((MiaLearningNote n) => n.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}

class MiaLearningNote {
  const MiaLearningNote(this.text, this.updatedAt, this.count);

  static MiaLearningNote? fromJson(Map<String, dynamic> json) {
    final Object? text = json['text'];
    final DateTime? at = DateTime.tryParse('${json['at']}');
    if (text is! String || text.isEmpty || at == null) return null;
    final Object? count = json['count'];
    return MiaLearningNote(text, at, count is int && count > 0 ? count : 1);
  }

  final String text;
  final DateTime updatedAt;

  /// How many times Mia noticed this point.
  final int count;

  Map<String, Object> toJson() => <String, Object>{
    'text': text,
    'at': updatedAt.toIso8601String(),
    'count': count,
  };
}
