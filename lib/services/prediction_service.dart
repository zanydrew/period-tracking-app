// ex: predicted date: 29-10-2025 and actual start date(today): 30-10-2025
// 29-30 = -1
import 'package:period_tracking_app/utils/date_utils.dart';

bool isOverdue(DateTime today) =>
    daysBetween(start, end)(dateOnly(today), dateOnly(predictionStart)) < 0;

int daysLate(DateTime today) {
  if (!isOverdue(today)) return 0;
  return daysBetween(dateOnly(today), dateOnly(predictionStart));
}
