import 'dart:async';

import 'package:flutter/foundation.dart';

import 'config/game_config.dart';
import 'models/achievement.dart';
import 'models/computer.dart';
import 'models/player.dart';
import 'models/research.dart';
import 'services/audio_service.dart';
import 'services/economy_service.dart';
import 'services/offline_income_service.dart';
import 'services/save_service.dart';
import 'services/vibration_service.dart';

class Statistics {
  Statistics();
  int computersPurchased = 0;
  int computersMerged = 0;
  int upgradesDone = 0;
  int researchCompleted = 0;
  int prestigeCount = 0;
  double highestIncomePerSec = 0;
  double highestComputingPower = 0;
  int totalPlaySeconds = 0;

  Map<String, dynamic> toJson() => {
        'computersPurchased': computersPurchased,
        'computersMerged': computersMerged,
        'upgradesDone': upgradesDone,
        'researchCompleted': researchCompleted,
        'prestigeCount': prestigeCount,
        'highestIncomePerSec': highestIncomePerSec,
        'highestComputingPower': highestComputingPower,
        'totalPlaySeconds': totalPlaySeconds,
      };

  factory Statistics.fromJson(Map<String, dynamic>? j) {
    final s = Statistics();
    if (j == null) return s;
    int i(String k) => j[k] is num ? (j[k] as num).toInt() : 0;
    double d(String k) => j[k] is num ? (j[k] as num).toDouble() : 0;
    s.computersPurchased = i('computersPurchased');
    s.computersMerged = i('computersMerged');
    s.upgradesDone = i('upgradesDone');
    s.researchCompleted = i('researchCompleted');
    s.prestigeCount = i('prestigeCount');
    s.highestIncomePerSec = d('highestIncomePerSec');
    s.highestComputingPower = d('highestComputingPower');
    s.totalPlaySeconds = i('totalPlaySeconds');
    return s;
  }
}

class OfflineReport {
  final int seconds;
  final double coins;
  OfflineReport(this.seconds, this.coins);
}

class SettingsState {
  SettingsState();
  bool sound = true;
  bool music = false;
  bool vibration = true;
  bool reducedAnimation = false;

  Map<String, dynamic> toJson() => {
        'sound': sound, 'music': music, 'vibration': vibration, 'reducedAnimation': reducedAnimation,
      };

  factory SettingsState.fromJson(Map<String, dynamic>? j) {
    final s = SettingsState();
    if (j == null) return s;
    s.sound = j['sound'] != false;
    s.music = j['music'] == true;
    s.vibration = j['vibration'] != false;
    s.reducedAnimation = j['reducedAnimation'] == true;
    return s;
  }
}

/// THE game. Single source of truth. UI only renders and calls intent methods.
class GameState extends ChangeNotifier {
  static final GameState instance = GameState._internal();
  GameState._internal();

  final Player player = Player();
  final List<Computer> computers = [];
  final ResearchState research = ResearchState({});
  final AchievementState achievements = AchievementState({});
  final Statistics stats = Statistics();
  final SettingsState settings = SettingsState();

  int _nextId = 1;
  bool saveDataError = false;
  bool tutorialSeen = false;
  DateTime lastOnlineTime = DateTime.now();
  DateTime lastSaveTime = DateTime.now();
  String? lastDailyClaimDate; // yyyy-mm-dd local
  int dailyStreak = 0; // 1..7, next claim day

  Timer? _ticker;
  DateTime _lastTick = DateTime.now();
  DateTime _lastAutosave = DateTime.now();
  double _rpAccumulator = 0;

  // events for UI (popups)
  final List<String> achievementQueue = [];

  // ---------------- computed ----------------
  int get totalComputers => computers.length;

  double get incomePerSecond => EconomyService.totalIncomePerSecond(
      computers: computers, player: player, researchDone: research.completed);

  double get computingPower => EconomyService.computingPower(computers, research.completed);

  double get energyUsage => EconomyService.energyUsage(computers);

  double get energyCapacity => EconomyService.energyCapacity(computers, player);

