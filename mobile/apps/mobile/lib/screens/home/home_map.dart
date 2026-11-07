import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart' show LatLng;

import '../../data/mock_map_places.dart';
import '../../data/mock_rental.dart';
import '../../data/mock_settings.dart';
import '../../data/mock_station_info.dart';
import '../../l10n/buno_locale.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_bay_tile.dart' show chargeColor;
import '../../widgets/buno_charge_ring.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/map_markers.dart';
import 'mock_map.dart';

/// Home's map (references 99–101): Google Maps in a dark style when the
/// app is built with a key ([googleMapsKey]), else CartoDB dark tiles
/// through flutter_map, or the drawn [MockMap] when tiles can't load
/// (offline, tests, or after a few tile errors). On top: station pins, the nearest station with its
/// name, a dotted walk to it, and [ring] on the user.
class HomeMap extends StatefulWidget {
  const HomeMap({
    super.key,
    required this.user,
    required this.anchor,
    required this.stations,
    required this.nearest,
    required this.ring,
    required this.ringSize,
    required this.routeColor,
    required this.bottomInset,
    this.onStation,
    this.focus,
    this.showUser = true,
    this.reservedLeft,
  });

  final LatLng user;

  /// Put under [anchor] instead of [user] (a place picked in search).
  final LatLng? focus;

  /// False when the location is unknown: no ring and no walk to [nearest].
  final bool showUser;

  /// Time left on the bay held at [nearest]: its pin turns amber with the
  /// countdown.
  final Duration? reservedLeft;

  /// Where the user's ring sits, in this widget's coordinates.
  final Offset anchor;
  final List<Station> stations;

  /// Drawn bigger, named, with the walking route to it.
  final Station? nearest;
  final Widget ring;
  final double ringSize;
  final Color routeColor;

  /// Height covered by the bottom sheet; the attribution sits above it.
  final double bottomInset;
  final ValueChanged<Station>? onStation;

  /// False under `flutter test` (no network), so tests get [MockMap].
  static bool realTiles = !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST');

  /// Set after a few tiles fail; home keeps the mock map from then on.
  static final tilesFailed = ValueNotifier<bool>(false);

  /// From `--dart-define-from-file=secrets.json`; empty means no Google Maps.
  static const googleMapsKey = String.fromEnvironment('GOOGLE_MAPS_KEY');

  /// Real keys are 39 characters; anything shorter is a placeholder.
  static bool get hasGoogleKey => googleMapsKey.length >= 30;

  // Esri's dark grey canvas: free, no key (CARTO's now asks for one).
  static const _tileUrl = 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}';
  static const _labelsUrl = 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}';
  static const _attribution = 'Powered by Esri · © OpenStreetMap contributors';

  /// Zoom that keeps nearby stations in the room above the ring.
  static double zoomFor(double anchorY) =>
      (16 + math.log(math.max(anchorY, 1) / 350) / math.ln2).clamp(14.5, 16.5);

  static double _metersPerPx(double lat, double zoom) =>
      156543.03392 * math.cos(lat * math.pi / 180) / math.pow(2, zoom);

  @override
  State<HomeMap> createState() => HomeMapState();
}

class HomeMapState extends State<HomeMap> {
  final _controller = MapController();
  Size _size = Size.zero;
  bool _ready = false;

  /// Cleared when the user pans; [recenter] sets it again. While set, the
  /// camera follows [HomeMap.user] as it moves.
  bool _following = true;

  /// The Google camera is moving because we moved it, not the user.
  bool _googleMoving = false;
  int _tileErrors = 0;

  gm.GoogleMapController? _google;

  /// The Google camera as it moves; null until it first moves.
  gm.CameraPosition? _camera;

  bool get _useGoogle => HomeMap.hasGoogleKey && HomeMap.realTiles && !MockSettings.simulateOffline.value;

  bool get _real => HomeMap.realTiles && !HomeMap.tilesFailed.value && !MockSettings.simulateOffline.value;

  double get _zoom => HomeMap.zoomFor(widget.anchor.dy);

  /// The point the camera keeps under [HomeMap.anchor].
  LatLng get _target => widget.focus ?? widget.user;

  /// Puts the user back under the ring.
  void recenter() {
    _following = true;
    if (_useGoogle) return _googleMove();
    if (_ready && _real) _move();
  }

  // Google Maps pads its camera by [HomeMap.bottomInset] so its logo stays
  // above the sheet; its centre is the middle of the part left above it.
  Offset get _googleCenter => Offset(_size.width / 2, math.max(_size.height - widget.bottomInset, 0) / 2);

