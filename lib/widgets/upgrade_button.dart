import 'package:flutter/material.dart';

import '../services/economy_service.dart';
import '../theme/app_theme.dart';

class UpgradeButton extends StatelessWidget {
  final String label;
  final double cost;
  final bool affordable;
  final bool enabled;
  final VoidCallback? onPressed;

  const UpgradeButton({
    super.key,
    required this.label,
    required this.cost,
    required this.affordable,
    this.enabled = true,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: (enabled && affordable) ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: affordable && enabled ? AppTheme.cyan : AppTheme.panelLight,
          foregroundColor: affordable && enabled ? Colors.black : AppTheme.textSecondary,
          minimumSize: const Size.fromHeight(46),
          padding: EdgeInsets.zero,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        // Two short lines scaled down to fit: never clips or overflows, even
        // on 320px-wide screens with long labels like "STORAGE LV.100".
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$label\n${EconomyService.format(cost)}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
