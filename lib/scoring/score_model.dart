import '../rhythm/judgment.dart';

class ScoreModel {
  int score = 0;
  int perfect = 0;
  int great = 0;
  int good = 0;
  int miss = 0;
  int maxCombo = 0;
  int currentCombo = 0;
  double multiplier = 1.0;

  int get totalJudged => perfect + great + good + miss;

  double get accuracy {
    if (totalJudged == 0) return 1.0;
    final w = perfect * 1.0 + great * 0.7 + good * 0.3;
    return w / totalJudged;
  }

  String get grade {
    final a = accuracy;
    if (miss == 0 && great == 0 && good == 0 && perfect > 0) return 'SS';
    if (a >= 0.98) return 'S';
    if (a >= 0.90) return 'A';
    if (a >= 0.80) return 'B';
    if (a >= 0.70) return 'C';
    return 'D';
  }

  void apply(Judgment j, {required int comboBefore}) {
    switch (j) {
      case Judgment.perfect:
        perfect++;
        currentCombo = comboBefore + 1;
        break;
      case Judgment.great:
        great++;
        currentCombo = comboBefore + 1;
        break;
      case Judgment.good:
        good++;
        currentCombo = comboBefore + 1;
        break;
      case Judgment.miss:
        miss++;
        currentCombo = 0;
        break;
      case Judgment.none:
        return;
    }
    if (currentCombo > maxCombo) maxCombo = currentCombo;
    multiplier = 1.0 + (currentCombo ~/ 10) * 0.1;
    if (multiplier > 4.0) multiplier = 4.0;
    score += (j.scoreBase * multiplier).round();
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'perfect': perfect,
        'great': great,
        'good': good,
        'miss': miss,
        'maxCombo': maxCombo,
        'accuracy': accuracy,
        'grade': grade,
      };
}
