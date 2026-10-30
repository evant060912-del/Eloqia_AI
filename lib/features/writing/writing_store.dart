import '../../core/storage/local_storage.dart';
import '../../services/mia/writing_review.dart';

/// A draft kept on the device until the text is submitted.
class WritingDraft {
  const WritingDraft({
    required this.taskId,
    required this.text,
    required this.updatedAt,
  });

  final String taskId;
  final String text;
  final DateTime updatedAt;
}

/// One submitted text with its review, so the learner can revisit it.
class WritingHistoryEntry {
  const WritingHistoryEntry({
    required this.id,
    required this.taskId,
    required this.genre,
    required this.taskTitle,
    required this.text,
    required this.submittedAt,
    this.review,
    this.xpAwarded = 0,
  });

  static WritingHistoryEntry? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final Map<String, dynamic> json = Map<String, dynamic>.from(raw);
    final Object? id = json['id'];
    final Object? taskId = json['taskId'];
    final Object? text = json['text'];
    final DateTime? at = DateTime.tryParse('${json['submittedAt']}');
    if (id is! String || taskId is! String || text is! String || at == null) {
      return null;
    }
    return WritingHistoryEntry(
      id: id,
      taskId: taskId,
      genre: '${json['genre'] ?? ''}',
      taskTitle: '${json['taskTitle'] ?? ''}',
      text: text,
      submittedAt: at.toUtc(),
      review: WritingReview.tryParse(json['review']),
      xpAwarded: json['xpAwarded'] is num
          ? (json['xpAwarded'] as num).toInt()
          : 0,
    );
  }

  final String id;
  final String taskId;
  final String genre;
  final String taskTitle;
  final String text;
  final DateTime submittedAt;

  /// Null when the text was finished without Mia's review (offline).
  final WritingReview? review;
  final int xpAwarded;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'taskId': taskId,
    'genre': genre,
    'taskTitle': taskTitle,
    'text': text,
    'submittedAt': submittedAt.toUtc().toIso8601String(),
    'review': review?.toJson(),
    'xpAwarded': xpAwarded,
  };
}

/// Local persistence for the Writing Studio (under the `eloqia.` namespace,
/// so "reset my data" also clears it). Data stays on this device.
class WritingStore {
  WritingStore._();

  static const String draftsKey = '${LocalStorage.namespace}.writing.drafts';
  static const String historyKey = '${LocalStorage.namespace}.writing.history';
  static const int schemaVersion = 1;
  static const int maxDrafts = 30;
  static const int maxHistory = 20;

  // ---------------------------------------------------------------- drafts

  static Future<Map<String, WritingDraft>> _readDrafts() async {
    final Map<String, dynamic>? stored = await LocalStorage.readJsonMap(
      draftsKey,
    );
    final Object? items = stored?['items'];
    final Map<String, WritingDraft> drafts = <String, WritingDraft>{};
    if (items is! Map) return drafts;
    for (final MapEntry<Object?, Object?> entry in items.entries) {
      final Object? value = entry.value;
      if (entry.key is! String || value is! Map) continue;
      final Object? text = value['text'];
      final DateTime? at = DateTime.tryParse('${value['updatedAt']}');
      if (text is! String || text.trim().isEmpty || at == null) continue;
      drafts[entry.key! as String] = WritingDraft(
        taskId: entry.key! as String,
        text: text,
        updatedAt: at.toUtc(),
      );
    }
    return drafts;
  }

  static Future<bool> _writeDrafts(Map<String, WritingDraft> drafts) {
    final List<WritingDraft> recent = drafts.values.toList()
      ..sort(
        (WritingDraft a, WritingDraft b) => b.updatedAt.compareTo(a.updatedAt),
      );
    return LocalStorage.saveJson(draftsKey, <String, dynamic>{
      'version': schemaVersion,
      'items': <String, dynamic>{
        for (final WritingDraft d in recent.take(maxDrafts))
          d.taskId: <String, String>{
            'text': d.text,
            'updatedAt': d.updatedAt.toIso8601String(),
          },
      },
    });
  }

  static Future<WritingDraft?> draftFor(String taskId) async =>
      (await _readDrafts())[taskId];

  /// Most recent first.
  static Future<List<WritingDraft>> drafts() async {
    final List<WritingDraft> list = (await _readDrafts()).values.toList()
      ..sort(
        (WritingDraft a, WritingDraft b) => b.updatedAt.compareTo(a.updatedAt),
      );
    return list;
  }

  /// Saves (or removes, when empty) the draft for [taskId].
  static Future<bool> saveDraft(String taskId, String text) async {
    final Map<String, WritingDraft> drafts = await _readDrafts();
    if (text.trim().isEmpty) {
      if (drafts.remove(taskId) == null) return true;
    } else {
      drafts[taskId] = WritingDraft(
        taskId: taskId,
        text: text,
        updatedAt: DateTime.now().toUtc(),
      );
    }
    return _writeDrafts(drafts);
  }

  static Future<bool> clearDraft(String taskId) => saveDraft(taskId, '');

  // --------------------------------------------------------------- history

  /// Most recent first.
  static Future<List<WritingHistoryEntry>> history() async {
    final Map<String, dynamic>? stored = await LocalStorage.readJsonMap(
      historyKey,
    );
    final Object? items = stored?['items'];
    if (items is! List) return <WritingHistoryEntry>[];
    final List<WritingHistoryEntry> entries =
        items
            .map(WritingHistoryEntry.tryParse)
            .whereType<WritingHistoryEntry>()
            .toList()
          ..sort(
            (WritingHistoryEntry a, WritingHistoryEntry b) =>
                b.submittedAt.compareTo(a.submittedAt),
          );
    return entries;
  }

  static Future<bool> addToHistory(WritingHistoryEntry entry) async {
    final List<WritingHistoryEntry> entries = (await history())
        .where((WritingHistoryEntry e) => e.id != entry.id)
        .toList();
    entries.insert(0, entry);
    return LocalStorage.saveJson(historyKey, <String, dynamic>{
      'version': schemaVersion,
      'items': entries
          .take(maxHistory)
          .map((WritingHistoryEntry e) => e.toJson())
          .toList(),
    });
  }
}
