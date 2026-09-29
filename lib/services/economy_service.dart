import 'dart:math' as math;

import '../config/game_config.dart';
import '../models/computer.dart';
import '../models/player.dart';

/// EconomyManager - THE single source of truth for every formula in the game.
/// UI files must never contain balance math.
class EconomyService {
  EconomyService._();

  // ---------- safety ----------
  static double clampVal(double v) {
    if (v.isNaN || v.isInfinite || v < 0) return 0;
    return v > GameConfig.maxValue ? GameConfig.maxValue : v;
  }

  // ---------- costs ----------
  static double computerCost(int tierIndex, int ownedOfTier) {
    final def = GameConfig.tiers[tierIndex.clamp(0, GameConfig.tiers.length - 1)];
    if (tierIndex == 0 && ownedOfTier == 0) return 0; // first basic computer is free
    final c = def.cost * math.pow(GameConfig.computerCostGrowth, math.max(0, ownedOfTier - (tierIndex == 0 ? 1 : 0)));
    return clampVal(c);
  }

  static double upgradeCost(double baseCost, int level) {
    final c = baseCost * math.pow(GameConfig.upgradeGrowth, math.max(0, level));
    return clampVal(c);
  }

  // ---------- multipliers ----------
  static double prestigeMult(Player p) => 1.0 + p.quantumPoints * GameConfig.prestigePerQP;

  static double researchIncomeMult(Set<String> done) {
    var m = 1.0;
    for (final r in GameConfig.research) {
      if (done.contains(r.id)) m += r.incomeMult;
    }
    return m;
  }

  static double researchPowerMult(Set<String> done) {
    var m = 1.0;
    for (final r in GameConfig.research) {
      if (done.contains(r.id)) m += r.powerMult;
    }
    return m;
  }

  static double networkMultiplier(int totalComputers) {
    var mult = 1.0;
    for (final b in GameConfig.networkBrackets) {
      if (totalComputers >= b[0]) mult = b[1];
    }
    return mult;
  }

  // ---------- energy ----------
  static double energyUsage(List<Computer> computers) {
    var u = 0.0;
    for (final c in computers) {
      var e = c.def.energy.toDouble();
      e *= 1.0 - c.level('cooling') * GameConfig.coolingEnergyReduction;
      u += math.max(0.1, e);
    }
    return u;
  }

  static double energyCapacity(List<Computer> computers, Player p) {
    var cap = GameConfig.baseEnergyCapacity;
    for (final c in computers) {
      cap += c.level('cooling') * GameConfig.energyCapacityPerCoolingLevel;
    }
    cap += p.prestigeCount * GameConfig.energyCapacityPerPrestige;
    return cap;
  }

  /// 1.0 when fine, scales down (min 0.25) when overloaded. Cooling raises capacity.
  static double energyEfficiency(List<Computer> computers, Player p) {
    final use = energyUsage(computers);
    final cap = energyCapacity(computers, p);
    if (use <= cap || use <= 0) return 1.0;
    final eff = cap / use;
    return eff < GameConfig.minEnergyEfficiency ? GameConfig.minEnergyEfficiency : eff;
  }

  // ---------- income ----------
  static double computerIncome(Computer c) {
    final def = c.def;
    var upg = 1.0;
    for (final e in GameConfig.upgrades.entries) {
      upg += c.level(e.key) * e.value.incomePerLevel;
    }
    return clampVal(def.income * upg);
  }

  static double totalIncomePerSecond({
    required List<Computer> computers,
    required Player player,
    required Set<String> researchDone,
  }) {
    var base = 0.0;
    for (final c in computers) {
      base += computerIncome(c);
    }
    final m = networkMultiplier(computers.length) *
        prestigeMult(player) *
        researchIncomeMult(researchDone) *
        energyEfficiency(computers, player);
    return clampVal(base * m);
  }

  static double computingPower(List<Computer> computers, Set<String> researchDone) {
    var p = 0.0;
    for (final c in computers) {
      var mult = 1.0;
      for (final e in GameConfig.upgrades.entries) {
        mult += c.level(e.key) * e.value.powerPerLevel;
      }
      p += c.def.power * mult;
    }
    return clampVal(p * researchPowerMult(researchDone));
  }

  // ---------- offline ----------
  static double offlineIncome(double incomePerSecond, int elapsedSeconds) {
    final capped = elapsedSeconds.clamp(0, GameConfig.offlineMaxSeconds);
    return clampVal(incomePerSecond * capped);
  }

  // ---------- prestige ----------
  static bool canPrestige(Player p) => p.runCoinsEarned >= GameConfig.prestigeRequirement;

  static int quantumPointsOnPrestige(Player p) {
    final base = p.runCoinsEarned / GameConfig.prestigeRequirement;
    return math.max(1, base.floor());
  }

  // ---------- daily reward ----------
  static double dailyRewardForStreak(int streakDay1to7) {
    final i = (streakDay1to7 - 1).clamp(0, GameConfig.dailyRewards.length - 1);
    return GameConfig.dailyRewards[i];
  }

  // ---------- formatting ----------
  /// Scientific-notation fallback so any value stays readable, correct and
  /// bounded all the way up to [GameConfig.maxValue] (1e100), instead of a
  /// named-unit list running out and printing a long raw number.
  static String _scientific(double v) {
    if (v <= 0) return '0.00e0';
    var exp = (math.log(v) / math.ln10).floor();
    var mantissa = v / math.pow(10, exp);
    // floating-point log() is not exact for round powers of 10, so the
    // mantissa can land just outside the canonical [1, 10) range in either
    // direction - normalize it instead of printing e.g. "10.00e5"/"0.10e7".
    if (mantissa >= 10) {
      mantissa /= 10;
      exp += 1;
    } else if (mantissa < 1) {
      mantissa *= 10;
      exp -= 1;
    }
    return '${mantissa.toStringAsFixed(2)}e$exp';
  }

  static String format(double v) {
    if (v.isNaN || v.isInfinite) return '0';
    if (v < 0) v = 0;
    if (v < 1000) {
      final s = v < 10 ? v.toStringAsFixed(1) : v.toStringAsFixed(0);
      return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
    }
    const units = ['', 'K', 'M', 'B', 'T', 'Qa', 'Qi', 'Sx', 'Sp', 'Oc', 'No', 'Dc'];
    // Beyond the last named unit (10^36) fall back to scientific notation so
    // values up to the 1e100 cap still print as a short, readable number.
    if (v >= 1e36) return _scientific(v);
    var i = 0;
    var x = v;
    while (x >= 1000 && i < units.length - 1) {
      x /= 1000;
      i++;
    }
    return '${x.toStringAsFixed(2)}${units[i]}';
  }

  /// Computing power formatter: H/s -> KH/s ... EH/s, then scientific H/s
  /// beyond the named range (same reasoning as [format]).
  static String formatHash(double h) {
    if (h.isNaN || h.isInfinite || h < 0) h = 0;
    const units = ['H/s', 'KH/s', 'MH/s', 'GH/s', 'TH/s', 'PH/s', 'EH/s'];
    if (h >= 1e21) return '${_scientific(h)} H/s';
    var i = 0;
    var x = h;
    while (x >= 1000 && i < units.length - 1) {
      x /= 1000;
      i++;
    }
    return '${x.toStringAsFixed(2)} ${units[i]}';
  }

  static String formatDuration(int seconds) {
    final s = seconds.clamp(0, 999999999);
    final d = s ~/ 86400;
    final h = (s % 86400) ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (d > 0) return '${d}d ${h}h ${m}m';
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}m ${(s % 60).toString().padLeft(2, '0')}s';
  }
}
