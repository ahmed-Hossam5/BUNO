import 'package:flutter/widgets.dart';

import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import 'buno_icon.dart';
import 'buno_pressable.dart';

/// "Add something" button: dashed `--color-border` outline, plus icon and
/// secondary label (Brand Board page 12, "ضيف طريقة دفع").
class BunoDashedButton extends StatelessWidget {
  const BunoDashedButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return BunoPressable(
      onTap: onPressed,
      semanticLabel: label,
      child: CustomPaint(
        painter: const _DashedBorder(),
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BunoIcon(BunoIcons.plus, color: BunoDark.text_secondary),
              const SizedBox(width: 10),
              Text(label, style: BunoType.body.copyWith(fontSize: 14, color: BunoDark.text_secondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = BunoDark.border;
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.5),
      const Radius.circular(20),
    );
    for (final m in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 8) {
        canvas.drawPath(m.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => false;
}
