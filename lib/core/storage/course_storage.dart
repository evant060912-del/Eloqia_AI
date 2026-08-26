import 'local_storage.dart';

/// ============================================================================
/// ELOQIA COURSE STORAGE
/// ============================================================================
///
/// Persistent learning-path engine for Eloqia.
///
/// Responsibilities:
/// - Persist AI-generated learning courses.
/// - Manage modules and lessons.
/// - Track course and lesson progress.
/// - Keep the active learning path.
/// - Provide safe normalization for persisted data.
/// - Prepare the application for future cloud synchronization.
///
/// Architectural principle:
///
///     UI
///      ↓
///     Learning Engine
///      ↓
///     CourseStorage
///      ↓
///     LocalStorage
///      ↓
///     SharedPreferences
///
/// CourseStorage does NOT generate pedagogical content.
/// It only persists and manages the learning structures produced by
/// Eloqia's future adaptive learning engine.
/// ============================================================================

class CourseStorage {
  CourseStorage._();

  // ===========================================================================
  // STORAGE
  // ===========================================================================

  static const int storageVersion = 1;

  static const int maxCourses = 50;

  static const int maxModulesPerCourse = 50;

  static const int maxLessonsPerModule = 100;

  // ===========================================================================
  // COURSE STATUS
  // ===========================================================================

  static const String statusDraft = 'draft';

  static const String statusActive = 'active';

  static const String statusCompleted = 'completed';

  static const String statusArchived = 'archived';

  // ===========================================================================
  // LESSON STATUS
  // ===========================================================================

  static const String lessonLocked = 'locked';

  static const String lessonAvailable = 'available';

  static const String lessonInProgress = 'in_progress';

  static const String lessonCompleted = 'completed';

  // ===========================================================================
  // LOAD
  // ===========================================================================

  /// Loads every locally persisted course.
  ///
  /// The result is normalized and ordered by most recent update.
  static Future<List<Map<String, dynamic>>> load() async {
    final Map<String, dynamic>? envelope =
        await LocalStorage.readJsonMap(
      LocalStorage.coursesKey,
    );

    if (envelope == null) {
      return <Map<String, dynamic>>[];
    }

    final dynamic rawCourses =
        envelope['courses'];

    if (rawCourses is! List) {
      return <Map<String, dynamic>>[];
    }

    final List<Map<String, dynamic>> courses =
        <Map<String, dynamic>>[];

    for (final dynamic rawCourse in rawCourses) {
      if (rawCourse is Map) {
        courses.add(
          _normalizeCourse(
            Map<String, dynamic>.from(rawCourse),
          ),
        );
      }
    }

    _sortCourses(courses);

    return courses;
  }

  // ===========================================================================
  // SAVE
  // ===========================================================================

  /// Persists the complete local course library.
  static Future<bool> save(
    List<Map<String, dynamic>> courses,
  ) async {
    final List<Map<String, dynamic>> normalized =
        courses
            .map(_normalizeCourse)
            .take(maxCourses)
            .toList();

    _sortCourses(normalized);

    return LocalStorage.saveJson(
      LocalStorage.coursesKey,
      <String, dynamic>{
        'schemaVersion': storageVersion,
        'updatedAt': _now(),
        'courses': normalized,
      },
    );
  }

  // ===========================================================================
  // CREATE
  // ===========================================================================

  /// Creates or replaces a course using its unique identifier.
  static Future<bool> upsert(
    Map<String, dynamic> course,
  ) async {
    final Map<String, dynamic> normalized =
        _normalizeCourse(course);

    final String id =
        normalized['id'] as String;

    final List<Map<String, dynamic>> courses =
        await load();

    final int existingIndex =
        courses.indexWhere(
      (Map<String, dynamic> item) =>
          item['id'] == id,
    );

    if (existingIndex == -1) {
      courses.insert(
        0,
        normalized,
      );
    } else {
      courses[existingIndex] =
          normalized;
    }

    return save(courses);
  }

  // ===========================================================================
  // FIND
  // ===========================================================================

  /// Returns one course by identifier.
  static Future<Map<String, dynamic>?> findById(
    String courseId,
  ) async {
    final String id =
        courseId.trim();

    if (id.isEmpty) {
      return null;
    }

    final List<Map<String, dynamic>> courses =
        await load();

    for (final Map<String, dynamic> course
        in courses) {
      if (course['id'] == id) {
        return Map<String, dynamic>.from(
          course,
        );
      }
    }

    return null;
  }

  // ===========================================================================
  // ACTIVE COURSE
  // ===========================================================================

