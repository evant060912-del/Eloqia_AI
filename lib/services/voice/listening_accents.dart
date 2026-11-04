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
    this.qualityHint,
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
      final Object? quality = item['quality'];
      voices.add(
        DeviceVoice(
          name: name,
          locale: normaliseLocale(locale),
          rawLocale: locale,
          qualityHint: quality == null ? null : '$quality',
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

  /// Quality the engine reports, when it does (iOS: "enhanced",
  /// "premium"; Android: a number, 400 = very high).
  final String? qualityHint;

  /// Novelty voices of macOS and iOS (singing, whispering, robots).
  static const Set<String> _novelty = <String>{
    'albert',
    'bad news',
    'bahh',
    'bells',
    'boing',
    'bubbles',
    'cellos',
    'good news',
    'jester',
    'organ',
    'superstar',
    'trinoids',
    'whisper',
    'wobble',
    'zarvox',
    'junior',
    'ralph',
    'fred',
    'kathy',
    'deranged',
    'hysterical',
    'pipe organ',
    'princess',
  };

  /// How natural the voice sounds, higher is better: neural voices (Edge
  /// "Natural", "Neural"), then enhanced or premium voices, then Google's,
  /// then standard voices; novelty voices are -1 and never chosen when
  /// another voice exists.
  int get quality {
    final String n = name.toLowerCase();
    final String base = n.split(RegExp(r'[\s(]')).first;
    if (_novelty.contains(n) || _novelty.contains(base)) return -1;
    if (n.contains('natural') || n.contains('neural')) return 4;
    final String hint = (qualityHint ?? '').toLowerCase();
    final int? level = int.tryParse(hint);
    if (n.contains('premium') ||
        n.contains('enhanced') ||
        hint.contains('premium') ||
        hint.contains('enhanced') ||
        (level != null && level >= 400)) {
      return 3;
    }
    if (n.startsWith('google') || n.contains('siri')) return 2;
    if (n.contains('espeak') || n.contains('compact')) return 0;
    return 1;
  }

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
  /// Keeps English voices, most natural first (novelty voices only when
  /// nothing else exists).
  VoiceCasting(List<DeviceVoice> voices) : _voices = _rank(voices);

  static List<DeviceVoice> _rank(List<DeviceVoice> voices) {
    final List<DeviceVoice> english = voices
        .where((DeviceVoice v) => v.isEnglish)
        .toList();
    final List<DeviceVoice> usable = english
        .where((DeviceVoice v) => v.quality >= 0)
        .toList();
    return (usable.isEmpty ? english : usable)
      ..sort((DeviceVoice a, DeviceVoice b) {
        final int byQuality = b.quality.compareTo(a.quality);
        return byQuality != 0 ? byQuality : a.name.compareTo(b.name);
      });
  }

  /// True when at least one neural ("Natural") voice is available.
  bool get hasNaturalVoices => _voices.any((DeviceVoice v) => v.quality >= 4);

  final List<DeviceVoice> _voices;
  final Map<String, DeviceVoice?> _cast = <String, DeviceVoice?>{};
  final Map<ListeningAccent, int> _used = <ListeningAccent, int>{};

  bool get hasEnglish => _voices.isNotEmpty;

  /// A new dialogue: every voice is free again.
  void reset() {
    _cast.clear();
    _used.clear();
  }

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
  ///
  /// With [strict] false (a line with no accent), any English voice not used
  /// yet is preferred, American first, so speakers never share a voice when
  /// the device has enough of them.
  DeviceVoice? voiceFor(
    String speaker,
    ListeningAccent accent, {
    bool strict = true,
  }) {
    final String key = '${strict ? accent.name : 'any'}|$speaker';
    if (_cast.containsKey(key)) return _cast[key];
    final List<DeviceVoice> candidates = voicesFor(accent);
    final Set<String> taken = <String>{
      for (final DeviceVoice? v in _cast.values)
        if (v != null) v.name,
    };
    DeviceVoice? voice;
    if (!strict && _voices.isNotEmpty) {
      final List<DeviceVoice> preferred = <DeviceVoice>[
        ...candidates,
        ..._voices.where((DeviceVoice v) => !candidates.contains(v)),
      ];
      voice = preferred.firstWhere(
        (DeviceVoice v) => !taken.contains(v.name),
        orElse: () => preferred[_cast.length % preferred.length],
      );
    } else if (candidates.isNotEmpty) {
      final int index = _used[accent] ?? 0;
      voice = candidates[index % candidates.length];
      _used[accent] = index + 1;
    } else if (_voices.isNotEmpty) {
      voice = _voices.firstWhere(
        (DeviceVoice v) => !taken.contains(v.name),
        orElse: () => _voices[_cast.length % _voices.length],
      );
    }
    _cast[key] = voice;
    return voice;
  }
}
