import 'package:flutter/widgets.dart';

import '../../theme/buno_tokens.dart';
import '../../widgets/map_markers.dart';

/// A station pin on the mock map, in reference-frame coordinates.
class MapStation {
  const MapStation(this.position, this.availability, {this.id});

  final Offset position;
  final StationAvailability availability;

  /// The [Station.id] this pin stands for, when it stands for one.
  final String? id;
}

/// Lightweight stand-in for a real map: the street grid, markers and walking
/// route from the reference, drawn locally. Geometry is authored in a 390pt
/// wide frame (the reference width) and scaled horizontally to the screen.
class MockMap extends StatelessWidget {
  const MockMap({
    super.key,
    required this.stations,
    required this.selected,
    required this.selectedReadyCount,
    this.user,
    this.onStationTap,
    this.markerBuilder,
  });

  static const frameWidth = 390.0;

  final List<MapStation> stations;
  /// The selected station's ring and the walking route to it; none when null.
  final Offset? selected;
  final int? selectedReadyCount;

  /// The user's dot; none when null (home draws its own on top).
  final Offset? user;
  final ValueChanged<MapStation>? onStationTap;

  /// Draws each pin, centred on its position, instead of a [StationMarker].
  final Widget Function(MapStation station)? markerBuilder;

  static const background = Color(0xFF13171A);
  static const road = Color(0xFF1D2226);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final sx = constraints.maxWidth / frameWidth;
      Offset p(Offset o) => Offset(o.dx * sx, o.dy);

      Widget at(Offset c, double size, Widget child) => Positioned(
            left: p(c).dx - size / 2,
            top: c.dy - size / 2,
            width: size,
            height: size,
            child: child,
          );

      return ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _StreetsPainter(scaleX: sx, route: selected != null),
              ),
            ),
            for (final s in stations)
              if (markerBuilder != null)
                Positioned(
                  left: p(s.position).dx,
                  top: s.position.dy,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -0.5),
                    child: markerBuilder!(s),
                  ),
                )
              else
                at(
                s.position,
                44,
                StationMarker(
                  availability: s.availability,
                  onTap: onStationTap == null ? null : () => onStationTap!(s),
                ),
              ),
            if (selected != null)
              at(selected!, 60,
                  SelectedStationMarker(readyCount: selectedReadyCount)),
            if (user != null) at(user!, 21, const UserLocationMarker()),
          ],
        ),
      );
    });
  }
}

class _StreetsPainter extends CustomPainter {
  _StreetsPainter({required this.scaleX, required this.route});

  final double scaleX;
  final bool route;

  // Street centre lines measured from the reference (map-local, 390 frame).
  static const _streets = [
    (Offset(0, 89.1), Offset(390, 68.3)),
    (Offset(0, 230.2), Offset(390, 253.1)),
    (Offset(109.7, -132), Offset(152.7, 370)),
    (Offset(292.2, -132), Offset(249.5, 370)),
  ];
  static const _streetWidth = 18.0;

  // Walking-route dots: 5pt, 7 of them, between the user and the ring.
  static const _dotCount = 7;
  static const _dotDiameter = 5.0;
  static const _routeStart = Offset(145.7, 239.0);
  static const _routeEnd = Offset(191.4, 191.5);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = MockMap.background);

    Offset p(Offset o) => Offset(o.dx * scaleX, o.dy);
    final road = Paint()
      ..color = MockMap.road
      ..strokeWidth = _streetWidth
      ..strokeCap = StrokeCap.butt;
    for (final (a, b) in _streets) {
      // Extend each street past the frame so it always bleeds off-screen.
      final d = b - a;
      canvas.drawLine(p(a - d), p(b + d), road);
    }

    if (!route) return;
    final dot = Paint()..color = BunoColors.primary;
    final a = p(_routeStart), b = p(_routeEnd);
    for (var i = 0; i < _dotCount; i++) {
      final t = i / (_dotCount - 1);
      canvas.drawCircle(Offset.lerp(a, b, t)!, _dotDiameter / 2, dot);
    }
  }

  @override
  bool shouldRepaint(_StreetsPainter old) => old.scaleX != scaleX || old.route != route;
}
