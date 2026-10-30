/// English accents for listening practice, and how to pick a device voice
/// for each speaker. Pure Dart (no Flutter import), so it is easy to test.
library;

enum ListeningAccent {
  american('American', 'en-US'),
  british('British', 'en-GB'),
  australian('Australian', 'en-AU');

  const ListeningAccent(this.label, this.locale);

  final String label;

  /// BCP 47 locale of the accent's voices.
  final String locale;

  static ListeningAccent? byName(String value) {
    for (final ListeningAccent accent in ListeningAccent.values) {
      if (accent.name == value) return accent;
    }
    return null;
  }
}

/// One voice installed on the device (as reported by the speech engine).
class DeviceVoice {
  const DeviceVoice({
    required this.name,
    required this.locale,
    String? rawLocale,
  }) : rawLocale = rawLocale ?? locale;

  /// Reads the maps returned by `flutter_tts` (`name`, `locale`), skipping
  /// anything malformed.
  static List<DeviceVoice> parse(Object? raw) {
    if (raw is! List) return const <DeviceVoice>[];
    final List<DeviceVoice> voices = <DeviceVoice>[];
    for (final Object? item in raw) {
      if (item is! Map) continue;
      final Object? name = item['name'];
      final Object? locale = item['locale'];
      if (name is! String || locale is! String || name.isEmpty) continue;
      voices.add(
        DeviceVoice(
          name: name,
          locale: normaliseLocale(locale),
          rawLocale: locale,
        ),
      );
    }
    return voices;
  }

  final String name;

  /// Normalised ("en-GB"), for matching accents.
  final String locale;

  /// As reported by the engine, which needs it back to select the voice.
  final String rawLocale;

  bool get isEnglish => locale.toLowerCase().startsWith('en');

  Map<String, String> toMap() => <String, String>{
    'name': name,
    'locale': rawLocale,
  };
}

/// "en_us" → "en-US".
String normaliseLocale(String locale) {
  final List<String> parts = locale.replaceAll('_', '-').split('-');
  if (parts.length < 2) return parts.first.toLowerCase();
  return '${parts.first.toLowerCase()}-${parts[1].toUpperCase()}';
}

/// Picks voices for a dialogue: each speaker keeps one voice, speakers with
/// the same accent get different voices when the device has several.
class VoiceCasting {
  VoiceCasting(List<DeviceVoice> voices)
    : _voices = voices.where((DeviceVoice v) => v.isEnglish).toList()
        ..sort((DeviceVoice a, DeviceVoice b) => a.name.compareTo(b.name));

  final List<DeviceVoice> _voices;
  final Map<String, DeviceVoice?> _cast = <String, DeviceVoice?>{};
  final Map<ListeningAccent, int> _used = <ListeningAccent, int>{};

  bool get hasEnglish => _voices.isNotEmpty;

  /// Accents with at least one installed voice.
  Set<ListeningAccent> get accents => <ListeningAccent>{
    for (final ListeningAccent a in ListeningAccent.values)
      if (_voices.any((DeviceVoice v) => v.locale == a.locale)) a,
  };

  List<DeviceVoice> voicesFor(ListeningAccent accent) => _voices
      .where((DeviceVoice v) => v.locale == accent.locale)
      .toList(growable: false);

  /// The voice for [speaker]. Without a voice for the accent, another
  /// English voice that no other speaker uses yet, so the speakers still
  /// sound different; null only when the device has no English voice.
  DeviceVoice? voiceFor(String speaker, ListeningAccent accent) {
    final String key = '${accent.name}|$speaker';
    if (_cast.containsKey(key)) return _cast[key];
    final List<DeviceVoice> candidates = voicesFor(accent);
    DeviceVoice? voice;
    if (candidates.isNotEmpty) {
      final int index = _used[accent] ?? 0;
      voice = candidates[index % candidates.length];
      _used[accent] = index + 1;
    } else if (_voices.isNotEmpty) {
      final Set<String> taken = <String>{
        for (final DeviceVoice? v in _cast.values)
          if (v != null) v.name,
      };
      voice = _voices.firstWhere(
        (DeviceVoice v) => !taken.contains(v.name),
        orElse: () => _voices[_cast.length % _voices.length],
      );
    }
    _cast[key] = voice;
    return voice;
  }
}
