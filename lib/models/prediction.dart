import 'package:period_tracking_app/utils/date_utils.dart';

class Prediction {
  final DateTime predictionStart;
  final DateTime predictionEnd;
  final DateTime earliestStart;
  final DateTime latestStart;

  /// profile.completedCycleCount at the time of the calculation.
  final int basedOnCycles;

  /// profile.usesLearnedAverages: true = based on real cycles,
  /// false = still based on onboarding answers.
  final bool usesLearnedAverages;

  // ex: predicted date: 29-10-2025 and actual start date(today): 30-10-2025
  // 29-30 = -1
  bool isOverdue(DateTime today) =>
      daysBetween(dateOnly(today), dateOnly(predictionStart)) < 0;

  int daysLate(DateTime today) {
    if (!isOverdue(today)) return 0;
    return daysBetween(dateOnly(today), dateOnly(predictionStart));
  }

  Prediction({
    required DateTime predictionStart,
    required DateTime predictionEnd,
    required DateTime earliestStart,
    required DateTime latestStart,
    required this.basedOnCycles,
    required this.usesLearnedAverages,
  }) : predictionStart = dateOnly(predictionStart),
       predictionEnd = DateTime(
         predictionEnd.year,
         predictionEnd.month,
         predictionEnd.day,
       ),
       earliestStart = DateTime(
         earliestStart.year,
         earliestStart.month,
         earliestStart.day,
       ),
       latestStart = DateTime(
         latestStart.year,
         latestStart.month,
         latestStart.day,
       );
}
