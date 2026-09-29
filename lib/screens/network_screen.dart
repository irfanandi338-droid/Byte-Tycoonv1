import 'package:flutter/material.dart';

import '../config/game_config.dart';
import '../game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/network_view.dart';
import '../widgets/resource_bar.dart';

class NetworkScreen extends StatelessWidget {
  const NetworkScreen({super.key});

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
                  child: Column(
                    children: [
                      Text('x${gs.networkMult.toStringAsFixed(2)}',
                          style: const TextStyle(color: AppTheme.cyan, fontSize: 40, fontWeight: FontWeight.w900)),
                      const Text('NETWORK MULTIPLIER', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 2)),
                      const SizedBox(height: 8),
                      const NetworkView(height: 300),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: AppTheme.panelDecoration(),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BRACKETS', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      for (final b in GameConfig.networkBrackets)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${b[0].toInt()} computers',
                                  style: TextStyle(
                                      color: gs.totalComputers >= b[0] ? AppTheme.cyan : AppTheme.textSecondary, fontSize: 12)),
                              Text('x${b[1].toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color: gs.totalComputers >= b[0] ? AppTheme.cyan : AppTheme.textSecondary,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: AppTheme.panelDecoration(accent: gs.overloaded ? AppTheme.red : AppTheme.border),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ENERGY GRID', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: gs.energyPercent.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: AppTheme.panelLight,
                        valueColor: AlwaysStoppedAnimation(gs.overloaded ? AppTheme.red : AppTheme.gold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'USAGE ${gs.energyUsage.toStringAsFixed(1)} / CAP ${gs.energyCapacity.toStringAsFixed(0)}'
                        '${gs.overloaded ? '  - INCOME REDUCED (upgrade COOLING)' : ''}',
                        style: TextStyle(color: gs.overloaded ? AppTheme.red : AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