  /// Returns the learner's active course.
  static Future<Map<String, dynamic>?> getActive() async {
    final List<Map<String, dynamic>> courses =
        await load();

    for (final Map<String, dynamic> course
        in courses) {
      if (course['active'] == true) {
        return Map<String, dynamic>.from(
          course,
        );
      }
    }

    return null;
  }

  /// Makes one course the active learning path.
  ///
  /// Eloqia maintains a single primary active path locally.
  static Future<bool> activate(
    String courseId,
  ) async {
    final String id =
        courseId.trim();

    if (id.isEmpty) {
      return false;
    }

    final List<Map<String, dynamic>> courses =
        await load();

    bool found = false;

    for (final Map<String, dynamic> course
        in courses) {
      final bool isTarget =
          course['id'] == id;

      course['active'] = isTarget;

      if (isTarget) {
        course['status'] =
            statusActive;

        course['updatedAt'] =
            _now();

        found = true;
      }
    }

    if (!found) {
      return false;
    }

    return save(courses);
  }

  // ===========================================================================
  // UPDATE COURSE
  // ===========================================================================

  /// Updates selected course properties.
  static Future<bool> update(
    String courseId,
    Map<String, dynamic> updates,
  ) async {
    final String id =
        courseId.trim();

    if (id.isEmpty) {
      return false;
    }

    final List<Map<String, dynamic>> courses =
        await load();

    final int index =
        courses.indexWhere(
      (Map<String, dynamic> course) =>
          course['id'] == id,
    );

    if (index == -1) {
      return false;
    }

    final Map<String, dynamic> updated =
        Map<String, dynamic>.from(
      courses[index],
    );

    updated.addAll(updates);

    updated['id'] = id;
    updated['updatedAt'] = _now();

    courses[index] =
        _normalizeCourse(updated);

    return save(courses);
  }

  // ===========================================================================
  // MODULES
  // ===========================================================================

  /// Returns all modules belonging to a course.
  static Future<List<Map<String, dynamic>>>
      getModules(
    String courseId,
  ) async {
    final Map<String, dynamic>? course =
        await findById(courseId);

    if (course == null) {
      return <Map<String, dynamic>>[];
    }

    final dynamic rawModules =
        course['modules'];

    if (rawModules is! List) {
      return <Map<String, dynamic>>[];
    }

    return rawModules
        .whereType<Map>()
        .map(
          (Map module) =>
              Map<String, dynamic>.from(module),
        )
        .toList();
  }

  /// Adds or replaces a module.
  static Future<bool> upsertModule(
    String courseId,
    Map<String, dynamic> module,
  ) async {
    final Map<String, dynamic>? course =
        await findById(courseId);

    if (course == null) {
      return false;
    }

    final List<Map<String, dynamic>> modules =
        await getModules(courseId);

    final Map<String, dynamic> normalized =
        _normalizeModule(module);

    final String id =
        normalized['id'] as String;

    final int index =
        modules.indexWhere(
      (Map<String, dynamic> item) =>
          item['id'] == id,
    );

    if (index == -1) {
      if (modules.length >= maxModulesPerCourse) {
        return false;
      }

      modules.add(normalized);
    } else {
      modules[index] =
          normalized;
    }

    return update(
      courseId,
      <String, dynamic>{
        'modules': modules,
      },
    );
  }

  // ===========================================================================
  // LESSONS
  // ===========================================================================

  /// Returns all lessons from one module.
  static Future<List<Map<String, dynamic>>>
      getLessons(
    String courseId,
    String moduleId,
  ) async {
    final List<Map<String, dynamic>> modules =
        await getModules(courseId);

    final int moduleIndex =
        modules.indexWhere(
      (Map<String, dynamic> module) =>
          module['id'] == moduleId,
    );

    if (moduleIndex == -1) {
      return <Map<String, dynamic>>[];
    }

    final dynamic rawLessons =
        modules[moduleIndex]['lessons'];

    if (rawLessons is! List) {
      return <Map<String, dynamic>>[];
    }

    return rawLessons
        .whereType<Map>()
        .map(
          (Map lesson) =>
              Map<String, dynamic>.from(lesson),
        )
        .toList();
  }

