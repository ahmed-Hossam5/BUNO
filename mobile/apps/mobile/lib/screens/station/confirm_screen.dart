import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_rental.dart';
import '../../data/mock_settings.dart';
import '../../data/mock_sos.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_amount_chip.dart';
import '../../widgets/buno_back_button.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_info_row.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/buno_text_link.dart';
import '../sos/sos_screen.dart' show openSos;
import '../../l10n/buno_locale.dart';

/// /confirm (reference 04_confirm): the chosen unit's charge and the price
/// rows. The CTA opens /verifying (which unlocks the bay), or shows the
/// low-balance sheet (05) when the wallet is below [mockMinBalance], unless
/// a friend paid the first hour («إلحقني», [SosSession.firstHourPaidBy]).
class ConfirmScreen extends StatelessWidget {
  const ConfirmScreen({super.key, required this.station, required this.bayIndex});

  final Station station;
  final int bayIndex;

  void _unlock(BuildContext context) {
    if (MockSettings.simulateOffline.value) {
      Navigator.of(context).pushNamed(AppRoutes.offline);
      return;
    }
    final paidBy = sosSession.firstHourPaidBy;
    if (paidBy == null && rentalSession.balance < mockMinBalance) {
      showLowBalanceSheet(context);
      return;
    }
    // Same rule as [RentalSession.unlock]: no second rental while one is
    // open. Returning goes through /return → /station, not here.
    final state = rentalSession.state;
    if (state != RentalState.idle && state != RentalState.returned && state != RentalState.kept) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(tr('عندك إيجار شغّال بالفعل', 'You already have an active rental')),
          behavior: SnackBarBehavior.floating,
        ));
      return;
    }
    sosSession.useFirstHour();
    Navigator.of(context).pushNamed(AppRoutes.verifying, arguments: (station, bayIndex));
  }

  @override
  Widget build(BuildContext context) {
    final charge = station.bays[bayIndex];
    final paidBy = sosSession.firstHourPaidBy;
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(tr('قبل ما تاخد', 'Before you take it'), style: BunoType.title),
                  const Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: BunoBackButton(),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: BunoSpace.s6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        tr('هتاخد وحدة شحنها', "You'll take a unit charged to"),
                        textAlign: TextAlign.center,
                        style: BunoType.bodySm.copyWith(
                          color: BunoDark.text_secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: BunoText(
                          charge == null ? '—' : '$charge%',
                          style: BunoType.display.copyWith(
                            fontSize: 88,
                            height: 1.15,
                            color: BunoColors.primary,
                          ),
                        ),
                      ),
                      BunoText(
                        tr('من ${station.name} · خانة ${bayIndex + 1}', 'From ${station.name} · bay ${bayIndex + 1}'),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: BunoType.bodySm.copyWith(
                          color: BunoDark.text_secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (paidBy != null) ...[
                        const SizedBox(height: BunoSpace.s3),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s4, vertical: BunoSpace.s2),
                            decoration: BoxDecoration(
                              color: BunoColors.primary_soft,
                              borderRadius: BorderRadius.circular(BunoRadius.pill),
                            ),
                            child: BunoText(
                              tr('الساعة الأولى مدفوعة من ${paidBy.name}', 'First hour paid by ${paidBy.name}'),
                              textAlign: TextAlign.center,
                              style: BunoType.bodySm.copyWith(
                                fontWeight: FontWeight.w600,
                                color: BunoColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: BunoSpace.s6),
                      BunoInfoRow(tr('أول ساعة', 'First hour'), tr('[السعر]', '[Price]'), divider: true),
                      BunoInfoRow(tr('بعدها', 'After that'), tr('[السعر] / دقيقة', '[Price] / min'), divider: true),
                      BunoInfoRow(tr('أقصى حاجة في اليوم', 'Daily maximum'), tr('[السقف اليومي]', '[Daily cap]'), divider: true),
                      BunoInfoRow(tr('لو مرجعتهاش في 24 ساعة', "If not returned within 24 hours"), tr('[رسوم عدم الإرجاع]', '[Non-return fee]')),
                    ],
                  ),
                ),
              ),
              BunoPrimaryButton(
                label: tr('تمام، افتح الخانة', 'OK, open the bay'),
                onPressed: charge == null ? null : () => _unlock(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Low-balance bottom sheet (reference 05): balance vs first hour, 50/100/200
/// chips, and a top-up CTA that opens /topup with the chosen amount. With
/// [askFriend], also "اطلب من صاحبك" («إلحقني») while today's is unused.
Future<void> showLowBalanceSheet(BuildContext context, {bool askFriend = true}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: BunoDark.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(BunoRadius.xxl)),
    ),
    builder: (_) => LowBalanceSheet(askFriend: askFriend),
  );
}

class LowBalanceSheet extends StatefulWidget {
  const LowBalanceSheet({super.key, this.askFriend = true});

  final bool askFriend;

  static const amounts = [50, 100, 200];

  @override
  State<LowBalanceSheet> createState() => _LowBalanceSheetState();
}

class _LowBalanceSheetState extends State<LowBalanceSheet> {
  int _amount = 100;

  void _topUp() {
    final nav = Navigator.of(context);
    nav.pop();
    nav.pushNamed(AppRoutes.topup, arguments: _amount);
  }

  void _askFriend() {
    final nav = Navigator.of(context);
    nav.pop();
    openSos(nav.context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, BunoSpace.s3, 22, BunoSpace.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: BunoDark.border,
                  borderRadius: BorderRadius.circular(BunoRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: BunoSpace.s5),
            Text(tr('رصيدك مش مكفّي', "Your balance isn't enough"), style: BunoType.h2),
            Text(
              tr('محتاج يغطي أول ساعة على الأقل.', 'It needs to cover at least the first hour.'),
              style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary),
            ),
            const SizedBox(height: BunoSpace.s3),
            BunoInfoRow(tr('رصيدك', 'Your balance'), tr('[الرصيد]', '[Balance]'), divider: true),
            BunoInfoRow(tr('أول ساعة', 'First hour'), tr('[السعر]', '[Price]')),
            const SizedBox(height: BunoSpace.s4),
            Row(
              children: [
                for (final a in LowBalanceSheet.amounts) ...[
                  if (a != LowBalanceSheet.amounts.first) const SizedBox(width: BunoSpace.s3),
                  Expanded(
                    child: BunoAmountChip(
                      amount: a,
                      selected: a == _amount,
                      onTap: () => setState(() => _amount = a),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: BunoSpace.s4),
            BunoPrimaryButton(label: tr('اشحن $_amount', 'Top up $_amount'), onPressed: _topUp),
            if (widget.askFriend && (sosSession.canSendToday || sosSession.state != SosState.idle))
              BunoTextLink(tr('اطلب من صاحبك', 'Ask a friend'), onTap: _askFriend, color: BunoColors.primary)
            else
              const SizedBox(height: BunoSpace.s3),
            Text(
              tr('مشترك؟ مش محتاج رصيد.', "Subscribed? You don't need a balance."),
              textAlign: TextAlign.center,
              style: BunoType.caption.copyWith(color: BunoDark.text_secondary),
            ),
          ],
        ),
      ),
    );
  }
}
