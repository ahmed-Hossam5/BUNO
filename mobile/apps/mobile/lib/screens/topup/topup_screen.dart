import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_topup.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_amount_chip.dart';
import '../../widgets/buno_back_button.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_tab_header.dart';
import '../../l10n/buno_locale.dart';

/// /topup (reference 16_topup): the amount, 50/100/200/500 chips and the
/// payment method. "كمّل" opens /topup/transfer with a [TopupRequest].
class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key, this.amount});

  /// Preselected amount (EGP), e.g. from the low-balance sheet; 100 if null.
  final int? amount;

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  late int _amount = widget.amount ?? 100;
  TopupMethod _method = TopupMethod.vodafoneCash;

  void _continue() => Navigator.of(context).pushNamed(
        AppRoutes.topupTransfer,
        arguments: TopupRequest(amount: _amount, method: _method),
      );

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
              TopupHeader(tr('اشحن المحفظة', 'Top up wallet')),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: BunoSpace.s6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TopupAmount(_amount),
                      const SizedBox(height: BunoSpace.s5),
                      Row(
                        children: [
                          for (final a in topupAmounts) ...[
                            if (a != topupAmounts.first) const SizedBox(width: BunoSpace.s2),
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
                      const SizedBox(height: BunoSpace.s6),
                      BunoSectionTitle(tr('هتدفع إزاي', 'How will you pay')),
                      const SizedBox(height: BunoSpace.s3),
                      for (final m in TopupMethod.values) ...[
                        if (m != TopupMethod.values.first) const SizedBox(height: BunoSpace.s3),
                        _MethodRow(
                          method: m,
                          selected: m == _method,
                          onTap: () => setState(() => _method = m),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              BunoPrimaryButton(label: tr('كمّل', 'Continue'), onPressed: _continue),
            ],
          ),
        ),
      ),
    );
  }
}

/// Title centred with the back button at the start, as on /confirm.
class TopupHeader extends StatelessWidget {
  const TopupHeader(this.title, {super.key, this.back = true});

  final String title;
  final bool back;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: BunoSize.touchMin,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(title, style: BunoType.title),
          if (back)
            const Align(
              alignment: AlignmentDirectional.centerEnd,
              child: BunoBackButton(),
            ),
        ],
      ),
    );
  }
}

/// "[amount] EGP", big and left-to-right like the wallet card.
class TopupAmount extends StatelessWidget {
  const TopupAmount(this.amount, {super.key, this.color = BunoDark.text_primary});

  final num amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final number = BunoType.number(BunoType.display).copyWith(fontSize: 72, height: 1.15, color: color);
    return Semantics(
      label: tr('${amount.round()} جنيه', '${amount.round()} EGP'),
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          textDirection: TextDirection.ltr,
          children: [
            Text('${amount.round()}', style: number),
            const SizedBox(width: BunoSpace.s3),
            Text(
              'EGP',
              style: number.copyWith(fontSize: 22, color: BunoDark.text_secondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({required this.method, required this.selected, required this.onTap});

  final TopupMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.of(context).disableAnimations ? Duration.zero : BunoMotion.fast;
    return Semantics(
      selected: selected,
      child: BunoPressable(
        onTap: onTap,
        semanticLabel: method.title,
        child: AnimatedContainer(
          duration: duration,
          padding: const EdgeInsets.all(BunoSpace.s4),
          decoration: BoxDecoration(
            color: BunoDark.card,
            borderRadius: BorderRadius.circular(BunoRadius.lg),
            border: Border.all(
              color: selected ? BunoColors.primary : BunoDark.border,
              width: selected ? BunoStroke.defaultWidth : BunoStroke.hairline,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: BunoSize.avatarMd,
                height: BunoSize.avatarMd,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? BunoColors.primary_soft : BunoDark.background,
                  borderRadius: BorderRadius.circular(BunoRadius.md),
                ),
                child: BunoIcon(
                  BunoIcons.wallet,
                  color: selected ? BunoColors.primary : BunoDark.text_primary,
                ),
              ),
              const SizedBox(width: BunoSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(method.title, style: BunoType.title.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      method.subtitle,
                      style: BunoType.caption.copyWith(color: BunoDark.text_secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BunoSpace.s3),
              AnimatedContainer(
                duration: duration,
                width: BunoSize.iconMd,
                height: BunoSize.iconMd,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? BunoColors.primary : BunoDark.border,
                    width: BunoStroke.defaultWidth,
                  ),
                ),
                child: selected
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: BunoColors.primary, shape: BoxShape.circle),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
