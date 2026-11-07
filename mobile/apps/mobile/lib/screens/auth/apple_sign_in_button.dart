import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';

/// "Sign in with Apple" (iCloud) as the board's outlined social button.
/// The Apple mark is not in the Buno or Lucide sets, so it comes from
/// Simple Icons (CC0) in assets/brand/.
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return BunoSecondaryButton(
      label: label,
      height: 52,
      labelSize: 15,
      labelWeight: FontWeight.w700,
      onPressed: onPressed,
      leading: SvgPicture.asset(
        'assets/brand/apple-logo.svg',
        width: BunoSize.iconMd,
        height: BunoSize.iconMd,
        colorFilter: const ColorFilter.mode(BunoDark.text_primary, BlendMode.srcIn),
        semanticsLabel: 'Apple',
      ),
    );
  }
}
