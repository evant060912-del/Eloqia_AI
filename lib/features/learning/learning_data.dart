import 'package:flutter/material.dart';

import '../../models/learning_profile.dart';

enum LearningCategory {
  conversation,
  writing,
  reading,
  listening,
  grammar,
  vocabulary,
  pronunciation,
}

enum LearningAvailability {
  available,
  comingSoon,
}

enum LearningDifficulty {
  beginner,
  intermediate,
  advanced,
}

class LearningCategoryData {
  final LearningCategory category;
  final String title;
  final String subtitle;
  final String description;
  final String icon;
  final LearningAvailability availability;
  final LearningDifficulty difficulty;
  final int estimatedMinutes;
  final int xpReward;
  final String tag;
  final Color primaryColor;
  final Color secondaryColor;

  const LearningCategoryData({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.availability,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.xpReward,
    required this.tag,
    required this.primaryColor,
    required this.secondaryColor,
  });

  bool get isAvailable =>
      availability == LearningAvailability.available;

  String get difficultyLabel {
    switch (difficulty) {
      case LearningDifficulty.beginner:
        return 'Beginner';

      case LearningDifficulty.intermediate:
        return 'Intermediate';

      case LearningDifficulty.advanced:
        return 'Advanced';
    }
  }

  String get availabilityLabel {
    switch (availability) {
      case LearningAvailability.available:
        return 'Available';

      case LearningAvailability.comingSoon:
        return 'Coming soon';
    }
  }
}

class DailyLearningPlan {
  final String greeting;
  final String headline;
  final String message;
  final LearningCategory recommendedCategory;
  final String reason;
  final String focus;
  final int estimatedMinutes;
  final int xpReward;

  const DailyLearningPlan({
    required this.greeting,
    required this.headline,
    required this.message,
    required this.recommendedCategory,
    required this.reason,
    required this.focus,
    required this.estimatedMinutes,
    required this.xpReward,
  });
}

class LearningData {
  LearningData._();

  // ---------------------------------------------------------------------------
  // Learning categories
  // ---------------------------------------------------------------------------

