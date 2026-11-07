import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/buno_tokens.dart';

/// The charge ring (components.md "Progress → Circular"): starts at
/// 12 o'clock and runs clockwise with round caps, on a `--color-card` track,
/// with a soft glow of [color] (Buno green by default) around the whole ring.
class BunoChargeRing extends StatelessWidget {
  const BunoChargeRing({
    super.key,
    required this.progress,
    required this.size,
    this.strokeWidth = 14,
    this.color = BunoColors.primary,
    this.child,
  });

  /// 0..1 of the full circle.
  final double progress;
  final double size;
  final double strokeWidth;

  /// Arc and glow colour.
  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(progress: progress.clamp(0, 1), stroke: strokeWidth, color: color),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.stroke, required this.color});

  final double progress;
  final double stroke;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - stroke) / 2,
    );

    // Glow: the full ring, blurred, under everything.
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = BunoDark.card,
    );
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.stroke != stroke || old.color != color;
}
