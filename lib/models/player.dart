/// Core player/currency data. All values validated (no NaN / negative / Infinity).
class Player {
  double coins;
  double totalCoinsEarned;   // lifetime
  double totalCoinsSpent;    // lifetime
  double runCoinsEarned;     // since last prestige (prestige requirement)
  double researchPoints;
  int quantumPoints;
  int prestigeCount;
  int playerLevel;

  Player({
    this.coins = 0,
    this.totalCoinsEarned = 0,
    this.totalCoinsSpent = 0,
    this.runCoinsEarned = 0,
    this.researchPoints = 0,
    this.quantumPoints = 0,
    this.prestigeCount = 0,
    this.playerLevel = 1,
  });

  /// Sanitize against corrupt saves / cheating UI. Game logic is the source of truth.
  void validate({double max = 1e100}) {
    double fix(double v) {
      if (v.isNaN || v.isInfinite || v < 0) return 0;
      return v > max ? max : v;
    }
    coins = fix(coins);
    totalCoinsEarned = fix(totalCoinsEarned);
    totalCoinsSpent = fix(totalCoinsSpent);
    runCoinsEarned = fix(runCoinsEarned);
    researchPoints = fix(researchPoints);
    if (researchPoints < 0) researchPoints = 0;
    if (quantumPoints < 0 || quantumPoints > 1000000) quantumPoints = quantumPoints.clamp(0, 1000000);
    if (prestigeCount < 0) prestigeCount = 0;
    if (playerLevel < 1) playerLevel = 1;
    if (playerLevel > 99) playerLevel = 99;
  }

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'totalCoinsEarned': totalCoinsEarned,
        'totalCoinsSpent': totalCoinsSpent,
        'runCoinsEarned': runCoinsEarned,
        'researchPoints': researchPoints,
        'quantumPoints': quantumPoints,
        'prestigeCount': prestigeCount,
        'playerLevel': playerLevel,
      };

  factory Player.fromJson(Map<String, dynamic> j) {
    double d(String k) {
      final v = j[k];
      if (v is num) return v.toDouble();
      return 0;
    }
    int i(String k) {
      final v = j[k];
      if (v is num) return v.toInt();
      return 0;
    }
    return Player(
      coins: d('coins'),
      totalCoinsEarned: d('totalCoinsEarned'),
      totalCoinsSpent: d('totalCoinsSpent'),
      runCoinsEarned: d('runCoinsEarned'),
      researchPoints: d('researchPoints'),
      quantumPoints: i('quantumPoints'),
      prestigeCount: i('prestigeCount'),
      playerLevel: i('playerLevel'),
    );
  }
}
