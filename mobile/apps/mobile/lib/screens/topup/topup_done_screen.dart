import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_topup.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_lottie_icon.dart';
import 'topup_screen.dart';
import '../../l10n/buno_locale.dart';

/// /topup/done (reference 19_topup_done): success plays once and the balance
/// counts up from [TopupReceipt.before] to [TopupReceipt.after]. "تمام" goes
/// back to the screen that opened /topup (the wallet, or /confirm when the
/// low-balance sheet opened it).
class TopupDoneScreen extends StatelessWidget {
  const TopupDoneScreen({super.key, required this.receipt});

  final TopupReceipt receipt;

  /// Long enough to read the count; no motion token is this slow.
  static const countUpDuration = Duration(milliseconds: 1200);

  static bool _isTopup(String? name) => name != null && name.startsWith(AppRoutes.topup);

  void _close(BuildContext context) {
    final nav = Navigator.of(context);
    String? landed;
    nav.popUntil((r) {
      if (r.isFirst || !_isTopup(r.settings.name)) {
        landed = r.settings.name;
        return true;
      }
      return false;
    });
    // Opened with nothing else below it: land on the wallet.
    if (_isTopup(landed)) nav.pushReplacementNamed(AppRoutes.wallet);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final request = receipt.request;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(context);
      },
      child: Scaffold(
        backgroundColor: BunoDark.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TopupHeader(tr('المحفظة', 'Wallet'), back: false),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: BunoSpace.s6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: BunoLottieIcon(name: 'success', size: 96, playKey: true)),
                          const SizedBox(height: BunoSpace.s4),
                          Text(
                            tr('الرصيد اتضاف', 'Balance added'),
                            textAlign: TextAlign.center,
                            style: BunoType.h2,
                          ),
                          const SizedBox(height: BunoSpace.s6),
                          Container(
                            padding: const EdgeInsets.all(BunoSpace.s5),
                            decoration: BoxDecoration(
                              color: BunoDark.card,
                              borderRadius: BorderRadius.circular(BunoRadius.xxl),
                              border: Border.all(color: BunoDark.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  tr('رصيد المحفظة', 'Wallet balance'),
                                  style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary),
                                ),
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: receipt.before, end: receipt.after),
                                  duration: reduceMotion ? Duration.zero : countUpDuration,
                                  curve: BunoMotion.easing,
                                  builder: (_, value, _) => TopupAmount(value, color: BunoColors.primary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: BunoSpace.s4),
                          Container(
                            padding: const EdgeInsets.all(BunoSpace.s4),
                            decoration: BoxDecoration(
                              color: BunoColors.primary_soft,
                              borderRadius: BorderRadius.circular(BunoRadius.lg),
                            ),
                            child: Row(
                              children: [
                                const BunoIcon(BunoIcons.plus, color: BunoColors.primary),
                                const SizedBox(width: BunoSpace.s3),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(tr('شحن المحفظة', 'Wallet top-up'), style: BunoType.title.copyWith(fontSize: 15)),
                                      Text(
                                        tr('${request.method.title} · دلوقتي', '${request.method.title} · now'),
                                        style: BunoType.caption.copyWith(color: BunoDark.text_secondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '+${request.amount}',
                                  textDirection: TextDirection.ltr,
                                  style: BunoType.number(BunoType.title).copyWith(color: BunoColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                BunoPrimaryButton(label: tr('تمام', 'Done'), onPressed: () => _close(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
