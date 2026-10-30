import '../writing/writing_catalog.dart';
import 'exam_formats.dart';
import 'exam_visuals.dart';

/// Original practice tasks in the public formats of the TOEFL iBT (2026) and
/// IELTS Writing. Official prompts are protected, so none is reproduced:
/// situations, questions, posts and data are written for Eloqia.
const List<WritingTask> examWritingTasks = <WritingTask>[
  // ============================================================ TOEFL EMAIL
  WritingTask(
    id: 'toefl-email-silent-teammate',
    genre: WritingGenre.toeflEmail,
    band: WritingBand.intermediate,
    title: 'A silent teammate',
    reader: 'Jordan, a classmate in your group',
    prompt:
        'Your biology group gives its presentation next Thursday, but one '
        'member, Jordan, has not answered the group chat for five days. '
        'Write an email to Jordan. In your email, do the following:\n'
        '• Explain where the group is with the presentation.\n'
        '• Ask whether everything is all right.\n'
        '• Suggest how to share the remaining work.',
    minWords: 80,
    maxWords: 0,
    hints: <String>[
      'Friendly but clear: "Hi Jordan," … "Thanks, [your name]".',
      'Show concern before asking for work: "I hope everything is OK."',
      'Make a concrete offer: "Could you prepare the slides on…by Monday?"',
    ],
  ),
  WritingTask(
    id: 'toefl-email-extension',
    genre: WritingGenre.toeflEmail,
    band: WritingBand.intermediate,
    title: 'Asking for more time',
    reader: 'Professor Lin, your economics professor',
    prompt:
        'You were ill and missed two economics classes this week. Your '
        'assignment for Professor Lin is due on Friday. Write an email to '
        'Professor Lin. In your email, do the following:\n'
        '• Explain why you missed the classes.\n'
        '• Ask for a short extension and say when you could submit.\n'
        '• Ask how to catch up on the material you missed.',
    minWords: 80,
    maxWords: 0,
    hints: <String>[
      '"Dear Professor Lin," and "Best regards," suit a professor.',
      'Requests: "I was wondering if I could…", "Would it be possible to…?"',
      'Give a precise new date: it makes the request easier to accept.',
    ],
  ),
  WritingTask(
    id: 'toefl-email-library-fee',
    genre: WritingGenre.toeflEmail,
    band: WritingBand.intermediate,
    title: 'A late fee by mistake',
    reader: 'The university library’s customer service',
    prompt:
        'The university library charged you a late fee for a book you are '
        'sure you returned on time. Write an email to the library’s customer '
        'service. In your email, do the following:\n'
        '• Say which book it is and when you returned it.\n'
        '• Explain why you think there is a mistake.\n'
        '• Say what you would like the library to do.',
    minWords: 80,
    maxWords: 0,
    hints: <String>[
      'Facts first: title, date, where you returned it.',
      'Polite but firm: "I believe there may be an error in my account."',
    ],
  ),
  WritingTask(
    id: 'toefl-email-film-club',
    genre: WritingGenre.toeflEmail,
    band: WritingBand.intermediate,
    title: 'The film night has moved',
    reader: 'The members of the campus film club',
    prompt:
        'You organise the campus film club. The room booked for Friday’s '
        'film night is no longer available. Write an email to the club '
        'members. In your email, do the following:\n'
        '• Explain what has changed and why.\n'
        '• Give the new place or time.\n'
        '• Ask members to confirm whether they are coming.',
    minWords: 80,
    maxWords: 0,
    hints: <String>[
      'A group email: "Hi everyone," works well.',
      'Put the new information where nobody can miss it.',
      'End with a clear action: "Please reply by Wednesday."',
    ],
  ),
  WritingTask(
    id: 'toefl-email-internship',
    genre: WritingGenre.toeflEmail,
    band: WritingBand.advanced,
    title: 'Before your internship',
    reader: 'Ms Okafor, your future manager',
    prompt:
        'You start a summer internship at a design company next month. You '
        'have just found out that one of your final exams is on your second '
        'day. Write an email to your future manager, Ms Okafor. In your '
        'email, do the following:\n'
        '• Thank her for the offer and confirm your start date.\n'
        '• Explain the problem with your exam.\n'
        '• Suggest a solution and ask one question about the first week.',
    minWords: 90,
    maxWords: 0,
    hints: <String>[
      'Professional and positive: start with thanks, then the problem.',
      'Offer a solution yourself ("I could make up the time on…").',
    ],
  ),
  WritingTask(
    id: 'toefl-email-noise',
    genre: WritingGenre.toeflEmail,
    band: WritingBand.foundation,
    title: 'Too much noise at night',
    reader: 'Sam, the resident assistant of your hall',
    prompt:
        'A student on your floor plays loud music late at night, and you '
        'cannot sleep before your morning classes. Write an email to Sam, '
        'the resident assistant. In your email, do the following:\n'
        '• Describe the problem.\n'
        '• Say what you have already tried.\n'
        '• Suggest what could be done.',
    minWords: 70,
    maxWords: 0,
    hints: <String>[
      'Describe, do not accuse: "Music can be heard until 2 a.m."',
      'Use the present perfect for what you tried: "I have asked…"',
    ],
  ),

  // ===================================================== TOEFL DISCUSSION
  WritingTask(
    id: 'toefl-discussion-online-course',
    genre: WritingGenre.toeflDiscussion,
    band: WritingBand.intermediate,
    title: 'One online course for everyone?',
    prompt:
        'Your professor is teaching a class on education. Write a post '
        'responding to the professor’s question. In your response, express '
        'and support your opinion and make a contribution to the discussion.',
    minWords: 100,
    maxWords: 0,
    discussion: DiscussionBoard(
      course: 'Education',
      professor: 'Rivera',
      question:
          'Some universities now require every student to take at least one '
          'course entirely online before graduating. Supporters say it '
          'prepares students for modern workplaces. Do you think this '
          'requirement is a good idea? Why or why not?',
      posts: <DiscussionPost>[
        DiscussionPost(
          'Maya',
          'I think it is a good idea. Many jobs now involve remote meetings '
              'and shared documents, and an online course teaches students '
              'to organise their own time without a teacher reminding them '
              'every day.',
        ),
        DiscussionPost(
          'Daniel',
          'I disagree. Some students learn much better face to face, and '
              'an online course could lower their grades. Universities should '
              'offer online courses, but students should be free to choose.',
        ),
      ],
    ),
    hints: <String>[
      'Opinion first: "In my view, this requirement makes sense because…"',
      'Engage: "Daniel raises a fair point about…, but…"',
      'Add something new: an example from your own experience.',
    ],
  ),
  WritingTask(
    id: 'toefl-discussion-car-free',
    genre: WritingGenre.toeflDiscussion,
    band: WritingBand.intermediate,
    title: 'Car-free city centres',
    prompt:
        'Your professor is teaching a class on urban planning. Write a post '
        'responding to the professor’s question. In your response, express '
        'and support your opinion and make a contribution to the discussion.',
    minWords: 100,
    maxWords: 0,
    discussion: DiscussionBoard(
      course: 'Urban planning',
      professor: 'Nakamura',
      question:
          'Several cities have closed their historic centres to private '
          'cars. Should more cities follow this example, or does it create '
          'more problems than it solves?',
      posts: <DiscussionPost>[
        DiscussionPost(
          'Aisha',
          'More cities should do it. The air is cleaner, the streets are '
              'safer for children and people spend more time in local shops '
              'when they walk.',
        ),
        DiscussionPost(
          'Tom',
          'It sounds nice, but older people and people with disabilities '
              'need to reach the centre too. Without cars, some of them would '
              'simply stop going there.',
        ),
      ],
    ),
    hints: <String>[
      'You can find a middle position, but make it clear.',
      'Answer Tom’s concern with a concrete solution if you agree with Aisha.',
    ],
  ),
  WritingTask(
    id: 'toefl-discussion-company-growth',
    genre: WritingGenre.toeflDiscussion,
    band: WritingBand.advanced,
    title: 'Grow fast or grow slowly?',
    prompt:
        'Your professor is teaching a class on business. Write a post '
        'responding to the professor’s question. In your response, express '
        'and support your opinion and make a contribution to the discussion.',
    minWords: 100,
    maxWords: 0,
    discussion: DiscussionBoard(
      course: 'Business',
      professor: 'Haddad',
      question:
          'When a new company becomes successful, it can try to grow as fast '
          'as possible or expand slowly and carefully. Which strategy is '
          'better for a young company, and why?',
      posts: <DiscussionPost>[
        DiscussionPost(
          'Lena',
          'Fast growth is necessary today. If a company does not take the '
              'market quickly, a bigger competitor will copy its idea and win '
              'the customers.',
        ),
        DiscussionPost(
          'Kwame',
          'Slow growth is safer. Many companies hire too many people too '
              'quickly and then run out of money. Growing slowly lets a '
              'company learn from its mistakes.',
        ),
      ],
    ),
    hints: <String>[
      'Hedge carefully: "It largely depends on…, but in most cases…"',
      'A real or imagined example makes your contribution stand out.',
    ],
  ),
  WritingTask(
    id: 'toefl-discussion-community-service',
    genre: WritingGenre.toeflDiscussion,
    band: WritingBand.intermediate,
    title: 'Community service to graduate',
    prompt:
        'Your professor is teaching a class on sociology. Write a post '
        'responding to the professor’s question. In your response, express '
        'and support your opinion and make a contribution to the discussion.',
    minWords: 100,
    maxWords: 0,
    discussion: DiscussionBoard(
      course: 'Sociology',
      professor: 'Brennan',
      question:
          'Some high schools require students to complete forty hours of '
          'community service, such as helping at a food bank, before they '
          'can graduate. Is this a good requirement?',
      posts: <DiscussionPost>[
        DiscussionPost(
          'Sofia',
          'Yes. Volunteering shows teenagers problems they never see in '
              'class, and many students continue to help after the required '
              'hours.',
        ),
        DiscussionPost(
          'Ethan',
          'If it is required, it is not really volunteering. Students who '
              'work part-time to help their families may not have forty free '
              'hours.',
        ),
      ],
    ),
    hints: <String>[
      'Respond to Ethan’s point about students who work.',
      'Use a conditional to propose a change: "If schools counted…, then…"',
    ],
  ),
  WritingTask(
    id: 'toefl-discussion-social-media',
    genre: WritingGenre.toeflDiscussion,
    band: WritingBand.intermediate,
    title: 'Connected or isolated?',
    prompt:
        'Your professor is teaching a class on psychology. Write a post '
        'responding to the professor’s question. In your response, express '
        'and support your opinion and make a contribution to the discussion.',
    minWords: 100,
    maxWords: 0,
    discussion: DiscussionBoard(
      course: 'Psychology',
      professor: 'Okonkwo',
      question:
          'Researchers disagree about the effect of social media on young '
          'people. Overall, do social media make young people feel more '
          'connected to others or more isolated?',
      posts: <DiscussionPost>[
        DiscussionPost(
          'Priya',
          'More connected. I keep in touch with friends from my old school '
              'every day, which would be impossible without social media.',
        ),
        DiscussionPost(
          'Lucas',
          'More isolated. People compare their lives with perfect pictures '
              'and spend less time with the friends who are actually near '
              'them.',
        ),
      ],
    ),
    hints: <String>[
      'Distinguish how social media are used: the answer may depend on it.',
    ],
  ),
  WritingTask(
    id: 'toefl-discussion-library-budget',
    genre: WritingGenre.toeflDiscussion,
    band: WritingBand.advanced,
    title: 'Books or digital resources?',
    prompt:
        'Your professor is teaching a class on public policy. Write a post '
        'responding to the professor’s question. In your response, express '
        'and support your opinion and make a contribution to the discussion.',
    minWords: 100,
    maxWords: 0,
    discussion: DiscussionBoard(
      course: 'Public policy',
      professor: 'Duarte',
      question:
          'Public libraries have limited budgets. Should they now spend more '
          'on digital resources, such as e-books and online databases, than '
          'on printed books?',
      posts: <DiscussionPost>[
        DiscussionPost(
          'Hana',
          'Yes. E-books can be borrowed from home at any hour, and one '
              'digital copy can serve readers all over the city.',
        ),
        DiscussionPost(
          'Marco',
          'Not yet. Many people still do not have a good device or internet '
              'connection at home, and the library is where they read.',
        ),
      ],
    ),
    hints: <String>[
      'Precise vocabulary: access, licence, the digital divide, a device.',
    ],
  ),

  // ================================================ IELTS TASK 1 ACADEMIC
  WritingTask(
    id: 'ielts-t1-leisure-bar',
    genre: WritingGenre.ieltsTask1Academic,
    band: WritingBand.intermediate,
    title: 'Young people’s leisure time',
    prompt:
        'The bar chart shows the average number of hours per week that '
        'people aged 16 to 24 spent on four leisure activities in 2015 and '
        '2025. Summarise the information by selecting and reporting the main '
        'features, and make comparisons where relevant.',
    minWords: 150,
    maxWords: 0,
    visual: ExamVisual(
      kind: ExamVisualKind.bar,
      title: 'Time spent on leisure activities by people aged 16–24',
      unit: 'hours per week',
      axisLabel: 'activity',
      categories: <String>['Gaming', 'Sport', 'Social media', 'Reading'],
      series: <ChartSeries>[
        ChartSeries('2015', <double>[5, 6, 9, 4]),
        ChartSeries('2025', <double>[8, 5, 14, 3]),
      ],
    ),
    hints: <String>[
      'Overview: social media took the most time in both years and grew '
          'the most.',
      'Compare rises and falls: "rose from 9 to 14 hours", "fell slightly".',
    ],
  ),
  WritingTask(
    id: 'ielts-t1-solar-bar',
    genre: WritingGenre.ieltsTask1Academic,
    band: WritingBand.advanced,
    title: 'Homes with solar panels',
    prompt:
        'The chart shows the percentage of households with solar panels in '
        'five countries in 2010 and 2024. Summarise the information by '
        'selecting and reporting the main features, and make comparisons '
        'where relevant.',
    minWords: 150,
    maxWords: 0,
    visual: ExamVisual(
      kind: ExamVisualKind.bar,
      title: 'Households with solar panels, 2010 and 2024',
      unit: '% of households',
      axisLabel: 'country',
      categories: <String>['Spain', 'Germany', 'Australia', 'Canada', 'Japan'],
      series: <ChartSeries>[
        ChartSeries('2010', <double>[2, 4, 9, 1, 5]),
        ChartSeries('2024', <double>[14, 18, 31, 6, 12]),
      ],
    ),
    hints: <String>[
      'Group countries with similar patterns instead of describing each one.',
      'Multiples help: "more than tripled", "six times higher".',
    ],
  ),
  WritingTask(
    id: 'ielts-t1-museums-line',
    genre: WritingGenre.ieltsTask1Academic,
    band: WritingBand.intermediate,
    title: 'Visitors to three museums',
    prompt:
        'The graph shows the number of visitors to three museums in a city '
        'between 2000 and 2025. Summarise the information by selecting and '
        'reporting the main features, and make comparisons where relevant.',
    minWords: 150,
    maxWords: 0,
    visual: ExamVisual(
      kind: ExamVisualKind.line,
      title: 'Visitors to three city museums, 2000–2025',
      unit: 'thousands of visitors per year',
      axisLabel: 'year',
      categories: <String>['2000', '2005', '2010', '2015', '2020', '2025'],
      series: <ChartSeries>[
        ChartSeries('Science Museum', <double>[120, 150, 210, 260, 180, 290]),
        ChartSeries('Art Gallery', <double>[200, 190, 185, 170, 160, 175]),
        ChartSeries('History Museum', <double>[80, 95, 110, 140, 150, 165]),
      ],
    ),
    hints: <String>[
      'Notice the crossover: when did the Science Museum overtake the Art '
          'Gallery?',
      'Mention the drop in 2020 without guessing its cause.',
    ],
  ),
  WritingTask(
    id: 'ielts-t1-rainfall-line',
    genre: WritingGenre.ieltsTask1Academic,
    band: WritingBand.advanced,
    title: 'Rainfall in two cities',
    prompt:
        'The graph compares the average monthly rainfall in two cities. '
        'Summarise the information by selecting and reporting the main '
        'features, and make comparisons where relevant.',
    minWords: 150,
    maxWords: 0,
    visual: ExamVisual(
      kind: ExamVisualKind.line,
      title: 'Average monthly rainfall in Port Elena and Varanpur',
      unit: 'millimetres',
      axisLabel: 'month',
      categories: <String>[
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ],
      series: <ChartSeries>[
        ChartSeries('Port Elena', <double>[
          110,
          95,
          80,
          55,
          35,
          15,
          8,
          10,
          30,
          70,
          100,
          120,
        ]),
        ChartSeries('Varanpur', <double>[
          10,
          12,
          20,
          45,
          110,
          210,
          260,
          240,
          150,
          60,
          20,
          8,
        ]),
      ],
    ),
    hints: <String>[
      'The overview is about opposite seasonal patterns.',
      'Give the peaks with their months: "peaking at 260 mm in July".',
    ],
  ),
  WritingTask(
    id: 'ielts-t1-budget-pie',
    genre: WritingGenre.ieltsTask1Academic,
    band: WritingBand.intermediate,
    title: 'A university budget',
    prompt:
        'The pie charts show how a university spent its budget in 2005 and '
        '2025. Summarise the information by selecting and reporting the main '
        'features, and make comparisons where relevant.',
    minWords: 150,
    maxWords: 0,
    visual: ExamVisual(
      kind: ExamVisualKind.pie,
      title: 'University spending by category, 2005 and 2025',
      unit: '% of the total budget',
      categories: <String>[
        'Teaching staff',
        'Research',
        'Buildings',
        'Student services',
        'IT',
        'Other',
      ],
      series: <ChartSeries>[
        ChartSeries('2005', <double>[48, 18, 16, 8, 4, 6]),
        ChartSeries('2025', <double>[41, 21, 12, 11, 10, 5]),
      ],
    ),
    hints: <String>[
      'Teaching staff remained the largest share: start the overview there.',
      'Percentages: "a share of", "accounted for", "rose by 6 percentage '
          'points".',
    ],
  ),
  WritingTask(
    id: 'ielts-t1-commute-table',
    genre: WritingGenre.ieltsTask1Academic,
    band: WritingBand.advanced,
    title: 'How people commute',
    prompt:
        'The table shows how people travel to work in four cities. Summarise '
        'the information by selecting and reporting the main features, and '
        'make comparisons where relevant.',
    minWords: 150,
    maxWords: 0,
    visual: ExamVisual(
      kind: ExamVisualKind.table,
      title: 'Main way of travelling to work in four cities',
      unit: '% of workers',
      categories: <String>['Car', 'Bus', 'Train', 'Bicycle', 'Walking'],
      series: <ChartSeries>[
        ChartSeries('Lyon', <double>[45, 20, 10, 10, 15]),
        ChartSeries('Oslo', <double>[30, 15, 25, 15, 15]),
        ChartSeries('Austin', <double>[72, 8, 2, 6, 12]),
        ChartSeries('Kyoto', <double>[25, 20, 30, 15, 10]),
      ],
    ),
    hints: <String>[
      'Do not describe the table line by line: compare cities by mode.',
      'Austin stands out: say how.',
    ],
  ),
  WritingTask(
    id: 'ielts-t1-glass-process',
    genre: WritingGenre.ieltsTask1Academic,
    band: WritingBand.intermediate,
    title: 'Recycling glass bottles',
    prompt:
        'The diagram shows how used glass bottles are recycled into new '
        'bottles. Summarise the information by selecting and reporting the '
        'main features.',
    minWords: 150,
    maxWords: 0,
    visual: ExamVisual(
      kind: ExamVisualKind.process,
      title: 'How used glass bottles become new bottles',
      steps: <String>[
        'Bottles are collected from recycling bins',
        'Trucks take them to a sorting centre',
        'They are sorted by colour',
        'They are washed to remove labels and dirt',
        'The glass is crushed into small pieces',
        'The pieces are mixed with sand and other raw materials',
        'The mixture is melted in a furnace at about 1,500°C',
        'The liquid glass is moulded into new bottles',
        'The new bottles are delivered to drinks companies',
      ],
    ),
    hints: <String>[
      'Overview: how many stages, where the process starts and ends.',
      'Use the passive and sequencers: "Once sorted, the bottles are…"',
    ],
  ),
  WritingTask(
    id: 'ielts-t1-village-map',
    genre: WritingGenre.ieltsTask1Academic,
    band: WritingBand.advanced,
    title: 'A seaside village changes',
    prompt:
        'The maps show a seaside village in 2000 and today. Summarise the '
        'information by selecting and reporting the main features, and make '
        'comparisons where relevant.',
    minWords: 150,
    maxWords: 0,
    visual: ExamVisual(
      kind: ExamVisualKind.map,
      title: 'The village of Calloway Bay, 2000 and today',
      plans: <MapPlan>[
        MapPlan('2000', <MapFeature>[
          MapFeature('Farmland', MapFeatureKind.green, 0.03, 0.05, 0.42, 0.35),
          MapFeature('Forest', MapFeatureKind.green, 0.6, 0.05, 0.37, 0.35),
          MapFeature('Main road', MapFeatureKind.road, 0, 0.45, 1, 0.08),
          MapFeature('Houses', MapFeatureKind.housing, 0.05, 0.58, 0.3, 0.2),
          MapFeature(
            'Fishing harbour',
            MapFeatureKind.facility,
            0.4,
            0.6,
            0.22,
            0.2,
          ),
          MapFeature('Beach', MapFeatureKind.sand, 0.68, 0.6, 0.3, 0.2),
          MapFeature('Sea', MapFeatureKind.water, 0, 0.82, 1, 0.18),
        ]),
        MapPlan('Today', <MapFeature>[
          MapFeature(
            'Hotel and car park',
            MapFeatureKind.building,
            0.03,
            0.05,
            0.42,
            0.35,
          ),
          MapFeature(
            'Holiday cottages',
            MapFeatureKind.housing,
            0.5,
            0.05,
            0.2,
            0.35,
          ),
          MapFeature('Forest', MapFeatureKind.green, 0.74, 0.05, 0.23, 0.35),
          MapFeature('Main road', MapFeatureKind.road, 0, 0.45, 1, 0.08),
          MapFeature('Houses', MapFeatureKind.housing, 0.05, 0.58, 0.3, 0.2),
          MapFeature('Marina', MapFeatureKind.facility, 0.4, 0.6, 0.22, 0.2),
          MapFeature('Beach', MapFeatureKind.sand, 0.68, 0.6, 0.3, 0.2),
          MapFeature('Sea', MapFeatureKind.water, 0, 0.82, 1, 0.18),
        ]),
      ],
    ),
    hints: <String>[
      'Overview: the village became more touristic; what stayed the same?',
      'Map language: "was replaced by", "was converted into", "to the north '
          'of the main road".',
    ],
  ),

  // ================================================= IELTS TASK 1 GENERAL
  WritingTask(
    id: 'ielts-gt-friend-visit',
    genre: WritingGenre.ieltsTask1General,
    band: WritingBand.intermediate,
    title: 'A friend’s first visit',
    reader: 'A friend from another country',
    prompt:
        'A friend from another country is going to visit your town for the '
        'first time. Write a letter to your friend. In your letter:\n'
        '• suggest the best time of year to come\n'
        '• describe two places your friend should see\n'
        '• explain how to travel from the airport or station to your home\n'
        'Begin your letter: "Dear …,".',
    minWords: 150,
    maxWords: 0,
    hints: <String>[
      'Informal tone: contractions are fine with a friend.',
      'One paragraph per bullet point, plus a short opening and closing.',
    ],
  ),
  WritingTask(
    id: 'ielts-gt-missing-parts',
    genre: WritingGenre.ieltsTask1General,
    band: WritingBand.intermediate,
    title: 'A desk with missing parts',
    reader: 'The customer service manager of an online furniture shop',
    prompt:
        'You ordered a desk online for your home office, but it arrived with '
        'parts missing. You have emailed customer service twice without '
        'receiving a useful answer. Write a letter to the customer service '
        'manager. In your letter:\n'
        '• describe what you ordered and what is wrong\n'
        '• explain what happened when you contacted customer service\n'
        '• say what you want the company to do\n'
        'Begin your letter: "Dear Sir or Madam,".',
    minWords: 150,
    maxWords: 0,
    hints: <String>[
      'Formal: no contractions; end with "Yours faithfully,".',
      'Give dates and an order number to make the complaint precise.',
    ],
  ),
  WritingTask(
    id: 'ielts-gt-evening-course',
    genre: WritingGenre.ieltsTask1General,
    band: WritingBand.advanced,
    title: 'Changing your hours',
    reader: 'Your manager',
    prompt:
        'You would like to change your working hours for three months so '
        'that you can attend an evening course. Write a letter to your '
        'manager. In your letter:\n'
        '• describe the course and explain why it matters to you\n'
        '• suggest your new working hours\n'
        '• explain how your work will still be done\n'
        'Begin your letter: "Dear …,".',
    minWords: 150,
    maxWords: 0,
    hints: <String>[
      'Semi-formal: polite and direct, "Kind regards," to close.',
      'Show the benefit for the company, not only for you.',
    ],
  ),
  WritingTask(
    id: 'ielts-gt-neighbour-help',
    genre: WritingGenre.ieltsTask1General,
    band: WritingBand.foundation,
    title: 'Help while you are away',
    reader: 'Your neighbour',
    prompt:
        'You are going abroad for a year and would like a neighbour to help '
        'with your home while you are away. Write a letter to your '
        'neighbour. In your letter:\n'
        '• explain your plans\n'
        '• describe what you need help with\n'
        '• offer something in return\n'
        'Begin your letter: "Dear …,".',
    minWords: 150,
    maxWords: 0,
    hints: <String>[
      'Requests: "Would you mind…?", "I would be very grateful if…"',
      'Be specific: how often, which plants, where the key is.',
    ],
  ),
  WritingTask(
    id: 'ielts-gt-park-council',
    genre: WritingGenre.ieltsTask1General,
    band: WritingBand.intermediate,
    title: 'A neglected park',
    reader: 'The local council',
    prompt:
        'The park near your home is often dirty and several of its lights '
        'are broken. Write a letter to the local council. In your letter:\n'
        '• describe the problems in the park\n'
        '• explain how they affect local residents\n'
        '• suggest what the council could do\n'
        'Begin your letter: "Dear Sir or Madam,".',
    minWords: 150,
    maxWords: 0,
    hints: <String>[
      'Formal tone and a clear purpose in the first sentence.',
      'Suggestions: "It would help if…", "The council could consider…"',
    ],
  ),

  // ========================================================= IELTS TASK 2
  WritingTask(
    id: 'ielts-t2-free-university',
    genre: WritingGenre.ieltsTask2,
    band: WritingBand.intermediate,
    title: 'Who should pay for university?',
    prompt:
        'Some people believe that university students should pay the full '
        'cost of their own studies. Others think that higher education '
        'should be free for everyone. Discuss both views and give your own '
        'opinion.',
    minWords: 250,
    maxWords: 0,
    hints: <String>[
      'Discuss BOTH views fairly, then make your own opinion clear.',
      'Introduction: paraphrase the question and announce your position.',
    ],
  ),
  WritingTask(
    id: 'ielts-t2-remote-work',
    genre: WritingGenre.ieltsTask2,
    band: WritingBand.intermediate,
    title: 'Working from home',
    prompt:
        'In many countries, more people now work from home for part of the '
        'week. Is this a positive or a negative development?',
    minWords: 250,
    maxWords: 0,
    hints: <String>[
      'Decide and say clearly: positive, negative, or mostly one of them.',
      'Consider several groups: workers, employers, cities.',
    ],
  ),
  WritingTask(
    id: 'ielts-t2-living-alone',
    genre: WritingGenre.ieltsTask2,
    band: WritingBand.intermediate,
    title: 'Living alone',
    prompt:
        'More and more adults choose to live alone rather than with family '
        'or friends. What are the advantages and disadvantages of this '
        'trend?',
    minWords: 250,
    maxWords: 0,
    hints: <String>[
      'One paragraph for advantages, one for disadvantages.',
      'Support each point with an explanation and an example.',
    ],
  ),
  WritingTask(
    id: 'ielts-t2-housing-costs',
    genre: WritingGenre.ieltsTask2,
    band: WritingBand.advanced,
    title: 'Young people and housing',
    prompt:
        'In many cities, young people find it increasingly difficult to '
        'afford a place to live. What are the causes of this problem, and '
        'what measures could be taken to solve it?',
    minWords: 250,
    maxWords: 0,
    hints: <String>[
      'Two questions: causes AND solutions. Answer both.',
      'Link each solution to a cause you described.',
    ],
  ),
  WritingTask(
    id: 'ielts-t2-news-social-media',
    genre: WritingGenre.ieltsTask2,
    band: WritingBand.advanced,
    title: 'News from social media',
    prompt:
        'Many people now get their news mainly from social media rather '
        'than from newspapers or television. Why is this happening? What '
        'effects does it have on society?',
    minWords: 250,
    maxWords: 0,
    hints: <String>[
      'Two-part question: reasons, then effects.',
      'Hedge your claims: "this may lead to", "tends to".',
    ],
  ),
  WritingTask(
    id: 'ielts-t2-fuel-prices',
    genre: WritingGenre.ieltsTask2,
    band: WritingBand.advanced,
    title: 'Protecting the environment',
    prompt:
        'Some people think that the best way to protect the environment is '
        'to make fuel much more expensive. To what extent do you agree or '
        'disagree?',
    minWords: 250,
    maxWords: 0,
    hints: <String>[
      '"The best way" is strong: you can agree only partly.',
      'Compare with other measures to justify your position.',
    ],
  ),
  WritingTask(
    id: 'ielts-t2-cooking-school',
    genre: WritingGenre.ieltsTask2,
    band: WritingBand.foundation,
    title: 'Cooking lessons at school',
    prompt:
        'Some people say that schools should teach children how to cook. '
        'Others believe that this is the responsibility of parents. Discuss '
        'both views and give your own opinion.',
    minWords: 250,
    maxWords: 0,
    hints: <String>[
      'Simple, clear paragraphs work well: view 1, view 2, your opinion.',
    ],
  ),
  WritingTask(
    id: 'ielts-t2-ai-languages',
    genre: WritingGenre.ieltsTask2,
    band: WritingBand.advanced,
    title: 'Translation apps and language learning',
    prompt:
        'Some people believe that, because translation technology is '
        'improving so quickly, learning a foreign language will soon be '
        'unnecessary. To what extent do you agree or disagree?',
    minWords: 250,
    maxWords: 0,
    hints: <String>[
      'Think beyond words: culture, relationships, jobs, thinking skills.',
      'Concede a point before rejecting it: "Although…, …"',
    ],
  ),
];
