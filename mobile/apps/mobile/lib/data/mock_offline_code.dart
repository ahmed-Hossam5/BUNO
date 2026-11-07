/// Offline unlock code (reference 27_offline_code): six digits that change
/// every [offlineCodePeriod], worked out on the phone from the clock alone.
/// A stand-in for a real time-based code shared with the station.
const offlineCodePeriod = Duration(seconds: 30);

/// The window [now] falls in; the code changes when it does.
int offlineCodeWindow(DateTime now) => now.millisecondsSinceEpoch ~/ offlineCodePeriod.inMilliseconds;

/// Six digits for [now], e.g. "482913".
String offlineCode(DateTime now) {
  // Cheap integer scramble (not secure) so neighbouring windows look unrelated.
  var x = offlineCodeWindow(now) * 2654435761 & 0xFFFFFFFF;
  x = (x ^ (x >> 15)) * 2246822519 & 0xFFFFFFFF;
  x ^= x >> 13;
  return (x % 1000000).toString().padLeft(6, '0');
}

/// Share of the current window still left, 1 → 0.
double offlineCodeRemaining(DateTime now) {
  final period = offlineCodePeriod.inMilliseconds;
  return 1 - (now.millisecondsSinceEpoch % period) / period;
}
