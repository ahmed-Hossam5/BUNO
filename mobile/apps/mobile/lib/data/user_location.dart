import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import 'mock_map_places.dart';

/// Whether the app may read the phone's location.
enum LocationAccess {
  /// Not read yet, or the platform can't say.
  unknown,

  /// "While using the app" (or always).
  granted,

  /// Refused, but the app may still ask.
  denied,

  /// Refused for good; only the phone's settings can change it.
  blocked,

  /// Location is switched off on the phone.
  serviceOff,
}

/// Where locations come from. The real one uses `geolocator`; tests pass a
/// fake.
abstract class LocationSource {
  Future<LocationAccess> check();

  /// Shows the system prompt when the platform still allows it.
  Future<LocationAccess> request();

  /// Fixes while the app is in use; errors when location is switched off.
  Stream<LatLng> positions();

  /// The phone's location settings for [LocationAccess.serviceOff], else
  /// this app's settings page.
  Future<void> openSettings(LocationAccess access);
}

class GeolocatorSource implements LocationSource {
  const GeolocatorSource();

  static LocationAccess _from(LocationPermission p) => switch (p) {
        LocationPermission.whileInUse || LocationPermission.always => LocationAccess.granted,
        LocationPermission.denied => LocationAccess.denied,
        LocationPermission.deniedForever => LocationAccess.blocked,
        LocationPermission.unableToDetermine => LocationAccess.unknown,
      };

  Future<LocationAccess> _read(Future<LocationPermission> Function() permission) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceOff;
      return _from(await permission());
    } catch (_) {
      return LocationAccess.unknown;
    }
  }

  @override
  Future<LocationAccess> check() => _read(Geolocator.checkPermission);

  @override
  Future<LocationAccess> request() => _read(Geolocator.requestPermission);

  @override
  Stream<LatLng> positions() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
      ).map((p) => LatLng(p.latitude, p.longitude));

  @override
  Future<void> openSettings(LocationAccess access) async {
    try {
      access == LocationAccess.serviceOff ? await Geolocator.openLocationSettings() : await Geolocator.openAppSettings();
    } catch (_) {}
  }
}

/// Under `flutter test` (no platform plugins): allowed, but no fix ever
/// arrives, so screens sit on [mockUserLocation] with no prompt.
class _SilentSource implements LocationSource {
  const _SilentSource();

  @override
  Future<LocationAccess> check() async => LocationAccess.granted;

  @override
  Future<LocationAccess> request() async => LocationAccess.granted;

  @override
  Stream<LatLng> positions() => const Stream.empty();

  @override
  Future<void> openSettings(LocationAccess access) async {}
}

/// Walking pace used for every walk time: about 80 m a minute.
const walkMetersPerMinute = 80.0;

/// Straight-line (haversine) distance in metres.
double distanceMeters(LatLng a, LatLng b) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.latitude - a.latitude), dLng = rad(b.longitude - a.longitude);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.latitude)) * math.cos(rad(b.latitude)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(h));
}

/// Walk from [a] to [b] at [walkMetersPerMinute], in whole minutes (1 at least).
int walkMinutesBetween(LatLng a, LatLng b) => math.max(1, (distanceMeters(a, b) / walkMetersPerMinute).round());

/// The point [meters] from [from] towards [bearing] (degrees, 0 = north).
LatLng offsetBy(LatLng from, double bearing, double meters) {
  final b = bearing * math.pi / 180;
  final perDegLng = 111320 * math.cos(from.latitude * math.pi / 180);
  return LatLng(from.latitude + meters * math.cos(b) / 111320, from.longitude + meters * math.sin(b) / perDegLng);
}

/// The phone's location for the UI. Follows it while anyone listens (home,
/// /stations) and the app is in the foreground; asks for "while using the
/// app" once per run when the platform still allows asking.
class UserLocation extends ChangeNotifier with WidgetsBindingObserver {
  UserLocation({LocationSource? source}) : _source = source ?? (_inTest ? const _SilentSource() : const GeolocatorSource());

  static bool get _inTest => !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  /// App-wide instance used by the screens. Tests may replace it.
  static UserLocation shared = UserLocation();

  final LocationSource _source;

  LocationAccess _access = LocationAccess.unknown;
  LocationAccess get access => _access;

  LatLng? _position;
  LatLng? _origin;

  /// The latest real fix; null until one arrives.
  LatLng? get position => _position;

  /// Where the map centres: the latest fix, else the fixed default point.
  LatLng get center => _position ?? mockUserLocation;

  /// The first real fix of this run (mock stations sit around it), else the
  /// default point.
  LatLng get origin => _origin ?? mockUserLocation;

  /// Location is refused or switched off: home asks to turn it on.
  bool get needsEnabling =>
      _access == LocationAccess.denied || _access == LocationAccess.blocked || _access == LocationAccess.serviceOff;

  StreamSubscription<LatLng>? _sub;
  int _listeners = 0;
  bool _asked = false;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    if (_listeners++ == 0) {
      WidgetsBinding.instance.addObserver(this);
      refresh(ask: true);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (--_listeners == 0) {
      WidgetsBinding.instance.removeObserver(this);
      _follow(false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the phone's settings, maybe with location on now.
    if (state == AppLifecycleState.resumed) {
      refresh();
    } else if (state == AppLifecycleState.paused) {
      _follow(false);
    }
  }

  /// Re-reads the permission; with [ask], shows the system prompt once per
  /// run when the user hasn't answered for good.
  Future<void> refresh({bool ask = false}) async {
    var access = await _source.check();
    if (ask && !_asked && access == LocationAccess.denied) {
      _asked = true;
      access = await _source.request();
    }
    _setAccess(access);
  }

  /// The /permissions switch: asks now (the prompt, or the phone's settings
  /// when asking is no longer allowed). True when location is allowed.
  Future<bool> requestAccess() async {
    var access = await _source.check();
    if (access == LocationAccess.denied || access == LocationAccess.unknown) {
      _asked = true;
      access = await _source.request();
    }
    if (access == LocationAccess.blocked || access == LocationAccess.serviceOff) await _source.openSettings(access);
    _setAccess(access);
    return access == LocationAccess.granted;
  }

  /// The pill on home: the settings page that can turn location on.
  Future<void> openSettings() => _source.openSettings(_access);

  void _setAccess(LocationAccess access) {
    final changed = access != _access;
    _access = access;
    _follow(access == LocationAccess.granted && _listeners > 0);
    if (changed) notifyListeners();
  }

  void _follow(bool on) {
    if (!on) {
      _sub?.cancel();
      _sub = null;
      return;
    }
    _sub ??= _source.positions().listen(_onFix, onError: (Object _) {
      // Location switched off while following.
      _setAccess(LocationAccess.serviceOff);
    });
  }

  void _onFix(LatLng p) {
    if (p == _position) return;
    _origin ??= p;
    _position = p;
    notifyListeners();
  }
}
