import 'package:flutter/widgets.dart';

import '../theme/buno_tokens_ext.dart';

/// Arabic text in Readex Pro where every numeric run (digits with an optional
/// `%`) is set in Sora and isolated left-to-right, per docs/typography.md:
/// "Numbers: always Sora, always left-to-right, even inside an Arabic sentence".
/// Codes like `BUN-01` and `PB-0417` count as one numeric run, so the
/// dash doesn't flip them to `01-BUN`.
class BunoText extends StatelessWidget {
  const BunoText(
    this.text, {
    super.key,
    required this.style,
    this.numberStyle,
    this.textAlign,
    this.maxLines,
  });

  final String text;
  final TextStyle style;

  /// Overrides for numeric runs (merged on top of `BunoType.number(style)`).
  final TextStyle? numberStyle;
  final TextAlign? textAlign;
  final int? maxLines;

  static final _numeric = RegExp(r'(?:[A-Za-z]+-)?#?[0-9٠-٩]+(?:[.,:][0-9]+)*%?');

  // Unicode LEFT-TO-RIGHT ISOLATE / POP DIRECTIONAL ISOLATE.
  static const _lri = '\u2066';
  static const _pdi = '\u2069';

  @override
  Widget build(BuildContext context) {
    final numStyle = BunoType.number(style).merge(numberStyle);
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _numeric.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      spans.add(TextSpan(text: '$_lri${m[0]}$_pdi', style: numStyle));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));

    return Text.rich(
      TextSpan(style: style, children: spans),
      textAlign: textAlign,
      maxLines: maxLines,
    );
  }
}
