// Shared helpers for all service tests.

import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracking_app/models/user_profile.dart';
import 'package:period_tracking_app/services/cycle_service.dart';

/// "Today" for every test. It has a time of day on purpose, to prove that the services only look at the calendar date.
final DateTime fixedToday = DateTime(2025, 11, 20, 15, 30);

/// A CycleService with a fixed clock and predictable ids (id-0, id-1, ...).
CycleService buildCycleService() {
  var counter = 0;
  return CycleService(clock: () => fixedToday, newId: () => 'id-${counter++}');
}

/// A profile that finished onboarding (one current cycle that started on lastPeriodStart.
UserProfile onboardedProfile(
  CycleService service, {
  DateTime? lastPeriodStart,
  int periodLength = 5,
  int cycleLength = 28,
}) {
  return service.completeOnboarding(
    name: 'Niza',
    lastPeriodStart: lastPeriodStart ?? DateTime(2025, 11, 1),
    periodLength: periodLength,
    cycleLength: cycleLength,
  );
}

// use for help not repested throw message at fail cases
Matcher throwsMessage(String text) => throwsA(
  predicate(
    (Object e) => e.toString().contains(text),
    'error message contains "$text"',
  ),
);
