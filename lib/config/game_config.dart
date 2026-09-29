/// BYTE TYCOON - central game balance configuration.
/// NEVER hardcode balance numbers in widgets. Change values here.
library;

import 'dart:math' as math;

class GameConfig {
  GameConfig._();

  // ---------- SAVE ----------
  static const int saveVersion = 1;

  // ---------- ECONOMY SAFETY ----------
  static const double maxValue = 1e100; // hard cap for any currency
  static const double startCoins = 0;

  // ---------- OFFLINE ----------
  static const int offlineMaxHours = 8;
  static int get offlineMaxSeconds => offlineMaxHours * 3600;
  /// minimum seconds away before the "WELCOME BACK" popup appears
  static const int offlinePopupMinSeconds = 60;

  // ---------- GAME LOOP ----------
  static const int tickMs = 250;          // UI/income tick
  static const int autosaveSeconds = 10;  // periodic autosave interval

  // ---------- PRESTIGE ----------
  static const double prestigeRequirement = 1000000; // total coins earned (current run)
  static const double prestigePerQP = 0.05;          // +5% permanent income per QP

  // ---------- RESEARCH POINTS ----------
  static const double rpPerMinute = 1.0; // passive RP from play time

  // ---------- PLAYER LEVEL ----------
  static double levelFromTotalEarned(double t) =>
      1 + (t <= 0 ? 0 : math.sqrt(t / 50).floor()).clamp(0, 98).toDouble();

  // ---------- COMPUTER TIERS ----------
  static const List<ComputerTierDef> tiers = [
    ComputerTierDef(name: 'BASIC COMPUTER',        cost: 15,      income: 1,       power: 10,    storageGB: 20,    energy: 1,   colorHex: 0xFFE53935),
    ComputerTierDef(name: 'ENHANCED COMPUTER',     cost: 100,     income: 3,       power: 25,    storageGB: 50,    energy: 2,   colorHex: 0xFFFDD835),
    ComputerTierDef(name: 'ADVANCED SERVER',       cost: 500,     income: 10,      power: 100,   storageGB: 250,   energy: 5,   colorHex: 0xFF1E88E5),
    ComputerTierDef(name: 'QUANTUM COMPUTER',      cost: 2500,    income: 40,      power: 500,   storageGB: 1024,  energy: 10,  colorHex: 0xFF8E24AA),
    ComputerTierDef(name: 'AI SERVER',             cost: 15000,   income: 150,     power: 2000,  storageGB: 5120,  energy: 20,  colorHex: 0xFF00BCD4),
    ComputerTierDef(name: 'AI DATA CENTER',        cost: 100000,  income: 750,     power: 9000,  storageGB: 20480, energy: 100, colorHex: 0xFF26C6DA),
    ComputerTierDef(name: 'MEGA DATA CENTER',      cost: 750000,  income: 4000,    power: 40000, storageGB: 102400,energy: 400, colorHex: 0xFF5E35B1),
    ComputerTierDef(name: 'QUANTUM CLOUD',         cost: 5000000, income: 25000,   power: 180000,storageGB: 512000,energy: 1200,colorHex: 0xFF7E57C2),
    ComputerTierDef(name: 'AI NETWORK',            cost: 40000000,income: 150000,  power: 900000,storageGB: 2048000,energy: 3600,colorHex: 0xFF26A69A),
    ComputerTierDef(name: 'GLOBAL COMPUTING EMPIRE',cost: 300000000,income: 1000000,power: 4000000,storageGB: 10240000,energy: 9000,colorHex: 0xFFEC407A),
  ];

  /// cost of next unit of a tier = baseCost * growth^ownedOfTier (tier 1 is free only for the very first)
  static const double computerCostGrowth = 1.15;

  // ---------- UPGRADES ----------
  static const double upgradeGrowth = 1.15; // cost = base * growth^level
  static const int upgradeMaxLevel = 100;
  static const Map<String, UpgradeDef> upgrades = {
    'cpu':     UpgradeDef(label: 'CPU',      baseCost: 25,    incomePerLevel: 0.10, powerPerLevel: 0.10),
    'ram':     UpgradeDef(label: 'RAM',      baseCost: 40,    incomePerLevel: 0.05, powerPerLevel: 0.06),
    'storage': UpgradeDef(label: 'STORAGE',  baseCost: 30,    incomePerLevel: 0.05, powerPerLevel: 0.02),
    'network': UpgradeDef(label: 'NETWORK',  baseCost: 60,    incomePerLevel: 0.05, powerPerLevel: 0.04),
    'cooling': UpgradeDef(label: 'COOLING',  baseCost: 50,    incomePerLevel: 0.00, powerPerLevel: 0.00),
    'ai':      UpgradeDef(label: 'AI CORE',  baseCost: 500,   incomePerLevel: 0.20, powerPerLevel: 0.25),
  };
  static const double coolingEnergyReduction = 0.02; // -2% energy usage per cooling level

