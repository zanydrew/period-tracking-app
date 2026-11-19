import 'package:period_tracking_app/utils/date_utils.dart';

class Cycle {
  // One menstrual cycle: from the first day of a period to the day before the next period starts.
  final String id;
  final DateTime startDate;
  // Last day if bleeding.
  // null while the period is still ongoing.
  // not null when user click on period end button
  final DateTime? periodEndDate;
  // Last day of this cycle.
  // null = this is the current cycle.
  final DateTime? cycleEndDate;

  // current cycle
  bool get isCurrent => cycleEndDate == null;
  // period day (day1 of your period, day2 of your period...)
  bool get isPeriodOngoing => periodEndDate == null;
  int? get periodLength =>
      periodEndDate == null ? null : daysBetween(startDate, periodEndDate!) + 1;

  int? get cycleLength =>
      cycleEndDate == null ? null : daysBetween(startDate, cycleEndDate!) + 1;

  // Day of the cycle (Day 1 of your cycle)
  int dayOfCycle(DateTime today) => daysBetween(startDate, today) + 1;

  int? dayOfPeriod(DateTime today) {
    // pre-condition: null if the period hasn't start yet

    if (dateOnly(today).isBefore(dateOnly(startDate))) {
      return null;
    }

    // null if the period already ended
    if (periodEndDate != null &&
        dateOnly(today).isAfter(dateOnly(periodEndDate!))) {
      return null;
    }

    return dayOfCycle(today);
  }

  Cycle({
    required this.id,
    required DateTime startDate,
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
}
