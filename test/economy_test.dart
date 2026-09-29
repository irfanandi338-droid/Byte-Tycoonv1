import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:byte_tycoon/config/game_config.dart';
import 'package:byte_tycoon/models/computer.dart';
import 'package:byte_tycoon/models/player.dart';
import 'package:byte_tycoon/services/economy_service.dart';
import 'package:byte_tycoon/services/offline_income_service.dart';

void main() {
  group('income calculation', () {
    test('one basic computer = 1/sec before multipliers', () {
      final c = Computer(id: 1, tier: 0);
      // levels start at 1 -> cpu +10%, ram +5%, storage +5%, network +5% = 1.25x tier income
      expect(EconomyService.computerIncome(c), closeTo(1.25, 0.001));
    });

    test('network multiplier brackets', () {
      expect(EconomyService.networkMultiplier(1), 1.00);
      expect(EconomyService.networkMultiplier(3), 1.15);
      expect(EconomyService.networkMultiplier(10), 1.75);
      expect(EconomyService.networkMultiplier(50), 4.00);
      expect(EconomyService.networkMultiplier(999), 4.00);
    });

    test('quantum points boost income', () {
      final p = Player()..quantumPoints = 2; // +10%
      final p0 = Player();
      final computers = [Computer(id: 1, tier: 0)];
      final i2 = EconomyService.totalIncomePerSecond(computers: computers, player: p, researchDone: {});
      final i0 = EconomyService.totalIncomePerSecond(computers: computers, player: p0, researchDone: {});
      expect(i2 / i0, closeTo(1.10, 0.001));
    });

    test('energy overload reduces income but never below floor', () {
      final computers = <Computer>[];
      for (var i = 0; i < 200; i++) {
        computers.add(Computer(id: i, tier: 9)); // 9000 energy each
      }
      final eff = EconomyService.energyEfficiency(computers, Player());
      expect(eff, greaterThan(0));
      expect(eff, greaterThanOrEqualTo(GameConfig.minEnergyEfficiency));
      expect(eff, lessThan(1.0));
    });
  });

  group('upgrade cost', () {
    test('cost = base * 1.15^level', () {
      expect(EconomyService.upgradeCost(25, 0), closeTo(25, 0.001));
      expect(EconomyService.upgradeCost(25, 1), closeTo(28.75, 0.001));
      expect(EconomyService.upgradeCost(25, 10), closeTo(25 * math.pow(1.15, 10), 0.01));
    });
  });

  group('purchase cost', () {
    test('first basic computer is free', () {
      expect(EconomyService.computerCost(0, 0), 0);
    });
    test('cost grows with owned units', () {
      expect(EconomyService.computerCost(1, 0), closeTo(100, 0.001));
      expect(EconomyService.computerCost(1, 1), closeTo(100 * 1.15, 0.001));
    });
    test('regression: 2nd+ BASIC COMPUTER must NOT be free (was an infinite-money exploit)', () {
      // Only the very first basic computer (ownedOfTier == 0) is free.
      expect(EconomyService.computerCost(0, 1), greaterThan(0));
      expect(EconomyService.computerCost(0, 2), greaterThan(EconomyService.computerCost(0, 1)));
    });
  });

  group('merge rule', () {
    test('merge requirement is 3 of same tier and next tier must exist', () {
      expect(GameConfig.mergeRequired, 3);
      // tier 10 (index 9) is last -> can never merge
      expect(GameConfig.tiers.length - 1, 9);
    });
  });

  group('research', () {
    test('research multipliers accumulate', () {
      final m = EconomyService.researchIncomeMult({'cpu_opt', 'ai_proc'});
      expect(m, closeTo(1.35, 0.001));
    });
  });

  group('prestige', () {
    test('cannot prestige below requirement', () {
      final p = Player()..runCoinsEarned = 999999;
      expect(EconomyService.canPrestige(p), false);
      p.runCoinsEarned = 1000000;
      expect(EconomyService.canPrestige(p), true);
      expect(EconomyService.quantumPointsOnPrestige(p), 1);
      p.runCoinsEarned = 5500000;
      expect(EconomyService.quantumPointsOnPrestige(p), 5);
    });
  });

  group('offline income', () {
    test('income = ips * seconds', () {
      final r = OfflineIncomeService.compute(
        lastOnline: DateTime(2026, 1, 1, 22, 0),
        now: DateTime(2026, 1, 2, 3, 0),
        incomePerSecond: 125,
      );
      expect(r.elapsedSeconds, 5 * 3600);
      expect(r.coins, closeTo(125 * 5 * 3600, 0.1)); // 2,250,000
    });

    test('capped at 8 hours', () {
      final r = OfflineIncomeService.compute(
        lastOnline: DateTime(2026, 1, 1),
        now: DateTime(2026, 1, 10),
        incomePerSecond: 10,
      );
      expect(r.elapsedSeconds, GameConfig.offlineMaxSeconds);
      expect(r.coins, closeTo(10 * GameConfig.offlineMaxSeconds, 0.1));
    });

    test('clock going backwards gives 0, no crash', () {
      final r = OfflineIncomeService.compute(
        lastOnline: DateTime(2026, 1, 2),
        now: DateTime(2026, 1, 1),
        incomePerSecond: 10,
      );
      expect(r.coins, 0);
    });
  });

  group('daily reward', () {
    test('streak cycles through config values', () {
      expect(EconomyService.dailyRewardForStreak(1), 100);
      expect(EconomyService.dailyRewardForStreak(7), 10000);
      expect(EconomyService.dailyRewardForStreak(99), 10000); // clamped
    });
  });

  group('number safety & formatting', () {
    test('clamp kills NaN, Infinity, negatives', () {
      expect(EconomyService.clampVal(double.nan), 0);
      expect(EconomyService.clampVal(double.infinity), 0);
      expect(EconomyService.clampVal(-5), 0);
      expect(EconomyService.clampVal(double.maxFinite), GameConfig.maxValue);
    });

    test('formatting big numbers', () {
      expect(EconomyService.format(1000), '1.00K');
      expect(EconomyService.format(1250000), '1.25M');
      expect(EconomyService.format(2400000000), '2.40B');
      expect(EconomyService.format(5800000000000), '5.80T');
    });

    test('hash rate formatting', () {
      // 1820 H/s = 1.82 KH/s (crosses the first 1000 threshold once).
      expect(EconomyService.formatHash(1820), contains('KH/s'));
      expect(EconomyService.formatHash(10), contains('H/s'));
      // TH/s requires crossing 4 thresholds of 1000 (H->K->M->G->T).
      expect(EconomyService.formatHash(2.5e12), contains('TH/s'));
    });

    test('formatting stays readable far beyond the named unit list (up to 1e100 cap)', () {
      // Named units only go up to Dc (10^33); beyond ~1e36 it must fall back
      // to short scientific notation instead of a long raw number.
      final s = EconomyService.format(1e50);
      expect(s.length, lessThan(12));
      expect(s, contains('e'));
      final capped = EconomyService.format(GameConfig.maxValue);
      expect(capped.length, lessThan(12));
    });

    test('player validate repairs corrupt data', () {
      final p = Player()
        ..coins = double.nan
        ..quantumPoints = -3
        ..playerLevel = -10;
      p.validate();
      expect(p.coins, 0);
      expect(p.quantumPoints, 0);
      expect(p.playerLevel, 1);
    });
  });

  group('save/load roundtrip (json)', () {
    test('computer json roundtrip keeps tier and levels valid', () {
      final c = Computer(id: 7, tier: 2, levels: {'cpu': 3, 'ram': 2, 'storage': 1, 'network': 1, 'cooling': 1, 'ai': 0});
      final back = Computer.fromJson(c.toJson());
      expect(back.id, 7);
      expect(back.tier, 2);
      expect(back.level('cpu'), 3);
      // corrupt tier gets clamped, never crashes
      final bad = Computer.fromJson({'id': 1, 'tier': 999, 'levels': {'cpu': -5}});
      expect(bad.tier, GameConfig.tiers.length - 1);
      expect(bad.level('cpu'), 0);
    });
  });
}
