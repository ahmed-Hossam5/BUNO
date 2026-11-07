import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import 'buno_icon.dart';
import '../l10n/buno_locale.dart';

/// Input (components.md "Inputs"): 54 high, radius 16, `--color-card` fill,
/// 1px border, 16pt inner padding, label 13 above, helper/error 12 below.
/// Focused = primary border, error = error border + message.
/// RTL: text aligns right and the icon sits on the right; set [ltrContent]
/// for e-mail addresses and codes so they type left-to-right.
class BunoTextField extends StatefulWidget {
  const BunoTextField({
    super.key,
    required this.label,
    required this.hint,
    this.icon,
    this.controller,
    this.focusNode,
    this.obscure = false,
    this.ltrContent = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final String hint;
  final BunoIcons? icon;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool obscure;
  final bool ltrContent;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<BunoTextField> createState() => _BunoTextFieldState();
}

class _BunoTextFieldState extends State<BunoTextField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? BunoColors.error
        : _focus.hasFocus
        ? BunoColors.primary
        : BunoDark.border;
    final style = BunoType.body.copyWith(fontSize: 17, height: 1.3);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: BunoType.bodySm.copyWith(
            height: 1.3,
            color: BunoDark.text_secondary,
          ),
        ),
        const SizedBox(height: 7.7),
        AnimatedContainer(
          duration: BunoMotion.fast,
          height: BunoSize.input,
          padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
          decoration: BoxDecoration(
            color: BunoDark.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: BunoStroke.hairline),
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                BunoIcon(widget.icon!, color: BunoDark.text_secondary),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: widget.obscure,
                  obscuringCharacter: '•',
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  autocorrect: !widget.ltrContent && !widget.obscure,
                  enableSuggestions: !widget.obscure,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  cursorColor: BunoColors.primary,
                  style: style,
                  // E-mails and passwords type LTR but stay aligned to the
                  // start (right) edge of the field.
                  textDirection: widget.ltrContent || widget.obscure
                      ? TextDirection.ltr
                      : null,
                  textAlign: widget.ltrContent || widget.obscure
                      ? (rtl ? TextAlign.right : TextAlign.left)
                      : TextAlign.start,
                  decoration: InputDecoration.collapsed(
                    hintText: widget.hint,
                    hintTextDirection: widget.ltrContent
                        ? TextDirection.ltr
                        : null,
                    hintStyle: style.copyWith(color: BunoDark.text_secondary),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: BunoType.caption.copyWith(color: BunoColors.error),
          ),
        ],
      ],
    );
  }
}

/// Inline text action (components.md "Text button"): primary colour, 600,
/// with a 44pt-tall touch target.
class BunoTextLink extends StatelessWidget {
  const BunoTextLink(this.label, {super.key, required this.onTap, this.style});

  final String label;
  final VoidCallback onTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: BunoSize.touchMin),
          child: Align(
            widthFactor: 1,
            child: Text(
              label,
              style: (style ?? BunoType.body).copyWith(
                fontWeight: FontWeight.w600,
                color: BunoColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Checkbox (components.md): 22pt, radius 7, checked = primary fill with an
/// ink tick; 44pt touch target.
class BunoCheckbox extends StatelessWidget {
  const BunoCheckbox({super.key, required this.value, required this.onChanged})
    : bare = false;

  /// Just the 22pt box, for use inside a row that is itself the touch
  /// target (so the label can sit closer than the 44pt target allows).
  const BunoCheckbox.bare({super.key, required this.value})
    : onChanged = null,
      bare = true;

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool bare;

  Widget _box() => AnimatedContainer(
    duration: BunoMotion.fast,
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: value ? BunoColors.primary : BunoDark.card,
      borderRadius: BorderRadius.circular(7),
      border: value ? null : Border.all(color: BunoDark.border, width: 1.5),
    ),
    child: value
        ? const BunoIcon(
            BunoIcons.check,
            size: BunoSize.iconSm,
            color: BunoDark.on_primary,
          )
        : null,
  );

  @override
  Widget build(BuildContext context) {
    if (bare) return _box();
    return Semantics(
      checked: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged!(!value),
        child: SizedBox.square(
          dimension: BunoSize.touchMin,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: _box(),
          ),
        ),
      ),
    );
  }
}

