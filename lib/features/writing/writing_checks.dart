/// Deterministic measurements on the learner's text.
///
/// Pure Dart (no Flutter import) so the rules are easy to test. Only
/// mechanical rules that are certain are checked here; everything that needs
/// judgement (grammar in context, register, organisation) is left to Mia's
/// review on the server.
library;

final RegExp _word = RegExp(r"[A-Za-z0-9]+(?:['’-][A-Za-z0-9]+)*");

/// Same rule as `count_words` in `backend/app/writing.py`.
int countWords(String text) => _word.allMatches(text).length;

class WritingStats {
  const WritingStats({
    required this.words,
    required this.sentences,
    required this.paragraphs,
    required this.longestSentence,
  });

  factory WritingStats.of(String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const WritingStats(
        words: 0,
        sentences: 0,
        paragraphs: 0,
        longestSentence: 0,
      );
    }
    final List<String> sentences = trimmed
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .where((String s) => countWords(s) > 0)
        .toList();
    int longest = 0;
    for (final String sentence in sentences) {
      final int words = countWords(sentence);
      if (words > longest) longest = words;
    }
    return WritingStats(
      words: countWords(trimmed),
      sentences: sentences.length,
      paragraphs: trimmed
          .split(RegExp(r'\n\s*\n'))
          .where((String p) => countWords(p) > 0)
          .length,
      longestSentence: longest,
    );
  }

  final int words;
  final int sentences;
  final int paragraphs;

  /// Words in the longest sentence.
  final int longestSentence;

  double get averageSentence => sentences == 0 ? 0 : words / sentences;
}

enum LengthStatus { empty, tooShort, inRange, tooLong }

/// [maxWords] 0 means no maximum.
LengthStatus lengthStatus(int words, int minWords, int maxWords) {
  if (words == 0) return LengthStatus.empty;
  if (words < minWords) return LengthStatus.tooShort;
  if (maxWords > 0 && words > maxWords) return LengthStatus.tooLong;
  return LengthStatus.inRange;
}

enum MechanicalKind {
  lowercaseI('Capital I'),
  sentenceStart('Capital letter'),
  repeatedWord('Repeated word'),
  spaceBeforePunctuation('Space before punctuation'),
  missingSpaceAfterPunctuation('Space after punctuation'),
  extraSpaces('Extra spaces');

  const MechanicalKind(this.label);

  final String label;
}

/// One certain mechanical issue, located in the text.
class MechanicalIssue {
  const MechanicalIssue({
    required this.kind,
    required this.offset,
    required this.length,
    required this.excerpt,
    required this.suggestion,
    required this.explanation,
  });

  final MechanicalKind kind;

  /// Position of the problem in the text.
  final int offset;
  final int length;

  /// The exact characters concerned, as written.
  final String excerpt;
  final String suggestion;
  final String explanation;
}

const Set<String> _abbreviations = <String>{
  'e.g',
  'i.e',
  'etc',
  'vs',
  'mr',
  'mrs',
  'ms',
  'dr',
  'st',
  'p.m',
  'a.m',
};

// "that that" and "had had" can be correct English.
const Set<String> _allowedRepeats = <String>{'that', 'had'};

