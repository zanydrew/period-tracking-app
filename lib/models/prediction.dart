import 'package:period_tracking_app/utils/date_utils.dart';

class Prediction {
  final DateTime predictionStart;
  final DateTime predictionEnd;
  final DateTime earliestStart;
  final DateTime latestStart;

  /// profile.completedCycleCount at the time of the calculation.
  final int basedOnCycles;

  /// true = based on her real cycles, false = still her onboarding answers
  /// (show "estimated" in the UI).
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
       earliestStart = dateOnly(earliestStart),
       latestStart = dateOnly(latestStart);
}
