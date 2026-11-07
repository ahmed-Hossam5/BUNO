import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../theme/buno_tokens.dart';
import '../../widgets/buno_back_button.dart';
import '../../widgets/buno_empty_state.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../l10n/buno_locale.dart';

/// /offline (reference 26_state_no_net): no connection. Retry goes back to
/// where the user was; the link opens /offline-code to unlock a bay at the
/// station without internet.
class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  void _retry(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          child: BunoEmptyState(
            header: const Align(alignment: AlignmentDirectional.centerEnd, child: BunoBackButton()),
            icon: const BunoLottieIcon(name: 'offline', size: 40, color: BunoColors.error, playKey: 0),
            title: tr('مفيش اتصال', 'No connection'),
            body: tr('موبايلك مش متصل بالنت، ومفيش أي فلوس اتخصمت. ', "Your phone is offline, and nothing was charged. ") +
                tr('لو انت عند المحطة، تقدر تفتح خانة بكود من غير نت.', "If you're at the station, you can open a bay with a code, no internet needed."),
            actionLabel: tr('جرّب تاني', 'Try again'),
            onAction: () => _retry(context),
            linkLabel: tr('افتح بكود من غير نت', 'Open with an offline code'),
            onLink: () => Navigator.of(context).pushNamed(AppRoutes.offlineCode),
          ),
        ),
      ),
    );
  }
}