/// "—— أو ——" separator.
class BunoOrDivider extends StatelessWidget {
  const BunoOrDivider({super.key, this.label});

  /// Defaults to "أو" / "or".
  final String? label;

  @override
  Widget build(BuildContext context) {
    const line = Expanded(
      child: Divider(color: BunoDark.border, thickness: 1, height: 1),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label ?? tr('أو', 'or'),
            style: BunoType.body.copyWith(color: BunoDark.text_secondary),
          ),
        ),
        line,
      ],
    );
  }
}

/// 4-cell one-time-code input (components.md "OTP input"): 56x66 cells,
/// radius 16, gap 12, digits in Sora 26/700, active cell primary border,
/// auto-advance, paste fills all cells, error turns all borders red.
/// Codes are numbers, so the cells always run left-to-right.
/// Station codes (`BUN-01`) pass their own keyboard, formatters and a
/// narrower [cellWidth]/[cellGap] so six cells fit a phone.
class BunoOtpField extends StatefulWidget {
  const BunoOtpField({
    super.key,
    this.length = 4,
    this.controller,
    this.hasError = false,
    this.onChanged,
    this.onCompleted,
    this.autofocus = true,
    this.keyboardType = TextInputType.number,
    this.inputFormatters,
    this.autofillHints = const [AutofillHints.oneTimeCode],
    this.cellWidth = 56,
    this.cellGap = 12,
    this.semanticLabel,
  });

  final int length;
  final TextEditingController? controller;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool autofocus;
  final TextInputType keyboardType;

  /// Defaults to digits only.
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final double cellWidth;
  final double cellGap;

  /// Read by screen readers for the tappable row of cells.
  /// Defaults to "الكود" / "Code".
  final String? semanticLabel;

  @override
  State<BunoOtpField> createState() => _BunoOtpFieldState();
}

class _BunoOtpFieldState extends State<BunoOtpField> {
  late final TextEditingController _c =
      widget.controller ?? TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _c.addListener(_changed);
    _focus.addListener(() => setState(() {}));
  }

  void _changed() {
    setState(() {});
    widget.onChanged?.call(_c.text);
    if (_c.text.length == widget.length) widget.onCompleted?.call(_c.text);
  }

  @override
  void dispose() {
    _c.removeListener(_changed);
    if (widget.controller == null) _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _c.text;
    return Semantics(
      label: widget.semanticLabel ?? tr('الكود', 'Code'),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: GestureDetector(
          onTap: () => _focus.requestFocus(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The real (invisible) input: handles typing, paste and autofill.
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: _c,
                    focusNode: _focus,
                    autofocus: widget.autofocus,
                    keyboardType: widget.keyboardType,
                    autofillHints: widget.autofillHints,
                    maxLength: widget.length,
                    showCursor: false,
                    enableInteractiveSelection: false,
                    inputFormatters:
                        widget.inputFormatters ??
                        [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < widget.length; i++) ...[
                      if (i > 0) SizedBox(width: widget.cellGap),
                      _cell(
                        i < text.length ? text[i] : '',
                        active: _focus.hasFocus && i == text.length,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(String digit, {required bool active}) {
    final border = widget.hasError
        ? BunoColors.error
        : active
        ? BunoColors.primary
        : BunoDark.border;
    return AnimatedContainer(
      duration: BunoMotion.fast,
      width: widget.cellWidth,
      height: 66,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: BunoDark.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: border,
          width: active || widget.hasError ? 1.5 : 1,
        ),
      ),
      child: Text(
        digit,
        style: const TextStyle(
          fontFamily: BunoFonts.sora,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          height: 1,
          color: BunoDark.text_primary,
        ),
      ),
    );
  }
}
