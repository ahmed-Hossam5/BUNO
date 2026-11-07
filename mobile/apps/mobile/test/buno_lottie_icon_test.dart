import 'package:buno/widgets/buno_lottie_icon.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

Widget _host(Widget child, {bool disableAnimations = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );
}

AnimationController _controllerOf(WidgetTester tester) =>
    tester.widget<Lottie>(find.byType(Lottie)).controller!
        as AnimationController;

/// Pumps until the composition has loaded (the controller gets its duration).
Future<void> _waitForLoad(WidgetTester tester) async {
  for (var i = 0; i < 50 && _controllerOf(tester).duration == null; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  expect(
    _controllerOf(tester).duration,
    isNotNull,
    reason: 'composition never loaded',
  );
}

void main() {
  testWidgets(
    'loads the named asset at the given size and rests on the last frame',
    (tester) async {
      await tester.pumpWidget(
        _host(const BunoLottieIcon(name: 'plus', size: 28)),
      );
      await _waitForLoad(tester);

      final lottie = tester.widget<Lottie>(find.byType(Lottie));
      expect(lottie.width, 28);
      expect(lottie.height, 28);
      expect(tester.getSize(find.byType(Lottie)), const Size(28, 28));
      expect(_controllerOf(tester).value, 1);
      expect(_controllerOf(tester).isAnimating, isFalse);
    },
  );

  testWidgets('defaults to the 22px icon size', (tester) async {
    await tester.pumpWidget(_host(const BunoLottieIcon(name: 'plus')));
    await _waitForLoad(tester);
    expect(tester.getSize(find.byType(Lottie)), const Size(22, 22));
  });

  testWidgets('plays once on load with a playKey and each time it changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const BunoLottieIcon(name: 'plus', playKey: 0)),
    );
    await _waitForLoad(tester);
    final controller = _controllerOf(tester);
    expect(controller.isAnimating, isTrue);
    await tester.pumpAndSettle();
    expect(controller.isAnimating, isFalse);
    expect(controller.value, 1);

    // Same key: nothing happens.
    await tester.pumpWidget(
      _host(const BunoLottieIcon(name: 'plus', playKey: 0)),
    );
    expect(controller.isAnimating, isFalse);

    await tester.pumpWidget(
      _host(const BunoLottieIcon(name: 'plus', playKey: 1)),
    );
    expect(controller.isAnimating, isTrue);
    await tester.pump(controller.duration! ~/ 2);
    expect(controller.value, inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(controller.isAnimating, isFalse);
    expect(controller.value, 1);

    // A further change plays it again from the start.
    await tester.pumpWidget(
      _host(const BunoLottieIcon(name: 'plus', playKey: 2)),
    );
    expect(controller.isAnimating, isTrue);
    await tester.pumpAndSettle();
    expect(controller.value, 1);
  });

  testWidgets('loops while loop is true and rests when it turns off', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const BunoLottieIcon(name: 'buno_loader', loop: true)),
    );
    await _waitForLoad(tester);
    final controller = _controllerOf(tester);

    expect(controller.isAnimating, isTrue);
    await tester.pump(controller.duration! * 3);
    expect(controller.isAnimating, isTrue);

    await tester.pumpWidget(_host(const BunoLottieIcon(name: 'buno_loader')));
    expect(controller.isAnimating, isFalse);
    expect(controller.value, 1);
  });

  testWidgets(
    'shows the last frame and never animates when animations are disabled',
    (tester) async {
      await tester.pumpWidget(
        _host(
          const BunoLottieIcon(name: 'buno_loader', loop: true, playKey: 0),
          disableAnimations: true,
        ),
      );
      await _waitForLoad(tester);
      final controller = _controllerOf(tester);
      expect(controller.isAnimating, isFalse);
      expect(controller.value, 1);

      await tester.pumpWidget(
        _host(
          const BunoLottieIcon(name: 'buno_loader', playKey: 1),
          disableAnimations: true,
        ),
      );
      expect(controller.isAnimating, isFalse);
      expect(controller.value, 1);
    },
  );

  testWidgets('stops looping when animations become disabled', (tester) async {
    await tester.pumpWidget(
      _host(const BunoLottieIcon(name: 'buno_loader', loop: true)),
    );
    await _waitForLoad(tester);
    final controller = _controllerOf(tester);
    expect(controller.isAnimating, isTrue);

    await tester.pumpWidget(
      _host(
        const BunoLottieIcon(name: 'buno_loader', loop: true),
        disableAnimations: true,
      ),
    );
    expect(controller.isAnimating, isFalse);
    expect(controller.value, 1);
  });
}