  /// Web Mercator, 0..1 across the world.
  static Offset _merc(LatLng p) {
    final s = math.sin(p.latitude * math.pi / 180);
    return Offset((p.longitude + 180) / 360, 0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi));
  }

  static LatLng _unmerc(Offset m) {
    final n = math.pi - 2 * math.pi * m.dy;
    return LatLng(180 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n))), m.dx * 360 - 180);
  }

  static double _worldPx(double zoom) => 256 * math.pow(2, zoom).toDouble();

  gm.CameraPosition _googleHome() {
    final c = _unmerc(_merc(_target) - (widget.anchor - _googleCenter) / _worldPx(_zoom));
    return gm.CameraPosition(target: gm.LatLng(c.latitude, c.longitude), zoom: _zoom);
  }

  void _googleMove() {
    final google = _google;
    if (google == null) return;
    _googleMoving = true;
    google.animateCamera(gm.CameraUpdate.newCameraPosition(_googleHome()));
  }

  Widget _googleMap() {
    final camera = _camera ?? _googleHome();
    final target = _merc(LatLng(camera.target.latitude, camera.target.longitude));
    final world = _worldPx(camera.zoom);
    return Stack(
      children: [
        Positioned.fill(
          child: gm.GoogleMap(
            initialCameraPosition: _googleHome(),
            style: _googleDarkStyle,
            padding: EdgeInsets.only(bottom: widget.bottomInset),
            compassEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            buildingsEnabled: false,
            indoorViewEnabled: false,
            trafficEnabled: false,
            minMaxZoomPreference: const gm.MinMaxZoomPreference(12, 18),
            onMapCreated: (c) => _google = c,
            onCameraMoveStarted: () {
              if (!_googleMoving) _following = false;
            },
            onCameraMove: (p) => setState(() => _camera = p),
            onCameraIdle: () => _googleMoving = false,
          ),
        ),
        Positioned.fill(child: _overlay((p) => (_merc(p) - target) * world + _googleCenter)),
      ],
    );
  }

  void _move() => _controller.move(_centerFor(_zoom), _zoom);

  @override
  void didUpdateWidget(HomeMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focused = oldWidget.focus != widget.focus;
    if (focused) _following = true;
    final moved = oldWidget.user != widget.user || focused;
    if (_useGoogle && (oldWidget.anchor != widget.anchor || oldWidget.bottomInset != widget.bottomInset || (moved && _following))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _googleMove();
      });
    } else if ((oldWidget.anchor != widget.anchor || moved) && _following && _ready && _real) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _move();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Camera centre that puts the user on [HomeMap.anchor].
  LatLng _centerFor(double zoom) {
    final t = _target;
    final mpp = HomeMap._metersPerPx(t.latitude, zoom);
    final d = widget.anchor - _size.center(Offset.zero);
    final perDegLng = 111320 * math.cos(t.latitude * math.pi / 180);
    return LatLng(
      t.latitude + d.dy * mpp / 111320,
      t.longitude - d.dx * mpp / perDegLng,
    );
  }

  Widget _overlay(Offset Function(LatLng) project) => _Overlay(
        project: project,
        user: widget.user,
        stations: widget.stations,
        nearest: widget.nearest,
        ring: widget.ring,
        ringSize: widget.ringSize,
        routeColor: widget.routeColor,
        onStation: widget.onStation,
        showUser: widget.showUser,
        reservedLeft: widget.reservedLeft,
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      _size = c.biggest;
      return ListenableBuilder(
        listenable: Listenable.merge([HomeMap.tilesFailed, MockSettings.simulateOffline]),
        builder: (context, _) {
          final zoom = _zoom;
          if (_useGoogle) return _googleMap();
          if (!_real) {
            _ready = false;
            final user = _target;
            final mpp = HomeMap._metersPerPx(user.latitude, zoom);
            final perDegLng = 111320 * math.cos(user.latitude * math.pi / 180);
            Offset project(LatLng p) => widget.anchor +
                Offset(
                  (p.longitude - user.longitude) * perDegLng / mpp,
                  -(p.latitude - user.latitude) * 111320 / mpp,
                );
            return Stack(
              children: [
                const Positioned.fill(child: MockMap(stations: [], selected: null, selectedReadyCount: null)),
                Positioned.fill(child: _overlay(project)),
              ],
            );
          }
          return FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _centerFor(zoom),
              initialZoom: zoom,
              minZoom: 12,
              maxZoom: 18,
              backgroundColor: MockMap.background,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              onMapReady: () {
                _ready = true;
                // The sheet may have been measured before the map was ready.
                if (_following) _move();
              },
              onPositionChanged: (_, gesture) {
                if (gesture) _following = false;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: HomeMap._tileUrl,
                userAgentPackageName: 'com.buno.buno',
                maxNativeZoom: 16,
                // Darkens Esri's grey to the app's map ground.
                tileBuilder: (context, tile, _) => ColorFiltered(colorFilter: _darken, child: tile),
                errorTileCallback: (_, _, _) {
                  if (++_tileErrors >= 3) HomeMap.tilesFailed.value = true;
                },
              ),
              TileLayer(
                urlTemplate: HomeMap._labelsUrl,
                userAgentPackageName: 'com.buno.buno',
                maxNativeZoom: 16,
              ),
              Builder(builder: (context) => _overlay(MapCamera.of(context).latLngToScreenOffset)),
              Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(start: BunoSpace.s2, bottom: widget.bottomInset + BunoSpace.s1),
                  child: Text(
                    HomeMap._attribution,
                    textDirection: TextDirection.ltr,
                    style: BunoType.caption.copyWith(fontSize: 9, height: 1, color: BunoDark.text_disabled),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }
}

/// Google Maps style matching the app's dark map: same ground and road
/// colours as [MockMap], quiet labels, no businesses or transit icons.
const _googleDarkStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#13171a"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8b918c"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#0a0a0b"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#242a28"}]},
  {"featureType": "poi", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi.park", "stylers": [{"visibility": "on"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#141c17"}]},
  {"featureType": "poi.park", "elementType": "labels", "stylers": [{"visibility": "off"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#1d2226"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#13171a"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#242a28"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#5a605b"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0d1b24"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#2f4a5a"}]}
]
''';

const _darken = ColorFilter.matrix([
  0.40, 0, 0, 0, 0,
  0, 0.46, 0, 0, 0,
  0, 0, 0.50, 0, 0,
  0, 0, 0, 1, 0,
]);

class _Overlay extends StatelessWidget {
  const _Overlay({
    required this.project,
    required this.user,
    required this.stations,
    required this.nearest,
    required this.ring,
    required this.ringSize,
    required this.routeColor,
    required this.onStation,
    required this.showUser,
    required this.reservedLeft,
  });

  final bool showUser;
  final Duration? reservedLeft;
  final Offset Function(LatLng) project;
  final LatLng user;
  final List<Station> stations;
  final Station? nearest;
  final Widget ring;
  final double ringSize;
  final Color routeColor;
  final ValueChanged<Station>? onStation;

  static Widget _at(Offset o, Offset anchor, Widget child) => Positioned(
        left: o.dx,
        top: o.dy,
        child: FractionalTranslation(translation: anchor, child: child),
      );

  @override
  Widget build(BuildContext context) {
    final u = project(user);
    final nearestPlace = nearest == null ? null : placeOf(nearest!);
    final n = nearestPlace == null ? null : project(nearestPlace);
    Offset? from, mid, normal;
    if (showUser && n != null && (n - u).distance > ringSize / 2 + 8) {
      final dir = (n - u) / (n - u).distance;
      from = u + dir * (ringSize / 2);
      mid = Offset.lerp(from, n, 0.5)!;
      normal = Offset(-dir.dy, dir.dx);
    }
    return Stack(
      children: [
        if (from != null)
          Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _RoutePainter(from, n!, routeColor))),
          ),
        for (final s in stations)
          if (s.id != nearest?.id && placeOf(s) != null)
            _at(
              project(placeOf(s)!),
              const Offset(-0.5, -0.5),
              StationChargePin(
                charge: s.bestCharge,
                closed: !isStationOpen(s),
                onTap: onStation == null ? null : () => onStation!(s),
              ),
            ),
        if (mid != null) _at(mid + normal! * 34, const Offset(-0.5, -0.5), _WalkChip(minutes: nearest!.walkMinutes)),
        if (showUser)
          Positioned(
            left: u.dx - ringSize / 2,
            top: u.dy - ringSize / 2,
            width: ringSize,
            height: ringSize,
            child: ring,
          ),
        if (n != null)
          _at(
            n,
            const Offset(-0.5, -1),
            reservedLeft != null
                ? _ReservedPin(left: reservedLeft!, onTap: onStation == null ? null : () => onStation!(nearest!))
                : _NearestPin(station: nearest!, onTap: onStation == null ? null : () => onStation!(nearest!)),
          ),
      ],
    );
  }
}

/// Dots from the ring's edge to the nearest station.
class _RoutePainter extends CustomPainter {
  _RoutePainter(this.from, this.to, this.color);

  final Offset from;
  final Offset to;
  final Color color;

  static const _gap = 9.0;
  static const _radius = 2.6;

  @override
  void paint(Canvas canvas, Size size) {
    final length = (to - from).distance;
    final count = (length / _gap).floor();
    final paint = Paint()..color = color;
    for (var i = 1; i < count; i++) {
      canvas.drawCircle(Offset.lerp(from, to, i / count)!, _radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.from != from || old.to != to || old.color != color;
}

/// "3 د" with a walker, beside the route.
class _WalkChip extends StatelessWidget {
  const _WalkChip({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tr('$minutes دقايق مشي', '$minutes min walk'),
      excludeSemantics: true,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: BunoDark.background.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(BunoRadius.pill),
          border: Border.all(color: BunoDark.border, width: BunoStroke.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BunoIcon(BunoIcons.walk, size: BunoSize.iconSm, color: BunoDark.text_secondary),
            const SizedBox(width: BunoSpace.s1),
            BunoText(
              tr('$minutes د', '$minutes min'),
              style: BunoType.caption.copyWith(fontWeight: FontWeight.w700, color: BunoDark.text_primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// The nearest station: its best ready charge and short name in a bubble
/// whose tail points at the station.
class _NearestPin extends StatelessWidget {
  const _NearestPin({required this.station, this.onTap});

  final Station station;
  final VoidCallback? onTap;

  /// "محطة التحرير" → "التحرير", "Tahrir Station" → "Tahrir".
  static String shortName(String name) => name.replaceFirst('محطة ', '').replaceFirst(' Station', '');

  @override
  Widget build(BuildContext context) {
    final best = station.bestCharge;
    final closed = !isStationOpen(station);
    final colour = best == null || closed ? BunoDark.text_disabled : chargeColor(best);
    final name = shortName(station.name);
    return Semantics(
      button: onTap != null,
      label: closed
          ? tr('$name، مقفولة دلوقتي', '$name, closed now')
          : best == null
              ? tr('أقرب محطة، $name', 'Nearest station, $name')
              : tr('أقرب محطة، $name، أعلى شحن $best%', 'Nearest station, $name, top charge $best%'),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: BunoSize.touchMin),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: colour,
                borderRadius: BorderRadius.circular(BunoRadius.lg),
                boxShadow: [BoxShadow(color: colour.withValues(alpha: 0.45), blurRadius: 14)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    best == null ? '—' : '$best%',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontFamily: BunoFonts.sora,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      height: 1,
                      color: BunoDark.on_primary,
                    ),
                  ),
                  const SizedBox(width: BunoSpace.s2),
                  BunoText(
                    name,
                    maxLines: 1,
                    style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w700, color: BunoDark.on_primary),
                  ),
                ],
              ),
            ),
            CustomPaint(size: const Size(14, 8), painter: _TailPainter(colour)),
          ],
        ),
      ),
    );
  }
}

/// The held bay's station (reference 112): "محجوزك 9:42" in amber, its
/// tail on the station.
class _ReservedPin extends StatelessWidget {
  const _ReservedPin({required this.left, this.onTap});

  final Duration left;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final m = left.inMinutes, s = (left.inSeconds % 60).toString().padLeft(2, '0');
    const colour = BunoColors.warning;
    return Semantics(
      button: onTap != null,
      label: tr('محجوزك، فاضل $m دقيقة', 'Your reservation, $m min left'),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: BunoSize.touchMin),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: colour,
                borderRadius: BorderRadius.circular(BunoRadius.lg),
                boxShadow: [BoxShadow(color: colour.withValues(alpha: 0.45), blurRadius: 14)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BunoText(
                    tr('محجوزك', 'Held'),
                    style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w700, color: BunoDark.on_primary),
                  ),
                  const SizedBox(width: BunoSpace.s2),
                  Text(
                    '$m:$s',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontFamily: BunoFonts.sora,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      height: 1,
                      color: BunoDark.on_primary,
                    ),
                  ),
                ],
              ),
            ),
            CustomPaint(size: const Size(14, 8), painter: _TailPainter(colour)),
          ],
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}

/// The user's dot wrapped in the phone-battery ring, with the % in a pill
/// under it and, while charging from Buno, a bolt in the dot.
class HomeUserRing extends StatelessWidget {
  const HomeUserRing({
    super.key,
    required this.percent,
    required this.color,
    required this.size,
    required this.bolt,
    required this.semanticsLabel,
  });

  final int? percent;
  final Color color;
  final double size;
  final bool bolt;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final dot = (size * 0.28).clamp(26.0, 34.0);
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            BunoChargeRing(
              progress: (percent ?? 0) / 100,
              size: size,
              strokeWidth: math.max(6, size * 0.075),
              color: color,
              child: Container(
                width: size * 0.72,
                height: size * 0.72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.alphaBlend(color.withValues(alpha: 0.10), BunoDark.card),
                ),
                child: Container(
                  width: dot,
                  height: dot,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(dot * 0.32),
                    border: Border.all(color: BunoDark.text_primary, width: BunoStroke.emphasis),
                  ),
                  child: bolt
                      ? const BunoIcon(BunoIcons.charging, size: BunoSize.iconSm, color: BunoDark.on_primary)
                      : null,
                ),
              ),
            ),
            Positioned(
              bottom: -12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(BunoRadius.pill),
                  border: Border.all(color: BunoDark.background, width: 2),
                ),
                child: Text(
                  percent == null ? '--%' : '$percent%',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontFamily: BunoFonts.sora,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1,
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
