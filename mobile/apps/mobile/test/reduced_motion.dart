import 'package:flutter_test/flutter_test.dart';

/// Turns on the platform's reduced-motion setting for the current test, so
/// looping BunoLottieIcons rest on their last frame and pumpAndSettle can
/// settle.
void useReducedMotion() {
  final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
  dispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
}
