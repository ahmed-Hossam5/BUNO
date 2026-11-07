import 'dart:async';

import 'package:buno/data/user_location.dart';
import 'package:latlong2/latlong.dart' show LatLng;

/// Test double for the phone's location: set [access], call [move] to
/// send a fix.
class FakeLocationSource implements LocationSource {
  FakeLocationSource({this.access = LocationAccess.granted, this.afterRequest});

  LocationAccess access;

  /// What the system prompt answers; [access] unchanged when null.
  LocationAccess? afterRequest;
  int requests = 0;
  final opened = <LocationAccess>[];
  final _fixes = StreamController<LatLng>.broadcast();

  @override
  Future<LocationAccess> check() async => access;

  @override
  Future<LocationAccess> request() async {
    requests++;
    return access = afterRequest ?? access;
  }

  @override
  Stream<LatLng> positions() => _fixes.stream;

  @override
  Future<void> openSettings(LocationAccess access) async => opened.add(access);

  void move(LatLng p) => _fixes.add(p);

  /// Location switched off while following.
  void switchOff() {
    access = LocationAccess.serviceOff;
    _fixes.addError(Exception('location service disabled'));
  }
}

/// Installs a fake as the app-wide location and returns it.
FakeLocationSource useFakeLocation({LocationAccess access = LocationAccess.granted, LocationAccess? afterRequest}) {
  final source = FakeLocationSource(access: access, afterRequest: afterRequest);
  UserLocation.shared = UserLocation(source: source);
  return source;
}
