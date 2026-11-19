import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracking_app/models/user_profile.dart';
import 'package:period_tracking_app/services/cycle_service.dart';
import 'package:period_tracking_app/services/prediction_service.dart';

import 'test_helpers.dart';

void main() {
  late CycleService cycleService;
  late PredictionService predictionService;

  setUp(() {
    cycleService = buildCycleService();
    predictionService = PredictionService(cycleService: cycleService);
  });

  /// Builds a profile that has finished cycles of the given lengths.
  /// The first cycle starts on firstStart, the last (current) cycle starts
  /// right after the last finished one.
  UserProfile profileWithCycles(DateTime firstStart, List<int> lengths) {
    final profile = onboardedProfile(cycleService, lastPeriodStart: firstStart);
    var start = firstStart;
    for (final length in lengths) {
      start = DateTime(start.year, start.month, start.day + length);
      cycleService.startPeriod(profile, date: start);
    }
    return profile;
  }

  group('predictNext / calculate', () {
    test('NORMAL: predicts the next period from the onboarding answers', () {
      // Cycle starts 1 Nov, average cycle = 28, average period = 5
      final profile = onboardedProfile(cycleService);

      final p = predictionService.predictNext(profile)!;

      expect(p.predictionStart, DateTime(2025, 11, 29)); // 1 Nov + 28
      expect(p.predictionEnd, DateTime(2025, 12, 3)); // start + 5 - 1
      expect(p.usesLearnedAverages, isFalse); // show "estimated" in the UI
      expect(p.basedOnCycles, 0);
    });

    test('NORMAL: estimated window is +/- 2 days around the prediction', () {
      final profile = onboardedProfile(cycleService);

      final p = predictionService.predictNext(profile)!;

      expect(p.earliestStart, DateTime(2025, 11, 27));
      expect(p.latestStart, DateTime(2025, 12, 1));
    });

    test('NORMAL: uses the learned averages after 2 finished cycles', () {
      // Cycles of 28 and 30 days, current cycle starts 28 Sep.
      final profile = profileWithCycles(DateTime(2025, 8, 1), [28, 30]);
      final current = cycleService.getCurrentCycle(profile)!;
      expect(current.startDate, DateTime(2025, 9, 28));

      final p = predictionService.predictNext(profile)!;

      expect(p.usesLearnedAverages, isTrue);
      expect(p.basedOnCycles, 2);
      expect(p.predictionStart, DateTime(2025, 10, 27)); // 28 Sep + average 29
      // Window = shortest (28) to longest (30) cycle seen so far.
      expect(p.earliestStart, DateTime(2025, 10, 26));
      expect(p.latestStart, DateTime(2025, 10, 28));
    });

    test('NORMAL: predictNext gives the same result as calculate', () {
      final profile = onboardedProfile(cycleService);
      final current = cycleService.getCurrentCycle(profile)!;

      final a = predictionService.predictNext(profile)!;
      final b = predictionService.calculate(
        currentCycle: current,
        profile: profile,
      );

      expect(a.predictionStart, b.predictionStart);
      expect(a.predictionEnd, b.predictionEnd);
      expect(a.earliestStart, b.earliestStart);
      expect(a.latestStart, b.latestStart);
    });

    test('INVALID: returns null when the profile has no current cycle', () {
      final empty = UserProfile(
        id: 'p',
        name: 'Test',
        averageCycleLength: 28,
        averagePeriodLength: 5,
      );
      expect(predictionService.predictNext(empty), isNull);
    });

    test('BOUNDARY: the window is capped at 7 days around the prediction', () {
      // Very irregular cycles: 20 and 40 days (average 30).
      final profile = profileWithCycles(DateTime(2025, 8, 1), [20, 40]);

      final p = predictionService.predictNext(profile)!;

      expect(p.predictionStart, DateTime(2025, 10, 30)); // 30 Sep + 30
      // Raw window would be 20 Oct - 9 Nov, capped to +/- 7 days.
      expect(p.earliestStart, DateTime(2025, 10, 23));
      expect(p.latestStart, DateTime(2025, 11, 6));
    });

    test('BOUNDARY: identical cycle lengths give a window of one day', () {
      final profile = profileWithCycles(DateTime(2025, 8, 1), [28, 28]);

      final p = predictionService.predictNext(profile)!;

      expect(p.earliestStart, p.predictionStart);
      expect(p.latestStart, p.predictionStart);
    });

    test('BOUNDARY: the predicted date is always inside its window', () {
      final profile = profileWithCycles(DateTime(2025, 8, 1), [26, 33]);

      final p = predictionService.predictNext(profile)!;

      expect(p.earliestStart.isAfter(p.predictionStart), isFalse);
      expect(p.latestStart.isBefore(p.predictionStart), isFalse);
    });
  });

  group('daysUntil / isOverdue / daysLate', () {
    // Predicted start is 29 Nov 2025 for this profile.
    late UserProfile profile;

    setUp(() {
      profile = onboardedProfile(cycleService);
    });

    test('NORMAL: counts the days left before the predicted start', () {
      final p = predictionService.predictNext(profile)!;
      final today = DateTime(2025, 11, 20);

      expect(predictionService.daysUntil(p, today), 9);
      expect(predictionService.isOverdue(p, today), isFalse);
      expect(predictionService.daysLate(p, today), 0);
    });

    test('NORMAL: is overdue and counts the days late', () {
      final p = predictionService.predictNext(profile)!;
      final today = DateTime(2025, 12, 4);

      expect(predictionService.daysUntil(p, today), -5);
      expect(predictionService.isOverdue(p, today), isTrue);
      expect(predictionService.daysLate(p, today), 5);
    });

    test('BOUNDARY: on the predicted day itself she is NOT late yet', () {
      final p = predictionService.predictNext(profile)!;
      final today = DateTime(2025, 11, 29, 23, 59);

      expect(predictionService.daysUntil(p, today), 0);
      expect(predictionService.isOverdue(p, today), isFalse);
      expect(predictionService.daysLate(p, today), 0);
    });

    test('BOUNDARY: one day after the predicted day she is 1 day late', () {
      final p = predictionService.predictNext(profile)!;
      final today = DateTime(2025, 11, 30, 0, 1);

      expect(predictionService.isOverdue(p, today), isTrue);
      expect(predictionService.daysLate(p, today), 1);
    });
  });

  group('Prediction model', () {
    test('isOverdue follows the same rule as the service', () {
      final profile = onboardedProfile(cycleService);
      final p = predictionService.predictNext(profile)!; // 29 Nov

      expect(p.isOverdue(DateTime(2025, 11, 28)), isFalse);
      expect(p.isOverdue(DateTime(2025, 11, 29)), isFalse);
      expect(p.isOverdue(DateTime(2025, 11, 30)), isTrue);
    });
  });
}
