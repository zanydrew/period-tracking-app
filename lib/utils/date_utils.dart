// helper function
// since DateTime take all the hour, day, month, year, so calculation could be incorrect for some cases.
// so take only the day, month and year is more accurate

// Normalize DateTime to calendar date.

DateTime dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

int daysBetween(DateTime start, DateTime end) {
  return dateOnly(end).difference(dateOnly(start)).inDays;
}
