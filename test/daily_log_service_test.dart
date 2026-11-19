import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracking_app/models/enums/daily_log_enums.dart';
import 'package:period_tracking_app/models/user_profile.dart';
import 'package:period_tracking_app/services/cycle_service.dart';
import 'package:period_tracking_app/services/daily_log_service.dart';

import 'test_helpers.dart';

void main() {
  late CycleService cycleService;
  late DailyLogService logService;
  late UserProfile profile;

  setUp(() {
    cycleService = buildCycleService();
    logService = DailyLogService(
      cycleService: cycleService,
      clock: () => fixedToday,
    );
    // older:   1 Oct - 28 Oct
    // current: 29 Oct -> today (20 Nov)
    profile = onboardedProfile(
      cycleService,
      lastPeriodStart: DateTime(2025, 10, 1),
    );
    cycleService.startPeriod(profile, date: DateTime(2025, 10, 29));
  });

  group('saveLog', () {
    test('NORMAL: saves a log and it can be read back', () {
      final saved = logService.saveLog(
        profile,
        date: DateTime(2025, 11, 2),
        flow: FlowLevel.medium,
        bloodColor: BloodColor.brightRed,
        cramps: CrampLevel.slightly,
        moods: {Mood.tired, Mood.sad},
        bodySymptoms: {BodySymptom.headache},
      );

      expect(saved, isNotNull);
      final found = logService.getLog(profile, DateTime(2025, 11, 2));
      expect(found, same(saved));
      expect(found!.flow, FlowLevel.medium);
      expect(found.bloodColor, BloodColor.brightRed);
      expect(found.cramps, CrampLevel.slightly);
      expect(found.moods, {Mood.tired, Mood.sad});
      expect(found.bodySymptoms, {BodySymptom.headache});
    });

    test(
      'NORMAL: the log is stored inside the cycle that contains the date',
      () {
        // Involves several entities: DailyLog -> Cycle -> UserProfile
        final older = profile.cycles[0];
        final current = profile.cycles[1];

        logService.saveLog(
          profile,
          date: DateTime(2025, 10, 10),
          flow: FlowLevel.little,
        );
        logService.saveLog(
          profile,
          date: DateTime(2025, 11, 10),
          flow: FlowLevel.heavy,
        );

        expect(older.logs.length, 1);
        expect(older.logs.first.flow, FlowLevel.little);
        expect(current.logs.length, 1);
        expect(current.logs.first.flow, FlowLevel.heavy);
      },
    );

    test('NORMAL: logging the same day again replaces the old log', () {
      logService.saveLog(
        profile,
        date: DateTime(2025, 11, 2),
        flow: FlowLevel.little,
      );
      logService.saveLog(
        profile,
        date: DateTime(2025, 11, 2),
        flow: FlowLevel.heavy,
      );

      final cycle = profile.cycles[1];
      expect(cycle.logs.length, 1); // still one log per day
      expect(cycle.logs.first.flow, FlowLevel.heavy);
    });

    test('NORMAL: logs are kept sorted by date', () {
      logService.saveLog(
        profile,
        date: DateTime(2025, 11, 5),
        flow: FlowLevel.little,
      );
      logService.saveLog(
        profile,
        date: DateTime(2025, 11, 2),
        flow: FlowLevel.little,
      );
      logService.saveLog(
        profile,
        date: DateTime(2025, 11, 9),
        flow: FlowLevel.little,
      );

      final dates = profile.cycles[1].logs.map((l) => l.date).toList();
      expect(dates, [
        DateTime(2025, 11, 2),
        DateTime(2025, 11, 5),
        DateTime(2025, 11, 9),
      ]);
    });

    test('INVALID: rejects a date in the future', () {
      expect(
        () => logService.saveLog(
          profile,
          date: DateTime(2025, 11, 21),
          flow: FlowLevel.little,
        ),
        throwsMessage('future'),
      );
      expect(profile.cycles[1].logs, isEmpty);
    });

    test('INVALID: rejects a date that no cycle covers', () {
      // The profile's first cycle starts on 1 Oct.
      expect(
        () => logService.saveLog(
          profile,
          date: DateTime(2025, 9, 30),
          flow: FlowLevel.little,
        ),
        throwsMessage('No cycle covers'),
      );
    });

    test('INVALID: rejects logging on a profile with no cycle at all', () {
      final empty = UserProfile(
        id: 'p',
        name: 'Test',
        averageCycleLength: 28,
        averagePeriodLength: 5,
      );
      expect(
        () => logService.saveLog(
          empty,
          date: DateTime(2025, 11, 2),
          flow: FlowLevel.little,
        ),
        throwsMessage('No cycle covers'),
      );
    });

    test('BOUNDARY: logging today (latest allowed day) is accepted', () {
      final saved = logService.saveLog(
        profile,
        date: DateTime(2025, 11, 20, 23, 59),
        cramps: CrampLevel.very,
      );
      expect(saved, isNotNull);
      expect(saved!.date, DateTime(2025, 11, 20));
    });

    test(
      'BOUNDARY: logging on the first day of the first cycle is accepted',
      () {
        final saved = logService.saveLog(
          profile,
          date: DateTime(2025, 10, 1),
          flow: FlowLevel.spotting,
        );
        expect(saved, isNotNull);
        expect(profile.cycles[0].logs.length, 1);
      },
    );

    test('BOUNDARY: logging on the last day of the older cycle (28 Oct)', () {
      logService.saveLog(
        profile,
        date: DateTime(2025, 10, 28),
        flow: FlowLevel.little,
      );
      logService.saveLog(
        profile,
        date: DateTime(2025, 10, 29),
        flow: FlowLevel.medium,
      );

      expect(profile.cycles[0].logs.length, 1); // 28 Oct -> older cycle
      expect(profile.cycles[1].logs.length, 1); // 29 Oct -> current cycle
    });

    test('SPECIAL: an empty selection returns null and saves nothing', () {
      final result = logService.saveLog(profile, date: DateTime(2025, 11, 2));

      expect(result, isNull);
      expect(profile.cycles[1].logs, isEmpty);
    });

    test(
      'SPECIAL: an empty selection deletes the existing log of that day',
      () {
        logService.saveLog(
          profile,
          date: DateTime(2025, 11, 2),
          flow: FlowLevel.heavy,
        );
        expect(logService.getLog(profile, DateTime(2025, 11, 2)), isNotNull);

        final result = logService.saveLog(profile, date: DateTime(2025, 11, 2));

        expect(result, isNull);
        expect(logService.getLog(profile, DateTime(2025, 11, 2)), isNull);
      },
    );

    test('SPECIAL: only moods / symptoms selected still counts as a log', () {
      final saved = logService.saveLog(
        profile,
        date: DateTime(2025, 11, 2),
        moods: {Mood.happy},
      );
      expect(saved, isNotNull);
      expect(saved!.isEmpty, isFalse);
    });
  });

  group('getLog', () {
    test('NORMAL: finds the log even if the time of day is different', () {
      logService.saveLog(
        profile,
        date: DateTime(2025, 11, 2, 8, 0),
        flow: FlowLevel.medium,
      );

      final found = logService.getLog(profile, DateTime(2025, 11, 2, 21, 45));
      expect(found, isNotNull);
      expect(found!.flow, FlowLevel.medium);
    });

    test('NORMAL: returns null for a day that was never logged', () {
      expect(logService.getLog(profile, DateTime(2025, 11, 3)), isNull);
    });

    test('INVALID: returns null for a date outside every cycle', () {
      expect(logService.getLog(profile, DateTime(2025, 1, 1)), isNull);
    });
  });
}
