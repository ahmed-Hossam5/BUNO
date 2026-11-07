import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/buno_tokens.dart';

/// The supplied `buno-logo-primary-dark-bg.svg`, rendered as-is.
///
/// The file sets the wordmark as live text with
/// `font-family="Sora, Poppins, Arial, sans-serif"`. Flutter's SVG renderer
/// passes that list through as one family name, so it would never match the
/// bundled Sora. The only change made at load time is collapsing that list to
/// `Sora`; every path, colour and coordinate comes from the file.
class BunoLogo extends StatelessWidget {
  const BunoLogo({super.key, required this.height, this.glow = true});

  /// Rendered height of the full 280x120 SVG box.
  final double height;
  final bool glow;

  static const _asset = 'assets/logo/buno-logo-primary-dark-bg.svg';
  static const _viewBox = Size(280, 120);

  /// Ring centre / outer radius inside the SVG viewBox:
  /// `translate(203 29) scale(0.6)` of a circle at (60,60), r=44 + 19/2 stroke.
  static const _ringCenter = Offset(203 + 60 * 0.6, 29 + 60 * 0.6);
  static const _ringOuterRadius = (44 + 19 / 2) * 0.6;

  /// Horizontal space between the ring's outer edge and the SVG's right edge.
  static const inkEndInset = 280 - (203 + (60 + 44 + 9.5) * 0.6);

  static Future<String>? _svg;
  static Future<String> _load() => _svg ??= rootBundle
      .loadString(_asset)
      .then((s) => s.replaceAll(
          'font-family="Sora, Poppins, Arial, sans-serif"', 'font-family="Sora"'));

  @override
  Widget build(BuildContext context) {
    final scale = height / _viewBox.height;
    final width = _viewBox.width * scale;
    return Semantics(
      label: 'Buno',
      image: true,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (glow)
              Positioned(
                left: (_ringCenter.dx - _ringOuterRadius) * scale,
                top: (_ringCenter.dy - _ringOuterRadius) * scale,
                width: _ringOuterRadius * 2 * scale,
                height: _ringOuterRadius * 2 * scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      // --elevation-glow blur, softened to match the reference.
                      BoxShadow(
                        color: BunoColors.primary.withValues(alpha: 0.18),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            Positioned.fill(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: FutureBuilder<String>(
                  future: _load(),
                  builder: (context, snap) => snap.hasData
                      ? SvgPicture.string(snap.data!, width: width, height: height)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
