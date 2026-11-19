import 'package:period_tracking_app/models/cycle.dart';
import 'package:period_tracking_app/models/user_profile.dart';
import 'package:period_tracking_app/utils/date_utils.dart';

// Public fields/methods for UI and test calls
// Pricate fields/methods for other code shouldn’t touch or replace them after construction

class CycleService {
  // We store Time as Function() instead of just DateTime because
  // A stored DateTime would be fixed at the moment the service was created.
  // A function is called each time _now() is used, so the real clock keeps moving, and a test can still return a fixed date.

  static const int minCyclesToLearn = 2;

  bool usesLearnedAverages(UserProfile profile) =>
      profile.completedCycleCount >= minCyclesToLearn;

  final DateTime Function() _now;
  final String Function() _newId;
  DateTime get _today => dateOnly(_now());

  CycleService({DateTime Function()? clock, String Function()? newId})
    : _now = clock ?? DateTime.now,
      _newId = newId ?? _defaultId;

  // generated Id

  static int _counter = 0;
  static String _defaultId() =>
      'id-${DateTime.now().microsecondsSinceEpoch}-${_counter++}';

  // Onboarding screen: creates the profile and first cycle.
  // Previous period becomes the current cycle, cycle end date is when user click on the 'cycle end' by their own
  /// estimate (start + period length - 1), so it is flagged as estimated.
  ///
  /// Preconditions:
  /// - name not empty
  /// - Period start date not in the future;
  /// period length >= 1; cycle length >= period length.

  UserProfile completeOnboarding({
    required String name,
    required DateTime lastPeriodStart,
    required int periodLength,
    required int cycleLength,
  }) {
    final start = dateOnly(lastPeriodStart);
    if (name.trim().isEmpty) {
      throw Exception('Please enter your name.');
    }
    if (start.isAfter(_today)) {
      throw Exception('The previous period cannot start in the future.');
    }
    if (periodLength < 1) {
      throw Exception('Period length must be at least 1 day.');
    }
    if (cycleLength < periodLength) {
      throw Exception(
        'Cycle length must be at least as long as the period length.',
      );
    }

    final profile = UserProfile(
      id: _newId(),
      name: name.trim(),
      averageCycleLength: cycleLength,
      averagePeriodLength: periodLength,
      onboardingCompleted: true,
    );
    _addCycle(
      profile,
      Cycle(
        id: _newId(),
        startDate: start,
        periodEndDate: addDays(start, periodLength - 1),
        periodEndEstimated: true,
      ),
    );
    return profile;
  }

  // The "Period Starts: Yes" Button.
  // Description: Closes the current cycle, opens a new one and refreshes the profile averages
  // Involves profile + both cycles

  // Preconditions: date (default today) not in the future
  // After the start of the current cycle (becasue period is in a cycle)

  Cycle startPeriod(UserProfile profile, {DateTime? date}) {
    final start = dateOnly(date ?? _now());
    if (start.isAfter(_today)) {
      throw Exception('A period cannot start in the future.');
    }
    final current = getCurrentCycle(profile);
    if (current != null && !start.isAfter(current.startDate)) {
      throw Exception(
        'The new period must start after the current cycle began.',
      );
    }

    final next = Cycle(id: _newId(), startDate: start);

    if (current != null) {
      final dayBefore = addDays(start, -1);
      // She never marked the period as ended: estimate it, but never later
      // than the day before the new period.
      if (current.isPeriodOngoing) {
        final estimated = addDays(
          current.startDate,
          profile.averagePeriodLength - 1,
        );
        current.periodEndDate = estimated.isAfter(dayBefore)
            ? dayBefore
            : estimated;
        current.periodEndEstimated = true;
      }
      current.cycleEndDate = dayBefore;
    }

    _addCycle(profile, next);
    recalculateProfile(profile);
    return next;
  }

  // "Period ended" Button
  //  Description: Sets the last bleeding day of the current cycle

  // Preconditions:
  // - a current cycle exists
  // - date (default today) not in the future and not before the period started.
  Cycle endPeriod(UserProfile profile, {DateTime? date}) {
    final end = dateOnly(date ?? _now());
    final current = getCurrentCycle(profile);
    if (current == null) {
      throw Exception('There is no cycle in progress.');
    }
    if (end.isAfter(_today)) {
      throw Exception('A period cannot end in the future.');
    }
    if (end.isBefore(current.startDate)) {
      throw Exception('A period cannot end before it started.');
    }
    current.periodEndDate = end;
    current.periodEndEstimated = false; // User's own date, not an estimate
    return current;
  }

  // Post-condition: Updates completedCycleCount and once she has minCyclesToLearn
  /// finished cycles, both averages (mean of ALL finished cycles, rounded to
  /// whole days). Period length ignores periods whose end was only estimated.
  void recalculateProfile(UserProfile profile) {
    final finished = getFinishedCycles(profile);
    profile.completedCycleCount = finished.length;
    if (finished.length < minCyclesToLearn) return;

    profile.averageCycleLength = _roundedToWholeDay(
      finished.map((c) => getCycleLength(c)!).toList(),
    );

    final periodLengths = finished
        .where((c) => getPeriodLength(c) != null && !c.periodEndEstimated)
        .map((c) => getPeriodLength(c)!)
        .toList();
    if (periodLengths.isNotEmpty) {
      profile.averagePeriodLength = _roundedToWholeDay(periodLengths);
    }
  }

  // Lookups

  Cycle? findCycleById(UserProfile profile, String id) {
    for (final c in profile.cycles) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// The cycle that contains date or null
  Cycle? findCycleOnDate(UserProfile profile, DateTime date) {
    for (final c in profile.cycles) {
      if (!dateOnly(date).isBefore(c.startDate) &&
          (c.cycleEndDate == null ||
              !dateOnly(date).isAfter(c.cycleEndDate!))) {
        return c;
      }
    }
    return null;
  }

  /// Bleeding days, counting the first and last day, null while ongoing.
  int? getPeriodLength(Cycle c) => c.periodEndDate == null
      ? null
      : daysBetween(c.startDate, c.periodEndDate!) + 1;

  /// Total days, counting the first and last day, null for the current cycle.
  int? getCycleLength(Cycle c) => c.cycleEndDate == null
      ? null
      : daysBetween(c.startDate, c.cycleEndDate!) + 1;

  /// The cycle with no end date, or null.
  Cycle? getCurrentCycle(UserProfile profile) {
    for (final c in profile.cycles) {
      if (c.isCurrent) return c;
    }
    return null;
  }

  /// Cycles that have ended, oldest first.
  List<Cycle> getFinishedCycles(UserProfile profile) =>
      profile.cycles.where((c) => !c.isCurrent).toList();

  // Day of the cycle (Day 1 of your cycle)
  int getDayOfCycle(Cycle c, DateTime today) =>
      daysBetween(c.startDate, today) + 1;

  // "Day 1 Of Your Period" banner
  int? getDayOfPeriod(Cycle c, DateTime today) {
    // pre-condition: null if the period hasn't start yet

    if (dateOnly(today).isBefore(dateOnly(c.startDate))) {
      return null;
    }

    // null if the period already ended
    if (c.periodEndDate != null &&
        dateOnly(today).isAfter(dateOnly(c.periodEndDate!))) {
      return null;
    }

    return getDayOfCycle(c, today);
  }

  void _addCycle(UserProfile profile, Cycle cycle) {
    profile.cycles.add(cycle);
    profile.cycles.sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  // helper function

  static int _roundedToWholeDay(List<int> values) =>
      (values.reduce((a, b) => a + b) / values.length).round();
}