  /// Adds or replaces a lesson inside a module.
  static Future<bool> upsertLesson(
    String courseId,
    String moduleId,
    Map<String, dynamic> lesson,
  ) async {
    final List<Map<String, dynamic>> modules =
        await getModules(courseId);

    final int moduleIndex =
        modules.indexWhere(
      (Map<String, dynamic> module) =>
          module['id'] == moduleId,
    );

    if (moduleIndex == -1) {
      return false;
    }

    final Map<String, dynamic> normalized =
        _normalizeLesson(lesson);

    final dynamic rawLessons =
        modules[moduleIndex]['lessons'];

    final List<Map<String, dynamic>> lessons =
        rawLessons is List
            ? rawLessons
                .whereType<Map>()
                .map(
                  (Map item) =>
                      Map<String, dynamic>.from(item),
                )
                .toList()
            : <Map<String, dynamic>>[];

    final String lessonId =
        normalized['id'] as String;

    final int lessonIndex =
        lessons.indexWhere(
      (Map<String, dynamic> item) =>
          item['id'] == lessonId,
    );

    if (lessonIndex == -1) {
      if (lessons.length >= maxLessonsPerModule) {
        return false;
      }

      lessons.add(normalized);
    } else {
      lessons[lessonIndex] =
          normalized;
    }

    modules[moduleIndex]['lessons'] =
        lessons;

    return update(
      courseId,
      <String, dynamic>{
        'modules': modules,
      },
    );
  }

  // ===========================================================================
  // LESSON PROGRESSION
  // ===========================================================================

  /// Updates a lesson's progression state.
  static Future<bool> updateLessonProgress(
    String courseId,
    String moduleId,
    String lessonId, {
    String? status,
    double? score,
    int? xpEarned,
  }) async {
    final List<Map<String, dynamic>> lessons =
        await getLessons(
      courseId,
      moduleId,
    );

    final int lessonIndex =
        lessons.indexWhere(
      (Map<String, dynamic> lesson) =>
          lesson['id'] == lessonId,
    );

    if (lessonIndex == -1) {
      return false;
    }

    final Map<String, dynamic> lesson =
        Map<String, dynamic>.from(
      lessons[lessonIndex],
    );

    if (status != null &&
        status.trim().isNotEmpty) {
      lesson['status'] =
          status.trim();
    }

    if (score != null) {
      lesson['score'] =
          score.clamp(0.0, 100.0);
    }

    if (xpEarned != null) {
      lesson['xpEarned'] =
          xpEarned < 0 ? 0 : xpEarned;
    }

    if (status == lessonCompleted) {
      lesson['completed'] = true;
      lesson['completedAt'] = _now();
    }

    lessons[lessonIndex] =
        _normalizeLesson(lesson);

    final List<Map<String, dynamic>> modules =
        await getModules(courseId);

    final int moduleIndex =
        modules.indexWhere(
      (Map<String, dynamic> module) =>
          module['id'] == moduleId,
    );

    if (moduleIndex == -1) {
      return false;
    }

    modules[moduleIndex]['lessons'] =
        lessons;

    return update(
      courseId,
      <String, dynamic>{
        'modules': modules,
      },
    );
  }

  // ===========================================================================
  // COURSE PROGRESS
  // ===========================================================================

  /// Calculates overall course completion.
  ///
  /// Result is expressed from 0.0 to 100.0.
  static Future<double> completionPercentage(
    String courseId,
  ) async {
    final List<Map<String, dynamic>> modules =
        await getModules(courseId);

    int totalLessons = 0;
    int completedLessons = 0;

    for (final Map<String, dynamic> module
        in modules) {
      final dynamic rawLessons =
          module['lessons'];

      if (rawLessons is! List) {
        continue;
      }

      for (final dynamic rawLesson
          in rawLessons) {
        if (rawLesson is! Map) {
          continue;
        }

        totalLessons++;

        final Map<String, dynamic> lesson =
            Map<String, dynamic>.from(
          rawLesson,
        );

        if (lesson['completed'] == true ||
            lesson['status'] ==
                lessonCompleted) {
          completedLessons++;
        }
      }
    }

    if (totalLessons == 0) {
      return 0.0;
    }

    return (completedLessons /
            totalLessons) *
        100.0;
  }

  // ===========================================================================
  // NEXT LESSON
  // ===========================================================================

  /// Finds the first lesson that is available or currently in progress.
  static Future<Map<String, dynamic>?>
      nextLesson(
    String courseId,
  ) async {
    final List<Map<String, dynamic>> modules =
        await getModules(courseId);

    for (final Map<String, dynamic> module
        in modules) {
      final dynamic rawLessons =
          module['lessons'];

      if (rawLessons is! List) {
        continue;
      }

      for (final dynamic rawLesson
          in rawLessons) {
        if (rawLesson is! Map) {
          continue;
        }

        final Map<String, dynamic> lesson =
            Map<String, dynamic>.from(
          rawLesson,
        );

        final String status =
            lesson['status'] is String
                ? lesson['status'] as String
                : lessonAvailable;

        if (status == lessonAvailable ||
            status == lessonInProgress) {
          return lesson;
        }
      }
    }

    return null;
  }

