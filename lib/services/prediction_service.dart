import 'package:period_tracking_app/models/cycle.dart';
import 'package:period_tracking_app/models/prediction.dart';
import 'package:period_tracking_app/models/user_profile.dart';
import 'package:period_tracking_app/services/cycle_service.dart';
import 'package:period_tracking_app/utils/date_utils.dart';

// Service for  "Calculate the next period date"
class PredictionService {
  final CycleService _cycleService;

  PredictionService({CycleService? cycleService, Cycle? cycle})
    : _cycleService = cycleService ?? CycleService();

  /// +/- days around the prediction while averages are only onboarding answers.
  static const int estimateWindowDays = 2;

  /// The window never extends further than this from the predicted date.
  static const int maxWindowDays = 7;

  /// null when there is no current cycle.
  Prediction? predictNext(UserProfile profile) {
    final current = _cycleService.getCurrentCycle(profile);
    if (current == null) return null;
    return calculate(currentCycle: current, profile: profile);
  }

  /// predictedStart = current cycle start + average cycle length
  /// predictedEnd   = predictedStart + average period length - 1
  Prediction calculate({
    required Cycle currentCycle,
    required UserProfile profile,
  }) {
    final start = currentCycle.startDate;

    // Cycle length counts the first day, so day 1 + 28 = day 1 of next cycle.
    final predictedStart = addDays(start, profile.averageCycleLength);
    final predictedEnd = addDays(
      predictedStart,
      profile.averagePeriodLength - 1,
    );

    final learned = _cycleService.usesLearnedAverages(profile);
    final finished = _cycleService.getFinishedCycles(profile);
    DateTime earliest;
    DateTime latest;
    if (learned && finished.isNotEmpty) {
      final lengths = finished
          .map((c) => _cycleService.getCycleLength(c)!)
          .toList();
      final shortest = lengths.reduce((a, b) => a < b ? a : b);
      final longest = lengths.reduce((a, b) => a > b ? a : b);
      earliest = addDays(start, shortest);
      latest = addDays(start, longest);
    } else {
      earliest = addDays(predictedStart, -estimateWindowDays);
      latest = addDays(predictedStart, estimateWindowDays);
    }

    // Cap the window, and keep the predicted date inside it.
    final minE = addDays(predictedStart, -maxWindowDays);
    final maxL = addDays(predictedStart, maxWindowDays);
    if (earliest.isBefore(minE)) earliest = minE;
    if (latest.isAfter(maxL)) latest = maxL;
    if (earliest.isAfter(predictedStart)) earliest = predictedStart;
    if (latest.isBefore(predictedStart)) latest = predictedStart;

    return Prediction(
      predictionStart: predictedStart,
      predictionEnd: predictedEnd,
      earliestStart: earliest,
      latestStart: latest,
      basedOnCycles: profile.completedCycleCount,
      usesLearnedAverages: learned,
    );
  }

  /// Days until the predicted start; negative when overdue.
  int daysUntil(Prediction p, DateTime today) =>
      daysBetween(today, p.predictionStart);

  bool isOverdue(Prediction p, DateTime today) => daysUntil(p, today) < 0;

  /// Days past the predicted start; 0 if not overdue yet.
  int daysLate(Prediction p, DateTime today) {
    final d = daysUntil(p, today);
    return d < 0 ? -d : 0;
  }
}
