import 'package:flutter/material.dart';

import '../config/game_config.dart';
import '../game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/resource_bar.dart';

class ResearchScreen extends StatelessWidget {
  const ResearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = GameState.instance;
    return SafeArea(
      child: Column(
        children: [
          const ResourceBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  decoration: AppTheme.panelDecoration(),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('RESEARCH POINTS', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900)),
                      Text('${gs.player.researchPoints.toInt()} RP',
                          style: const TextStyle(color: AppTheme.cyan, fontSize: 20, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (final r in GameConfig.research)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ResearchNode(def: r, gs: gs),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResearchNode extends StatelessWidget {
  final ResearchDef def;
  final GameState gs;

  const _ResearchNode({required this.def, required this.gs});

  @override
  Widget build(BuildContext context) {
    final done = gs.research.isDone(def.id);
    final unlocked = gs.research.isUnlocked(def);
    final affordable = gs.player.researchPoints >= def.cost;
    final effect = <String>[
      if (def.incomeMult > 0) '+${(def.incomeMult * 100).toInt()}% income',
      if (def.powerMult > 0) '+${(def.powerMult * 100).toInt()}% computing power',
    ].join('   ');

    return Container(
      decoration: AppTheme.panelDecoration(accent: done ? AppTheme.green : (unlocked ? AppTheme.cyan : AppTheme.border)),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : (unlocked ? Icons.science : Icons.lock),
              color: done ? AppTheme.green : (unlocked ? AppTheme.cyan : AppTheme.textSecondary)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(def.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 13)),
                Text(effect, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                if (!unlocked && def.requires != null)
                  Text('Requires ${GameConfig.research.firstWhere((x) => x.id == def.requires).name}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          SizedBox(
            width: 90,
            height: 38,
            child: ElevatedButton(
              onPressed: (!done && unlocked && affordable) ? () => gs.doResearch(def.id) : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(90, 38),
                padding: EdgeInsets.zero,
                disabledBackgroundColor: AppTheme.panelLight,
                disabledForegroundColor: AppTheme.textSecondary,
                textStyle: const TextStyle(fontSize: 11),
              ),
              child: Text(done ? 'DONE' : '${def.cost} RP'),
            ),
          ),
        ],
      ),
    );
  }
}
