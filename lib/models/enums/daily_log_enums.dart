enum FlowLevel { spotting, little, medium, large, heavy }

enum BloodColor { lightRed, brightRed, darkRed, brown, black }

enum CrampLevel {
  none,
  rarely,
  slightly,
  very,
  extremely;

  /// 0-4, used for pain charts and averages.
  int get score => index;
}

enum Mood {
  calm,
  happy,
  energetic,
  tired,
  apathetic,
  irritated,
  sad,
  depressed,
}

enum BodySymptom { headache, dizziness, pimples, musclePain, itching }
