/// Spaced review of grammar and vocabulary exercises (Leitner boxes).
///
/// An exercise missed on the first try enters the deck, due the next day.
/// Each correct first try moves it to the next box, with a longer wait
/// (1, 3, 7, 14, then 30 days); a mistake sends it back to the first box.
/// After the last box the exercise counts as mastered and leaves the deck.
/// Reading and listening exercises need their text or audio, so they are not
/// reviewed on their own. Pure Dart (no Flutter import).
library;

class ReviewItem {
  const ReviewItem({
    required this.exerciseId,
    required this.box,
    required this.dueAt,
    required this.addedAt,
    this.lapses = 0,
  });

  static ReviewItem? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final Object? id = raw['exerciseId'];
    final Object? box = raw['box'];
    final DateTime? due = DateTime.tryParse('${raw['dueAt']}');
    final DateTime? added = DateTime.tryParse('${raw['addedAt']}');
    if (id is! String || id.isEmpty || box is! num || due == null) return null;
    return ReviewItem(
      exerciseId: id,
      box: box.toInt().clamp(0, ReviewDeck.intervals.length - 1),
      dueAt: due.toUtc(),
      addedAt: (added ?? due).toUtc(),
      lapses: raw['lapses'] is num ? (raw['lapses'] as num).toInt() : 0,
    );
  }

  final String exerciseId;

  /// 0 = just missed; the last box is the longest wait.
  final int box;
  final DateTime dueAt;
  final DateTime addedAt;

  /// How many times the learner got it wrong again after reviewing it.
  final int lapses;

  bool isDue(DateTime now) => !dueAt.isAfter(now);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'exerciseId': exerciseId,
    'box': box,
    'dueAt': dueAt.toUtc().toIso8601String(),
    'addedAt': addedAt.toUtc().toIso8601String(),
    'lapses': lapses,
  };
}

/// What a lesson changed in the deck (for the results screen).
class ReviewChange {
  const ReviewChange({
    this.added = 0,
    this.promoted = 0,
    this.reset = 0,
    this.mastered = 0,
  });

  final int added;
  final int promoted;
  final int reset;
  final int mastered;

  bool get isEmpty => added + promoted + reset + mastered == 0;
}

class ReviewDeck {
  ReviewDeck({
    Map<String, ReviewItem> items = const <String, ReviewItem>{},
    this.masteredCount = 0,
  }) : items = Map<String, ReviewItem>.unmodifiable(items);

  /// Days to wait after a correct answer, by box (box 0 waits 1 day).
  static const List<int> intervals = <int>[1, 3, 7, 14, 30];

  /// Exercises reviewed in one session at most.
  static const int sessionSize = 10;

  final Map<String, ReviewItem> items;

  /// Exercises that went through every box.
  final int masteredCount;

  int get length => items.length;

  /// Due items, the most overdue (then the lowest box) first.
  List<ReviewItem> due(DateTime now) {
    final List<ReviewItem> list =
        items.values.where((ReviewItem i) => i.isDue(now)).toList()
          ..sort((ReviewItem a, ReviewItem b) {
            final int byDate = a.dueAt.compareTo(b.dueAt);
            return byDate != 0 ? byDate : a.box.compareTo(b.box);
          });
    return list;
  }

  /// Next time something becomes due, or null when the deck is empty.
  DateTime? nextDue() {
    DateTime? next;
    for (final ReviewItem i in items.values) {
      if (next == null || i.dueAt.isBefore(next)) next = i.dueAt;
    }
    return next;
  }

  /// Applies first-try results ([exerciseId] → correct) from a lesson or a
  /// review session. Only ids accepted by [eligible] can enter the deck.
  ({ReviewDeck deck, ReviewChange change}) record(
    Map<String, bool> firstTry, {
    required DateTime now,
    required bool Function(String exerciseId) eligible,
  }) {
    final DateTime today = _day(now);
    final Map<String, ReviewItem> next = Map<String, ReviewItem>.of(items);
    int added = 0;
    int promoted = 0;
    int reset = 0;
    int mastered = 0;
    firstTry.forEach((String id, bool correct) {
      final ReviewItem? current = next[id];
      if (current == null) {
        if (correct || !eligible(id)) return;
        next[id] = ReviewItem(
          exerciseId: id,
          box: 0,
          dueAt: today.add(const Duration(days: 1)),
          addedAt: now.toUtc(),
        );
        added++;
        return;
      }
      if (!correct) {
        next[id] = ReviewItem(
          exerciseId: id,
          box: 0,
          dueAt: today.add(const Duration(days: 1)),
          addedAt: current.addedAt,
          lapses: current.lapses + 1,
        );
        reset++;
        return;
      }
      // A correct answer before the due date does not skip a box.
      if (!current.isDue(now)) return;
      final int box = current.box + 1;
      if (box >= intervals.length) {
        next.remove(id);
        mastered++;
        return;
      }
      next[id] = ReviewItem(
        exerciseId: id,
        box: box,
        dueAt: today.add(Duration(days: intervals[box])),
        addedAt: current.addedAt,
        lapses: current.lapses,
      );
      promoted++;
    });
    return (
      deck: ReviewDeck(items: next, masteredCount: masteredCount + mastered),
      change: ReviewChange(
        added: added,
        promoted: promoted,
        reset: reset,
        mastered: mastered,
      ),
    );
  }

  /// Start of the day in UTC: items become due at midnight, not at the
  /// exact minute of the mistake.
  static DateTime _day(DateTime now) {
    final DateTime utc = now.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }

  static ReviewDeck fromJson(Object? raw) {
    if (raw is! Map) return ReviewDeck();
    final Object? list = raw['items'];
    final Map<String, ReviewItem> items = <String, ReviewItem>{};
    if (list is List) {
      for (final ReviewItem item
          in list.map(ReviewItem.tryParse).whereType<ReviewItem>()) {
        items[item.exerciseId] = item;
      }
    }
    final Object? mastered = raw['mastered'];
    return ReviewDeck(
      items: items,
      masteredCount: mastered is num ? mastered.toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': 1,
    'mastered': masteredCount,
    'items': items.values.map((ReviewItem i) => i.toJson()).toList(),
  };
}
