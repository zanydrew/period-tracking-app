import 'package:period_tracking_app/models/daily_log.dart';
import 'package:period_tracking_app/utils/date_utils.dart';

class Cycle {
  // One menstrual cycle: from the first day of a period to the day before the next period starts.
  final String id;
  final DateTime startDate;
  // Last day if bleeding.
  // null while the period is still ongoing.
  // not null when user click on period end button
  DateTime? periodEndDate;
  // Last day of this cycle.
  // null = this is the current cycle.
  DateTime? cycleEndDate;

  /// true = periodEndDate was estimated (from onboarding or a "period ended" button wasn't clicked), not entered by her.
  bool periodEndEstimated;

  final List<DailyLog> logs = [];

  // current cycle
  bool get isCurrent => cycleEndDate == null;
  // period day (day1 of your period, day2 of your period...)
  bool get isPeriodOngoing => periodEndDate == null;

  Cycle({
    required this.id,
    required DateTime startDate,
    this.periodEndEstimated = false,
    DateTime? periodEndDate,
    DateTime? cycleEndDate,
  }) : startDate = DateTime(startDate.year, startDate.month, startDate.day),
       periodEndDate = periodEndDate == null
           ? null
           : DateTime(
               periodEndDate.year,
               periodEndDate.month,
               periodEndDate.day,
             ),
       cycleEndDate = cycleEndDate == null
           ? null
           : DateTime(cycleEndDate.year, cycleEndDate.month, cycleEndDate.day);

  @override
  String toString() =>
      'Cycle id: $id, start: $startDate, period end: $periodEndDate, '
      'cycle end: $cycleEndDate, logs: ${logs.length}';
}
