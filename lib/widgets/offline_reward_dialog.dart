import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/economy_service.dart';
import '../theme/app_theme.dart';

class OfflineRewardDialog {
  static Future<void> show(BuildContext context, int seconds, double coins) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.cyan)),
        title: const Center(child: Text('WELCOME BACK!', style: TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.w900, letterSpacing: 2))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You were offline for:', style: TextStyle(color: AppTheme.textSecondary)),
            Text(EconomyService.formatDuration(seconds),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text('+${EconomyService.format(coins)} COINS',
                style: const TextStyle(color: AppTheme.gold, fontSize: 20, fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              AudioService.coin();
              Navigator.of(context).pop();
            },
            child: const Text('COLLECT'),
          ),
        ],
      ),
    );
  }
}
