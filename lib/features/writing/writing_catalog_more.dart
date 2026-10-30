import 'writing_catalog.dart';

/// 30 more studio tasks across the 13 genres (added with exam preparation).
const List<WritingTask> moreStudioTasks = <WritingTask>[
  // ------------------------------------------------------------------ EMAIL
  WritingTask(
    id: 'email-recommend-book',
    genre: WritingGenre.email,
    band: WritingBand.foundation,
    title: 'Recommend a book',
    reader: 'Your friend Lea',
    prompt:
        'Your friend Lea is looking for a good book or series to read on '
        'holiday. Write to her: recommend one, say what it is about without '
        'the ending, and explain why she will like it.',
    minWords: 40,
    maxWords: 90,
    hints: <String>[
      'Start friendly: "Hi Lea," and react to her message.',
      'Use the present simple for the story: "It tells the story of…"',
    ],
  ),
  WritingTask(
    id: 'email-landlord-repair',
    genre: WritingGenre.email,
    band: WritingBand.intermediate,
    title: 'Ask for a repair',
    reader: 'Mr Patel, your landlord',
    prompt:
        'The heating in your flat has stopped working and the nights are '
        'getting cold. Write to your landlord: describe the problem and when '
        'it started, explain how it affects you, and ask when someone can '
        'come to repair it.',
    minWords: 110,
    maxWords: 170,
    hints: <String>[
      '"Dear Mr Patel," and a clear purpose in the first line.',
      'Give your availability to make the visit easy to arrange.',
    ],
  ),

  // ------------------------------------------------------ PRACTICAL MESSAGE
  WritingTask(
    id: 'message-roommate-shopping',
    genre: WritingGenre.practicalMessage,
    band: WritingBand.foundation,
    title: 'A note for your roommate',
    reader: 'Your roommate',
    prompt:
        'You are going away for the weekend. Leave a note for your roommate: '
        'say when you will be back, what they need to buy for the flat, and '
        'one thing they must not forget.',
    minWords: 25,
    maxWords: 60,
    hints: <String>[
      'Imperatives are fine in a note: "Please buy…", "Don’t forget…"',
    ],
  ),
  WritingTask(
    id: 'message-lost-pet',
    genre: WritingGenre.practicalMessage,
    band: WritingBand.intermediate,
    title: 'Lost cat notice',
    prompt:
        'Your cat has been missing since yesterday. Write a notice for your '
        'building’s noticeboard: describe the cat, say where and when it was '
        'last seen, and tell people what to do if they find it.',
    minWords: 60,
    maxWords: 110,
    hints: <String>[
      'A short title people can read from far away: "Missing cat".',
      'Precise description: colour, size, collar, name it answers to.',
    ],
  ),
  WritingTask(
    id: 'message-new-procedure',
    genre: WritingGenre.practicalMessage,
    band: WritingBand.advanced,
    title: 'A new booking procedure',
    reader: 'All members of a sports club',
    prompt:
        'From next month, members of your sports club must book courts '
        'online instead of at the front desk. Write a short announcement: '
        'explain the change and why it is happening, give the steps to '
        'book, and say who to contact for help.',
    minWords: 90,
    maxWords: 150,
    hints: <String>[
      'Put the date of the change at the top.',
      'Numbered steps are clearer than a paragraph for instructions.',
    ],
  ),

  // ----------------------------------------------------------- FREE WRITING
  WritingTask(
    id: 'free-perfect-weekend',
    genre: WritingGenre.free,
    band: WritingBand.foundation,
    title: 'My perfect weekend',
    prompt:
        'Describe your perfect weekend: where you would be, who with, and '
        'what you would do from Saturday morning to Sunday evening.',
    minWords: 50,
    maxWords: 0,
    hints: <String>['"I would…" helps you imagine: "I would wake up late…"'],
  ),
  WritingTask(
    id: 'free-proud-english',
    genre: WritingGenre.free,
    band: WritingBand.intermediate,
    title: 'A moment in English',
    prompt:
        'Write about a moment when you used English in real life and felt '
        'proud, surprised or embarrassed. What happened, and what did you '
        'learn from it?',
    minWords: 120,
    maxWords: 0,
    hints: <String>[
      'Mix past simple for events and past continuous for the background.',
    ],
  ),
  WritingTask(
    id: 'free-overrated',
    genre: WritingGenre.free,
    band: WritingBand.advanced,
    title: 'Overrated?',
    prompt:
        'Choose something that almost everyone seems to love — a film, a '
        'habit, a place, a piece of technology — and explain honestly why '
        'you are less enthusiastic.',
    minWords: 200,
    maxWords: 0,
    hints: <String>[
      'Nuance keeps readers on your side: "I can see why…, yet…"',
    ],
  ),

  // ------------------------------------------------------------------ ESSAY
  WritingTask(
    id: 'essay-someone-admire',
    genre: WritingGenre.essay,
    band: WritingBand.foundation,
    title: 'Someone I admire',
    prompt:
        'Write a short essay about a person you admire (famous or not). Who '
        'are they, what have they done, and why do you admire them?',
    minWords: 70,
    maxWords: 130,
    hints: <String>[
      'Three short paragraphs: who, what they did, why you admire them.',
    ],
  ),
  WritingTask(
    id: 'essay-city-or-country',
    genre: WritingGenre.essay,
    band: WritingBand.intermediate,
    title: 'City or countryside?',
    prompt:
        'Is it better to grow up in a city or in the countryside? Write an '
        'essay that considers both and reaches a conclusion.',
    minWords: 180,
    maxWords: 260,
    hints: <String>[
      'Compare with the same criteria: freedom, safety, opportunities.',
      'Your conclusion should answer the question, not only summarise.',
    ],
  ),

  // ---------------------------------------------------------- ARGUMENTATIVE
  WritingTask(
    id: 'argument-longer-school-day',
    genre: WritingGenre.argumentative,
    band: WritingBand.foundation,
    title: 'A longer school day?',
    prompt:
        'Your school wants to finish one hour later every day and give no '
        'homework. Are you for or against this idea? Give two reasons.',
    minWords: 60,
    maxWords: 120,
    hints: <String>['"I am against this idea because…" then "Also,…"'],
  ),
  WritingTask(
    id: 'argument-free-museums',
    genre: WritingGenre.argumentative,
    band: WritingBand.advanced,
    title: 'Free museums for all',
    prompt:
        'Should national museums be free to enter for everyone? Write an '
        'argument for one side, supporting each reason with evidence or an '
        'example and answering the strongest objection.',
    minWords: 260,
    maxWords: 380,
    hints: <String>[
      'Anticipate the cost objection: who pays if visitors do not?',
      'Concede and counter: "Admittedly…; nevertheless…"',
    ],
  ),

  // ---------------------------------------------------------------- OPINION
  WritingTask(
    id: 'opinion-learn-words',
    genre: WritingGenre.opinion,
    band: WritingBand.foundation,
    title: 'The best way to learn words',
    prompt:
        'What is the best way to learn new English words: lists, songs, '
        'films, apps or something else? Give your opinion and explain why.',
    minWords: 50,
    maxWords: 110,
    hints: <String>['Give an example of a word you learned that way.'],
  ),
  WritingTask(
    id: 'opinion-video-games-art',
    genre: WritingGenre.opinion,
    band: WritingBand.advanced,
    title: 'Are video games art?',
    prompt:
        'Some critics argue that video games can be art in the same way as '
        'films or novels. What is your opinion? Explain your view with '
        'precise examples.',
    minWords: 220,
    maxWords: 340,
    hints: <String>['Define what you mean by "art" before you answer.'],
  ),

  // -------------------------------------------------------- FOR AND AGAINST
  WritingTask(
    id: 'for-against-e-scooters',
    genre: WritingGenre.forAgainst,
    band: WritingBand.intermediate,
    title: 'Electric scooters in town',
    prompt:
        'Rental electric scooters are now common in many towns. Write an '
        'essay presenting the advantages and disadvantages, then give your '
        'own view in the conclusion.',
    minWords: 160,
    maxWords: 240,
    hints: <String>[
      'Balance: as many good arguments on each side.',
      'Linkers: "On the one hand", "On the other hand", "All things '
          'considered".',
    ],
  ),
  WritingTask(
    id: 'for-against-gap-year',
    genre: WritingGenre.forAgainst,
    band: WritingBand.advanced,
    title: 'A gap year before university',
    prompt:
        'More students take a gap year between school and university. '
        'Discuss the benefits and drawbacks for the students themselves and '
        'for their future studies, then give a reasoned conclusion.',
    minWords: 250,
    maxWords: 360,
    hints: <String>['Distinguish short-term and long-term effects.'],
  ),

  // --------------------------------------------------------------- ACADEMIC
  WritingTask(
    id: 'academic-handwriting-memory',
    genre: WritingGenre.academic,
    band: WritingBand.intermediate,
    title: 'Handwriting and memory',
    prompt:
        'Write an academic paragraph discussing whether taking notes by hand '
        'helps students remember more than typing them. Use careful claims '
        'and avoid personal anecdotes.',
    minWords: 140,
    maxWords: 210,
    hints: <String>[
      'Hedging: "may", "appears to", "some studies suggest".',
      'No contractions, no "I think".',
    ],
  ),
  WritingTask(
    id: 'academic-urban-gardens',
    genre: WritingGenre.academic,
    band: WritingBand.advanced,
    title: 'Urban gardens',
    prompt:
        'Write a short academic text evaluating the benefits and limits of '
        'community gardens in cities (health, environment, social life). '
        'Present balanced claims and a careful conclusion.',
    minWords: 250,
    maxWords: 360,
    hints: <String>[
      'Evaluate, do not only list: which benefit is strongest, and why?',
    ],
  ),
  WritingTask(
    id: 'academic-screen-reading',
    genre: WritingGenre.academic,
    band: WritingBand.advanced,
    title: 'Reading on screens',
    prompt:
        'Write an academic paragraph comparing reading long texts on paper '
        'and on screens, considering comprehension, convenience and cost. '
        'Keep a formal register throughout.',
    minWords: 180,
    maxWords: 260,
    hints: <String>[
      'Comparison language: "whereas", "in contrast", "to a lesser extent".',
    ],
  ),

  // -------------------------------------------------------------- NARRATIVE
  WritingTask(
    id: 'narrative-power-cut',
    genre: WritingGenre.narrative,
    band: WritingBand.foundation,
    title: 'The power cut',
    prompt:
        'One evening, all the lights in your street went out for three '
        'hours. Tell the story of that evening.',
    minWords: 60,
    maxWords: 120,
    hints: <String>[
      'Time words: "At first", "Then", "After an hour", "Finally".',
    ],
  ),
  WritingTask(
    id: 'narrative-wrong-train',
    genre: WritingGenre.narrative,
    band: WritingBand.intermediate,
    title: 'The wrong train',
    prompt:
        'Write a story that begins: "As soon as the doors closed, I knew I '
        'was on the wrong train." Tell what happened and how it ended.',
    minWords: 160,
    maxWords: 240,
    hints: <String>[
      'Past perfect for earlier events: "I had forgotten to check…"',
      'Build tension before the ending.',
    ],
  ),

  // ------------------------------------------------------------ DESCRIPTIVE
  WritingTask(
    id: 'descriptive-family-member',
    genre: WritingGenre.descriptive,
    band: WritingBand.foundation,
    title: 'Someone in my family',
    prompt:
        'Describe a person in your family: how they look, their personality '
        'and something they often do or say.',
    minWords: 50,
    maxWords: 100,
    hints: <String>['Order: appearance, then personality, then a habit.'],
  ),
  WritingTask(
    id: 'descriptive-city-night',
    genre: WritingGenre.descriptive,
    band: WritingBand.advanced,
    title: 'A city at night',
    prompt:
        'Describe a city you know at night, so that a reader who has never '
        'been there can see, hear and feel it. Choose precise images rather '
        'than many adjectives.',
    minWords: 200,
    maxWords: 300,
    hints: <String>[
      'Move through space like a camera: from far away to a single detail.',
    ],
  ),

  // --------------------------------------------------------------- CREATIVE
  WritingTask(
    id: 'creative-morning-poem',
    genre: WritingGenre.creative,
    band: WritingBand.foundation,
    title: 'A morning poem',
    prompt:
        'Write a short poem (6 to 10 lines) about your mornings. It does not '
        'need to rhyme.',
    minWords: 25,
    maxWords: 80,
    hints: <String>['Each line can start with a sound, a colour or a smell.'],
  ),
  WritingTask(
    id: 'creative-postcard-planet',
    genre: WritingGenre.creative,
    band: WritingBand.intermediate,
    title: 'Postcard from another planet',
    prompt:
        'You are the first tourist on a newly discovered planet. Write a '
        'postcard home describing what you see, what surprises you and what '
        'you miss from Earth.',
    minWords: 120,
    maxWords: 200,
    hints: <String>[
      'Invent details and name them: a strange fruit, two moons, the '
          'weather.',
    ],
  ),

  // ---------------------------------------------------------------- SUMMARY
  WritingTask(
    id: 'summary-light-pollution',
    genre: WritingGenre.summary,
    band: WritingBand.intermediate,
    title: 'Where have the stars gone?',
    prompt:
        'Summarise the article in your own words for a school science page. '
        'Keep the main problem, its effects and the solutions.',
    minWords: 80,
    maxWords: 130,
    hints: <String>[
      'One sentence for the problem, one or two for effects, one for '
          'solutions.',
    ],
    sourceText:
        'Most people living in cities today can see only a few dozen stars '
        'at night, while someone in a remote desert can see thousands. The '
        'reason is light pollution: artificial light from street lamps, '
        'buildings and advertising escapes into the sky and makes it glow.\n\n'
        'The problem is not only for astronomers. Many animals depend on '
        'darkness. Young sea turtles find the ocean by moving towards the '
        'brightest horizon, and bright coasts send them in the wrong '
        'direction. Migrating birds can become confused by lit towers. '
        'Humans are affected too: light at night can disturb sleep by '
        'reducing the hormone that tells the body it is time to rest.\n\n'
        'Unlike many environmental problems, light pollution is easy to '
        'reduce. Lamps can be shielded so that they shine down rather than '
        'up, switched off when nobody needs them, or replaced with warmer, '
        'dimmer light. Some towns have already done this and been named '
        '"dark-sky places", which now attract visitors who want to see the '
        'Milky Way again.',
  ),
  WritingTask(
    id: 'summary-adult-learners',
    genre: WritingGenre.summary,
    band: WritingBand.advanced,
    title: 'Is it too late to learn a language?',
    prompt:
        'Write a summary of the article for a magazine for adult learners, '
        'keeping the argument and the evidence, without adding your own '
        'opinion.',
    minWords: 110,
    maxWords: 170,
    hints: <String>[
      'Keep the contrast: what children do better, what adults do better.',
      'Paraphrase rather than copy whole phrases.',
    ],
    sourceText:
        'It is often said that languages must be learned in childhood. The '
        'belief is partly true. Children who grow up hearing a language '
        'usually develop a native-like accent, something adults rarely '
        'achieve, and they seem to absorb grammar without explicit study.\n\n'
        'However, the picture changes when we look at the early stages of '
        'learning. In classroom studies, adults and teenagers often progress '
        'faster than young children during the first months, because they '
        'can use strategies children do not yet have: they notice patterns, '
        'compare the new language with their own, take notes and plan their '
        'practice. Adults also bring a larger vocabulary of ideas, which '
        'helps them understand complex texts sooner.\n\n'
        'What seems to matter most is not age but the amount and quality of '
        'exposure. Children have years of daily contact with the language; '
        'adults usually have a few hours a week. Researchers therefore '
        'suggest that adults should not aim to sound exactly like native '
        'speakers, but to communicate clearly, and that they can make '
        'remarkable progress if they read, listen and speak regularly over a '
        'long period.',
  ),

  // ----------------------------------------------------------------- REPORT
  WritingTask(
    id: 'report-sports-day',
    genre: WritingGenre.report,
    band: WritingBand.foundation,
    title: 'Report on sports day',
    prompt:
        'Write a short report for the school newsletter about your school’s '
        'sports day: what events took place, what went well, and one thing '
        'to improve next year.',
    minWords: 60,
    maxWords: 120,
    hints: <String>['Headings: "The day", "What went well", "Next year".'],
  ),
  WritingTask(
    id: 'report-library-use',
    genre: WritingGenre.report,
    band: WritingBand.intermediate,
    title: 'How students use the library',
    prompt:
        'A survey of 80 students shows: 55% use the library mainly to study '
        'quietly, 25% to borrow books, 20% for the computers; 65% would like '
        'it to open later in the evening. Write a report for the school '
        'director presenting the findings and recommending changes.',
    minWords: 150,
    maxWords: 230,
    hints: <String>[
      'Report the figures accurately and group them logically.',
      'Each recommendation should come from a finding.',
    ],
  ),
  WritingTask(
    id: 'report-event-review',
    genre: WritingGenre.report,
    band: WritingBand.advanced,
    title: 'After the charity concert',
    prompt:
        'You helped organise a charity concert that raised less money than '
        'expected, although the audience enjoyed it. Write a report for the '
        'organising committee: summarise what happened, analyse why the '
        'target was missed, and recommend changes for next year.',
    minWords: 260,
    maxWords: 380,
    hints: <String>[
      'Separate facts (Findings) from interpretation (Analysis).',
      'Make recommendations specific and realistic.',
    ],
  ),
];
