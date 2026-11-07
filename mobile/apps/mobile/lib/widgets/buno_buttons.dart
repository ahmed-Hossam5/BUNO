import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import 'buno_icon.dart';
import 'buno_pressable.dart';

/// Primary button (components.md): 56 high, radius 16, `--color-primary`
/// fill, label always `#0A0A0B` (never white). One per screen. A tap gives
/// light haptic feedback.
class BunoPrimaryButton extends StatelessWidget {
  const BunoPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.loading = false,
  });

  final String label;
  final BunoIcons? icon;
  final VoidCallback? onPressed;

  /// A widget shown before the label in place of [icon] (e.g. an animated
  /// BunoLottieIcon tinted `on_primary`).
  final Widget? leading;

  /// Loading state (components.md): the label swaps for a 20pt spinner and
  /// taps are ignored; the button keeps its size.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return BunoPressable(
      onTap: loading || onPressed == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPressed!();
            },
      semanticLabel: label,
      child: Container(
        height: BunoSize.buttonLg,
        decoration: BoxDecoration(
          color: BunoColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: loading
            ? const Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: BunoDark.on_primary,
                  ),
                ),
              )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 10),
            ] else if (icon != null) ...[
              BunoIcon(icon!, color: BunoDark.on_primary),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: BunoType.button.copyWith(
                    color: BunoDark.on_primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Secondary button (components.md): transparent, 1px `--color-border`,
/// radius 16, label `--color-text-primary` 600.
class BunoSecondaryButton extends StatelessWidget {
  const BunoSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 52,
    this.icon,
    this.iconColor = BunoDark.text_secondary,
    this.compact = false,
    this.labelSize,
    this.leading,
    this.labelWeight = FontWeight.w400,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final BunoIcons? icon;
  final Color iconColor;

  /// Half-width variant (pair of buttons): 18pt icon, 13pt label.
  final bool compact;

  /// Overrides the label size (defaults: 14, or 13 when [compact]).
  final double? labelSize;

  /// A non-icon-set mark shown before the label (e.g. the Apple logo).
  final Widget? leading;
  final FontWeight labelWeight;

  @override
  Widget build(BuildContext context) {
    return BunoPressable(
      onTap: onPressed,
      semanticLabel: label,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BunoDark.border, width: BunoStroke.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ],
            if (icon != null) ...[
              BunoIcon(
                icon!,
                color: iconColor,
                size: compact ? BunoSize.iconSm : BunoSize.iconMd,
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: BunoType.button.copyWith(
                    fontWeight: labelWeight,
                    fontSize: labelSize ?? (compact ? 13 : 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