  // ===========================================================================
  // COURSE COMPLETION
  // ===========================================================================

  /// Marks a course as completed.
  static Future<bool> complete(
    String courseId,
  ) async {
    return update(
      courseId,
      <String, dynamic>{
        'status': statusCompleted,
        'active': false,
        'completedAt': _now(),
      },
    );
  }

  // ===========================================================================
  // RECENT
  // ===========================================================================

  /// Returns the most recently updated courses.
  static Future<List<Map<String, dynamic>>>
      recent({
    int limit = 5,
  }) async {
    final List<Map<String, dynamic>> courses =
        await load();

    final int safeLimit =
        limit < 0 ? 0 : limit;

    return courses
        .take(safeLimit)
        .map(
          (Map<String, dynamic> course) =>
              Map<String, dynamic>.from(course),
        )
        .toList();
  }

  // ===========================================================================
  // DELETE
  // ===========================================================================

  /// Deletes one complete course.
  static Future<bool> delete(
    String courseId,
  ) async {
    final String id =
        courseId.trim();

    if (id.isEmpty) {
      return false;
    }

    final List<Map<String, dynamic>> courses =
        await load();

    final int initialLength =
        courses.length;

    courses.removeWhere(
      (Map<String, dynamic> course) =>
          course['id'] == id,
    );

    if (courses.length ==
        initialLength) {
      return false;
    }

    return save(courses);
  }

  // ===========================================================================
  // LIBRARY INFORMATION
  // ===========================================================================

  /// Returns the number of persisted courses.
  static Future<int> count() async {
    final List<Map<String, dynamic>> courses =
        await load();

    return courses.length;
  }

  /// Returns whether the local course library exists.
  static Future<bool> exists() async {
    return LocalStorage.containsKey(
      LocalStorage.coursesKey,
    );
  }

  // ===========================================================================
  // CLEAR
  // ===========================================================================

  /// Clears only Eloqia's local course library.
  static Future<bool> clear() async {
    return LocalStorage.delete(
      LocalStorage.coursesKey,
    );
  }

  // ===========================================================================
  // NORMALIZATION — COURSE
  // ===========================================================================

  static Map<String, dynamic> _normalizeCourse(
    Map<String, dynamic> source,
  ) {
    final Map<String, dynamic> course =
        Map<String, dynamic>.from(source);

    course['id'] =
        _readString(course['id']) ??
            _createId('course');

    course['title'] =
        _readString(course['title']) ??
            'Eloqia Learning Path';

    course['description'] =
        _readString(course['description']) ??
            '';

    course['objective'] =
        _readString(course['objective']) ??
            '';

    course['level'] =
        _readString(course['level']) ??
            '';

    course['goal'] =
        _readString(course['goal']) ??
            '';

    course['status'] =
        _readString(course['status']) ??
            statusDraft;

    course['active'] =
        course['active'] == true;

    course['generatedBy'] =
        _readString(course['generatedBy']) ??
            'eloqia_ai';

    course['version'] =
        _readPositiveInt(
      course['version'],
      fallback: 1,
    );

    course['estimatedMinutes'] =
        _readNonNegativeInt(
      course['estimatedMinutes'],
    );

    course['createdAt'] =
        _readString(course['createdAt']) ??
            _now();

    course['updatedAt'] =
        _readString(course['updatedAt']) ??
            course['createdAt'];

    course['completedAt'] =
        _readString(course['completedAt']);

    course['tags'] =
        _readStringList(
      course['tags'],
    );

    course['modules'] =
        _normalizeModules(
      course['modules'],
    );

    return course;
  }

  // ===========================================================================
  // NORMALIZATION — MODULES
  // ===========================================================================

  static List<Map<String, dynamic>>
      _normalizeModules(
    dynamic value,
  ) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    final List<Map<String, dynamic>> modules =
        <Map<String, dynamic>>[];

    for (final dynamic rawModule in value) {
      if (rawModule is Map) {
        modules.add(
          _normalizeModule(
            Map<String, dynamic>.from(
              rawModule,
            ),
          ),
        );
      }
    }

