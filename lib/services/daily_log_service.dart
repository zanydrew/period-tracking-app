import 'package:period_tracking_app/models/daily_log.dart';
import 'package:period_tracking_app/models/enums/daily_log_enums.dart';
import 'package:period_tracking_app/models/user_profile.dart';
import 'package:period_tracking_app/services/cycle_service.dart';
import 'package:period_tracking_app/utils/date_utils.dart';

class DailyLogService {
  final CycleService _cycleService;
  final DateTime Function() _now;

  DailyLogService({CycleService? cycleService, DateTime Function()? clock})
    : _now = clock ?? DateTime.now,
      _cycleService = cycleService ?? CycleService(clock: clock);

  /// The log of one day, or null.
  DailyLog? getLog(UserProfile profile, DateTime date) {
    final cycle = _cycleService.findCycleOnDate(profile, date);
    if (cycle == null) return null;
    final day = dateOnly(date);
    for (final log in cycle.logs) {
      if (log.date == day) return log;
    }
    return null;
  }

  /// Saves the whole log of date into the cycle that contains it
  /// if user log twice or more in the same day it will edit by replace the old log
  /// returns null when nothing is selected
  /// an existing log of that day is then removed.
  ///
  /// Preconditions: date not in the future, some cycle contains the date.
  DailyLog? saveLog(
    UserProfile profile, {
    required DateTime date,
    FlowLevel? flow,
    BloodColor? bloodColor,
    CrampLevel? cramps,
    Set<Mood>? moods = const {},
    Set<BodySymptom>? bodySymptoms = const {},
  }) {
    final day = dateOnly(date);
    if (day.isAfter(dateOnly(_now()))) {
      throw Exception('You cannot log a day in the future.');
    }
    final cycle = _cycleService.findCycleOnDate(profile, day);
    if (cycle == null) {
      throw Exception('No cycle covers this date. Start a period first.');
    }

    final log = DailyLog(
      date: day,
      flow: flow,
      bloodColor: bloodColor,
      cramps: cramps,
      moods: moods,
      bodySymptoms: bodySymptoms,
    );

    cycle.logs.removeWhere((l) => l.date == day); // one log per day,
    if (log.isEmpty) return null;

    cycle.logs.add(log);
    cycle.logs.sort((a, b) => a.date.compareTo(b.date));
    return log;
  }
}
