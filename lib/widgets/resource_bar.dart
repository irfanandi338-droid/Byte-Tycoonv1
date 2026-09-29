import 'package:flutter/material.dart';

import '../game_state.dart';
import '../services/economy_service.dart';
import '../theme/app_theme.dart';

class ResourceBar extends StatelessWidget {
  const ResourceBar({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = GameState.instance;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.panel,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    EconomyService.format(gs.player.coins),
                    style: const TextStyle(color: AppTheme.gold, fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  '+${EconomyService.format(gs.incomePerSecond)} / sec',
                  style: const TextStyle(color: AppTheme.green, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          _res(Icons.science, '${gs.player.researchPoints.toInt()}', AppTheme.cyan, 'RP'),
          const SizedBox(width: 10),
          _res(Icons.bolt, '${(gs.energyPercent * 100).toStringAsFixed(0)}%', gs.overloaded ? AppTheme.red : AppTheme.gold, 'ENERGY'),
          const SizedBox(width: 10),
          _res(Icons.memory, EconomyService.formatHash(gs.computingPower).split(' ').first, AppTheme.purple,
              EconomyService.formatHash(gs.computingPower).split(' ')[1]),
        ],
      ),
    );
  }

  Widget _res(IconData icon, String value, Color color, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8)),
      ],
    );
  }
}
