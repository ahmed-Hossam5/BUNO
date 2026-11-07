import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_sos.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_text.dart';
import 'sos_avatar.dart';
import '../../l10n/buno_locale.dart';

/// /sos/got (reference 52): the friend paid the first hour. "امسح وخد"
/// opens /scan; the next /confirm says who paid.
class SosGotScreen extends StatelessWidget {
  const SosGotScreen({super.key});

  static const _avatar = 112.0;

  /// How far the two avatars overlap.
  static const _overlap = 36.0;

  @override
  Widget build(BuildContext context) {
    final name = (sosSession.firstHourPaidBy ?? mockSosFriends.first).name;
    final friendInitial = String.fromCharCode(name.runes.first);
    final meInitial = String.fromCharCode(mockSosAsker.runes.first);
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: c.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Semantics(
                              label: tr('$name وانت', '$name and you'),
                              excludeSemantics: true,
                              child: SizedBox(
                                width: _avatar * 2 - _overlap,
                                height: _avatar,
                                child: Stack(
                                  children: [
                                    PositionedDirectional(
                                      start: 0,
                                      child: SosAvatar(friendInitial, size: _avatar, filled: true),
                                    ),
                                    PositionedDirectional(
                                      end: 0,
                                      child: SosAvatar(meInitial, size: _avatar),
                                    ),
                                    const Positioned.fill(
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: BunoLottieIcon(
                                          name: 'success',
                                          size: 44,
                                          playKey: true,
                                          color: BunoColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: BunoSpace.s6),
                          BunoText(tr('$name لحقك!', '$name came through!'), textAlign: TextAlign.center, style: BunoType.h1),
                          const SizedBox(height: BunoSpace.s2),
                          BunoText(
                            tr('دفعلك أول ساعة. امسح الـ QR على المحطة والخانة هتفتح.', 'They paid your first hour. Scan the QR on the station and the bay will open.'),
                            textAlign: TextAlign.center,
                            style: BunoType.bodySm.copyWith(
                              fontWeight: FontWeight.w600,
                              color: BunoDark.text_secondary,
                            ),
                          ),
                          const SizedBox(height: BunoSpace.s4),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s4, vertical: BunoSpace.s2),
                              decoration: BoxDecoration(
                                color: BunoDark.card,
                                borderRadius: BorderRadius.circular(BunoRadius.pill),
                              ),
                              child: BunoText(
                                tr('هيوصله إشعار أول ما تاخد الوحدة', "They'll be notified as soon as you take the unit"),
                                textAlign: TextAlign.center,
                                style: BunoType.caption.copyWith(color: BunoDark.text_secondary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              BunoPrimaryButton(
                label: tr('امسح وخد', 'Scan and take'),
                icon: BunoIcons.scan,
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.scan),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
