import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracking_app/models/cycle.dart';
import 'package:period_tracking_app/models/user_profile.dart';
import 'package:period_tracking_app/services/cycle_service.dart';

import 'test_helpers.dart';

void main() {
  late CycleService service;

  setUp(() {
    service = buildCycleService();
  });

  group('completeOnboarding', () {
    test('NORMAL: creates the profile and its first (current) cycle', () {
      final profile = service.completeOnboarding(
        name: '  Niza  ',
        lastPeriodStart: DateTime(2025, 11, 1),
        periodLength: 5,
        cycleLength: 28,
      );

      expect(profile.name, 'Niza'); // trimmed
      expect(profile.averageCycleLength, 28);
      expect(profile.averagePeriodLength, 5);
      expect(profile.onboardingCompleted, isTrue);
      expect(profile.cycles.length, 1);

      final first = profile.cycles.first;
      expect(first.startDate, DateTime(2025, 11, 1));
      expect(first.periodEndDate, DateTime(2025, 11, 5)); // start + 5 - 1
      expect(first.periodEndEstimated, isTrue); // not entered by the user
      expect(first.isCurrent, isTrue);
    });

    test('INVALID: rejects an empty / blank name', () {
      expect(
        () => service.completeOnboarding(
          name: '   ',
          lastPeriodStart: DateTime(2025, 11, 1),
          periodLength: 5,
          cycleLength: 28,
        ),
        throwsMessage('enter your name'),
      );
    });

    test('INVALID: rejects a last period that starts in the future', () {
      expect(
        () => service.completeOnboarding(
          name: 'Niza',
          lastPeriodStart: DateTime(2025, 11, 21), // tomorrow
          periodLength: 5,
          cycleLength: 28,
        ),
        throwsMessage('future'),
      );
    });

    test('INVALID: rejects a period length smaller than 1 day', () {
      expect(
        () => service.completeOnboarding(
          name: 'Niza',
          lastPeriodStart: DateTime(2025, 11, 1),
          periodLength: 0,
          cycleLength: 28,
        ),
        throwsMessage('at least 1 day'),
      );
    });

    test('INVALID: rejects a cycle length shorter than the period length', () {
      expect(
        () => service.completeOnboarding(
          name: 'Niza',
          lastPeriodStart: DateTime(2025, 11, 1),
          periodLength: 7,
          cycleLength: 6,
        ),
        throwsMessage('at least as long'),
      );
    });

    test('BOUNDARY: a period that starts today is accepted', () {
      final profile = onboardedProfile(
        service,
        lastPeriodStart: DateTime(2025, 11, 20, 23, 59), // today, late evening
      );
      expect(profile.cycles.first.startDate, DateTime(2025, 11, 20));
    });

    test('BOUNDARY: cycle length equal to period length is accepted', () {
      final profile = onboardedProfile(
        service,
        periodLength: 5,
        cycleLength: 5,
      );
      expect(profile.averageCycleLength, 5);
    });

    test('BOUNDARY: a 1-day period ends on the same day it starts', () {
      final profile = onboardedProfile(service, periodLength: 1);
      expect(profile.cycles.first.periodEndDate, DateTime(2025, 11, 1));
    });
  });

  group('startPeriod (involves profile + two cycles)', () {
    test('NORMAL: closes the current cycle and opens a new one', () {
      final profile = onboardedProfile(
        service,
        lastPeriodStart: DateTime(2025, 10, 20),
      );
      final old = profile.cycles.first;

      final next = service.startPeriod(profile, date: DateTime(2025, 11, 17));

      expect(profile.cycles.length, 2);
      expect(old.cycleEndDate, DateTime(2025, 11, 16)); // day before new start
      expect(service.getCycleLength(old), 28);
      expect(old.isCurrent, isFalse);
      expect(next.startDate, DateTime(2025, 11, 17));
      expect(next.isCurrent, isTrue);
      expect(service.getCurrentCycle(profile), same(next));
      expect(profile.completedCycleCount, 1);
    });

    test('NORMAL: uses today when no date is given', () {
      final profile = onboardedProfile(
        service,
        lastPeriodStart: DateTime(2025, 10, 20),
      );
      final next = service.startPeriod(profile);
      expect(next.startDate, DateTime(2025, 11, 20));
    });

    test('NORMAL: keeps the end date the user entered (not estimated)', () {
      final profile = onboardedProfile(
        service,
        lastPeriodStart: DateTime(2025, 10, 1),
      );
      service.startPeriod(profile, date: DateTime(2025, 10, 29));
      service.endPeriod(profile, date: DateTime(2025, 11, 1));
      final second = service.getCurrentCycle(profile)!;

      service.startPeriod(profile, date: DateTime(2025, 11, 15));

      expect(second.periodEndDate, DateTime(2025, 11, 1));
      expect(second.periodEndEstimated, isFalse);
    });

    test('NORMAL: estimates the period end if the user never pressed it', () {
      final profile = onboardedProfile(
        service,
        lastPeriodStart: DateTime(2025, 10, 1),
      );
      final second = service.startPeriod(profile, date: DateTime(2025, 10, 29));
      expect(second.isPeriodOngoing, isTrue);

      service.startPeriod(profile, date: DateTime(2025, 11, 15));

      // start (29 Oct) + average period (5) - 1 = 2 Nov
      expect(second.periodEndDate, DateTime(2025, 11, 2));
      expect(second.periodEndEstimated, isTrue);
    });

    test('INVALID: rejects a start date in the future', () {
      final profile = onboardedProfile(service);
      expect(
        () => service.startPeriod(profile, date: DateTime(2025, 11, 21)),
        throwsMessage('future'),
      );
      expect(profile.cycles.length, 1); // nothing was changed
    });

    test('INVALID: rejects a start before the current cycle began', () {
      final profile = onboardedProfile(service); // cycle starts 1 Nov
      expect(
        () => service.startPeriod(profile, date: DateTime(2025, 10, 30)),
        throwsMessage('after the current cycle began'),
      );
      expect(profile.cycles.length, 1);
    });

    test('BOUNDARY: rejects a start on the SAME day as the current cycle', () {
      final profile = onboardedProfile(service);
      expect(
        () => service.startPeriod(profile, date: DateTime(2025, 11, 1)),
        throwsMessage('after the current cycle began'),
      );
    });

    test('BOUNDARY: starting the day after is accepted (1-day cycle)', () {
      final profile = onboardedProfile(service);
      service.startPeriod(profile, date: DateTime(2025, 11, 2));
      expect(service.getCycleLength(profile.cycles.first), 1);
    });

    test('BOUNDARY: estimated period end is capped at the day before', () {
      final profile = onboardedProfile(
        service,
        lastPeriodStart: DateTime(2025, 10, 1),
      );
      final second = service.startPeriod(profile, date: DateTime(2025, 10, 29));

      // New period starts 2 days later: estimate (2 Nov) would be after it.
      service.startPeriod(profile, date: DateTime(2025, 10, 31));

      expect(second.periodEndDate, DateTime(2025, 10, 30)); // day before
    });

    test('SPECIAL: works on a profile that has no cycle yet', () {
      final empty = UserProfile(
        id: 'p',
        name: 'Test',
        averageCycleLength: 28,
        averagePeriodLength: 5,
      );
      final first = service.startPeriod(empty, date: DateTime(2025, 11, 10));
      expect(empty.cycles, [first]);
      expect(empty.completedCycleCount, 0);
    });
  });

  group('endPeriod', () {
    late UserProfile profile;
    late Cycle current;

    setUp(() {
      // Current cycle starts 10 Nov and its period is still ongoing.
      profile = onboardedProfile(
        service,
        lastPeriodStart: DateTime(2025, 10, 13),
      );
      current = service.startPeriod(profile, date: DateTime(2025, 11, 10));
    });

    test('NORMAL: sets the last bleeding day of the current cycle', () {
      final result = service.endPeriod(profile, date: DateTime(2025, 11, 13));

      expect(result, same(current));
      expect(current.periodEndDate, DateTime(2025, 11, 13));
      expect(current.periodEndEstimated, isFalse);
      expect(service.getPeriodLength(current), 4);
      expect(current.isPeriodOngoing, isFalse);
    });

    test('NORMAL: uses today when no date is given', () {
      service.endPeriod(profile);
      expect(current.periodEndDate, DateTime(2025, 11, 20));
    });

    test('NORMAL: replaces an estimated end with the real one', () {
      final p = onboardedProfile(service); // onboarding end is only estimated
      final first = p.cycles.first;
      expect(first.periodEndEstimated, isTrue);

      service.endPeriod(p, date: DateTime(2025, 11, 4));

      expect(first.periodEndDate, DateTime(2025, 11, 4));
      expect(first.periodEndEstimated, isFalse);
    });

    test('INVALID: rejects when there is no cycle in progress', () {
      final empty = UserProfile(
        id: 'p',
        name: 'Test',
        averageCycleLength: 28,
        averagePeriodLength: 5,
      );
      expect(() => service.endPeriod(empty), throwsMessage('no cycle'));
    });

    test('INVALID: rejects an end date in the future', () {
      expect(
        () => service.endPeriod(profile, date: DateTime(2025, 11, 21)),
        throwsMessage('future'),
      );
      expect(current.isPeriodOngoing, isTrue); // unchanged
    });

    test('INVALID: rejects an end date before the period started', () {
      expect(
        () => service.endPeriod(profile, date: DateTime(2025, 11, 9)),
        throwsMessage('before it started'),
      );
    });

    test('BOUNDARY: ending on the start day gives a 1-day period', () {
      service.endPeriod(profile, date: DateTime(2025, 11, 10));
      expect(service.getPeriodLength(current), 1);
    });

    test('BOUNDARY: ending today (latest allowed date) is accepted', () {
      service.endPeriod(profile, date: DateTime(2025, 11, 20, 23, 59));
      expect(current.periodEndDate, DateTime(2025, 11, 20));
    });
  });

  group('recalculateProfile (learning the averages)', () {
    test('NORMAL: learns the averages after 2 finished cycles', () {
      // Cycle A: 1 Aug - 28 Aug (28 days)   period end only estimated
      // Cycle B: 29 Aug - 27 Sep (30 days)  period 29 Aug - 3 Sep = 6 days
      // Cycle C: 28 Sep -> current
      final profile = onboardedProfile(
        service,
        lastPeriodStart: DateTime(2025, 8, 1),
      );
      service.startPeriod(profile, date: DateTime(2025, 8, 29));
      service.endPeriod(profile, date: DateTime(2025, 9, 3));
      service.startPeriod(profile, date: DateTime(2025, 9, 28));

      expect(profile.completedCycleCount, 2);
      expect(service.usesLearnedAverages(profile), isTrue);
      expect(profile.averageCycleLength, 29); // (28 + 30) / 2
      // Cycle A's period end was only estimated, so only cycle B counts.
      expect(profile.averagePeriodLength, 6);
    });

    test('BOUNDARY: 1 finished cycle is NOT enough to learn', () {
      final profile = onboardedProfile(
        service,
        lastPeriodStart: DateTime(2025, 8, 1),
        cycleLength: 31, // onboarding answer
      );
      service.startPeriod(profile, date: DateTime(2025, 8, 29)); // 28 days

      expect(profile.completedCycleCount, 1);
      expect(service.usesLearnedAverages(profile), isFalse);
      expect(profile.averageCycleLength, 31); // still the onboarding answer
    });

    test('BOUNDARY: an average ending in .5 is rounded up (28.5 -> 29)', () {
      // Cycle A = 28 days, cycle B = 29 days
      final profile = onboardedProfile(
        service,
        lastPeriodStart: DateTime(2025, 8, 1),
      );
      service.startPeriod(profile, date: DateTime(2025, 8, 29));
      service.startPeriod(profile, date: DateTime(2025, 9, 27));

      expect(profile.averageCycleLength, 29);
    });

    test(
      'SPECIAL: keeps the onboarding period length if all are estimates',
      () {
        final profile = onboardedProfile(
          service,
          lastPeriodStart: DateTime(2025, 8, 1),
          periodLength: 4,
        );
        service.startPeriod(profile, date: DateTime(2025, 8, 29));
        service.startPeriod(profile, date: DateTime(2025, 9, 28));
        // The user never pressed "period ended": every end is an estimate.

        expect(profile.completedCycleCount, 2);
        expect(profile.averagePeriodLength, 4);
      },
    );
  });
}
