import 'package:flutter/material.dart';

import '../config/game_config.dart';
import '../game_state.dart';
import '../services/audio_service.dart';
import '../services/economy_service.dart';
import '../theme/app_theme.dart';
import '../widgets/resource_bar.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = GameState.instance;
    final s = gs.stats;
    return SafeArea(
      child: Column(
        children: [
          const ResourceBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  decoration: AppTheme.panelDecoration(accent: AppTheme.cyan),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.person, color: AppTheme.cyan, size: 48),
                      const Text('PLAYER', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, letterSpacing: 3)),
                      const SizedBox(height: 8),
                      _row('Level', '${gs.player.playerLevel}'),
                      _row('Total Coins Earned', EconomyService.format(gs.player.totalCoinsEarned)),
                      _row('Total Computers', '${gs.totalComputers}'),
                      _row('Computing Power', EconomyService.formatHash(gs.computingPower)),
                      _row('Prestige', '${gs.player.prestigeCount}'),
                      _row('Quantum Points',
                          '${gs.player.quantumPoints} (+${(gs.player.quantumPoints * GameConfig.prestigePerQP * 100).toStringAsFixed(0)}%)'),
                      _row('Achievements', '${gs.achievements.unlockedCount}/${gs.achievements.totalCount}'),
                      _row('Play Time', EconomyService.formatDuration(s.totalPlaySeconds)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _prestigeCard(context, gs),
                const SizedBox(height: 12),
                _dailyCard(context, gs),
                const SizedBox(height: 12),
                Container(
                  decoration: AppTheme.panelDecoration(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('STATISTICS', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      _row('Total Coins Spent', EconomyService.format(gs.player.totalCoinsSpent)),
                      _row('Computers Purchased', '${s.computersPurchased}'),
                      _row('Computers Merged', '${s.computersMerged}'),
                      _row('Upgrades', '${s.upgradesDone}'),
                      _row('Research Completed', '${s.researchCompleted}'),
                      _row('Prestige Count', '${s.prestigeCount}'),
                      _row('Highest Income/sec', EconomyService.format(s.highestIncomePerSec)),
                      _row('Highest Computing Power', EconomyService.formatHash(s.highestComputingPower)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  child: const Text('SETTINGS'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _prestigeCard(BuildContext context, GameState gs) {
    final ready = gs.canPrestige;
    return Container(
      decoration: AppTheme.panelDecoration(accent: ready ? AppTheme.purple : AppTheme.border),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('PRESTIGE', style: TextStyle(color: AppTheme.purple, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(
            'Requirement: ${EconomyService.format(GameConfig.prestigeRequirement)} earned this run\n'
            'Progress: ${EconomyService.format(gs.player.runCoinsEarned)}\n'
            'Reward: ${gs.quantumPointsOnPrestige} Quantum Points (+5% permanent income each)',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: ready ? () => _confirmPrestige(context, gs) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ready ? AppTheme.purple : AppTheme.panelLight,
                foregroundColor: ready ? Colors.white : AppTheme.textSecondary,
              ),
              child: const Text('PRESTIGE'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPrestige(BuildContext context, GameState gs) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.panel,
        title: const Text('PRESTIGE?', style: TextStyle(color: AppTheme.purple, fontWeight: FontWeight.w900)),
        content: const Text(
          'Coins and computers will RESET.\nYou keep research, achievements and gain QUANTUM POINTS (+5% income each, permanent).',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.purple, foregroundColor: Colors.white),
            child: const Text('PRESTIGE'),
          ),
        ],
      ),
    );
    if (ok == true) {
      gs.prestige();
    }
  }

  Widget _dailyCard(BuildContext context, GameState gs) {
    final (can, day) = gs.dailyStatus();
    return Container(
      decoration: AppTheme.panelDecoration(accent: can ? AppTheme.gold : AppTheme.border),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('DAILY REWARD', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w900, letterSpacing: 2)),
          Text('Day $day / 7 - ${EconomyService.format(EconomyService.dailyRewardForStreak(day))} coins',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: can
                  ? () {
                      final r = gs.claimDaily();
                      if (r > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Daily reward: +${EconomyService.format(r)} coins')));
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: can ? AppTheme.gold : AppTheme.panelLight,
                foregroundColor: can ? Colors.black : AppTheme.textSecondary,
              ),
              child: Text(can ? 'CLAIM' : 'CLAIMED TODAY'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          Text(v, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
