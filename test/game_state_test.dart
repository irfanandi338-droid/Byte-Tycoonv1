import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:byte_tycoon/config/game_config.dart';
import 'package:byte_tycoon/game_state.dart';
import 'package:byte_tycoon/models/computer.dart';
import 'package:byte_tycoon/services/audio_service.dart';
import 'package:byte_tycoon/services/vibration_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Keep platform plugins (audioplayers/haptics) out of pure logic tests.
    AudioService.soundOn = false;
    VibrationService.vibrationOn = false;
    // GameState.saveGame() is fire-and-forget; give it a working (mocked)
    // SharedPreferences backend so those background calls never throw.
    SharedPreferences.setMockInitialValues({});
  });

  late GameState gs;

  setUp(() {
    gs = GameState.instance;
    // GameState.instance is a true singleton, so reset it to a known,
    // fresh-start-equivalent state before every test to avoid leaking state
    // between tests.
    gs.player.coins = 0;
    gs.player.totalCoinsEarned = 0;
    gs.player.totalCoinsSpent = 0;
    gs.player.runCoinsEarned = 0;
    gs.player.researchPoints = 0;
    gs.player.quantumPoints = 0;
    gs.player.prestigeCount = 0;
    gs.player.playerLevel = 1;
    gs.computers
      ..clear()
      ..add(Computer(id: 1, tier: 0));
    gs.research.completed.clear();
    gs.achievements.unlocked.clear();
    gs.achievementQueue.clear();
    gs.lastDailyClaimDate = null;
    gs.dailyStreak = 0;
    gs.lastOnlineTime = DateTime.now();
  });

  group('merge', () {
    test('3 same-tier computers merge atomically into 1 of the next tier', () {
      gs.computers
        ..clear()
        ..addAll([
          Computer(id: 1, tier: 0, levels: {'cpu': 4, 'ram': 2, 'storage': 1, 'network': 1, 'cooling': 1, 'ai': 0}),
          Computer(id: 2, tier: 0, levels: {'cpu': 2, 'ram': 2, 'storage': 1, 'network': 1, 'cooling': 1, 'ai': 0}),
          Computer(id: 3, tier: 0, levels: {'cpu': 3, 'ram': 2, 'storage': 1, 'network': 1, 'cooling': 1, 'ai': 0}),
        ]);
      final mergedBefore = gs.stats.computersMerged;

      final ok = gs.mergeTier(0);

      expect(ok, true);
      // 3 units gone, 1 new unit created -> never a state where units are
      // lost without the replacement (or vice versa).
      expect(gs.computers.length, 1);
      expect(gs.computers.single.tier, 1);
      expect(gs.computers.single.level('cpu'), 3); // (4+2+3)/3 floored
      expect(gs.stats.computersMerged, mergedBefore + 1);
    });

    test('cannot merge with fewer than 3 of the same tier', () {
      gs.computers
        ..clear()
        ..addAll([Computer(id: 1, tier: 0), Computer(id: 2, tier: 0)]);
      expect(gs.mergeTier(0), false);
      expect(gs.computers.length, 2);
    });

    test('cannot merge the highest tier (no next tier exists)', () {
      final lastTier = GameConfig.tiers.length - 1;
      gs.computers
        ..clear()
        ..addAll(List.generate(3, (i) => Computer(id: i + 1, tier: lastTier)));
      expect(gs.canMergeTier(lastTier), false);
      expect(gs.mergeTier(lastTier), false);
      expect(gs.computers.length, 3);
    });
  });

  group('prestige', () {
    test('cannot prestige below the requirement', () {
      gs.player.runCoinsEarned = GameConfig.prestigeRequirement - 1;
      expect(gs.prestige(), false);
    });

    test('prestige resets the run but keeps quantum points and grants a fresh starter', () {
      gs.player.coins = 500000;
      gs.player.runCoinsEarned = GameConfig.prestigeRequirement * 2; // -> 2 QP
      gs.computers
        ..clear()
        ..addAll([Computer(id: 1, tier: 3), Computer(id: 2, tier: 4)]);

      final ok = gs.prestige();

      expect(ok, true);
      expect(gs.player.coins, 0);
      expect(gs.player.runCoinsEarned, 0);
      expect(gs.player.quantumPoints, 2);
      expect(gs.player.prestigeCount, 1);
      expect(gs.computers.length, 1);
      expect(gs.computers.single.tier, 0);
    });
  });

  group('daily reward', () {
    test('can claim once, then blocked for the rest of the same day', () {
      final first = gs.claimDaily();
      expect(first, greaterThan(0));
      final second = gs.claimDaily();
      expect(second, 0);
    });

    test('regression: rolling the clock backward must NOT unlock another claim', () {
      expect(gs.claimDaily(), greaterThan(0)); // claims "today"
      // Simulate the device clock having been wound back relative to the
      // stored claim date: pretend the last claim is "tomorrow" from now's
      // point of view (equivalent to the user having turned the clock back).
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      gs.lastDailyClaimDate = '${tomorrow.year.toString().padLeft(4, '0')}-'
          '${tomorrow.month.toString().padLeft(2, '0')}-'
          '${tomorrow.day.toString().padLeft(2, '0')}';
      final (can, _) = gs.dailyStatus();
      expect(can, false);
      expect(gs.claimDaily(), 0);
    });
  });

  group('offline income (GameState.resume - cold start / background return)', () {
    test('real close-and-reopen (5h away) grants the correctly-sized reward', () {
      gs.lastOnlineTime = DateTime.now().subtract(const Duration(hours: 5));
      final report = gs.resume();
      expect(report, isNotNull);
      expect(report!.seconds, closeTo(5 * 3600, 5));
      expect(report.coins, greaterThan(0));
    });

    test('capped at 8 hours even if away much longer', () {
      gs.lastOnlineTime = DateTime.now().subtract(const Duration(hours: 30));
      final report = gs.resume();
      expect(report, isNotNull);
      expect(report!.seconds, GameConfig.offlineMaxSeconds);
    });

    test('regression: calling resume() twice in a row must NOT double-grant the reward', () {
      gs.lastOnlineTime = DateTime.now().subtract(const Duration(hours: 5));
      final first = gs.resume();
      expect(first, isNotNull);
      final second = gs.resume(); // e.g. a duplicate lifecycle callback
      expect(second, isNull);
    });
  });
}
