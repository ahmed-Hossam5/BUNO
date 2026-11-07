import 'package:flutter/widgets.dart';

import '../../theme/buno_tokens.dart';
import '../../widgets/map_markers.dart';

/// The three onboarding illustrations from Brand Board pages 1–3.
///
/// The design system has no illustration assets yet (README "Known gaps" #4),
/// so these are drawn in code. All geometry is measured from the board and
/// expressed in the 248pt disc's own coordinates.
class OnboardingDisc extends StatelessWidget {
  const OnboardingDisc({super.key, required this.child});

  static const size = 248.0;
  static const color = Color(0xFF12151A);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: color),
      // Map streets are allowed to poke past the disc, as on the board.
      child: Stack(clipBehavior: Clip.none, children: [Positioned.fill(child: child)]),
    );
  }
}

// Board → disc coordinates: the disc's top-left sits at (71, 168.5).
Offset _d(double x, double y) => Offset(x - 71, y - 168.5);
Rect _r(double l, double t, double r, double b) =>
    Rect.fromPoints(_d(l, t), _d(r, b));

/// Page 1 — "Buno stations around you": streets, nearby stations, the
/// selected one, the user and a dotted walking route.
class NearbyStationsIllustration extends StatelessWidget {
  const NearbyStationsIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    Widget at(Offset c, double box, Widget w) => Positioned(
          left: c.dx - box / 2,
          top: c.dy - box / 2,
          width: box,
          height: box,
          child: w,
        );
    return OnboardingDisc(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: CustomPaint(painter: _StreetsAndRoute())),
          at(_d(133, 240.3), 44, const StationMarker(
            availability: StationAvailability.available,
            size: 33,
            strokeWidth: 3.5,
          )),
          at(_d(266.7, 354.3), 44, const StationMarker(
            availability: StationAvailability.available,
            size: 33,
            strokeWidth: 3.5,
          )),
          at(_d(235.5, 259.5), 66, const SelectedStationMarker(
            size: 46,
            haloSize: 66,
            strokeWidth: 4,
            haloOpacity: 0.17,
          )),
          at(_d(156.3, 350.5), 23, const UserLocationMarker(size: 23, borderWidth: 3.75)),
        ],
      ),
    );
  }
}

class _StreetsAndRoute extends CustomPainter {
  const _StreetsAndRoute();

  static const _street = Color(0xFF1D2226);

  @override
  void paint(Canvas canvas, Size size) {
    final street = Paint()..color = _street;
    for (final x in [156.5, 243.5]) {
      canvas.drawRect(_r(x - 4.85, 176, x + 4.85, 408), street);
    }
    for (final y in [253.8, 331.2]) {
      canvas.drawRect(_r(79, y - 4.85, 311, y + 4.85), street);
    }

    final dot = Paint()..color = BunoColors.primary;
    final a = _d(165.5, 335.7), b = _d(223, 287.5);
    const n = 7;
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(Offset.lerp(a, b, i / (n - 1))!, 3.15, dot);
    }
  }

  @override
  bool shouldRepaint(_StreetsAndRoute old) => false;
}

/// Page 2 — "Scan the code": a scanner frame with corner brackets and a
/// scan line.
class ScanIllustration extends StatelessWidget {
  const ScanIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingDisc(child: CustomPaint(painter: _ScanPainter()));
  }
}

class _ScanPainter extends CustomPainter {
  const _ScanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Frame: 108x151, radius 24, 4pt border.
    final frame = RRect.fromRectAndRadius(_r(143, 219, 247, 366), const Radius.circular(22));
    canvas.drawRRect(frame, Paint()..color = BunoDark.background);
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = BunoDark.border,
    );

    // Corner brackets: 28pt arms, 5.5pt round stroke.
    const w = 5.5, arm = 28.0, k = 9.0;
    final bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = BunoColors.primary;
    final box = _r(159.7 + w / 2, 227.3 + w / 2, 231.3 - w / 2, 357.7 - w / 2);
    final len = arm - w;
    void corner(Offset c, double sx, double sy) {
      final path = Path()
        ..moveTo(c.dx, c.dy + sy * len)
        ..lineTo(c.dx, c.dy + sy * k)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + sx * k, c.dy)
        ..lineTo(c.dx + sx * len, c.dy);
      canvas.drawPath(path, bracket);
    }

    corner(box.topLeft, 1, 1);
    corner(box.topRight, -1, 1);
    corner(box.bottomLeft, 1, -1);
    corner(box.bottomRight, -1, -1);

    // Scan line: Buno green at 65%.
    canvas.drawLine(
      _d(158.3 + 2.15, 292.5),
      _d(232.7 - 2.15, 292.5),
      Paint()
        ..strokeWidth = 4.3
        ..strokeCap = StrokeCap.round
        ..color = BunoColors.primary.withValues(alpha: 0.65),
    );
  }

  @override
  bool shouldRepaint(_ScanPainter old) => false;
}

/// Page 3 — "Return it to any station": a station with three filled bays and
/// one empty (dashed) bay, and a power bank sliding back along a dotted arrow.
class ReturnIllustration extends StatelessWidget {
  const ReturnIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingDisc(child: CustomPaint(painter: _ReturnPainter()));
  }
}

class _ReturnPainter extends CustomPainter {
  const _ReturnPainter();

  static const _emptyBay = Color(0xFF2E334B);

  @override
  void paint(Canvas canvas, Size size) {
    // Station body: 83x130, radius 22, 4pt border.
    final body = RRect.fromRectAndRadius(_r(108, 230.7, 187.3, 356.3), const Radius.circular(20));
    canvas.drawRRect(body, Paint()..color = BunoDark.background);
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = BunoDark.border,
    );

    const bayR = Radius.circular(8);
    void bay(double l, double t, Color c) => canvas.drawRRect(
        RRect.fromRectAndRadius(_r(l, t, l + 23, t + 36.7), bayR), Paint()..color = c);
    bay(121.7, 250, BunoColors.secondary);
    bay(150.7, 250, BunoColors.secondary);
    bay(121.7, 298.3, BunoColors.primary);
    _dashedRRect(
      canvas,
      RRect.fromRectAndRadius(_r(150.7, 298.3, 173.7, 335), bayR),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.7
        ..color = _emptyBay,
    );

    // Dotted shaft + chevron.
    final green = Paint()
      ..color = BunoColors.primary
      ..strokeWidth = 5.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final x in [213.35, 226.85, 240.5, 254.0]) {
      canvas.drawLine(_d(x - 0.9, 292.5), _d(x + 0.9, 292.5), green);
    }
    canvas.drawPath(
      Path()
        ..moveTo(_d(249.15, 278.85).dx, _d(249.15, 278.85).dy)
        ..lineTo(_d(264.45, 292.5).dx, _d(264.45, 292.5).dy)
        ..lineTo(_d(249.15, 306.15).dx, _d(249.15, 306.15).dy),
      green,
    );

    // Power bank.
    canvas.drawRRect(
      RRect.fromRectAndRadius(_r(274.3, 261.7, 307, 323.3), const Radius.circular(14)),
      Paint()..color = BunoColors.primary,
    );
  }

  static void _dashedRRect(Canvas canvas, RRect rrect, Paint paint) {
    const dash = 4.7, gap = 5.0;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ReturnPainter old) => false;
}
