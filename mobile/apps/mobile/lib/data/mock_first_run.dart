import 'package:flutter/foundation.dart';

/// First-run state, kept in memory only (a cold start counts as a first run).
class MockFirstRun {
  MockFirstRun._();

  /// Set once /splash has sent the user to onboarding; later splashes go home.
  static bool onboardingSeen = false;

  /// University e-mail from /verify-uni; null until one is sent (or skipped).
  static String? uniEmail;

  static void reset() {
    onboardingSeen = false;
    uniEmail = null;
  }
}

/// Mock permission switches on /permissions (reference 36). Nothing asks the
/// OS yet; on/off is kept in memory.
class MockPermissions {
  MockPermissions._();

  static final location = ValueNotifier<bool>(true);
  static final notifications = ValueNotifier<bool>(true);
  static final camera = ValueNotifier<bool>(false);

  static void reset() {
    location.value = true;
    notifications.value = true;
    camera.value = false;
  }
}

/// `name@uni.edu.eg`: a university e-mail on an Egyptian `.edu.eg` domain.
bool isUniEmail(String email) => RegExp(r'^[^@\s]+@[^@\s]+\.edu\.eg$', caseSensitive: false).hasMatch(email.trim());
