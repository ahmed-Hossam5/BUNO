import 'package:flutter/material.dart';

import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import 'buno_icon.dart';
import '../l10n/buno_locale.dart';

/// Search field (components.md): 48 high, radius 14, `--color-card` fill,
/// 1px border, leading icon 18, placeholder in `--color-text-secondary`,
/// clear button once there is text. RTL: text right-aligned, icon on the right.
class BunoSearchField extends StatefulWidget {
  const BunoSearchField({
    super.key,
    required this.hint,
    this.leadingIcon = BunoIcons.location,
    this.onChanged,
    this.autofocus = false,
  });

  final String hint;
  final bool autofocus;
  final BunoIcons leadingIcon;
  final ValueChanged<String>? onChanged;

  @override
  State<BunoSearchField> createState() => _BunoSearchFieldState();
}

class _BunoSearchFieldState extends State<BunoSearchField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = BunoType.body.copyWith(height: 1.3);
    final hasText = _controller.text.isNotEmpty;
    return AnimatedContainer(
      duration: BunoMotion.fast,
      height: BunoSize.buttonMd,
      decoration: BoxDecoration(
        color: BunoDark.card,
        borderRadius: BorderRadius.circular(BunoRadius.md),
        border: Border.all(
          color: _focus.hasFocus ? BunoColors.primary : BunoDark.border,
          width: BunoStroke.hairline,
        ),
      ),
      padding: const EdgeInsetsDirectional.only(start: 15),
      child: Row(
        children: [
          BunoIcon(widget.leadingIcon, size: BunoSize.iconSm, color: BunoDark.text_secondary),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              style: textStyle,
              cursorColor: BunoColors.primary,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration.collapsed(
                hintText: widget.hint,
                hintStyle: textStyle.copyWith(color: BunoDark.text_secondary),
              ),
            ),
          ),
          if (hasText)
            Semantics(
              button: true,
              label: tr('مسح', 'Clear'),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _controller.clear();
                  widget.onChanged?.call('');
                },
                child: const SizedBox(
                  width: BunoSize.touchMin,
                  height: BunoSize.touchMin,
                  child: Center(
                    child: BunoIcon(
                      BunoIcons.close,
                      size: BunoSize.iconSm,
                      color: BunoDark.text_secondary,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 16),
        ],
      ),
    );
  }
}
