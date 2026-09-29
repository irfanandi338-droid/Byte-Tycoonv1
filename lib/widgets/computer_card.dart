import 'package:flutter/material.dart';

import '../config/game_config.dart';
import '../game_state.dart';
import '../models/computer.dart';
import '../services/economy_service.dart';
import '../theme/app_theme.dart';
import 'computer_painter.dart';
import 'upgrade_button.dart';

class ComputerCard extends StatelessWidget {
  final Computer computer;
  final int index;

  const ComputerCard({super.key, required this.computer, required this.index});

  @override
  Widget build(BuildContext context) {
    final gs = GameState.instance;
    final def = computer.def;
    final accent = Color(def.colorHex);
    final income = EconomyService.computerIncome(computer);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ComputerVisual(tier: computer.tier, size: 64, reducedAnimation: gs.settings.reducedAnimation),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${def.name} #${index.toString().padLeft(2, '0')}',
                          style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 14)),
                      Text('+${EconomyService.format(income)}/sec base',
                          style: const TextStyle(color: AppTheme.green, fontSize: 12)),
                      Text('${EconomyService.format(computer.storageGB)} GB',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final key in GameConfig.upgrades.keys)
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 66) / 3,
                    child: UpgradeButton(
                      label: '${GameConfig.upgrades[key]!.label} LV.${computer.level(key)}',
                      cost: EconomyService.upgradeCost(GameConfig.upgrades[key]!.baseCost, computer.level(key)),
                      affordable: gs.player.coins >=
                          EconomyService.upgradeCost(GameConfig.upgrades[key]!.baseCost, computer.level(key)),
                      enabled: computer.level(key) < GameConfig.upgradeMaxLevel &&
                          (key != 'ai' || gs.research.isDone('ai_proc')),
                      onPressed: () => gs.upgradeComputer(computer.id, key),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
