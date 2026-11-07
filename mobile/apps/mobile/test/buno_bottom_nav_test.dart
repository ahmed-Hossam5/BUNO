import 'package:buno/widgets/buno_bottom_nav.dart';
import 'package:buno/widgets/buno_icon.dart';
import 'package:buno/widgets/buno_lottie_icon.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

const _items = [
  BunoNavItem(icon: BunoIcons.home, label: 'Home'),
  BunoNavItem(icon: BunoIcons.history, label: 'Trips'),
  BunoNavItem(icon: BunoIcons.wallet, label: 'Wallet'),
];

Widget _nav(int index) => MediaQuery(
  data: const MediaQueryData(),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.bottomCenter,
      child: BunoBottomNav(
        items: _items,
        currentIndex: index,
        onSelected: (_) {},
      ),
    ),
  ),
);

AnimationController _controllerFor(WidgetTester tester, String name) {
  final icon = find.byWidgetPredicate(
    (w) => w is BunoLottieIcon && w.name == name,
    skipOffstage: false,
  );
  final lottie = find.descendant(
    of: icon,
    matching: find.byType(Lottie, skipOffstage: false),
    skipOffstage: false,
  );
  return tester.widget<Lottie>(lottie).controller! as AnimationController;
}

Future<void> _waitForLoad(WidgetTester tester, String name) async {
  for (
    var i = 0;
    i < 50 && _controllerFor(tester, name).duration == null;
    i++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  expect(_controllerFor(tester, name).duration, isNotNull);
}

void main() {
  testWidgets('selecting a tab plays its Lottie icon once', (tester) async {
    await tester.pumpWidget(_nav(0));
    await _waitForLoad(tester, 'nav_home');
    await _waitForLoad(tester, 'nav_wallet');

    final wallet = _controllerFor(tester, 'nav_wallet');
    expect(wallet.isAnimating, isFalse);

    await tester.pumpWidget(_nav(2));
    expect(wallet.isAnimating, isTrue);
    await tester.pumpAndSettle();
    expect(wallet.value, 1);
  });

  testWidgets('a nav built with a tab already selected plays its icon', (
    tester,
  ) async {
    await tester.pumpWidget(_nav(2));
    await _waitForLoad(tester, 'nav_wallet');
    await _waitForLoad(tester, 'nav_home');

    expect(_controllerFor(tester, 'nav_wallet').isAnimating, isTrue);
    expect(_controllerFor(tester, 'nav_home').isAnimating, isFalse);
    await tester.pumpAndSettle();
    expect(_controllerFor(tester, 'nav_wallet').value, 1);
  });

  testWidgets('the trips tab animates with the clock', (tester) async {
    await tester.pumpWidget(_nav(1));
    expect(find.byType(BunoLottieIcon, skipOffstage: false), findsNWidgets(3));
    await _waitForLoad(tester, 'clock');
    expect(_controllerFor(tester, 'clock').isAnimating, isTrue);
    await tester.pumpAndSettle();
    expect(_controllerFor(tester, 'clock').value, 1);
  });
}
