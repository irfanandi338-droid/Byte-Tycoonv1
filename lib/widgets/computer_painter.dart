import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/game_config.dart';

/// Original vector-style computer/server drawn with CustomPainter.
/// No bitmap assets -> tiny APK. LEDs animate via [pulse] 0..1.
class ComputerPainter extends CustomPainter {
  final int tier;
  final double pulse; // 0..1 animation phase
  final bool reducedAnimation;

  ComputerPainter({required this.tier, required this.pulse, this.reducedAnimation = false});

  @override
  void paint(Canvas canvas, Size size) {
    final def = GameConfig.tiers[tier.clamp(0, GameConfig.tiers.length - 1)];
    final accent = Color(def.colorHex);
    final w = size.width;
    final h = size.height;
    final isDataCenter = tier >= 5;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.12, w * 0.64, h * 0.76),
      Radius.circular(w * 0.06),
    );

    // soft glow (light)
    if (!reducedAnimation) {
      final glow = Paint()
        ..color = accent.withValues(alpha: 0.12 + 0.06 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawRRect(body, glow);
    }

    // chassis
    final chassis = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF2A3550), const Color(0xFF141C2E)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(body, chassis);
    canvas.drawRRect(body, Paint()..color = accent..style = PaintingStyle.stroke..strokeWidth = 1.6);

    // heatsink fins
    final finPaint = Paint()..color = Colors.white.withValues(alpha: 0.10);
    for (var i = 0; i < 5; i++) {
      final y = h * 0.20 + i * h * 0.075;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.26, y, w * 0.28, h * 0.035), Radius.circular(2)),
        finPaint,
      );
    }

    // motherboard / server detail
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.26, h * 0.60, w * 0.48, h * 0.20), Radius.circular(4)),
      Paint()..color = accent.withValues(alpha: 0.15),
    );
    final chip = Paint()..color = accent.withValues(alpha: 0.85);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.36, h * 0.64, w * 0.12, h * 0.10), Radius.circular(2)),
      chip,
    );
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(Rect.fromLTWH(w * 0.54 + i * w * 0.06, h * 0.66, w * 0.03, h * 0.03), chip);
    }

    // ports
    for (var i = 0; i < (isDataCenter ? 4 : 2); i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.60, h * (0.22 + i * 0.075), w * 0.10, h * 0.04), Radius.circular(1.5)),
        Paint()..color = const Color(0xFF0A0E18),
      );
    }

    // animated LEDs
    final ledOn = Paint()..color = accent;
    final ledOff = Paint()..color = accent.withValues(alpha: 0.25);
    for (var i = 0; i < 3; i++) {
      final phase = reducedAnimation ? 0.9 : (math.sin(pulse * math.pi * 2 + i * 1.7) + 1) / 2;
      final on = phase > 0.45;
      canvas.drawCircle(Offset(w * (0.30 + i * 0.07), h * 0.88), w * 0.018, on ? ledOn : ledOff);
    }

    // power button LED (tier color identity, clearly visible)
    canvas.drawCircle(Offset(w * 0.70, h * 0.88), w * 0.024, ledOn);
  }

  @override
  bool shouldRepaint(ComputerPainter old) =>
      old.tier != tier || old.pulse != pulse || old.reducedAnimation != reducedAnimation;
}

/// Stateful wrapper that drives the LED pulse only while visible.
class ComputerVisual extends StatefulWidget {
  final int tier;
  final double size;
  final bool reducedAnimation;

  const ComputerVisual({super.key, required this.tier, this.size = 120, required this.reducedAnimation});

  @override
  State<ComputerVisual> createState() => _ComputerVisualState();
}

class _ComputerVisualState extends State<ComputerVisual> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    if (!widget.reducedAnimation) _controller.repeat();
  }

  @override
  void didUpdateWidget(ComputerVisual old) {
    super.didUpdateWidget(old);
    if (widget.reducedAnimation && _controller.isAnimating) {
      _controller.stop();
    } else if (!widget.reducedAnimation && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: ComputerPainter(
          tier: widget.tier,
          pulse: _controller.value,
          reducedAnimation: widget.reducedAnimation,
        ),
      ),
    );
  }
}
