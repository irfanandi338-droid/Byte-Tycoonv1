import 'package:flutter/material.dart';

import '../config/game_config.dart';
import '../game_state.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/computer_card.dart';
import '../widgets/resource_bar.dart';

class ComputersScreen extends StatelessWidget {
  const ComputersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = GameState.instance;
    return SafeArea(
      child: Column(
        children: [
          const ResourceBar(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: gs.computers.length + 1,
              itemBuilder: (context, i) {
                if (i == gs.computers.length) {
                  return _mergeSection(context, gs);
                }
                final c = gs.computers[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ComputerCard(computer: c, index: i + 1),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _mergeSection(BuildContext context, GameState gs) {
    final mergeable = <int>[];
    for (var t = 0; t < GameConfig.tiers.length - 1; t++) {
      if (gs.canMergeTier(t)) mergeable.add(t);
    }
    if (mergeable.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('MERGE: own 3 computers of the same tier to merge them into the next tier.',
              textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ),
      );
    }
    return Container(
      decoration: AppTheme.panelDecoration(accent: AppTheme.purple),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MERGE', style: TextStyle(color: AppTheme.purple, fontWeight: FontWeight.w900, letterSpacing: 2)),
          for (final t in mergeable)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _confirmMerge(context, gs, t),
                  child: Text('3x ${GameConfig.tiers[t].name} -> 1x ${GameConfig.tiers[t + 1].name}'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmMerge(BuildContext context, GameState gs, int tier) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.panel,
        title: const Text('MERGE COMPUTERS?', style: TextStyle(color: AppTheme.purple, fontWeight: FontWeight.w900)),
        content: Text(
          '3x ${GameConfig.tiers[tier].name}\n-> 1x ${GameConfig.tiers[tier + 1].name}',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.purple, foregroundColor: Colors.white),
            child: const Text('MERGE'),
          ),
        ],
      ),
    );
    if (ok == true) {
      AudioService.merge();
      gs.mergeTier(tier);
    }
  }
}
