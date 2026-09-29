import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/game_config.dart';
import '../game_state.dart';
import '../theme/app_theme.dart';

/// Network topology view: computers connected to a central CORE with
/// light packets travelling along the links (disabled in reduced animation).
class NetworkView extends StatefulWidget {
  final double height;

  const NetworkView({super.key, this.height = 320});

  @override
  State<NetworkView> createState() => _NetworkViewState();
}

class _NetworkViewState extends State<NetworkView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    final reduced = GameState.instance.settings.reducedAnimation;
    if (!reduced) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = GameState.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([gs, _controller]),
      builder: (context, _) {
        final reduced = gs.settings.reducedAnimation;
        if (!reduced && !_controller.isAnimating) _controller.repeat();
        if (reduced && _controller.isAnimating) _controller.stop();
        return SizedBox(
          height: widget.height,
          child: CustomPaint(
            size: Size(MediaQuery.of(context).size.width, widget.height),
            painter: _NetworkPainter(
              tierCounts: _tierCounts(gs),
              progress: _controller.value,
              reduced: reduced,
            ),
          ),
        );
      },
    );
  }

  List<int> _tierCounts(GameState gs) {
    final counts = List<int>.filled(GameConfig.tiers.length, 0);
    for (final c in gs.computers) {
      counts[c.tier]++;
    }
    return counts;
  }
}

class _NetworkPainter extends CustomPainter {
  final List<int> tierCounts;
  final double progress;
  final bool reduced;

  _NetworkPainter({required this.tierCounts, required this.progress, required this.reduced});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final linePaint = Paint()
      ..color = AppTheme.border
      ..strokeWidth = 1.4;
    final packetPaint = Paint()..color = AppTheme.cyan;

    // gather up to 16 nodes around the core (visual cap for low-end phones)
    final nodes = <Offset>[];
    var idx = 0;
    for (var t = 0; t < tierCounts.length && nodes.length < 16; t++) {
      final color = Color(GameConfig.tiers[t].colorHex);
      for (var i = 0; i < tierCounts[t] && nodes.length < 16; i++) {
        final angle = (idx / 16) * math.pi * 2 - math.pi / 2;
        final radius = math.min(size.width, size.height) * 0.38;
        final pos = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius * 0.8);
        nodes.add(pos);

        // link
        canvas.drawLine(center, pos, linePaint);

        // moving packet along link
        if (!reduced) {
          final p = center + (pos - center) * ((progress + idx * 0.13) % 1.0);
          canvas.drawCircle(p, 2.2, packetPaint);
        }

        // node
        canvas.drawCircle(pos, 9, Paint()..color = color.withValues(alpha: 0.25));
        canvas.drawCircle(pos, 5.5, Paint()..color = color);
        idx++;
      }
    }

    // core
    canvas.drawCircle(center, 26, Paint()..color = AppTheme.cyan.withValues(alpha: 0.15));
    canvas.drawCircle(center, 18, Paint()..color = AppTheme.panelLight);
    canvas.drawCircle(center, 18, Paint()..color = AppTheme.cyan..style = PaintingStyle.stroke..strokeWidth = 1.6);
    final tp = TextPainter(
      text: const TextSpan(text: 'CORE', style: TextStyle(color: AppTheme.cyan, fontSize: 9, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_NetworkPainter old) =>
      old.progress != progress || old.reduced != reduced || !listEquals(old.tierCounts, tierCounts);

  static bool listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
