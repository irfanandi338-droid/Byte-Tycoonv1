import '../config/game_config.dart';

/// One owned computer instance. tier is an index into GameConfig.tiers (0..9).
class Computer {
  int id;
  int tier;
  Map<String, int> levels; // cpu, ram, storage, network, cooling, ai

  Computer({
    required this.id,
    required this.tier,
    Map<String, int>? levels,
  }) : levels = levels ?? {'cpu': 1, 'ram': 1, 'storage': 1, 'network': 1, 'cooling': 1, 'ai': 0};

  ComputerTierDef get def => GameConfig.tiers[tier.clamp(0, GameConfig.tiers.length - 1)];

  int level(String k) => (levels[k] ?? 0).clamp(0, GameConfig.upgradeMaxLevel);

  int get totalUpgradeLevels => levels.values.fold(0, (a, b) => a + b);

  double get storageGB {
    final base = def.storageGB;
    final mult = 1.0 + level('storage') * 0.25;
    return base * mult;
  }

  Map<String, dynamic> toJson() => {'id': id, 'tier': tier, 'levels': levels};

  factory Computer.fromJson(Map<String, dynamic> j) {
    final lv = <String, int>{};
    (j['levels'] as Map?)?.forEach((k, v) {
      final n = (v is num) ? v.toInt() : 0;
      lv[k.toString()] = n.clamp(0, GameConfig.upgradeMaxLevel);
    });
    for (final k in ['cpu', 'ram', 'storage', 'network', 'cooling', 'ai']) {
      lv.putIfAbsent(k, () => k == 'ai' ? 0 : 1);
    }
    final t = (j['tier'] is num) ? (j['tier'] as num).toInt() : 0;
    return Computer(id: (j['id'] as num?)?.toInt() ?? 0, tier: t.clamp(0, GameConfig.tiers.length - 1), levels: lv);
  }

  Computer clone() => Computer(id: id, tier: tier, levels: Map<String, int>.from(levels));
}
