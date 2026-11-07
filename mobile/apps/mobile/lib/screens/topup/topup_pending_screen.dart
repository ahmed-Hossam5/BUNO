import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_rental.dart';
import '../../data/mock_topup.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_empty_state.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/buno_text_link.dart';
import 'topup_screen.dart';
import '../../l10n/buno_locale.dart';

/// /topup/pending (reference 18_topup_pending): the transfer is under
/// review. The mock review ([reviewTopup]) takes [topupReviewDelay], then
/// this screen replaces itself with /topup/done. Back is disabled. A
/// debug-only link simulates a declined transfer (reference
/// 31_state_topup_declined).
class TopupPendingScreen extends StatefulWidget {
  const TopupPendingScreen({super.key, required this.request});

  final TopupRequest request;

  @override
  State<TopupPendingScreen> createState() => _TopupPendingScreenState();
}

class _TopupPendingScreenState extends State<TopupPendingScreen> {
  /// The transfer was declined (simulated).
  bool _declined = false;

  @override
  void initState() {
    super.initState();
    reviewTopup(widget.request).then((receipt) {
      // The mock review can't be stopped, so undo what it added.
      if (_declined) rentalSession.balance = receipt.before;
      if (!mounted || _declined) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.topupDone, arguments: receipt);
    });
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    if (_declined) {
      return Scaffold(
        backgroundColor: BunoDark.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
            child: BunoEmptyState(
              header: TopupHeader(tr('الشحن', 'Top-up')),
              icon: const BunoLottieIcon(name: 'nav_wallet', size: 40, color: BunoColors.error, playKey: 0),
              title: tr('التحويل اترفض', 'Transfer declined'),
              body: tr('رقم العملية مش موجود في كشف الحساب، ومفيش فلوس اتخصمت من محفظتك. ', "The transaction number isn't on the statement, and nothing was taken from your wallet. ") +
                  tr('اتأكد من الرقم وارفع الإيصال تاني.', 'Check the number and upload the receipt again.'),
              actionLabel: tr('ارفع إيصال تاني', 'Upload another receipt'),
              onAction: () => Navigator.of(context).pushReplacementNamed(AppRoutes.topupTransfer, arguments: request),
              linkLabel: tr('كلّمنا', 'Contact us'),
              onLink: () => Navigator.of(context).pushNamed(AppRoutes.help),
            ),
          ),
        ),
      );
    }
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: BunoDark.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TopupHeader(tr('شحن تحت المراجعة', 'Top-up under review'), back: false),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: BunoSpace.s6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: BunoLottieIcon(name: 'buno_loader', size: 96, loop: true)),
                          const SizedBox(height: BunoSpace.s4),
                          BunoText(
                            tr('${request.amount} جنيه جايين في السكة', '${request.amount} EGP on the way'),
                            textAlign: TextAlign.center,
                            style: BunoType.h2.copyWith(color: BunoColors.warning),
                          ),
                          Text(
                            request.method.title,
                            textAlign: TextAlign.center,
                            style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary),
                          ),
                          const SizedBox(height: BunoSpace.s6),
                          Container(
                            padding: const EdgeInsets.all(BunoSpace.s5),
                            decoration: BoxDecoration(
                              color: BunoDark.card,
                              borderRadius: BorderRadius.circular(BunoRadius.lg),
                              border: Border.all(color: BunoDark.border),
                            ),
                            child: Column(
                              children: [
                                _Step(tr('استلمنا الطلب', 'Request received'), tr('دلوقتي', 'Now'), _StepStatus.done),
                                _Step(tr('بنراجع التحويل', 'Reviewing the transfer'), tr('عادةً في خلال 15 دقيقة', 'Usually within 15 minutes'), _StepStatus.current),
                                _Step(tr('اتضاف للرصيد', 'Added to balance'), null, _StepStatus.next, last: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (kDebugMode)
                  BunoTextLink(
                    tr('تجربة: التحويل اترفض', 'Test: transfer declined'),
                    onTap: () => setState(() => _declined = true),
                    color: BunoColors.info,
                  ),
                BunoText(
                  tr('هنبعتلك إشعار أول ما الرصيد يوصل.', "We'll notify you as soon as the balance arrives."),
                  textAlign: TextAlign.center,
                  style: BunoType.caption.copyWith(color: BunoDark.text_secondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _StepStatus { done, current, next }

class _Step extends StatelessWidget {
  const _Step(this.title, this.detail, this.status, {this.last = false});

  final String title;
  final String? detail;
  final _StepStatus status;
  final bool last;

  static const _dot = 26.0;

  @override
  Widget build(BuildContext context) {
    final pending = status == _StepStatus.next;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: _dot,
                height: _dot,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: status == _StepStatus.done ? BunoColors.primary : null,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: switch (status) {
                      _StepStatus.done => BunoColors.primary,
                      _StepStatus.current => BunoColors.warning,
                      _StepStatus.next => BunoDark.border,
                    },
                    width: BunoStroke.defaultWidth,
                  ),
                ),
                child: switch (status) {
                  _StepStatus.done => const BunoIcon(BunoIcons.check, size: BunoSize.iconSm, color: BunoDark.on_primary),
                  _StepStatus.current => const BunoLottieIcon(
                      name: 'clock',
                      size: BunoSize.iconSm,
                      color: BunoColors.warning,
                      loop: true,
                    ),
                  _StepStatus.next => null,
                },
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: BunoStroke.defaultWidth,
                    constraints: const BoxConstraints(minHeight: BunoSpace.s3),
                    color: status == _StepStatus.done ? BunoColors.primary : BunoDark.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: BunoSpace.s3),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : BunoSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: BunoType.title.copyWith(
                      fontSize: 15,
                      color: pending ? BunoDark.text_secondary : BunoDark.text_primary,
                    ),
                  ),
                  if (detail != null)
                    BunoText(detail!, style: BunoType.caption.copyWith(color: BunoDark.text_secondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
