import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_rental.dart';
import '../../data/mock_sos.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_info_row.dart';
import '../../widgets/buno_logo.dart';
import '../../widgets/buno_status_pill.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/buno_text_link.dart';
import '../station/confirm_screen.dart' show showLowBalanceSheet;
import 'sos_avatar.dart';
import '../../l10n/buno_locale.dart';

/// /sos/help (reference 51): the friend's side of «إلحقني». "ادفعله بونو"
/// takes the first hour ([mockMinBalance], shown as `[سعر أول ساعة]`) from
/// the wallet, or shows the low-balance sheet when it isn't enough.
class SosHelpScreen extends StatelessWidget {
  const SosHelpScreen({super.key});

  static void _leave(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed(AppRoutes.home);
    }
  }

  void _pay(BuildContext context) {
    if (rentalSession.balance < mockMinBalance) {
      showLowBalanceSheet(context, askFriend: false);
      return;
    }
    rentalSession.balance -= mockMinBalance;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(tr('دفعت ل$mockSosAsker أول ساعة. هيوصله إشعار.', "You paid $mockSosAsker's first hour. They'll be notified.")),
        behavior: SnackBarBehavior.floating,
      ));
    _leave(context);
  }

  @override
  Widget build(BuildContext context) {
    final secondary = BunoType.bodySm.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary);
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BunoLogo(height: 32, glow: false),
                  BunoStatusPill(tr('إلحقني', 'Help me out'), color: BunoColors.error),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: BunoSpace.s6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: SizedBox(
                          width: 120,
                          height: 132,
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              SosAvatar(String.fromCharCode(mockSosAsker.runes.first), size: 120),
                              Positioned(
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s3),
                                  decoration: BoxDecoration(
                                    color: BunoColors.error,
                                    borderRadius: BorderRadius.circular(BunoRadius.pill),
                                  ),
                                  child: BunoText(
                                    '$mockSosAskerCharge%',
                                    style: BunoType.bodySm.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: BunoDark.on_primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: BunoSpace.s4),
                      BunoText(
                        tr('$mockSosAsker بيقولك\n«إلحقني»', '$mockSosAsker is asking you\n“Help me out”'),
                        textAlign: TextAlign.center,
                        style: BunoType.h1,
                      ),
                      const SizedBox(height: BunoSpace.s3),
                      BunoText(
                        tr('موبايله على $mockSosAskerCharge% وواقف عند [اسم المكان]. ', 'Their phone is at $mockSosAskerCharge% and they are at [place name]. ') +
                        tr('ادفعله أول ساعة وهو ياخد الباور بانك.', 'Pay their first hour and they take the power bank.'),
                        textAlign: TextAlign.center,
                        style: secondary,
                      ),
                      const SizedBox(height: BunoSpace.s5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s4),
                        decoration: BoxDecoration(
                          color: BunoDark.card,
                          borderRadius: BorderRadius.circular(BunoRadius.lg),
                          border: Border.all(color: BunoDark.border),
                        ),
                        child: Column(
                          children: [
                            BunoInfoRow(tr('هتدفع', "You'll pay"), tr('[سعر أول ساعة]', '[First hour price]'), divider: true),
                            BunoInfoRow(tr('بعد الساعة', 'After the hour'), tr('على حسابه هو', "It's on them")),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              BunoPrimaryButton(label: tr('ادفعله بونو', 'Pay for their Buno'), onPressed: () => _pay(context)),
              const SizedBox(height: BunoSpace.s2),
              BunoTextLink(tr('مش دلوقتي', 'Not now'), onTap: () => _leave(context)),
            ],
          ),
        ),
      ),
    );
  }
}
