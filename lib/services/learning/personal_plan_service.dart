import '../../core/storage/local_storage.dart';
import '../progress_service.dart';
import 'personal_plan.dart';

/// Applies the plan once: the daily goal follows the pace chosen during
/// onboarding. After that the learner's own changes are never overwritten.
class PersonalPlanService {
  PersonalPlanService._();

  static const String appliedKey =
      '${LocalStorage.namespace}.plan.dailyGoalApplied';

  /// Returns true when the daily goal was changed now.
  static Future<bool> applyDailyGoalOnce(PersonalPlan plan) async {
    if (plan.paceLabel == 'not chosen yet') return false;
    try {
      if (await LocalStorage.readBool(appliedKey) == true) return false;
      final bool saved = await ProgressService.setDailyGoal(plan.dailyMinutes);
      if (saved) await LocalStorage.saveBool(appliedKey, true);
      return saved;
    } on Object {
      return false;
    }
  }
}
