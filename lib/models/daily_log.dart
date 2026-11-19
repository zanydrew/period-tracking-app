import 'package:period_tracking_app/models/enums/daily_log_enums.dart';

class DailyLog {
  final String id;
  final String cycleId;
  final DateTime date;

  final FlowLevel? flow;
  final BloodColor? bloodColor;
  final CrampLevel? cramps;
  final Set<Mood> moods;
  final Set<BodySymptom> bodySymptoms;

  bool get isEmpty =>
      flow == null &&
      bloodColor == null &&
      cramps == null &&
      moods.isEmpty &&
      bodySymptoms.isEmpty;

  DailyLog({
    required this.id,
    required this.cycleId,
    required DateTime date,
    this.flow,
    this.bloodColor,
    this.cramps,
    this.moods = const {},
    this.bodySymptoms = const {},
  }) : date = DateTime(date.year, date.month, date.day);

  @override
  String toString() =>
      'DailyLog date: $date, flow: $flow, cramps: $cramps, moods: $moods, '
      'body: $bodySymptoms';
}
