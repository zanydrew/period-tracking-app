import 'package:period_tracking_app/models/cycle.dart';

class UserProfile {
  final String id;
  final String name;
  final List<Cycle> cycles = [];

  // Onboarding answer at first, replaced by the average when calculated in CycleService
  int averageCycleLength;
  int averagePeriodLength;

  // Number of finished cycles since she started using the app (could be use later for compute average)
  int completedCycleCount;

  // "Remind me if my period is late".
  bool lateReminderEnabled;

  // false = show the onboarding screens, true = go to Home.
  bool onboardingCompleted;

  UserProfile({
    required this.id,
    required this.name,
    required this.averageCycleLength,
    required this.averagePeriodLength,
    this.completedCycleCount = 0,
    this.lateReminderEnabled = true,
    this.onboardingCompleted = false,
  });

  @override
  String toString() =>
      'UserProfile id: $id, name: $name, cycle: $averageCycleLength, '
      'period: $averagePeriodLength, cycles: ${cycles.length}';
}
