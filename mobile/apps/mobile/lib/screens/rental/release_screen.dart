import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/repositories.dart';
import '../../data/mock_rental.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_back_button.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_text.dart';
import '../../l10n/buno_locale.dart';

/// /release (reference 07_release): the open bay's number in a green square.
/// "خدتها" confirms the pickup and opens /rental in place of the rental flow.
/// Going back cancels the open bay (nothing has been charged yet).
class ReleaseScreen extends StatefulWidget {
  const ReleaseScreen({super.key});

  @override
  State<ReleaseScreen> createState() => _ReleaseScreenState();
}

class _ReleaseScreenState extends State<ReleaseScreen> {
  static const _square = 180.0;

  @override
  void initState() {
    super.initState();
    // Opened directly (`--route /release`): open the mock's best bay.
    final s = rentalSession.state;
    if (s == RentalState.idle || s == RentalState.returned) {
      final station = Repos.stations.all.first;
      unawaited(rentalSession.unlock(station, station.bestBayIndex!));
    }
    rentalSession.addListener(_onSession);
  }

  @override
  void dispose() {
    rentalSession.removeListener(_onSession);
    super.dispose();
  }

  void _onSession() => setState(() {});

  void _took() {
    rentalSession.confirmPickup();
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.rental, ModalRoute.withName(AppRoutes.home));
  }

  void _onPop(bool didPop, Object? _) {
    if (didPop && rentalSession.state == RentalState.released) rentalSession.reset();
  }

  @override
  Widget build(BuildContext context) {
    final bay = (rentalSession.bayIndex ?? 0) + 1;
    final released = rentalSession.state == RentalState.released;
    final secondary = BunoType.bodySm.copyWith(
      color: BunoDark.text_secondary,
      fontWeight: FontWeight.w600,
    );
    return PopScope(
      onPopInvokedWithResult: _onPop,
      child: Scaffold(
        backgroundColor: BunoDark.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: BunoBackButton(),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: BunoSpace.s4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                            child: BunoLottieIcon(
                              name: 'success',
                              size: BunoSize.iconLg,
                              color: BunoColors.primary,
                              playKey: true,
                            ),
                          ),
                          const SizedBox(height: BunoSpace.s3),
                          Text(tr('اسحب الباور بانك من خانة', 'Pull the power bank from bay'), textAlign: TextAlign.center, style: secondary),
                          const SizedBox(height: BunoSpace.s4),
                          Center(
                            child: Semantics(
                              label: tr('خانة $bay', 'Bay $bay'),
                              excludeSemantics: true,
                              child: Container(
                                width: _square,
                                height: _square,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: BunoColors.primary,
                                  borderRadius: BorderRadius.circular(BunoRadius.xxl * 1.5),
                                  boxShadow: const [BunoElevation.glow],
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: BunoText(
                                    '$bay',
                                    style: BunoType.display.copyWith(
                                      fontSize: 120,
                                      height: 1,
                                      color: BunoDark.on_primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: BunoSpace.s6),
                          Text(
                            tr('النور الأخضر بيرمش عليها', 'The green light is blinking on it'),
                            textAlign: TextAlign.center,
                            style: BunoType.h2,
                          ),
                          const SizedBox(height: BunoSpace.s3),
                          Text(
                            tr('الكابل جوه الوحدة. وصّله بموبايلك وامشي.', 'The cable is inside the unit. Plug it into your phone and go.'),
                            textAlign: TextAlign.center,
                            style: secondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                BunoPrimaryButton(label: tr('خدتها', 'Got it'), onPressed: released ? _took : null),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
