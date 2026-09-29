import '../config/game_config.dart';

class AchievementState {
  final Set<String> unlocked;

  AchievementState(this.unlocked);

  bool isUnlocked(String id) => unlocked.contains(id);
  int get unlockedCount => unlocked.length;
  int get totalCount => GameConfig.achievements.length;

  Map<String, dynamic> toJson() => {'unlocked': unlocked.toList()};

  factory AchievementState.fromJson(Map<String, dynamic>? j) {
    final set = <String>{};
    (j?['unlocked'] as List?)?.forEach((e) => set.add(e.toString()));
    return AchievementState(set);
  }
}
