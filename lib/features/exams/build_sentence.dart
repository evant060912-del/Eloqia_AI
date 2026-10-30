/// TOEFL "Build a Sentence" practice (format introduced in January 2026):
/// someone says something, the learner completes the reply by placing words
/// and phrases in the blanks. Some words are already in place and the bank
/// may hold one word too many. Scoring is all or nothing per item.
///
/// Items are original. Each one is written so that a single order is
/// grammatical; [SentenceItem.accepted] lists any other acceptable order.
/// Pure Dart (no Flutter import).
library;

import 'dart:math' as math;

class SentenceItem {
  const SentenceItem({
    required this.id,
    required this.speaker,
    required this.prompt,
    required this.answer,
    required this.ending,
    required this.tip,
    this.fixed = const <int>{},
    this.extra = const <String>[],
    this.accepted = const <List<String>>[],
  });

  final String id;

  /// Who speaks first ("Classmate", "Professor").
  final String speaker;
  final String prompt;

  /// The reply, chunk by chunk, in the correct order.
  final List<String> answer;

  /// Indexes of [answer] that are already in place.
  final Set<int> fixed;

  /// Distractors: words that look possible but break a rule.
  final List<String> extra;

  /// "." or "?".
  final String ending;

  /// The grammar pattern the item practises, shown after answering.
  final String tip;

  /// Other complete orders that are also correct (rarely needed).
  final List<List<String>> accepted;

  int get blanks => answer.length - fixed.length;

  String get sentence => '${answer.join(' ')}$ending';

  /// Chunks the learner places, shuffled the same way on every device.
  List<String> get bank {
    final List<String> chunks = <String>[
      for (int i = 0; i < answer.length; i++)
        if (!fixed.contains(i)) answer[i],
      ...extra,
    ];
    final List<String> original = List<String>.of(chunks);
    chunks.shuffle(math.Random(_seed(id)));
    if (_sameOrder(chunks, original) && chunks.length > 1) {
      chunks.add(chunks.removeAt(0));
    }
    return chunks;
  }

  /// Builds the full reply from the learner's choices, one per blank
  /// (null for an empty blank).
  List<String?> assemble(List<String?> placed) {
    final List<String?> out = <String?>[];
    int next = 0;
    for (int i = 0; i < answer.length; i++) {
      if (fixed.contains(i)) {
        out.add(answer[i]);
      } else {
        out.add(next < placed.length ? placed[next] : null);
        next++;
      }
    }
    return out;
  }

  /// All or nothing: every blank filled with the right chunk.
  bool isCorrect(List<String?> placed) {
    if (placed.length != blanks || placed.any((String? c) => c == null)) {
      return false;
    }
    final String built = _normalise(assemble(placed).whereType<String>());
    if (built == _normalise(answer)) return true;
    return accepted.any((List<String> a) => built == _normalise(a));
  }

  static String _normalise(Iterable<String> chunks) =>
      chunks.join(' ').toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  static bool _sameOrder(List<String> a, List<String> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Stable across platforms (String.hashCode is not guaranteed to be).
  static int _seed(String text) {
    int value = 17;
    for (final int unit in text.codeUnits) {
      value = (value * 31 + unit) & 0x7fffffff;
    }
    return value;
  }
}

class SentenceSet {
  const SentenceSet({
    required this.id,
    required this.title,
    required this.level,
    required this.items,
  });

  final String id;
  final String title;
  final String level;
  final List<SentenceItem> items;
}

/// Result of one item in an attempt.
class SentenceOutcome {
  const SentenceOutcome({
    required this.item,
    required this.placed,
    required this.correct,
  });

  final SentenceItem item;
  final List<String?> placed;
  final bool correct;

  /// The learner's reply as built (blanks shown as "___").
  String get learnerSentence =>
      '${item.assemble(placed).map((String? c) => c ?? '___').join(' ')}'
      '${item.ending}';
}

class SentenceAttemptResult {
  SentenceAttemptResult(this.outcomes);

  final List<SentenceOutcome> outcomes;

  int get correct => outcomes.where((SentenceOutcome o) => o.correct).length;
  int get total => outcomes.length;

  /// Tips of the items the learner missed, without repetition.
  List<String> get tipsToReview => outcomes
      .where((SentenceOutcome o) => !o.correct)
      .map((SentenceOutcome o) => o.item.tip)
      .toSet()
      .toList(growable: false);

  static SentenceAttemptResult score(
    List<SentenceItem> items,
    List<List<String?>> answers,
  ) => SentenceAttemptResult(<SentenceOutcome>[
    for (int i = 0; i < items.length; i++)
      SentenceOutcome(
        item: items[i],
        placed: i < answers.length ? answers[i] : <String?>[],
        correct: i < answers.length && items[i].isCorrect(answers[i]),
      ),
  ]);
}

class BuildSentenceCatalog {
  BuildSentenceCatalog._();

