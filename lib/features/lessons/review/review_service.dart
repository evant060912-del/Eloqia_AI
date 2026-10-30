import '../../../core/storage/local_storage.dart';
import 'review_deck.dart';
import 'review_session.dart';

/// The review deck on the device, under the `eloqia.` namespace (so "reset my
/// data" also clears it).
class ReviewService {
  ReviewService._();

  static const String key = '${LocalStorage.namespace}.lessons.review';

  static Future<ReviewDeck> load() async {
    try {
      return ReviewDeck.fromJson(await LocalStorage.readJsonMap(key));
    } on Object {
      return ReviewDeck();
    }
  }

  static Future<bool> save(ReviewDeck deck) =>
      LocalStorage.saveJson(key, deck.toJson());

  /// Updates the deck with a lesson's (or a review's) first-try results.
  static Future<ReviewChange> recordLesson(
    Map<String, bool> firstTry, {
    DateTime? now,
  }) async {
    final ReviewDeck deck = await load();
    final result = deck.record(
      firstTry,
      now: now ?? DateTime.now(),
      eligible: ReviewSessions.eligible,
    );
    if (!result.change.isEmpty) await save(result.deck);
    return result.change;
  }
}
