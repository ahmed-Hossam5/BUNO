import 'package:flutter/widgets.dart';

import '../theme/buno_tokens_ext.dart';
import 'buno_logo.dart';

/// Header of the tab screens (Wallet, Profile — Brand Board page 12):
/// screen title on the start side, logo on the end side.
class BunoTabHeader extends StatelessWidget {
  const BunoTabHeader({super.key, required this.title});

  final String title;

  static const _logoHeight = 24.1;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Pull the SVG's left padding out so the "b" sits on the gutter.
    final nudge = 6 * _logoHeight / 120;
    return Row(
      children: [
        Text(title, style: BunoType.h1.copyWith(fontSize: 22, height: 1.3)),
        const Spacer(),
        Transform.translate(
          offset: Offset(rtl ? -nudge : nudge, 0),
          child: const BunoLogo(height: _logoHeight),
        ),
      ],
    );
  }
}

/// Section heading inside a tab screen ("طرق الدفع", "آخر العمليات").
class BunoSectionTitle extends StatelessWidget {
  const BunoSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: BunoType.body.copyWith(fontWeight: FontWeight.w700, height: 1.3));
}
