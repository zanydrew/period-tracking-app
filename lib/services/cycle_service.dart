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