    return modules
        .take(maxModulesPerCourse)
        .toList();
  }

  static Map<String, dynamic> _normalizeModule(
    Map<String, dynamic> source,
  ) {
    final Map<String, dynamic> module =
        Map<String, dynamic>.from(source);

    module['id'] =
        _readString(module['id']) ??
            _createId('module');

    module['title'] =
        _readString(module['title']) ??
            'Learning Module';

    module['description'] =
        _readString(module['description']) ??
            '';

    module['order'] =
        _readNonNegativeInt(
      module['order'],
    );

    module['status'] =
        _readString(module['status']) ??
            statusDraft;

    module['lessons'] =
        _normalizeLessons(
      module['lessons'],
    );

    return module;
  }

  // ===========================================================================
  // NORMALIZATION — LESSONS
  // ===========================================================================

  static List<Map<String, dynamic>>
      _normalizeLessons(
    dynamic value,
  ) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    final List<Map<String, dynamic>> lessons =
        <Map<String, dynamic>>[];

    for (final dynamic rawLesson in value) {
      if (rawLesson is Map) {
        lessons.add(
          _normalizeLesson(
            Map<String, dynamic>.from(
              rawLesson,
            ),
          ),
        );
      }
    }

    return lessons
        .take(maxLessonsPerModule)
        .toList();
  }

  static Map<String, dynamic> _normalizeLesson(
    Map<String, dynamic> source,
  ) {
    final Map<String, dynamic> lesson =
        Map<String, dynamic>.from(source);

    lesson['id'] =
        _readString(lesson['id']) ??
            _createId('lesson');

    lesson['title'] =
        _readString(lesson['title']) ??
            'Eloqia Learning Session';

    lesson['description'] =
        _readString(lesson['description']) ??
            '';

    lesson['type'] =
        _readString(lesson['type']) ??
            'lesson';

    lesson['difficulty'] =
        _readString(lesson['difficulty']) ??
            '';

    lesson['status'] =
        _readString(lesson['status']) ??
            lessonAvailable;

    lesson['completed'] =
        lesson['completed'] == true;

    lesson['durationMinutes'] =
        _readNonNegativeInt(
      lesson['durationMinutes'],
    );

    lesson['xpReward'] =
        _readNonNegativeInt(
      lesson['xpReward'],
    );

    lesson['xpEarned'] =
        _readNonNegativeInt(
      lesson['xpEarned'],
    );

    lesson['score'] =
        _readScore(
      lesson['score'],
    );

    lesson['createdAt'] =
        _readString(lesson['createdAt']) ??
            _now();

    lesson['completedAt'] =
        _readString(
      lesson['completedAt'],
    );

    return lesson;
  }

  // ===========================================================================
  // SORTING
  // ===========================================================================

  static void _sortCourses(
    List<Map<String, dynamic>> courses,
  ) {
    courses.sort(
      (
        Map<String, dynamic> first,
        Map<String, dynamic> second,
      ) {
        final DateTime firstDate =
            _parseDate(
          first['updatedAt'],
        );

        final DateTime secondDate =
            _parseDate(
          second['updatedAt'],
        );

        return secondDate.compareTo(
          firstDate,
        );
      },
    );
  }

  // ===========================================================================
  // SAFE READERS
  // ===========================================================================

  static String? _readString(
    dynamic value,
  ) {
    if (value is! String) {
      return null;
    }

    final String result =
        value.trim();

    return result.isEmpty
        ? null
        : result;
  }

  static List<String> _readStringList(
    dynamic value,
  ) {
    if (value is! List) {
      return <String>[];
    }

    return value
        .whereType<String>()
        .map(
          (String item) => item.trim(),
        )
        .where(
          (String item) => item.isNotEmpty,
        )
        .toList();
  }

  static int _readNonNegativeInt(
    dynamic value,
  ) {
    if (value is int) {
      return value < 0 ? 0 : value;
    }

    if (value is num) {
      final int result =
          value.toInt();

      return result < 0 ? 0 : result;
    }

    return 0;
  }

  static int _readPositiveInt(
    dynamic value, {
    required int fallback,
  }) {
    final int result =
        _readNonNegativeInt(value);

    return result <= 0
        ? fallback
        : result;
  }

  static double _readScore(
    dynamic value,
  ) {
    if (value is num) {
      return value
          .toDouble()
          .clamp(0.0, 100.0);
    }

    return 0.0;
  }

  // ===========================================================================
  // DATES
  // ===========================================================================

  static DateTime _parseDate(
    dynamic value,
  ) {
    if (value is String) {
      final DateTime? parsed =
          DateTime.tryParse(value);

      if (parsed != null) {
        return parsed;
      }
    }

    return DateTime.fromMillisecondsSinceEpoch(
      0,
      isUtc: true,
    );
  }

  static String _now() {
    return DateTime.now()
        .toUtc()
        .toIso8601String();
  }

  // ===========================================================================
  // IDENTIFIERS
  // ===========================================================================

  static String _createId(
    String prefix,
  ) {
    final int timestamp =
        DateTime.now()
            .toUtc()
            .microsecondsSinceEpoch;

    return '${prefix}_$timestamp';
  }
}