/// Mechanical issues, in text order. Capped at [limit].
List<MechanicalIssue> mechanicalIssues(String text, {int limit = 20}) {
  final List<MechanicalIssue> issues = <MechanicalIssue>[];

  void add(
    MechanicalKind kind,
    int offset,
    int length,
    String suggestion,
    String explanation,
  ) {
    issues.add(
      MechanicalIssue(
        kind: kind,
        offset: offset,
        length: length,
        excerpt: text.substring(offset, offset + length),
        suggestion: suggestion,
        explanation: explanation,
      ),
    );
  }

  // The pronoun "I" is always a capital letter (i, i'm, i've...).
  for (final RegExpMatch m in RegExp(
    r"(?<![\w.'’-])i(?=['’][a-z]|[\s,!?;:)]|$)",
  ).allMatches(text)) {
    add(
      MechanicalKind.lowercaseI,
      m.start,
      1,
      'I',
      'The pronoun "I" is always written with a capital letter.',
    );
  }

  // First letter of the text, and after . ! ? followed by a space.
  final RegExpMatch? first = RegExp(r'^\s*([a-z])').firstMatch(text);
  final int firstAt = first == null ? -1 : first.end - 1;
  if (first != null &&
      !issues.any((MechanicalIssue i) => i.offset == firstAt)) {
    final int at = firstAt;
    add(
      MechanicalKind.sentenceStart,
      at,
      1,
      text[at].toUpperCase(),
      'A text starts with a capital letter.',
    );
  }
  for (final RegExpMatch m in RegExp(
    r'([A-Za-z.]*)([.!?])[ \t]+([a-z])',
  ).allMatches(text)) {
    final String before = '${m.group(1)}'.toLowerCase();
    final String token = before.endsWith('.')
        ? before.substring(0, before.length - 1)
        : before;
    if (m.group(2) == '.' && _abbreviations.contains(token)) continue;
    // "Wait... what?": an ellipsis does not always end a sentence.
    if (m.group(2) == '.' && before.endsWith('.')) continue;
    final int at = m.end - 1;
    // "i" is already reported by the rule above.
    if (issues.any((MechanicalIssue i) => i.offset == at)) continue;
    add(
      MechanicalKind.sentenceStart,
      at,
      1,
      text[at].toUpperCase(),
      'A new sentence starts with a capital letter.',
    );
  }

  // "the the": the same word typed twice.
  for (final RegExpMatch m in RegExp(
    r'\b([A-Za-z]+)\s+\1\b',
    caseSensitive: false,
  ).allMatches(text)) {
    if (_allowedRepeats.contains(m.group(1)!.toLowerCase())) continue;
    add(
      MechanicalKind.repeatedWord,
      m.start,
      m.end - m.start,
      m.group(1)!,
      'The same word appears twice in a row.',
    );
  }

  // "Hello !" — French typography; English has no space before ! ? : ;
  // and none before , or . either.
  for (final RegExpMatch m in RegExp(
    r'(?<=\S)[ \t]+([!?:;,.])(?!\.)',
  ).allMatches(text)) {
    add(
      MechanicalKind.spaceBeforePunctuation,
      m.start,
      m.end - m.start,
      m.group(1)!,
      'In English there is no space before ${m.group(1)}',
    );
  }

  // "Hello,Sam" / "Yes.Then": a space is needed after punctuation.
  for (final RegExpMatch m in RegExp(
    r'(?<=[a-z])([,;!?])(?=[A-Za-z])|(?<=[a-z])(\.)(?=[A-Z][a-z])',
  ).allMatches(text)) {
    final String mark = m.group(0)!;
    add(
      MechanicalKind.missingSpaceAfterPunctuation,
      m.start,
      1,
      '$mark ',
      'Put a space after "$mark".',
    );
  }

  // Two or more spaces between words (inside a line).
  for (final RegExpMatch m in RegExp(
    r'(?<=\S)[ ]{2,}(?=\S)',
  ).allMatches(text)) {
    if (issues.any(
      (MechanicalIssue i) =>
          i.kind == MechanicalKind.spaceBeforePunctuation &&
          i.offset == m.start,
    )) {
      continue;
    }
    add(
      MechanicalKind.extraSpaces,
      m.start,
      m.end - m.start,
      ' ',
      'Use a single space between words.',
    );
  }

  issues.sort((MechanicalIssue a, MechanicalIssue b) => a.offset - b.offset);
  return issues.length > limit ? issues.sublist(0, limit) : issues;
}

/// A short excerpt around [offset] so the learner sees the context.
String contextAround(String text, int offset, int length, {int radius = 18}) {
  final int start = offset - radius < 0 ? 0 : offset - radius;
  final int end = offset + length + radius > text.length
      ? text.length
      : offset + length + radius;
  final String prefix = start > 0 ? '…' : '';
  final String suffix = end < text.length ? '…' : '';
  return '$prefix${text.substring(start, end).replaceAll('\n', ' ')}$suffix';
}
