import 'package:flutter/material.dart';

import '../game_state.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = GameState.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: AnimatedBuilder(
        animation: gs,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _toggle(gs, 'Sound', gs.settings.sound, (v) => gs.settings.sound = v),
            _toggle(gs, 'Music', gs.settings.music, (v) => gs.settings.music = v),
            _toggle(gs, 'Vibration', gs.settings.vibration, (v) => gs.settings.vibration = v),
            _toggle(gs, 'Reduced Animation', gs.settings.reducedAnimation, (v) => gs.settings.reducedAnimation = v),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => _confirmResetStage1(context, gs),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.red, side: const BorderSide(color: AppTheme.red)),
              child: const Text('RESET GAME'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle(GameState gs, String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.panelDecoration(),
      child: SwitchListTile(
        title: Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
        value: value,
        activeTrackColor: AppTheme.cyan.withValues(alpha: 0.5),
        activeThumbColor: AppTheme.cyan,
        onChanged: (v) {
          onChanged(v);
          gs.applySettings();
        },
      ),
    );
  }

  Future<void> _confirmResetStage1(BuildContext context, GameState gs) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.panel,
        title: const Text('DELETE ALL PROGRESS?', style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.w900)),
        content: const Text('This cannot be undone.', style: TextStyle(color: AppTheme.textPrimary)),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red, foregroundColor: Colors.white),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await _confirmResetStage2(context, gs);
    }
  }

  Future<void> _confirmResetStage2(BuildContext context, GameState gs) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.panel,
        title: const Text('ARE YOU ABSOLUTELY SURE?', style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.w900)),
        content: const Text('Every coin, computer and research point will be erased forever.',
            style: TextStyle(color: AppTheme.textPrimary)),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red, foregroundColor: Colors.white),
            child: const Text('DELETE FOREVER'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await gs.resetGame();
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}
