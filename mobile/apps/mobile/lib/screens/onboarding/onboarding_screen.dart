import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_logo.dart';
import '../../widgets/buno_page_dots.dart';
import 'onboarding_illustrations.dart';
import '../../l10n/buno_locale.dart';

class _Slide {
  const _Slide(this.illustration, this.title, this.body);

  final Widget illustration;
  final String title;
  final String body;
}

/// Onboarding — Brand Board pages 1–3. The illustrations swipe in a
/// PageView (which follows RTL: the next page enters from the left); the
/// title and body cross-fade with the page.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onFinished, this.onHaveAccount});

  /// Called by "ابدأ دلوقتي" and "تخطي". Defaults to the sign-up screen.
  final VoidCallback? onFinished;
  final VoidCallback? onHaveAccount;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// The board insets this screen's buttons 24pt (Home uses 22pt).
  static const _buttonGutter = 24.0;

  static List<_Slide> get _slides => [
    _Slide(
      NearbyStationsIllustration(),
      tr('محطات بونو حواليك', 'Buno stations around you'),
      tr('لاقي أقرب محطة على الخريطة، في الجامعة أو الكافيه أو المول.', 'Find the nearest station on the map: on campus, at a café or at the mall.'),
    ),
    _Slide(
      ScanIllustration(),
      tr('امسح الكود وخد بونو', 'Scan the code, take a Buno'),
      tr('خانة بتتفتح على طول، وتمشي وانت مطمّن إن موبايلك مش هيفصل.', "A bay opens right away, and you walk off knowing your phone won't die."),
    ),
    _Slide(
      ReturnIllustration(),
      tr('رجّعه في أي محطة', 'Return it at any station'),
      tr('مش لازم نفس المحطة. سيبه في أقرب واحدة وانت في طريقك.', "It doesn't have to be the same station. Drop it at the nearest one on your way."),
    ),
  ];

  final _pager = PageController();
  int _page = 0;

  bool get _isLast => _page == _slides.length - 1;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _finish() {
    if (widget.onFinished != null) {
      widget.onFinished!();
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.signup);
    }
  }

  void _next() {
    if (_isLast) return _finish();
    _pager.nextPage(duration: BunoMotion.slow, curve: BunoMotion.easing);
  }

  void _haveAccount() {
    if (widget.onHaveAccount != null) return widget.onHaveAccount!();
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(showSkip: !_isLast, onSkip: _finish),
            Expanded(
              child: PageView.builder(
                controller: _pager,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                // Scales the 248pt disc down on short phones instead of clipping.
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.6),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _slides[i].illustration,
                    ),
                  ),
                ),
              ),
            ),
            Center(child: BunoPageDots(count: _slides.length, index: _page)),
            const SizedBox(height: 26),
            AnimatedSwitcher(
              duration: BunoMotion.base,
              child: _SlideText(key: ValueKey(_page), title: slide.title, body: slide.body),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(_buttonGutter, 26, _buttonGutter, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BunoPrimaryButton(
                    label: _isLast ? tr('ابدأ دلوقتي', 'Get started') : tr('يلا', "Let's go"),
                    onPressed: _next,
                  ),
                  const SizedBox(height: 12),
                  BunoSecondaryButton(
                    label: tr('عندي حساب', 'I have an account'),
                    height: 50,
                    labelSize: 15,
                    onPressed: _haveAccount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.showSkip, required this.onSkip});

  final bool showSkip;
  final VoidCallback onSkip;

  static const _logoHeight = 26.9;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final nudge = BunoLogo.inkEndInset * _logoHeight / 120;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 22, end: 2, top: 18.6),
      child: SizedBox(
        height: BunoSize.touchMin,
        child: Row(
          children: [
            Transform.translate(
              offset: Offset(rtl ? nudge : -nudge, 0),
              child: const BunoLogo(height: _logoHeight),
            ),
            const Spacer(),
            // Hidden (not removed) on the last page so the header keeps its size.
            Visibility(
              visible: showSkip,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSkip,
                  child: Container(
                    height: BunoSize.touchMin,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      tr('تخطي', 'Skip'),
                      style: BunoType.body.copyWith(
                        fontSize: 14,
                        height: 1.2,
                        color: BunoDark.text_secondary,
                      ),
                    ),
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

class _SlideText extends StatelessWidget {
  const _SlideText({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: BunoType.h1.copyWith(fontSize: 28, height: 1.3),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: BunoType.body.copyWith(height: 27 / 15, color: BunoDark.text_secondary),
          ),
        ],
      ),
    );
  }
}
