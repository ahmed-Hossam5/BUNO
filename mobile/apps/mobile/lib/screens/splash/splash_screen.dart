import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_first_run.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_logo.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../l10n/buno_locale.dart';

/// /splash (reference 35_splash): buno_logo_intro plays once, then
/// onboarding the first time ([MockFirstRun.onboardingSeen]) and home after
/// that. With reduced motion the logo rests on its last frame and the
/// splash still holds for [duration].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Length of buno_logo_intro (90 frames at 60 fps).
  static const duration = Duration(milliseconds: 1500);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const _logoSize = 150.0;

  // A ticker rather than a Timer, so widget tests' pumpAndSettle waits it out.
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: SplashScreen.duration,
    animationBehavior: AnimationBehavior.preserve,
  );

  @override
  void initState() {
    super.initState();
    _hold.forward().whenComplete(_leave);
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _leave() {
    if (!mounted) return;
    final first = !MockFirstRun.onboardingSeen;
    MockFirstRun.onboardingSeen = true;
    Navigator.of(context).pushNamedAndRemoveUntil(first ? AppRoutes.onboarding : AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: Semantics(
                    label: tr('بونو', 'Buno'),
                    excludeSemantics: true,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BunoLottieIcon(name: 'buno_logo_intro', size: _logoSize, playKey: 0),
                        SizedBox(height: BunoSpace.s5),
                        BunoLogo(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
              Text(
                tr('باور بانك للإيجار', 'Power banks for rent'),
                textAlign: TextAlign.center,
                style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