  static const List<LearningCategoryData> categories = [
    LearningCategoryData(
      category: LearningCategory.conversation,
      title: 'Conversation',
      subtitle: 'Speak with confidence',
      description:
          'Practice natural conversations and become more comfortable expressing yourself.',
      icon: '💬',
      availability: LearningAvailability.available,
      difficulty: LearningDifficulty.intermediate,
      estimatedMinutes: 10,
      xpReward: 80,
      tag: 'Speak',
      primaryColor: Color(0xFF6C63FF),
      secondaryColor: Color(0xFF9B8CFF),
    ),

    LearningCategoryData(
      category: LearningCategory.writing,
      title: 'Writing',
      subtitle: 'Express your ideas',
      description:
          'Write through guided prompts, challenges, corrections, and progressively harder exercises.',
      icon: '✍️',
      availability: LearningAvailability.available,
      difficulty: LearningDifficulty.intermediate,
      estimatedMinutes: 10,
      xpReward: 100,
      tag: 'Create',
      primaryColor: Color(0xFF00C6FF),
      secondaryColor: Color(0xFF7B61FF),
    ),

    LearningCategoryData(
      category: LearningCategory.reading,
      title: 'Reading',
      subtitle: 'Understand the world',
      description:
          'Read carefully selected texts adapted to your level and discover new vocabulary in context.',
      icon: '📖',
      availability: LearningAvailability.comingSoon,
      difficulty: LearningDifficulty.intermediate,
      estimatedMinutes: 15,
      xpReward: 100,
      tag: 'Explore',
      primaryColor: Color(0xFF42E695),
      secondaryColor: Color(0xFF3BB2B8),
    ),

    LearningCategoryData(
      category: LearningCategory.listening,
      title: 'Listening',
      subtitle: 'Train your ear',
      description:
          'Develop your understanding of natural English through progressively challenging audio experiences.',
      icon: '🎧',
      availability: LearningAvailability.comingSoon,
      difficulty: LearningDifficulty.intermediate,
      estimatedMinutes: 15,
      xpReward: 110,
      tag: 'Listen',
      primaryColor: Color(0xFFFF9966),
      secondaryColor: Color(0xFFFF5E62),
    ),

    LearningCategoryData(
      category: LearningCategory.grammar,
      title: 'Grammar',
      subtitle: 'Master the details',
      description:
          'Strengthen the grammar concepts that matter most for your current level and goals.',
      icon: '🧠',
      availability: LearningAvailability.comingSoon,
      difficulty: LearningDifficulty.intermediate,
      estimatedMinutes: 15,
      xpReward: 110,
      tag: 'Master',
      primaryColor: Color(0xFF8E2DE2),
      secondaryColor: Color(0xFF4A00E0),
    ),

    LearningCategoryData(
      category: LearningCategory.vocabulary,
      title: 'Vocabulary',
      subtitle: 'Expand your world',
      description:
          'Learn useful words and expressions selected around your interests and personal goals.',
      icon: '✨',
      availability: LearningAvailability.comingSoon,
      difficulty: LearningDifficulty.intermediate,
      estimatedMinutes: 10,
      xpReward: 90,
      tag: 'Discover',
      primaryColor: Color(0xFFF7971E),
      secondaryColor: Color(0xFFFFD200),
    ),

    LearningCategoryData(
      category: LearningCategory.pronunciation,
      title: 'Pronunciation',
      subtitle: 'Sound natural',
      description:
          'Improve pronunciation, rhythm, intonation, and clarity to communicate more naturally.',
      icon: '🎙️',
      availability: LearningAvailability.comingSoon,
      difficulty: LearningDifficulty.intermediate,
      estimatedMinutes: 15,
      xpReward: 120,
      tag: 'Perfect',
      primaryColor: Color(0xFF00F2FE),
      secondaryColor: Color(0xFF4FACFE),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Daily learning plan
  // ---------------------------------------------------------------------------

  static DailyLearningPlan createDailyPlan(
    LearningProfile profile,
  ) {
    final category = _recommendCategory(profile);

    final categoryData = getCategory(category);

    return DailyLearningPlan(
      greeting: _buildGreeting(profile),
      headline: _buildHeadline(category),
      message: _buildDailyMessage(category),
      recommendedCategory: category,
      reason: _buildRecommendationReason(
        profile,
        category,
      ),
      focus: _buildFocus(category),
      estimatedMinutes: categoryData.estimatedMinutes,
      xpReward: categoryData.xpReward,
    );
  }

  // ---------------------------------------------------------------------------
  // Personalized recommendation
  // ---------------------------------------------------------------------------

  static LearningCategory _recommendCategory(
    LearningProfile profile,
  ) {
    final primaryGoal = profile.primaryGoal.trim().toLowerCase();

    final difficulties = profile.difficulties
        .map((difficulty) => difficulty.toLowerCase())
        .join(' ');

    final interests = profile.interests
        .map((interest) => interest.toLowerCase())
        .join(' ');

    if (primaryGoal.contains('writing') ||
        primaryGoal.contains('write') ||
        difficulties.contains('writing')) {
      return LearningCategory.writing;
    }

    if (primaryGoal.contains('speak') ||
        primaryGoal.contains('conversation') ||
        primaryGoal.contains('oral') ||
        difficulties.contains('confidence')) {
      return LearningCategory.conversation;
    }

    if (interests.contains('book') ||
        interests.contains('reading') ||
        primaryGoal.contains('read')) {
      return LearningCategory.reading;
    }

    return LearningCategory.writing;
  }

  // ---------------------------------------------------------------------------
  // Personalized copy
  // ---------------------------------------------------------------------------

  static String _buildGreeting(
    LearningProfile profile,
  ) {
    final name = _displayName(profile);

    if (name == 'there') {
      return 'Welcome back.';
    }

    return 'Welcome back, $name.';
  }

  static String _buildHeadline(
    LearningCategory category,
  ) {
    switch (category) {
      case LearningCategory.conversation:
        return 'Let’s make your voice stronger today.';

      case LearningCategory.writing:
        return 'Let’s turn your ideas into great English.';

      case LearningCategory.reading:
        return 'Let’s discover something new today.';

      case LearningCategory.listening:
        return 'Let’s train your ear today.';

      case LearningCategory.grammar:
        return 'Let’s make your English more precise.';

      case LearningCategory.vocabulary:
        return 'Let’s expand your English today.';

      case LearningCategory.pronunciation:
        return 'Let’s make your English sound natural.';
    }
  }

  static String _buildDailyMessage(
    LearningCategory category,
  ) {
    switch (category) {
      case LearningCategory.conversation:
        return 'Mia has prepared a conversation designed around your current goals.';

      case LearningCategory.writing:
        return 'Mia has prepared a writing challenge adapted to your current level.';

      case LearningCategory.reading:
        return 'Mia has selected a reading experience designed to challenge you without overwhelming you.';

      case LearningCategory.listening:
        return 'Mia has prepared a listening session adapted to your current abilities.';

      case LearningCategory.grammar:
        return 'Mia has selected the grammar concepts most relevant to your progress.';

      case LearningCategory.vocabulary:
        return 'Mia has prepared vocabulary connected to your goals and interests.';

      case LearningCategory.pronunciation:
        return 'Mia has prepared targeted pronunciation practice for you.';
    }
  }

  static String _buildRecommendationReason(
    LearningProfile profile,
    LearningCategory category,
  ) {
    final goal = profile.primaryGoal.trim();

    switch (category) {
      case LearningCategory.writing:
        if (goal.isNotEmpty) {
          return 'This session supports your goal of $goal while strengthening your ability to express ideas clearly.';
        }

        return 'Writing gives you a focused way to build accuracy, vocabulary, and confidence.';

      case LearningCategory.conversation:
        return 'Speaking regularly is one of the best ways to turn your knowledge into real communication.';

      case LearningCategory.reading:
        return 'Reading exposes you to authentic vocabulary, structures, and ideas in context.';

      case LearningCategory.listening:
        return 'Listening helps you become more comfortable with natural English and different speaking patterns.';

      case LearningCategory.grammar:
        return 'A focused grammar session can strengthen the areas currently holding back your progress.';

      case LearningCategory.vocabulary:
        return 'Expanding the right vocabulary makes every other learning activity more powerful.';

      case LearningCategory.pronunciation:
        return 'Targeted pronunciation practice can make your speech clearer and more natural.';
    }
  }

  static String _buildFocus(
    LearningCategory category,
  ) {
    switch (category) {
      case LearningCategory.conversation:
        return 'Confidence & spontaneous speaking';

      case LearningCategory.writing:
        return 'Clarity, structure & expression';

      case LearningCategory.reading:
        return 'Comprehension & vocabulary';

      case LearningCategory.listening:
        return 'Comprehension & natural speech';

      case LearningCategory.grammar:
        return 'Accuracy & sentence structure';

      case LearningCategory.vocabulary:
        return 'Useful words & expressions';

      case LearningCategory.pronunciation:
        return 'Clarity, rhythm & intonation';
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static LearningCategoryData getCategory(
    LearningCategory category,
  ) {
    return categories.firstWhere(
      (item) => item.category == category,
    );
  }

  static List<LearningCategoryData> get availableCategories {
    return categories
        .where((category) => category.isAvailable)
        .toList();
  }

  static List<LearningCategoryData> get upcomingCategories {
    return categories
        .where((category) => !category.isAvailable)
        .toList();
  }

  static String _displayName(
    LearningProfile profile,
  ) {
    final name = profile.name.trim();

    if (name.isEmpty) {
      return 'there';
    }

    return name;
  }
}