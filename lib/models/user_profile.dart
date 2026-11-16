class UserProfile {
  final String id;
  final String name;

  // Onboarding answer at first, replaced by the average when calculated in CycleService
  final int averageCycleLength;
  final int averagePeriodLength;

  // Number of finished cycles since she started using the app (could be use later for compute average)
  final int completedCycleCount;

  // "Remind me if my period is late".
  final bool lateReminderEnabled;

  // false = show the onboarding screens, true = go to Home.
  final bool onboardingCompleted;

  // minimun cycle count used for compute average
  static const int minCycleToLearn = 2;

  bool get usesLearnedAverages => completedCycleCount >= minCycleToLearn;

  UserProfile({
    required this.id,
    required this.name,
    required this.averageCycleLength,
    required this.averagePeriodLength,
    this.completedCycleCount = 0,
    this.lateReminderEnabled = true,
    this.onboardingCompleted = false,
  });
}