  // NOTE: clamp() bounds must both be double here - mixing int/double bounds
  // (e.g. .clamp(0, 9.99)) makes Dart's static return type `num`, which does
  // not compile as the declared `double` return type of this getter.
  double get energyPercent => energyCapacity <= 0 ? 0.0 : (energyUsage / energyCapacity).clamp(0.0, 9.99);

  double get networkMult => EconomyService.networkMultiplier(computers.length);

  bool get overloaded => energyUsage > energyCapacity;

  int ownedOfTier(int tier) => computers.where((c) => c.tier == tier).length;

  double costOfNextComputer(int tier) => EconomyService.computerCost(tier, ownedOfTier(tier));

  bool get canPrestige => EconomyService.canPrestige(player);

  int get quantumPointsOnPrestige => EconomyService.quantumPointsOnPrestige(player);

  int get highestTierOwned {
    var t = -1;
    for (final c in computers) {
      if (c.tier > t) t = c.tier;
    }
    return t;
  }

  bool canMergeTier(int tier) {
    if (tier < 0 || tier >= GameConfig.tiers.length - 1) return false;
    return ownedOfTier(tier) >= GameConfig.mergeRequired;
  }

  /// next daily claim info: (canClaimToday, dayNumber1to7)
  (bool, int) dailyStatus() {
    final now = DateTime.now();
    final today = _dateKey(now);
    final last = lastDailyClaimDate;
    if (last == null) return (true, 1);
    if (last == today) return (false, dailyStreak.clamp(1, 7));
    // yyyy-mm-dd strings compare lexicographically the same as chronologically.
    // If "today" is BEFORE the last claim date, the device clock was rolled
    // backward - block the claim entirely instead of letting the player farm
    // the reward by winding the clock back and forth.
    if (today.compareTo(last) < 0) return (false, dailyStreak.clamp(1, 7));
    final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
    final nextDay = last == yesterday ? (dailyStreak % 7) + 1 : 1;
    return (true, nextDay);
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------------- lifecycle ----------------
  static Future<GameState> load() async {
    final gs = instance;
    final (data, hadError) = await SaveService.loadGame();
    gs.saveDataError = hadError;
    if (data != null) {
      gs._fromJson(SaveService.migrate(data));
    } else {
      gs._freshStart();
    }
    gs.player.validate();
    gs._applySettings();
    return gs;
  }

  void startGameLoop() {
    _ticker?.cancel();
    _lastTick = DateTime.now();
    _ticker = Timer.periodic(Duration(milliseconds: GameConfig.tickMs), (_) => _tick());
  }

  void stopGameLoop() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Called when app resumes (both cold start and coming back from
  /// background). Uses [lastOnlineTime] - a field that survives a full app
  /// restart, unlike the tick loop's [_lastTick] - so real "app was closed
  /// for N hours" offline income actually works. Consumes/refreshes
  /// [lastOnlineTime] immediately so a duplicate call right after grants 0
  /// (no double reward). Applies capped catch-up income and returns a
  /// report if the player was away long enough to deserve a popup.
  OfflineReport? resume() {
    final now = DateTime.now();
    final away = now.difference(lastOnlineTime).inSeconds;
    if (away < 1) return null; // nothing meaningful to catch up on
    final ips = incomePerSecond;
    final res = OfflineIncomeService.compute(lastOnline: lastOnlineTime, now: now, incomePerSecond: ips);
    lastOnlineTime = now; // consumed - prevents double-claiming this window
    if (res.coins > 0) {
      _earn(res.coins);
    }
    if (res.elapsedSeconds >= GameConfig.offlinePopupMinSeconds) {
      saveGame(force: true);
      notifyListeners();
      return OfflineReport(res.elapsedSeconds, res.coins);
    }
    notifyListeners();
    return null;
  }

  void pauseAndSave() {
    lastOnlineTime = DateTime.now();
    saveGame(force: true);
  }

  // ---------------- game loop ----------------
  void _tick() {
    final now = DateTime.now();
    var dt = now.difference(_lastTick).inMilliseconds / 1000.0;
    _lastTick = now;
    if (dt < 0) dt = 0;
    if (dt > GameConfig.offlineMaxSeconds) dt = GameConfig.offlineMaxSeconds.toDouble();

    final gain = incomePerSecond * dt;
    if (gain > 0) _earn(gain);

    stats.totalPlaySeconds += dt.floor();
    _rpAccumulator += dt / 60.0 * GameConfig.rpPerMinute;
    if (_rpAccumulator >= 1) {
      final rp = _rpAccumulator.floor();
      _rpAccumulator -= rp;
      player.researchPoints += rp;
    }

    final lvl = GameConfig.levelFromTotalEarned(player.totalCoinsEarned).toInt();
    if (lvl != player.playerLevel) {
      player.playerLevel = lvl.clamp(1, 99);
    }

    final cp = computingPower;
    if (cp > stats.highestComputingPower) stats.highestComputingPower = cp;
    final ips = incomePerSecond;
    if (ips > stats.highestIncomePerSec) stats.highestIncomePerSec = ips;

    _checkAchievements();

    if (now.difference(_lastAutosave).inSeconds >= GameConfig.autosaveSeconds) {
      _lastAutosave = now;
      saveGame();
    }
    notifyListeners();
  }

  void _earn(double amount) {
    amount = EconomyService.clampVal(amount);
    if (amount <= 0) return;
    player.coins = EconomyService.clampVal(player.coins + amount);
    player.totalCoinsEarned = EconomyService.clampVal(player.totalCoinsEarned + amount);
    player.runCoinsEarned = EconomyService.clampVal(player.runCoinsEarned + amount);
  }

  bool _spend(double amount) {
    amount = EconomyService.clampVal(amount);
    if (amount < 0) return false;
    if (player.coins < amount) return false;
    player.coins -= amount;
    player.totalCoinsSpent = EconomyService.clampVal(player.totalCoinsSpent + amount);
    return true;
  }

  // ---------------- intents (all validated here, never trust UI) ----------------
  bool buyComputer(int tier) {
    if (tier < 0 || tier >= GameConfig.tiers.length) return false;
    final cost = costOfNextComputer(tier);
    if (!_spend(cost)) return false;
    computers.add(Computer(id: _nextId++, tier: tier));
    stats.computersPurchased++;
    AudioService.purchase();
    VibrationService.light();
    saveGame();
    notifyListeners();
    return true;
  }

  bool upgradeComputer(int id, String key) {
    if (!GameConfig.upgrades.containsKey(key)) return false;
    final c = computers.where((x) => x.id == id).cast<Computer?>().firstWhere((x) => true, orElse: () => null);
    if (c == null) return false;
    final lv = c.level(key);
    if (lv >= GameConfig.upgradeMaxLevel) return false;
    // AI core requires AI Processing research
    if (key == 'ai' && !research.isDone('ai_proc')) return false;
    final cost = EconomyService.upgradeCost(GameConfig.upgrades[key]!.baseCost, lv);
    if (!_spend(cost)) return false;
    c.levels[key] = lv + 1;
    stats.upgradesDone++;
    AudioService.upgrade();
    VibrationService.light();
    saveGame();
    notifyListeners();
    return true;
  }

  /// Merge 3 same-tier units into 1 of the next tier.
  /// Units are only removed after the new unit is created successfully.
  bool mergeTier(int tier) {
    if (!canMergeTier(tier)) return false;
    final candidates = computers.where((c) => c.tier == tier).toList();
    if (candidates.length < GameConfig.mergeRequired) return false;
    final picked = candidates.take(GameConfig.mergeRequired).toList();
    // carry over average upgrade levels (floor) so merging is not a downgrade feel
    final merged = Computer(id: _nextId++, tier: tier + 1);
    for (final key in merged.levels.keys) {
      var sum = 0;
      for (final c in picked) {
        sum += c.level(key);
      }
      merged.levels[key] = (sum ~/ GameConfig.mergeRequired).clamp(0, GameConfig.upgradeMaxLevel);
    }
    computers.removeWhere((c) => picked.any((p) => p.id == c.id));
    computers.add(merged);
    stats.computersMerged++;
    AudioService.merge();
    VibrationService.medium();
    saveGame(force: true);
    notifyListeners();
    return true;
  }

  bool doResearch(String id) {
    final def = GameConfig.research.where((r) => r.id == id).toList();
    if (def.isEmpty) return false;
    final r = def.first;
    if (research.isDone(id) || !research.isUnlocked(r)) return false;
    if (player.researchPoints < r.cost) return false;
    player.researchPoints -= r.cost;
    research.completed.add(id);
    stats.researchCompleted++;
    AudioService.achievement();
    VibrationService.medium();
    saveGame(force: true);
    notifyListeners();
    return true;
  }

  bool prestige() {
    if (!EconomyService.canPrestige(player)) return false;
    final qp = EconomyService.quantumPointsOnPrestige(player);
    // reset run
    player.coins = 0;
    player.runCoinsEarned = 0;
    player.quantumPoints += qp;
    player.prestigeCount++;
    stats.prestigeCount++;
    computers.clear();
    computers.add(Computer(id: _nextId++, tier: 0)); // free starter again
    AudioService.prestige();
    VibrationService.heavy();
    saveGame(force: true);
    notifyListeners();
    return true;
  }

  double claimDaily() {
    final (can, day) = dailyStatus();
    if (!can) return 0;
    final reward = EconomyService.dailyRewardForStreak(day);
    _earn(reward);
    lastDailyClaimDate = _dateKey(DateTime.now());
    dailyStreak = day;
    AudioService.coin();
    saveGame(force: true);
    notifyListeners();
    return reward;
  }

  void applySettings() {
    _applySettings();
    saveGame();
    notifyListeners();
  }

  void _applySettings() {
    AudioService.soundOn = settings.sound;
    AudioService.musicOn = settings.music;
    VibrationService.vibrationOn = settings.vibration;
  }

  Future<void> resetGame() async {
    stopGameLoop();
    await SaveService.resetGame();
    _freshStart();
    _applySettings();
    _lastTick = DateTime.now();
    startGameLoop();
    notifyListeners();
  }

  void markTutorialSeen() {
    tutorialSeen = true;
    saveGame();
  }

  // ---------------- achievements ----------------
  void _checkAchievements() {
    for (final a in GameConfig.achievements) {
      if (achievements.isUnlocked(a.id)) continue;
      if (!_achievementCondition(a.id)) continue;
      achievements.unlocked.add(a.id);
      if (a.coinReward > 0) _earn(a.coinReward);
      player.researchPoints += a.rpReward;
      achievementQueue.add(a.name);
      AudioService.achievement();
    }
  }

  bool _achievementCondition(String id) {
    switch (id) {
      case 'first_pc': return computers.isNotEmpty;
      case 'first_upg': return stats.upgradesDone >= 1;
      case 'net_builder': return computers.length >= 10;
      case 'server_farm': return computers.length >= 50;
      case 'data_center': return incomePerSecond >= 100000;
      case 'ai_lord': return highestTierOwned >= 4;
      case 'quantum': return highestTierOwned >= 3;
      case 'global': return incomePerSecond >= 1000000;
      case 'first_merge': return stats.computersMerged >= 1;
      case 'prestige1': return player.prestigeCount >= 1;
      default: return false;
    }
  }

  // ---------------- persistence ----------------
  Map<String, dynamic> toJson() => {
        'saveVersion': GameConfig.saveVersion,
        'player': player.toJson(),
        'computers': computers.map((c) => c.toJson()).toList(),
        'research': research.toJson(),
        'achievements': achievements.toJson(),
        'statistics': stats.toJson(),
        'settings': settings.toJson(),
        'nextId': _nextId,
        'tutorialSeen': tutorialSeen,
        'lastOnlineTime': lastOnlineTime.toIso8601String(),
        'lastSaveTime': DateTime.now().toIso8601String(),
        'lastDailyClaimDate': lastDailyClaimDate,
        'dailyStreak': dailyStreak,
      };

  void _fromJson(Map<String, dynamic> j) {
    final p = Player.fromJson((j['player'] as Map?)?.cast<String, dynamic>() ?? {});
    // copy into singleton
    player.coins = p.coins;
    player.totalCoinsEarned = p.totalCoinsEarned;
    player.totalCoinsSpent = p.totalCoinsSpent;
    player.runCoinsEarned = p.runCoinsEarned;
    player.researchPoints = p.researchPoints;
    player.quantumPoints = p.quantumPoints;
    player.prestigeCount = p.prestigeCount;
    player.playerLevel = p.playerLevel;

    computers.clear();
    final list = (j['computers'] as List?) ?? [];
    for (final c in list) {
      if (c is Map<String, dynamic>) computers.add(Computer.fromJson(c));
    }
    final rs = ResearchState.fromJson((j['research'] as Map?)?.cast<String, dynamic>());
    research.completed.clear();
    research.completed.addAll(rs.completed);
    final ach = AchievementState.fromJson((j['achievements'] as Map?)?.cast<String, dynamic>());
    achievements.unlocked.clear();
    achievements.unlocked.addAll(ach.unlocked);

    final st = Statistics.fromJson((j['statistics'] as Map?)?.cast<String, dynamic>());
    stats.computersPurchased = st.computersPurchased;
    stats.computersMerged = st.computersMerged;
    stats.upgradesDone = st.upgradesDone;
    stats.researchCompleted = st.researchCompleted;
    stats.prestigeCount = st.prestigeCount;
    stats.highestIncomePerSec = st.highestIncomePerSec;
    stats.highestComputingPower = st.highestComputingPower;
    stats.totalPlaySeconds = st.totalPlaySeconds;

    final s = SettingsState.fromJson((j['settings'] as Map?)?.cast<String, dynamic>());
    settings.sound = s.sound;
    settings.music = s.music;
    settings.vibration = s.vibration;
    settings.reducedAnimation = s.reducedAnimation;

    _nextId = (j['nextId'] is num) ? (j['nextId'] as num).toInt() : (computers.isEmpty ? 1 : computers.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1);
    tutorialSeen = j['tutorialSeen'] == true;
    final lot = j['lastOnlineTime'];
    lastOnlineTime = (lot is String) ? (DateTime.tryParse(lot) ?? DateTime.now()) : DateTime.now();
    lastSaveTime = DateTime.now();
    lastDailyClaimDate = j['lastDailyClaimDate'] as String?;
    dailyStreak = (j['dailyStreak'] is num) ? (j['dailyStreak'] as num).toInt() : 0;
  }

  void _freshStart() {
    player.coins = GameConfig.startCoins;
    player.totalCoinsEarned = 0;
    player.totalCoinsSpent = 0;
    player.runCoinsEarned = 0;
    player.researchPoints = 0;
    player.quantumPoints = 0;
    player.prestigeCount = 0;
    player.playerLevel = 1;
    computers.clear();
    computers.add(Computer(id: 1, tier: 0));
    _nextId = 2;
    research.completed.clear();
    achievements.unlocked.clear();
    tutorialSeen = false;
    lastDailyClaimDate = null;
    dailyStreak = 0;
    saveDataError = false;
    lastOnlineTime = DateTime.now(); // no bogus offline income right after a fresh start
  }

  DateTime _lastSaveWrite = DateTime.fromMillisecondsSinceEpoch(0);

  /// Persists the game. Does NOT touch [lastOnlineTime] - that field is only
  /// ever set by [pauseAndSave] (when the app actually leaves foreground) and
  /// consumed by [resume]; touching it here would make every autosave/action
  /// erase the timestamp needed to compute real offline time later.
  /// [force] bypasses the light throttle (used for pause and other
  /// must-not-be-skipped saves); regular action/autosave calls are throttled
  /// to avoid redundant disk writes if actions fire in rapid succession.
  void saveGame({bool force = false}) {
    final now = DateTime.now();
    if (!force && now.difference(_lastSaveWrite).inMilliseconds < 400) return;
    _lastSaveWrite = now;
    lastSaveTime = now;
    SaveService.saveGame(toJson()); // fire and forget; validated on load
  }
}
