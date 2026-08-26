import 'learning_data.dart';

enum LearningSessionStatus {
  notStarted,
  inProgress,
  completed,
}

enum LearningActivityType {
  introduction,
  warmUp,
  exercise,
  challenge,
  reflection,
  feedback,
}

class LearningActivity {
  final String id;
  final LearningActivityType type;
  final String title;
  final String subtitle;
  final String instruction;
  final String? hint;
  final int estimatedMinutes;
  final int xpReward;
  final bool requiresInput;

  const LearningActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.instruction,
    this.hint,
    required this.estimatedMinutes,
    required this.xpReward,
    required this.requiresInput,
  });
}

class LearningSession {
  final String id;
  final LearningCategory category;
  final int durationMinutes;
  final int totalXp;
  final String title;
  final String subtitle;
  final String objective;
  final String focus;
  final List<LearningActivity> activities;

  LearningSessionStatus status;
  int currentActivityIndex;

  LearningSession({
    required this.id,
    required this.category,
    required this.durationMinutes,
    required this.totalXp,
    required this.title,
    required this.subtitle,
    required this.objective,
    required this.focus,
    required this.activities,
    this.status = LearningSessionStatus.notStarted,
    this.currentActivityIndex = 0,
  });

  int get totalActivities => activities.length;

  int get completedActivities => currentActivityIndex;

  double get progress {
    if (totalActivities == 0) {
      return 0;
    }

    return (completedActivities / totalActivities)
        .clamp(0.0, 1.0);
  }

  LearningActivity? get currentActivity {
    if (currentActivityIndex < 0 ||
        currentActivityIndex >= activities.length) {
      return null;
    }

    return activities[currentActivityIndex];
  }

  bool get isFirstActivity =>
      currentActivityIndex == 0;

  bool get isLastActivity =>
      currentActivityIndex == activities.length - 1;

  void start() {
    status = LearningSessionStatus.inProgress;
  }

  void completeCurrentActivity() {
    if (status != LearningSessionStatus.inProgress) {
      return;
    }

    if (isLastActivity) {
      complete();
      return;
    }

    currentActivityIndex++;
  }

  void complete() {
    status = LearningSessionStatus.completed;
    currentActivityIndex = activities.length;
  }

  void reset() {
    status = LearningSessionStatus.notStarted;
    currentActivityIndex = 0;
  }
}

class LearningSessionBuilder {
  LearningSessionBuilder._();

  static LearningSession createWritingSession({
    required int durationMinutes,
  }) {
    final activities = _writingActivities(
      durationMinutes,
    );

    final totalXp = activities.fold<int>(
      0,
      (total, activity) => total + activity.xpReward,
    );

    return LearningSession(
      id: 'writing_${DateTime.now().millisecondsSinceEpoch}',
      category: LearningCategory.writing,
      durationMinutes: durationMinutes,
      totalXp: totalXp,
      title: 'Writing Lab',
      subtitle: 'Turn your ideas into powerful English.',
      objective:
          'Express your ideas clearly while improving structure, vocabulary, and accuracy.',
      focus: 'Clarity • Structure • Expression',
      activities: activities,
    );
  }

