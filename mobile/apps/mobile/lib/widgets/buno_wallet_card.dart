import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import 'buno_logo.dart';
import 'buno_lottie_icon.dart';
import 'buno_pressable.dart';
import 'buno_text.dart';
import '../l10n/buno_locale.dart';

/// Dark bank-style wallet card (references 18/19): chip and logo, the
/// balance with an eye toggle that hides it, the holder and the masked
/// Buno ID. A second card peeks out behind it.
class BunoWalletCard extends StatefulWidget {
  const BunoWalletCard({
    super.key,
    required this.balance,
    required this.holder,
    required this.idLast4,
    this.level,
    this.onLevelTap,
  });

  /// Shown before "EGP", e.g. `[الرصيد]`.
  final String balance;
  final String holder;
  final String idLast4;

  /// Trust level name shown as a badge in the top row (e.g. "عميل منتظم");
  /// tapping it calls [onLevelTap].
  final String? level;
  final VoidCallback? onLevelTap;

  @override
  State<BunoWalletCard> createState() => _BunoWalletCardState();
}

class _BunoWalletCardState extends State<BunoWalletCard> {
  bool _hidden = false;

  /// How far the card behind peeks out above this one.
  static const _peek = 12.0;
  static const _height = 220.0;

  @override
  Widget build(BuildContext context) {
    final label = BunoType.caption.copyWith(color: BunoDark.text_secondary);
    final mono = BunoType.number(BunoType.caption).copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1,
      color: BunoDark.text_secondary,
    );
    return SizedBox(
      height: _height + _peek,
      child: Stack(
        children: [
          // The card behind.
          Positioned(
            top: 0,
            left: BunoSpace.s4,
            right: BunoSpace.s4,
            height: _height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: BunoDark.surface,
                borderRadius: BorderRadius.circular(BunoRadius.xxl),
                border: Border.all(color: BunoDark.border),
              ),
            ),
          ),
          Positioned.fill(
            top: _peek,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BunoRadius.xxl),
                border: Border.all(color: BunoDark.border),
                gradient: const LinearGradient(
                  begin: AlignmentDirectional.topEnd,
                  end: AlignmentDirectional.bottomStart,
                  colors: [BunoDark.elevated, BunoColors.primary_soft],
                ),
              ),
              child: Stack(
                children: [
                  const Positioned.fill(child: CustomPaint(painter: _Watermark())),
                  Padding(
                    padding: const EdgeInsets.all(BunoSpace.s5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const BunoLogo(height: 28, glow: false),
                            const SizedBox(width: BunoSpace.s3),
                            Expanded(
                              child: widget.level == null
                                  ? const SizedBox.shrink()
                                  : Align(
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: _LevelBadge(widget.level!, onTap: widget.onLevelTap),
                                    ),
                            ),
                            const SizedBox(width: BunoSpace.s3),
                            const _Chip(),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(tr('رصيد المحفظة', 'Wallet balance'), style: label),
                            const SizedBox(width: BunoSpace.s1),
                            BunoPressable(
                              onTap: () => setState(() => _hidden = !_hidden),
                              semanticLabel: _hidden ? tr('اظهر الرصيد', 'Show balance') : tr('اخفي الرصيد', 'Hide balance'),
                              child: SizedBox.square(
                                dimension: BunoSize.touchMin / 1.5,
                                child: Center(
                                  child: BunoLottieIcon(
                                    name: 'eye',
                                    size: BunoSize.iconSm,
                                    color: BunoDark.text_secondary,
                                    playKey: _hidden ? 1 : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        _Balance(_hidden ? '••••' : widget.balance),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tr('صاحب المحفظة', 'Wallet owner'), style: label.copyWith(fontSize: 11)),
                                  Text(
                                    widget.holder,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('BUNO ID', textDirection: TextDirection.ltr, style: mono),
                                Text(
                                  '•••• ${widget.idLast4}',
                                  textDirection: TextDirection.ltr,
                                  style: BunoType.number(BunoType.bodySm).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "[balance] EGP", left-to-right and aligned to the start (right) edge.
class _Balance extends StatelessWidget {
  const _Balance(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final big = BunoType.display.copyWith(fontSize: 38, height: 1.2);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          textDirection: TextDirection.ltr,
          children: [
            Text(
              'EGP',
              style: BunoType.number(BunoType.title).copyWith(color: BunoDark.text_secondary),
            ),
            const SizedBox(width: BunoSpace.s3),
            BunoText(text, style: big),
          ],
        ),
      ),
    );
  }
}

/// Trust level pill in the card's top row; opens /trust.
class _LevelBadge extends StatelessWidget {
  const _LevelBadge(this.level, {this.onTap});

  final String level;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BunoPressable(
      onTap: onTap,
      semanticLabel: tr('مستواك: $level', 'Your level: $level'),
      child: Container(
        constraints: const BoxConstraints(minHeight: BunoSize.avatarSm),
        padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s3),
        decoration: BoxDecoration(
          color: BunoColors.primary_soft,
          borderRadius: BorderRadius.circular(BunoRadius.pill),
          border: Border.all(color: BunoColors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BunoLottieIcon(name: 'shield', size: BunoSize.iconSm, color: BunoColors.primary),
            const SizedBox(width: BunoSpace.s1),
            Flexible(
              child: Text(
                level,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BunoType.caption.copyWith(fontWeight: FontWeight.w700, color: BunoColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card's contact chip, drawn in a muted warning tint.
class _Chip extends StatelessWidget {
  const _Chip();

  @override
  Widget build(BuildContext context) {
    final line = BunoColors.warning_deep.withValues(alpha: 0.6);
    return Container(
      width: 40,
      height: 30,
      decoration: BoxDecoration(
        color: BunoColors.warning.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(BunoRadius.xs),
      ),
      child: CustomPaint(painter: _ChipLines(line)),
    );
  }
}

class _ChipLines extends CustomPainter {
  const _ChipLines(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = BunoStroke.hairline;
    final w = size.width, h = size.height;
    canvas
      ..drawLine(Offset(0, h / 3), Offset(w, h / 3), p)
      ..drawLine(Offset(0, h * 2 / 3), Offset(w, h * 2 / 3), p)
      ..drawLine(Offset(w / 2, 0), Offset(w / 2, h / 3), p)
      ..drawLine(Offset(w / 2, h * 2 / 3), Offset(w / 2, h), p)
      ..drawRect(Rect.fromLTWH(w * 0.3, h / 3, w * 0.4, h / 3), p..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_ChipLines old) => old.color != color;
}

/// Faint charging ring with a bolt, cut off by the card's bottom-left corner.
class _Watermark extends CustomPainter {
  const _Watermark();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height * 0.55;
    final c = Offset(size.width * 0.18, size.height * 0.9);
    final paint = Paint()
      ..color = BunoColors.primary.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.28
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi * 0.35, math.pi * 1.7, false, paint);
    final s = r * 0.5;
    final bolt = Path()
      ..moveTo(c.dx + s * 0.15, c.dy - s)
      ..lineTo(c.dx - s * 0.45, c.dy + s * 0.1)
      ..lineTo(c.dx - s * 0.02, c.dy + s * 0.1)
      ..lineTo(c.dx - s * 0.15, c.dy + s)
      ..lineTo(c.dx + s * 0.45, c.dy - s * 0.1)
      ..lineTo(c.dx + s * 0.02, c.dy - s * 0.1)
      ..close();
    canvas.drawPath(bolt, Paint()..color = BunoColors.primary.withValues(alpha: 0.06));
  }

  @override
  bool shouldRepaint(_Watermark old) => false;
}
