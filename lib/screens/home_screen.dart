import 'package:flutter/material.dart';

import '../config/game_config.dart';
import '../game_state.dart';
import '../services/audio_service.dart';
import '../services/economy_service.dart';
import '../theme/app_theme.dart';
import '../widgets/computer_painter.dart';
import '../widgets/network_view.dart';
import '../widgets/resource_bar.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onGoToComputers;

  const HomeScreen({super.key, required this.onGoToComputers});

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
                _mainComputer(context, gs),
                const SizedBox(height: 16),
                _buySection(context, gs),
                const SizedBox(height: 16),
                _networkSection(gs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mainComputer(BuildContext context, GameState gs) {
    final top = gs.highestTierOwned >= 0 ? gs.highestTierOwned : 0;
    final def = GameConfig.tiers[top];
    return Container(
      decoration: AppTheme.panelDecoration(accent: Color(def.colorHex).withValues(alpha: 0.6)),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ComputerVisual(tier: top, size: 140, reducedAnimation: gs.settings.reducedAnimation),
          const SizedBox(height: 8),
          Text(def.name, style: TextStyle(color: Color(def.colorHex), fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          Text('+${EconomyService.format(gs.incomePerSecond)} / sec',
              style: const TextStyle(color: AppTheme.green, fontSize: 16, fontWeight: FontWeight.w800)),
          Text('NETWORK x${gs.networkMult.toStringAsFixed(2)}   ${gs.overloaded ? 'OVERLOADED!' : 'ENERGY OK'}',
              style: TextStyle(color: gs.overloaded ? AppTheme.red : AppTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                AudioService.click();
                onGoToComputers();
              },
              child: const Text('UPGRADE'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buySection(BuildContext context, GameState gs) {
    final maxShow = (gs.highestTierOwned + 3).clamp(0, GameConfig.tiers.length - 1);
    return Container(
      decoration: AppTheme.panelDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BUY COMPUTER', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 8),
          for (var t = 0; t <= maxShow; t++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: Color(GameConfig.tiers[t].colorHex), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(GameConfig.tiers[t].name,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  Text('+${EconomyService.format(GameConfig.tiers[t].income)}/s',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: gs.player.coins >= gs.costOfNextComputer(t)
                          ? () {
                              if (!gs.buyComputer(t)) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough coins')));
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(110, 36),
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(fontSize: 11),
                        disabledBackgroundColor: AppTheme.panelLight,
                        disabledForegroundColor: AppTheme.textSecondary,
                      ),
                      child: Text(gs.costOfNextComputer(t) == 0 ? 'FREE' : EconomyService.format(gs.costOfNextComputer(t))),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _networkSection(GameState gs) {
    return Container(
      decoration: AppTheme.panelDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NETWORK', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, letterSpacing: 1)),
          Text('${gs.totalComputers} nodes   multiplier x${gs.networkMult.toStringAsFixed(2)}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          const NetworkView(height: 240),
        ],
      ),
    );
  }
}
