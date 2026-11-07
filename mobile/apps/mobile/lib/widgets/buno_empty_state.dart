import 'package:flutter/widgets.dart';

import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import 'buno_buttons.dart';
import 'buno_text.dart';
import 'buno_text_link.dart';

/// Empty and error states (references 26–33): an icon in a round badge, a
/// title, and a [body] that says what happened, what happened to the money,
/// and the one next step. The primary button sits at the bottom with an
/// optional text link under it.
///
/// Fills its parent; the screen supplies the Scaffold, SafeArea and gutters.
class BunoEmptyState extends StatelessWidget {
  const BunoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.linkLabel,
    this.onLink,
    this.header,
  }) : assert((linkLabel == null) == (onLink == null));

  /// A [BunoIcon] or [BunoLottieIcon], tinted by the caller.
  final Widget icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;
  final String? linkLabel;
  final VoidCallback? onLink;

  /// Title bar or tab header above the message.
  final Widget? header;

  static const badgeSize = 110.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?header,
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: BunoSpace.s4),
              child: Column(
                children: [
                  Container(
                    width: badgeSize,
                    height: badgeSize,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: BunoDark.card),
                    child: icon,
                  ),
                  const SizedBox(height: BunoSpace.s5),
                  Text(title, textAlign: TextAlign.center, style: BunoType.h2),
                  const SizedBox(height: BunoSpace.s2),
                  BunoText(
                    body,
                    textAlign: TextAlign.center,
                    style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
        BunoPrimaryButton(label: actionLabel, onPressed: onAction),
        if (linkLabel != null) ...[
          const SizedBox(height: BunoSpace.s2),
          BunoTextLink(linkLabel!, onTap: onLink!),
        ],
      ],
    );
  }
}
