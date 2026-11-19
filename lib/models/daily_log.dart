import 'package:period_tracking_app/models/enums/daily_log_enums.dart';

class DailyLog {
  // no need id cus every daily log is already store inside a cycle so no need an id to link back to its cycle
  // The date is its identifier
  final DateTime date;

  final FlowLevel? flow;
  final BloodColor? bloodColor;
  final CrampLevel? cramps;
  final Set<Mood>? moods;
  final Set<BodySymptom>? bodySymptoms;

  bool get isEmpty =>
      flow == null &&
      bloodColor == null &&
      cramps == null &&
      moods!.isEmpty &&
      bodySymptoms!.isEmpty;

  DailyLog({
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