  static List<LearningActivity> _writingActivities(
    int durationMinutes,
  ) {
    if (durationMinutes <= 5) {
      return const [
        LearningActivity(
          id: 'writing_warmup',
          type: LearningActivityType.warmUp,
          title: 'Quick Start',
          subtitle: 'Warm up your English',
          instruction:
              'Write three sentences about something interesting that happened to you recently.',
          hint:
              'Focus on communicating your idea. Do not worry about perfection yet.',
          estimatedMinutes: 2,
          xpReward: 20,
          requiresInput: true,
        ),
        LearningActivity(
          id: 'writing_challenge',
          type: LearningActivityType.challenge,
          title: 'Mini Challenge',
          subtitle: 'Push yourself',
          instruction:
              'Rewrite one of your sentences using a more precise or interesting expression.',
          hint:
              'Try replacing a simple word with a stronger one.',
          estimatedMinutes: 3,
          xpReward: 30,
          requiresInput: true,
        ),
      ];
    }

    if (durationMinutes <= 15) {
      return const [
        LearningActivity(
          id: 'writing_intro',
          type: LearningActivityType.introduction,
          title: 'Your Mission',
          subtitle: 'Set your intention',
          instruction:
              'Today, your mission is to express an idea clearly and make your writing more engaging.',
          estimatedMinutes: 1,
          xpReward: 10,
          requiresInput: false,
        ),
        LearningActivity(
          id: 'writing_warmup',
          type: LearningActivityType.warmUp,
          title: 'Warm Up',
          subtitle: 'Get your ideas flowing',
          instruction:
              'Write three to five sentences about a subject you genuinely enjoy.',
          hint:
              'Choose something personal. Writing becomes easier when the idea matters to you.',
          estimatedMinutes: 3,
          xpReward: 25,
          requiresInput: true,
        ),
        LearningActivity(
          id: 'writing_main',
          type: LearningActivityType.exercise,
          title: 'Main Challenge',
          subtitle: 'Build your response',
          instruction:
              'Write a short paragraph explaining why this subject interests you.',
          hint:
              'Try to connect your ideas using because, however, although, or therefore.',
          estimatedMinutes: 6,
          xpReward: 45,
          requiresInput: true,
        ),
        LearningActivity(
          id: 'writing_reflection',
          type: LearningActivityType.reflection,
          title: 'Level Up',
          subtitle: 'Improve one sentence',
          instruction:
              'Choose your favorite sentence and rewrite it to make it clearer or more sophisticated.',
          hint:
              'Look for a stronger verb, a more precise adjective, or a better connector.',
          estimatedMinutes: 3,
          xpReward: 30,
          requiresInput: true,
        ),
        LearningActivity(
          id: 'writing_feedback',
          type: LearningActivityType.feedback,
          title: 'Session Reflection',
          subtitle: 'Look back at your work',
          instruction:
              'Think about one thing you did well and one thing you want to improve next time.',
          estimatedMinutes: 2,
          xpReward: 20,
          requiresInput: true,
        ),
      ];
    }

    return const [
      LearningActivity(
        id: 'writing_intro',
        type: LearningActivityType.introduction,
        title: 'Today’s Mission',
        subtitle: 'Know what you are building',
        instruction:
            'Today, you will create a structured piece of writing and progressively refine it.',
        estimatedMinutes: 2,
        xpReward: 15,
        requiresInput: false,
      ),
      LearningActivity(
        id: 'writing_warmup',
        type: LearningActivityType.warmUp,
        title: 'Idea Spark',
        subtitle: 'Unlock your thoughts',
        instruction:
            'Write freely for a few minutes about a subject you care about.',
        hint:
            'Do not stop to correct every sentence. Your first goal is to generate ideas.',
        estimatedMinutes: 5,
        xpReward: 30,
        requiresInput: true,
      ),
      LearningActivity(
        id: 'writing_structure',
        type: LearningActivityType.exercise,
        title: 'Build the Structure',
        subtitle: 'Give your ideas direction',
        instruction:
            'Organize your ideas into an introduction, a developed point, and a conclusion.',
        hint:
            'Ask yourself: What is my main idea? What supports it? What should the reader remember?',
        estimatedMinutes: 6,
        xpReward: 45,
        requiresInput: true,
      ),
      LearningActivity(
        id: 'writing_main',
        type: LearningActivityType.challenge,
        title: 'Writing Challenge',
        subtitle: 'Go beyond the obvious',
        instruction:
            'Write a complete response using precise vocabulary and varied sentence structures.',
        hint:
            'Try using at least one contrast, one example, and one explanation.',
        estimatedMinutes: 8,
        xpReward: 60,
        requiresInput: true,
      ),
      LearningActivity(
        id: 'writing_polish',
        type: LearningActivityType.reflection,
        title: 'Polish Your Writing',
        subtitle: 'Think like an editor',
        instruction:
            'Read your response again and improve three sentences.',
        hint:
            'Look for repetition, unclear ideas, weak vocabulary, and unnecessary words.',
        estimatedMinutes: 5,
        xpReward: 40,
        requiresInput: true,
      ),
      LearningActivity(
        id: 'writing_feedback',
        type: LearningActivityType.feedback,
        title: 'Your Progress',
        subtitle: 'Finish with intention',
        instruction:
            'Identify your strongest improvement today and choose one skill to focus on next time.',
        estimatedMinutes: 4,
        xpReward: 30,
        requiresInput: true,
      ),
    ];
  }
}