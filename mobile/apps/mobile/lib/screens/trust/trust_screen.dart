import 'package:flutter/material.dart';

import '../../data/mock_trust.dart';
import '../../l10n/buno_locale.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_charge_bar.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_status_pill.dart';
import '../../widgets/buno_text.dart';
import '../account/account_scaffold.dart';

/// Trust level (مستواك في بونو, reference 59): new → regular → trusted by
/// on-time returns ([MockTrust]), what each level unlocks, and progress to
/// the next one. From /profile and the wallet card's level badge.
class TrustScreen extends StatelessWidget {
  const TrustScreen({super.key});

  Future<void> _howToLevelUp(BuildContext context) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: BunoDark.elevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BunoRadius.xl)),
          title: Text(tr('إزاي بترفع مستواك', 'How to level up'), style: BunoType.title),
          content: BunoText(
            tr(
              'كل إيجار ترجّعه في الوقت بيتحسب لك. [العدد] إيجارات في الوقت بيخلّوك عميل منتظم، و[العدد] بيخلّوك عميل موثوق. أي تأخير بينزّلك مستوى.',
              'Every rental you return on time counts. [N] on-time returns make you Regular, [N] make you Trusted. Any late return drops you a level.',
            ),
            style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(tr('تمام', 'OK'), style: BunoType.body.copyWith(fontWeight: FontWeight.w700, color: BunoColors.primary)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AccountScaffold(
      title: tr('مستواك في بونو', 'Your Buno level'),
      button: BunoSecondaryButton(
        label: tr('إزاي بترفع مستواك', 'How to level up'),
        labelWeight: FontWeight.w700,
        onPressed: () => _howToLevelUp(context),
      ),
      children: [
        const _CurrentLevelCard(),
        const SizedBox(height: BunoSpace.s4),
        const _LevelsCard(),
        const SizedBox(height: BunoSpace.s5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsetsDirectional.only(top: 2),
              child: BunoLottieIcon(name: 'clock', size: BunoSize.iconSm, color: BunoColors.warning),
            ),
            const SizedBox(width: BunoSpace.s2),
            Expanded(
              child: Text(
                tr('التأخير في الإرجاع بينزّلك مستوى. الإرجاع في الوقت بيرفعك.', 'A late return drops you a level. Returning on time raises you.'),
                style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: BunoDark.card,
      borderRadius: BorderRadius.circular(BunoRadius.xl),
      border: Border.all(color: BunoDark.border),
    );

class _CurrentLevelCard extends StatelessWidget {
  const _CurrentLevelCard();

  @override
  Widget build(BuildContext context) {
    final level = MockTrust.current;
    final next = MockTrust.next;
    final returns = MockTrust.onTimeReturns;
    final muted = BunoType.bodySm.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary);
    final value = BunoType.bodySm.copyWith(fontWeight: FontWeight.w700);
    return Container(
      padding: const EdgeInsets.all(BunoSpace.s5),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BunoText(tr('مستوى ${level.number}', 'Level ${level.number}'), style: muted),
                    Text(level.name.text, style: BunoType.h1.copyWith(height: 1.3)),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: BunoColors.primary_soft),
                child: const BunoIcon(BunoIcons.check, size: BunoSize.iconLg, color: BunoColors.primary),
              ),
            ],
          ),
          const SizedBox(height: BunoSpace.s3),
          _PerkRow(label: tr('أقصى مدة إيجار', 'Longest rental'), value: level.hoursText, labelStyle: muted, valueStyle: value),
          const SizedBox(height: BunoSpace.s1),
          _PerkRow(label: tr('عدد الوحدات في نفس الوقت', 'Units at the same time'), value: level.unitsText, labelStyle: muted, valueStyle: value),
          const SizedBox(height: BunoSpace.s4),
          if (next == null)
            Text(tr('إنت في أعلى مستوى', "You're at the top level"), style: value.copyWith(color: BunoColors.primary))
          else ...[
            Row(
              children: [
                Expanded(
                  child: BunoText(
                    tr(
                      'فاضل [العدد] إيجارات للمستوى ${next.number}',
                      '[N] more rentals to level ${next.number}',
                    ),
                    style: value.copyWith(color: BunoDark.text_secondary),
                  ),
                ),
                const SizedBox(width: BunoSpace.s2),
                BunoText(tr('$returns / [العدد]', '$returns / [N]'), style: value.copyWith(color: BunoDark.text_secondary)),
              ],
            ),
            const SizedBox(height: BunoSpace.s2),
            LayoutBuilder(
              builder: (context, c) => BunoChargeBar(
                value: returns / next.returnsNeeded,
                width: c.maxWidth,
                color: BunoColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({required this.label, required this.value, required this.labelStyle, required this.valueStyle});

  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        const SizedBox(width: BunoSpace.s2),
        BunoText(value, style: valueStyle),
      ],
    );
  }
}

class _LevelsCard extends StatelessWidget {
  const _LevelsCard();

  @override
  Widget build(BuildContext context) {
    final current = MockTrust.current;
    return Container(
      padding: const EdgeInsets.all(BunoSpace.s5),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr('المستويات', 'Levels'), style: BunoType.body.copyWith(fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: BunoSpace.s3),
          for (var i = 0; i < MockTrust.levels.length; i++)
            _LevelStep(
              level: MockTrust.levels[i],
              state: MockTrust.levels[i].number < current.number
                  ? _StepState.done
                  : MockTrust.levels[i] == current
                      ? _StepState.current
                      : _StepState.locked,
              last: i == MockTrust.levels.length - 1,
            ),
        ],
      ),
    );
  }
}

enum _StepState { done, current, locked }

/// One level on the timeline: marker and connector at the start edge.
class _LevelStep extends StatelessWidget {
  const _LevelStep({required this.level, required this.state, required this.last});

  final TrustLevel level;
  final _StepState state;
  final bool last;

  static const _marker = 26.0;

  @override
  Widget build(BuildContext context) {
    final locked = state == _StepState.locked;
    final marker = Container(
      width: _marker,
      height: _marker,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (state) {
          _StepState.done => BunoColors.primary_soft,
          _StepState.current => BunoColors.primary,
          _StepState.locked => BunoDark.card,
        },
        border: locked ? Border.all(color: BunoDark.border) : null,
      ),
      child: locked
          ? BunoText('${level.number}', style: BunoType.caption.copyWith(color: BunoDark.text_secondary))
          : BunoIcon(
              BunoIcons.check,
              size: BunoSize.iconSm,
              color: state == _StepState.current ? BunoDark.on_primary : BunoColors.primary,
            ),
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _marker,
            child: Column(
              children: [
                const SizedBox(height: 2),
                marker,
                if (!last)
                  const Expanded(child: VerticalDivider(width: 1, thickness: 1, color: BunoDark.border)),
              ],
            ),
          ),
          const SizedBox(width: BunoSpace.s3),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : BunoSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: BunoSpace.s2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        level.name.text,
                        style: BunoType.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                          color: locked ? BunoDark.text_secondary : BunoDark.text_primary,
                        ),
                      ),
                      if (state == _StepState.current) BunoStatusPill(tr('مستواك', 'You')),
                    ],
                  ),
                  BunoText(
                    '${level.hoursText} · ${level.unitsText}',
                    style: BunoType.caption.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
