// Tokens from buno-design-system/tokens/tokens.css and docs/typography.md
// that the supplied buno_tokens.dart does not include yet (size, stroke,
// elevation, motion, type scale). Values are copied 1:1 from those files.
import 'package:flutter/widgets.dart';

import 'buno_tokens.dart';

class BunoSize {
  static const buttonLg = 56.0;
  static const buttonMd = 48.0;
  static const buttonSm = 40.0;
  static const input = 54.0;
  static const appbar = 64.0;
  static const bottomNav = 72.0;

  /// Only these three visible icon sizes are allowed.
  static const iconSm = 18.0;
  static const iconMd = 22.0;
  static const iconLg = 28.0;

  static const avatarSm = 32.0;
  static const avatarMd = 44.0;
  static const touchMin = 44.0;
}

class BunoStroke {
  static const hairline = 1.0;
  static const defaultWidth = 1.5;
  static const icon = 2.0;
  static const emphasis = 3.0;
}

class BunoElevation {
  /// --elevation-glow: 0 0 14px rgba(57,255,136,0.45)
  static const glow = BoxShadow(
    color: Color(0x7339FF88),
    blurRadius: 14,
  );
}

class BunoMotion {
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 320);
  static const easing = Cubic(0.2, 0.8, 0.2, 1);
}

class BunoFonts {
  static const sora = 'Sora';
  static const readex = 'ReadexPro';
}

/// Arabic column of docs/typography.md (Readex Pro), plus the Sora styles
/// used for numbers ("Numbers: always Sora, always left-to-right").
class BunoType {
  static TextStyle _readex(double size, double lineHeight, FontWeight w) =>
      TextStyle(
        fontFamily: BunoFonts.readex,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: w,
        color: BunoDark.text_primary,
        leadingDistribution: TextLeadingDistribution.even,
      );

  static final display = _readex(40, 52, FontWeight.w700);
  static final h1 = _readex(30, 42, FontWeight.w700);
  static final h2 = _readex(24, 34, FontWeight.w700);
  static final h3 = _readex(20, 30, FontWeight.w600);
  static final title = _readex(17, 26, FontWeight.w600);
  static final bodyLg = _readex(17, 30, FontWeight.w400);
  static final body = _readex(15, 26, FontWeight.w400);
  static final bodySm = _readex(13, 23, FontWeight.w400);
  static final button = _readex(17, 22, FontWeight.w700);
  static final caption = _readex(12, 19, FontWeight.w500);

  /// Number style: Sora, same size/weight as the surrounding [base] style.
  static TextStyle number(TextStyle base) => base.copyWith(
        fontFamily: BunoFonts.sora,
        letterSpacing: 0,
      );
}
