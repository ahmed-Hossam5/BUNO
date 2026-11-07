import 'package:latlong2/latlong.dart';

import 'mock_rental.dart';
import 'user_location.dart';

/// Where the map centres when the real location can't be read (permission
/// refused or location off): downtown Cairo, a short walk from Tahrir. Mock.
const mockUserLocation = LatLng(30.0444, 31.2357);

/// Each mock station ([Station.id]) as (bearing in degrees, metres) from
/// [UserLocation.origin], the user's first real fix, so the demo works
/// wherever the phone is. 150 m–1 km in different directions. Mock.
const mockStationOffsets = <String, (double, double)>{
  'st-01': (40, 330),
  'st-02': (150, 730),
  'st-03': (300, 900),
  'st-04': (220, 980),
};

/// The station's map position; null when it has none yet.
LatLng? placeOf(Station s) {
  final o = mockStationOffsets[s.id];
  return o == null ? null : offsetBy(UserLocation.shared.origin, o.$1, o.$2);
}
