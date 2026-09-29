import '../config/game_config.dart';
import '../services/economy_service.dart';

/// Static helper wrapper so UI can ask upgrade questions without knowing formulas.
class UpgradeInfo {
  final String key;
  final String label;
  final int level;
  final double cost;
  final double incomePerLevel;

  UpgradeInfo({
    required this.key,
    required this.label,
    required this.level,
    required this.cost,
    required this.incomePerLevel,
  });

  static UpgradeInfo of(String key, int level) {
    final def = GameConfig.upgrades[key]!;
    return UpgradeInfo(
      key: key,
      label: def.label,
      level: level,
      cost: EconomyService.upgradeCost(def.baseCost, level),
      incomePerLevel: def.incomePerLevel,
    );
  }
}
