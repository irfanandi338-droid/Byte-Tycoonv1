import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'computer_painter.dart';

class TutorialOverlay {
  static Future<void> show(BuildContext context) {
    final steps = [
      ('STEP 1', 'Your first computer is ready.', 'BASIC COMPUTER  +1/sec', true),
      ('STEP 2', 'Earn coins automatically, even offline.', '', false),
      ('STEP 3', 'Upgrade CPU, RAM, STORAGE, NETWORK, COOLING, AI CORE.', '', false),
      ('STEP 4', 'Buy computers, merge 3 into 1, build your network.', '', false),
      ('STEP 5', 'Research, prestige, become a COMPUTING EMPIRE.', '', false),
    ];
    var index = 0;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final s = steps[index];
          return AlertDialog(
            backgroundColor: AppTheme.panel,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.border)),
            title: Text(s.$1, style: const TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.w900, letterSpacing: 2)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (s.$4)
                  const ComputerVisual(tier: 0, size: 110, reducedAnimation: false),
                Text(s.$2, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
                if (s.$3.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(s.$3, style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('SKIP', style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (index < steps.length - 1) {
                    setState(() => index++);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: Text(index < steps.length - 1 ? 'NEXT' : 'START'),
              ),
            ],
          );
        },
      ),
    );
  }
}