  static const Duration timeLimit = Duration(minutes: 6, seconds: 50);

  static SentenceSet? byId(String id) {
    for (final SentenceSet set in sets) {
      if (set.id == id) return set;
    }
    return null;
  }

  static const List<SentenceSet> sets = <SentenceSet>[
    SentenceSet(
      id: 'bas-campus-life',
      title: 'Campus life',
      level: 'Core patterns',
      items: <SentenceItem>[
        SentenceItem(
          id: 'bas-1',
          speaker: 'Classmate',
          prompt: 'The library is closing early today.',
          answer: <String>[
            'Do',
            'you',
            'know',
            'if',
            'the study rooms',
            'are',
            'still open',
          ],
          fixed: <int>{0},
          extra: <String>['is'],
          ending: '?',
          tip:
              'After "Do you know if…", keep statement order: subject + '
              'verb ("the study rooms are"). Plural subject, plural verb.',
        ),
        SentenceItem(
          id: 'bas-2',
          speaker: 'Roommate',
          prompt: 'I’m going to the grocery store.',
          answer: <String>['Could', 'you', 'pick up', 'some milk', 'for me'],
          fixed: <int>{0, 4},
          extra: <String>['picks up'],
          ending: '?',
          tip:
              'Polite request: Could + subject + base verb ("Could you pick '
              'up…"), never a verb with -s after a modal.',
        ),
        SentenceItem(
          id: 'bas-3',
          speaker: 'Professor',
          prompt: 'Your essay is due next Friday.',
          answer: <String>[
            'Is',
            'it',
            'possible',
            'to submit',
            'it',
            'on Monday',
            'instead',
          ],
          fixed: <int>{0, 5, 6},
          extra: <String>['possibly'],
          ending: '?',
          tip:
              '"Is it possible to + verb…?" The adjective "possible" follows '
              '"Is it"; the adverb "possibly" does not fit there.',
        ),
        SentenceItem(
          id: 'bas-4',
          speaker: 'Classmate',
          prompt: 'I just finished the chemistry homework.',
          answer: <String>['How long', 'did', 'it', 'take', 'you', 'to finish'],
          fixed: <int>{0},
          extra: <String>['took'],
          ending: '?',
          tip:
              'Past question: did + subject + BASE verb ("did it take"), not '
              '"did it took". Pattern: it takes someone time to do something.',
        ),
        SentenceItem(
          id: 'bas-5',
          speaker: 'Friend',
          prompt: 'The new café on campus opened yesterday.',
          answer: <String>['Have', 'you', 'tried', 'their coffee', 'yet'],
          fixed: <int>{0},
          extra: <String>['try'],
          ending: '?',
          tip:
              'Present perfect question: Have + subject + past participle '
              '("tried"); "yet" goes at the end.',
        ),
        SentenceItem(
          id: 'bas-6',
          speaker: 'Advisor',
          prompt: 'You need one more science class to graduate.',
          answer: <String>[
            'Which courses',
            'are',
            'still',
            'open',
            'this semester',
          ],
          fixed: <int>{0, 4},
          extra: <String>['is'],
          ending: '?',
          tip:
              'Plural subject, plural verb ("courses are"). Adverbs like '
              '"still" go after "be": "are still open".',
        ),
        SentenceItem(
          id: 'bas-7',
          speaker: 'Classmate',
          prompt: 'I missed the bus again this morning.',
          answer: <String>[
            'You',
            'should',
            'leave',
            'home',
            'a little earlier',
          ],
          fixed: <int>{0},
          extra: <String>['to leave'],
          ending: '.',
          tip:
              'Modal + base verb without "to": "should leave", not "should '
              'to leave".',
        ),
        SentenceItem(
          id: 'bas-8',
          speaker: 'Teammate',
          prompt: 'Our group presentation is on Thursday.',
          answer: <String>['When', 'should', 'we', 'meet', 'to rehearse'],
          fixed: <int>{0},
          extra: <String>['meeting'],
          ending: '?',
          tip:
              'Wh-question: question word + modal + subject + base verb '
              '("When should we meet…?"). "to rehearse" gives the purpose.',
        ),
        SentenceItem(
          id: 'bas-9',
          speaker: 'Classmate',
          prompt: 'I heard the professor changed the exam date.',
          answer: <String>[
            'Can',
            'you',
            'tell me',
            'when',
            'the new exam',
            'is',
          ],
          fixed: <int>{0},
          extra: <String>['does'],
          ending: '?',
          tip:
              'Embedded question: "Can you tell me when the new exam is?" '
              'Statement order after "when", not "when is the new exam".',
        ),
        SentenceItem(
          id: 'bas-10',
          speaker: 'Librarian',
          prompt: 'This book has to be returned by Friday.',
          answer: <String>['Is there', 'a way', 'to renew', 'it', 'online'],
          fixed: <int>{0, 4},
          extra: <String>['renewing'],
          ending: '?',
          tip:
              '"a way to + verb": "Is there a way to renew it online?" The '
              'object pronoun "it" follows the verb.',
        ),
      ],
    ),
    SentenceSet(
      id: 'bas-plans-and-work',
      title: 'Plans and work',
      level: 'Questions and clauses',
      items: <SentenceItem>[
        SentenceItem(
          id: 'bas-11',
          speaker: 'Friend',
          prompt: 'I’m thinking about joining the photography club.',
          answer: <String>[
            'What',
            'made',
            'you',
            'interested',
            'in photography',
          ],
          fixed: <int>{0},
          extra: <String>['did'],
          ending: '?',
          tip:
              'When the question word is the subject ("What made you…?"), '
              'there is no "did".',
        ),
        SentenceItem(
          id: 'bas-12',
          speaker: 'Classmate',
          prompt: 'The lab report is longer than I expected.',
          answer: <String>['How many pages', 'does', 'it', 'have to', 'be'],
          fixed: <int>{0},
          extra: <String>['do'],
          ending: '?',
          tip:
              '"it" is third person singular: "does it have to be", not "do '
              'it".',
        ),
        SentenceItem(
          id: 'bas-13',
          speaker: 'Manager',
          prompt: 'We need someone to work this Saturday.',
          answer: <String>[
            'I',
            'could work',
            'in the morning',
            'if',
            'that',
            'helps',
          ],
          fixed: <int>{0, 3},
          extra: <String>['help'],
          ending: '.',
          tip:
              '"that" is singular: "if that helps". The time phrase follows '
              'the verb: "could work in the morning".',
        ),
        SentenceItem(
          id: 'bas-14',
          speaker: 'Professor',
          prompt: 'Several students asked about the reading list.',
          answer: <String>[
            'Will',
            'the reading list',
            'be',
            'posted',
            'online',
          ],
          fixed: <int>{0},
          extra: <String>['post'],
          ending: '?',
          tip:
              'Passive question: Will + subject + be + past participle '
              '("be posted").',
        ),
        SentenceItem(
          id: 'bas-15',
          speaker: 'Roommate',
          prompt: 'Someone left the kitchen in a mess again.',
          answer: <String>['I', 'wonder', 'who', 'forgot', 'to clean up'],
          fixed: <int>{0},
          extra: <String>['did'],
          ending: '.',
          tip:
              '"who" is the subject of the embedded clause: "who forgot", '
              'with no "did".',
        ),
        SentenceItem(
          id: 'bas-16',
          speaker: 'Classmate',
          prompt: 'The museum trip was cancelled.',
          answer: <String>[
            'Do',
            'you',
            'know',
            'why',
            'they',
            'cancelled',
            'it',
          ],
          fixed: <int>{0},
          extra: <String>['did'],
          ending: '?',
          tip:
              'Inside "Do you know why…", use statement order and a normal '
              'past verb: "why they cancelled it", not "why did they".',
        ),
        SentenceItem(
          id: 'bas-17',
          speaker: 'Advisor',
          prompt: 'You should choose your major by the end of the year.',
          answer: <String>[
            'I',
            'haven’t decided',
            'which one',
            'suits',
            'me',
            'best',
          ],
          fixed: <int>{0, 5},
          extra: <String>['suit'],
          ending: '.',
          tip:
              '"which one" is singular: "which one suits me best". Embedded '
              'clause in statement order.',
        ),
        SentenceItem(
          id: 'bas-18',
          speaker: 'Teammate',
          prompt: 'The deadline for the project moved to next week.',
          answer: <String>[
            'That',
            'gives',
            'us',
            'more time',
            'to improve',
            'the slides',
          ],
          fixed: <int>{0},
          extra: <String>['give'],
          ending: '.',
          tip:
              'give + person + thing: "gives us more time", then "to + verb" '
              'for the purpose.',
        ),
        SentenceItem(
          id: 'bas-19',
          speaker: 'Friend',
          prompt: 'I finally got my driving licence.',
          answer: <String>[
            'How long',
            'have',
            'you',
            'been',
            'taking',
            'lessons',
          ],
          fixed: <int>{0},
          extra: <String>['did'],
          ending: '?',
          tip:
              'Present perfect continuous question: How long + have + '
              'subject + been + -ing.',
        ),
        SentenceItem(
          id: 'bas-20',
          speaker: 'Classmate',
          prompt: 'I can’t decide between the two internships.',
          answer: <String>[
            'Which one',
            'would',
            'you',
            'learn',
            'more',
            'from',
          ],
          fixed: <int>{0, 5},
          extra: <String>['learned'],
          ending: '?',
          tip:
              'Modal + base verb ("would you learn"). A preposition can end a '
              'question: "Which one… learn more from?"',
        ),
      ],
    ),
    SentenceSet(
      id: 'bas-academic',
      title: 'Academic situations',
      level: 'Advanced structures',
      items: <SentenceItem>[
        SentenceItem(
          id: 'bas-21',
          speaker: 'Professor',
          prompt: 'The results of the survey were surprising.',
          answer: <String>[
            'Could',
            'you',
            'explain',
            'what',
            'made',
            'them',
            'so unexpected',
          ],
          fixed: <int>{0},
          extra: <String>['did'],
          ending: '?',
          tip:
              '"what" is the subject of "made": "explain what made them so '
              'unexpected", with no "did".',
        ),
        SentenceItem(
          id: 'bas-22',
          speaker: 'Classmate',
          prompt: 'The guest speaker was really inspiring.',
          answer: <String>['I', 'wish', 'I', 'had been', 'able', 'to attend'],
          fixed: <int>{0},
          extra: <String>['have been'],
          ending: '.',
          tip:
              'A regret about the past: wish + past perfect ("I wish I had '
              'been able to…").',
        ),
        SentenceItem(
          id: 'bas-23',
          speaker: 'Advisor',
          prompt: 'Applications for the exchange programme close soon.',
          answer: <String>[
            'Do',
            'you',
            'know',
            'whether',
            'I',
            'need',
            'a recommendation letter',
          ],
          fixed: <int>{0},
          extra: <String>['do'],
          ending: '?',
          tip:
              'After "whether", statement order: "whether I need", not '
              '"whether do I need".',
        ),
        SentenceItem(
          id: 'bas-24',
          speaker: 'Roommate',
          prompt: 'The heating hasn’t worked since Monday.',
          answer: <String>[
            'Has',
            'anyone',
            'reported',
            'the problem',
            'to the landlord',
          ],
          fixed: <int>{0},
          extra: <String>['report'],
          ending: '?',
          tip:
              'Present perfect question: Has + subject + past participle '
              '("Has anyone reported…?").',
        ),
        SentenceItem(
          id: 'bas-25',
          speaker: 'Professor',
          prompt: 'Your thesis needs a stronger conclusion.',
          answer: <String>[
            'Would',
            'it',
            'help',
            'if',
            'I',
            'summarised',
            'the main findings',
          ],
          fixed: <int>{0},
          extra: <String>['will'],
          ending: '?',
          tip:
              'Second conditional: would + base verb, then "if" + past '
              '("if I summarised"). No "will" after "if".',
        ),
        SentenceItem(
          id: 'bas-26',
          speaker: 'Classmate',
          prompt: 'I’ve read the article three times and I’m still lost.',
          answer: <String>[
            'Which part',
            'did',
            'you',
            'find',
            'the most confusing',
          ],
          fixed: <int>{0},
          extra: <String>['found'],
          ending: '?',
          tip:
              'did + subject + base verb ("did you find"); find + object + '
              'adjective.',
        ),
        SentenceItem(
          id: 'bas-27',
          speaker: 'Manager',
          prompt: 'The client wants the report earlier than planned.',
          answer: <String>[
            'Do',
            'they',
            'realise',
            'how much work',
            'is',
            'left',
          ],
          fixed: <int>{0},
          extra: <String>['are'],
          ending: '?',
          tip:
              '"work" is uncountable: "how much work is left", in statement '
              'order inside the question.',
        ),
        SentenceItem(
          id: 'bas-28',
          speaker: 'Teammate',
          prompt: 'Nobody answered my email about the meeting.',
          answer: <String>['Maybe', 'it', 'ended up', 'in their spam folder'],
          fixed: <int>{0},
          extra: <String>['end up'],
          ending: '.',
          tip:
              'A past event needs a past verb: "it ended up", a phrasal verb '
              'kept together.',
        ),
        SentenceItem(
          id: 'bas-29',
          speaker: 'Professor',
          prompt: 'The library will extend its opening hours during exams.',
          answer: <String>[
            'Will',
            'it',
            'also',
            'be',
            'open',
            'on Sunday mornings',
          ],
          fixed: <int>{0, 5},
          extra: <String>['opens'],
          ending: '?',
          tip:
              'Will + subject + (also) + be + adjective. "also" sits before '
              'the main verb.',
        ),
        SentenceItem(
          id: 'bas-30',
          speaker: 'Friend',
          prompt: 'I’m not sure the restaurant is still open.',
          answer: <String>[
            'Let’s',
            'check',
            'what time',
            'it',
            'closes',
            'before we go',
          ],
          fixed: <int>{0, 5},
          extra: <String>['does'],
          ending: '.',
          tip:
              '"Let’s + base verb", then an embedded question in statement '
              'order: "what time it closes".',
        ),
      ],
    ),
  ];
}
