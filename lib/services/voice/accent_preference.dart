import '../../core/storage/local_storage.dart';
import 'listening_accents.dart';

/// The accent the learner wants to work on (null = any). It orders
/// recommendations, the listening library and the media library.
class AccentPreference {
  AccentPreference._();

  static String get key => '${LocalStorage.namespace}.listening.accent';

  static Future<ListeningAccent?> load() async {
    try {
      final String? raw = await LocalStorage.readString(key);
      return ListeningAccent.values
          .where((ListeningAccent a) => a.name == raw)
          .firstOrNull;
    } on Object {
      return null;
    }
  }

  static Future<void> save(ListeningAccent? accent) async {
    if (accent == null) {
      await LocalStorage.delete(key);
    } else {
      await LocalStorage.saveString(key, accent.name);
    }
  }
}