  // ---------- ENERGY ----------
  static const double baseEnergyCapacity = 50;
  static const double energyCapacityPerCoolingLevel = 5;
  static const double energyCapacityPerPrestige = 25;
  static const double minEnergyEfficiency = 0.25; // income floor when overloaded

  // ---------- NETWORK ----------
  /// (minComputers, multiplier) - highest reached bracket applies
  static const List<List<double>> networkBrackets = [
    [1, 1.00],
    [3, 1.15],
    [5, 1.30],
    [10, 1.75],
    [25, 2.50],
    [50, 4.00],
  ];

  // ---------- MERGE ----------
  static const int mergeRequired = 3;

  // ---------- RESEARCH ----------
  static const List<ResearchDef> research = [
    ResearchDef(id: 'cpu_opt',   name: 'CPU OPTIMIZATION',     cost: 5,   requires: null,        incomeMult: 0.10),
    ResearchDef(id: 'parallel',  name: 'PARALLEL COMPUTING',   cost: 15,  requires: 'cpu_opt',   incomeMult: 0.00, powerMult: 0.20),
    ResearchDef(id: 'ai_proc',   name: 'AI PROCESSING',        cost: 40,  requires: 'parallel',  incomeMult: 0.25),
    ResearchDef(id: 'neural',    name: 'NEURAL NETWORK',       cost: 100, requires: 'ai_proc',   incomeMult: 0.50),
    ResearchDef(id: 'quantum_r', name: 'QUANTUM COMPUTING',    cost: 250, requires: 'neural',    incomeMult: 1.00),
  ];

  // ---------- ACHIEVEMENTS ----------
  static const List<AchievementDef> achievements = [
    AchievementDef(id: 'first_pc',    name: 'FIRST COMPUTER',  desc: 'Own your first computer.',        coinReward: 50,    rpReward: 1),
    AchievementDef(id: 'first_upg',   name: 'FIRST UPGRADE',   desc: 'Upgrade any computer once.',      coinReward: 100,   rpReward: 1),
    AchievementDef(id: 'net_builder', name: 'NETWORK BUILDER', desc: 'Own 10 computers.',               coinReward: 1000,  rpReward: 3),
    AchievementDef(id: 'server_farm', name: 'SERVER FARM',     desc: 'Own 50 computers.',               coinReward: 25000, rpReward: 10),
    AchievementDef(id: 'data_center', name: 'DATA CENTER',     desc: 'Reach 100K coins/sec income.',    coinReward: 100000,rpReward: 15),
    AchievementDef(id: 'ai_lord',     name: 'AI LORD',         desc: 'Own an AI SERVER.',               coinReward: 50000, rpReward: 10),
    AchievementDef(id: 'quantum',     name: 'QUANTUM',         desc: 'Own a QUANTUM COMPUTER.',         coinReward: 10000, rpReward: 8),
    AchievementDef(id: 'global',      name: 'GLOBAL EMPIRE',   desc: 'Reach 1M coins/sec income.',      coinReward: 1000000,rpReward: 50),
    AchievementDef(id: 'first_merge', name: 'ALCHEMIST',       desc: 'Merge 3 computers into 1.',       coinReward: 500,   rpReward: 3),
    AchievementDef(id: 'prestige1',   name: 'REBIRTH',         desc: 'Prestige once.',                  coinReward: 0,     rpReward: 25),
  ];

  // ---------- DAILY REWARD ----------
  static const List<double> dailyRewards = [100, 250, 500, 1000, 2500, 5000, 10000];

  // ---------- MISC ----------
  static const double buyIncomeConfirmThreshold = 1e12; // (reserved for future)
}

class ComputerTierDef {
  final String name;
  final double cost;
  final double income;
  final double power;
  final double storageGB;
  final double energy;
  final int colorHex;
  const ComputerTierDef({
    required this.name,
    required this.cost,
    required this.income,
    required this.power,
    required this.storageGB,
    required this.energy,
    required this.colorHex,
  });
}

class UpgradeDef {
  final String label;
  final double baseCost;
  final double incomePerLevel;
  final double powerPerLevel;
  const UpgradeDef({
    required this.label,
    required this.baseCost,
    required this.incomePerLevel,
    required this.powerPerLevel,
  });
}

class ResearchDef {
  final String id;
  final String name;
  final int cost;
  final String? requires;
  final double incomeMult; // +X% global income
  final double powerMult;  // +X% computing power
  const ResearchDef({
    required this.id,
    required this.name,
    required this.cost,
    required this.requires,
    this.incomeMult = 0,
    this.powerMult = 0,
  });
}

class AchievementDef {
  final String id;
  final String name;
  final String desc;
  final double coinReward;
  final int rpReward;
  const AchievementDef({
    required this.id,
    required this.name,
    required this.desc,
    required this.coinReward,
    required this.rpReward,
  });
}
