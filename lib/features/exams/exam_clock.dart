import 'exam_formats.dart';

enum ExamClockPhase { notStarted, running, lastMinutes, over }

/// Countdown for one timed attempt. Like the real exam it does not pause;
/// after the limit it keeps counting so the learner sees the overtime.
class ExamClock {
  ExamClock({required this.limit, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Duration limit;
  final DateTime Function() _now;
  DateTime? _startedAt;

  bool get started => _startedAt != null;

  void start() => _startedAt ??= _now();

  void reset() => _startedAt = null;

  Duration get elapsed {
    final DateTime? at = _startedAt;
    if (at == null) return Duration.zero;
    final Duration value = _now().difference(at);
    return value.isNegative ? Duration.zero : value;
  }

  /// Negative after the limit.
  Duration get remaining => limit - elapsed;

  bool get isOver => started && elapsed >= limit;

  /// Warning zone: the last tenth of the time, at least the last minute.
  Duration get warningZone {
    final Duration tenth = Duration(seconds: limit.inSeconds ~/ 10);
    return tenth < const Duration(minutes: 1)
        ? const Duration(minutes: 1)
        : tenth;
  }

  ExamClockPhase get phase {
    if (!started) return ExamClockPhase.notStarted;
    if (isOver) return ExamClockPhase.over;
    if (remaining <= warningZone) return ExamClockPhase.lastMinutes;
    return ExamClockPhase.running;
  }

  /// "19:42" while running, "+1:05" after the limit.
  String get display {
    if (!started) return formatClock(limit);
    return isOver ? '+${formatClock(elapsed - limit)}' : formatClock(remaining);
  }
}
