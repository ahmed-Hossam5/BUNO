import 'package:flutter/widgets.dart';

import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import 'buno_lottie_icon.dart';

/// Favourite heart. [on]: the animated `heart` (filled, green), which plays
/// whenever [playKey] changes. Off: an outline, so it never reads as saved.
class BunoHeart extends StatelessWidget {
  const BunoHeart({
    super.key,
    required this.on,
    this.playKey,
    this.size = BunoSize.iconMd,
    this.offColor = BunoDark.text_secondary,
  });

  final bool on;
  final Object? playKey;
  final double size;
  final Color offColor;

  @override
  Widget build(BuildContext context) {
    if (on) return BunoLottieIcon(name: 'heart', size: size, playKey: playKey, color: BunoColors.primary);
    return CustomPaint(size: Size.square(size), painter: _HeartOutline(offColor));
  }
}

class _HeartOutline extends CustomPainter {
  const _HeartOutline(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Drawn in a 24-unit box like the SVG icons, with a 2-unit margin.
    final path = Path()
      ..moveTo(w * 0.5, h * 0.86)
      ..cubicTo(w * 0.18, h * 0.64, w * 0.08, h * 0.48, w * 0.08, h * 0.34)
      ..cubicTo(w * 0.08, h * 0.2, w * 0.19, h * 0.12, w * 0.3, h * 0.12)
      ..cubicTo(w * 0.39, h * 0.12, w * 0.46, h * 0.17, w * 0.5, h * 0.24)
      ..cubicTo(w * 0.54, h * 0.17, w * 0.61, h * 0.12, w * 0.7, h * 0.12)
      ..cubicTo(w * 0.81, h * 0.12, w * 0.92, h * 0.2, w * 0.92, h * 0.34)
      ..cubicTo(w * 0.92, h * 0.48, w * 0.82, h * 0.64, w * 0.5, h * 0.86)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = BunoStroke.icon * size.width / 24
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_HeartOutline old) => old.color != color;
}
