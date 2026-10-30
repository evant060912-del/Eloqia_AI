/// Measures computed on the device from the speech-recognition transcript.
/// They describe what was recognised, not pronunciation itself: a word the
/// recogniser missed may still have been said. Pure Dart (no Flutter import).
library;

const Map<String, String> _numbers = <String, String>{
  '0': 'zero',
  '1': 'one',
  '2': 'two',
  '3': 'three',
  '4': 'four',
  '5': 'five',
  '6': 'six',
  '7': 'seven',
  '8': 'eight',
  '9': 'nine',
  '10': 'ten',
  '11': 'eleven',
  '12': 'twelve',
  '15': 'fifteen',
  '20': 'twenty',
  '30': 'thirty',
};

const Map<String, List<String>> _contractions = <String, List<String>>{
  "i'm": <String>['i', 'am'],
  "you're": <String>['you', 'are'],
  "we're": <String>['we', 'are'],
  "they're": <String>['they', 'are'],
  "it's": <String>['it', 'is'],
  "that's": <String>['that', 'is'],
  "there's": <String>['there', 'is'],
  "don't": <String>['do', 'not'],
  "doesn't": <String>['does', 'not'],
  "didn't": <String>['did', 'not'],
  "isn't": <String>['is', 'not'],
  "aren't": <String>['are', 'not'],
  "can't": <String>['can', 'not'],
  "won't": <String>['will', 'not'],
  "i'll": <String>['i', 'will'],
  "we'll": <String>['we', 'will'],
  "i've": <String>['i', 'have'],
  "you'll": <String>['you', 'will'],
  "let's": <String>['let', 'us'],
};

/// Lower-case words, numbers as words, contractions expanded, so "I'm 3"
/// and "I am three" compare equal.
List<String> normaliseWords(String text) {
  final List<String> out = <String>[];
  final Iterable<String> raw = text
      .toLowerCase()
      .replaceAll('’', "'")
      .split(RegExp(r"[^a-z0-9']+"))
      .where((String w) => w.isNotEmpty && w != "'");
  for (String word in raw) {
    word = word.replaceAll(RegExp(r"^'+|'+$"), '');
    if (word.isEmpty) continue;
    final List<String>? expanded = _contractions[word];
    if (expanded != null) {
      out.addAll(expanded);
    } else {
      out.add(_numbers[word] ?? word);
    }
  }
  return out;
}

/// One word of the target sentence and whether it was recognised.
class RepeatWord {
  const RepeatWord(this.word, this.heard);

  final String word;
  final bool heard;
}

class RepeatScore {
  const RepeatScore({
    required this.words,
    required this.extra,
    required this.said,
  });

  /// Target words in order, each marked heard or missed.
  final List<RepeatWord> words;

  /// Recognised words that are not in the sentence.
  final int extra;
  final String said;

  int get heard => words.where((RepeatWord w) => w.heard).length;

  /// Share of the sentence recognised, minus a little for extra words.
  double get accuracy {
    if (words.isEmpty) return 0;
    final double value = (heard - extra * 0.5) / words.length;
    return value.clamp(0, 1).toDouble();
  }

  /// Counts as a correct repetition.
  bool get correct => accuracy >= 0.9;

  /// Compares what was said with the sentence (longest common subsequence,
  /// so the word order matters).
  static RepeatScore compare(String target, String said) {
    final List<String> a = normaliseWords(target);
    final List<String> b = normaliseWords(said);
    final List<List<int>> table = List<List<int>>.generate(
      a.length + 1,
      (_) => List<int>.filled(b.length + 1, 0),
    );
    for (int i = a.length - 1; i >= 0; i--) {
      for (int j = b.length - 1; j >= 0; j--) {
        table[i][j] = a[i] == b[j]
            ? table[i + 1][j + 1] + 1
            : (table[i + 1][j] > table[i][j + 1]
                  ? table[i + 1][j]
                  : table[i][j + 1]);
      }
    }
    final List<bool> heard = List<bool>.filled(a.length, false);
    int i = 0;
    int j = 0;
    while (i < a.length && j < b.length) {
      if (a[i] == b[j]) {
        heard[i] = true;
        i++;
        j++;
      } else if (table[i + 1][j] >= table[i][j + 1]) {
        i++;
      } else {
        j++;
      }
    }
    final int matched = heard.where((bool h) => h).length;
    return RepeatScore(
      words: <RepeatWord>[
        for (int k = 0; k < a.length; k++) RepeatWord(a[k], heard[k]),
      ],
      extra: b.length - matched,
      said: said,
    );
  }
}

class FluencyStats {
  const FluencyStats({
    required this.words,
    required this.seconds,
    required this.fillers,
  });

  static const Set<String> fillerWords = <String>{
    'um',
    'uh',
    'er',
    'erm',
    'hmm',
    'ah',
  };

  static FluencyStats of(String transcript, Duration duration) {
    final List<String> words = normaliseWords(transcript);
    return FluencyStats(
      words: words.length,
      seconds: duration.inSeconds,
      fillers: words.where(fillerWords.contains).length,
    );
  }

  final int words;
  final int seconds;
  final int fillers;

  /// Words per minute, or null for very short answers.
  int? get wordsPerMinute =>
      seconds < 5 ? null : (words * 60 / seconds).round();
}
