import 'package:flutter/material.dart';

import '../../data/mock_rental.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_info_row.dart';
import '../../widgets/buno_text.dart';
import '../../l10n/buno_locale.dart';

/// Colour of each late-return stage (the stepper in references 44–47).
Color lateStageColor(LateStage stage) => switch (stage) {
      LateStage.reminder => BunoColors.secondary,
      LateStage.warning => BunoColors.warning,
      LateStage.lastChance => BunoColors.error,
      LateStage.kept => BunoDark.text_secondary,
    };

/// Banner on /rental for a late rental (references 44–47): a four-step
/// stepper, then the stage's message. [remaining] is the time left before
/// the no-return fee, shown as a countdown at [LateStage.warning] and
/// [LateStage.lastChance].
class LateReturnBanner extends StatelessWidget {
  const LateReturnBanner({super.key, required this.stage, required this.remaining});

  final LateStage stage;
  final Duration remaining;

  static List<String> get _labels => [tr('تذكير', 'Reminder'), tr('تنبيه', 'Warning'), tr('آخر فرصة', 'Last chance'), tr('بعد 24 ساعة', 'After 24 hours')];

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final color = lateStageColor(stage);
    // Whole minutes left, rounded up so it reads 00:00 only at the fee.
    final left = remaining.isNegative ? 0 : (remaining.inSeconds + 59) ~/ 60;
    final (h, m) = (left ~/ 60, left % 60);
    final (title, body) = switch (stage) {
      LateStage.reminder => (tr('خلّصت شحن؟', 'Done charging?'), tr('بقالك [المدة] معاك. لو موبايلك اتشحن، رجّعه دلوقتي ووقّف العدّاد.', "You've had it for [duration]. If your phone is charged, return it now and stop the timer.")),
      LateStage.warning => (tr('فاضل وقت قليل', 'Not much time left'), tr('الساعات اللي فاتت متحسبة بالسقف اليومي، مش بالدقيقة.', 'Past hours are charged at the daily cap, not by the minute.')),
      LateStage.lastChance => (tr('آخر فرصة للإرجاع', 'Last chance to return'), tr('في مشكلة منعتك؟ كلّمنا قبل ما الوقت يخلص وهنشوف حل.', "Something stopping you? Talk to us before time runs out and we'll find a fix.")),
      LateStage.kept => (
          tr('الوحدة بقت بتاعتك', 'The unit is yours now'),
          tr('عدّت 24 ساعة، فاتحسبت رسوم عدم الإرجاع، والباور بانك بقى ملكك تستخدمه زي ما تحب.', '24 hours have passed, so the non-return fee was charged and the power bank is yours to use as you like.')
        ),
    };
    final countdown = stage == LateStage.warning || stage == LateStage.lastChance;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(BunoSpace.s4),
        decoration: BoxDecoration(
          color: Color.alphaBlend(color.withValues(alpha: 0.08), BunoDark.card),
          borderRadius: BorderRadius.circular(BunoRadius.xl),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Stepper(stage: stage, labels: _labels),
            const SizedBox(height: BunoSpace.s3),
            Row(
              children: [
                Expanded(child: BunoText(title, style: BunoType.title.copyWith(fontWeight: FontWeight.w700))),
                if (countdown) ...[
                  const SizedBox(width: BunoSpace.s2),
                  Semantics(
                    label: tr('فاضل $h ساعة و$m دقيقة', '${h}h ${m}m left'),
                    excludeSemantics: true,
                    child: BunoText(
                      '${_two(h)}:${_two(m)}',
                      style: BunoType.number(BunoType.h2).copyWith(color: color, height: 1.1),
                    ),
                  ),
                ],
              ],
            ),
            if (countdown)
              BunoText(
                tr('فاضل قبل رسوم عدم الإرجاع', 'left before the non-return fee'),
                style: BunoType.caption.copyWith(color: BunoDark.text_secondary),
              ),
            const SizedBox(height: BunoSpace.s1),
            BunoText(body, style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary)),
            if (stage == LateStage.lastChance) ...[
              const SizedBox(height: BunoSpace.s2),
              _FeeRow(tr('لو مرجعتوش', "If you don't return it"), tr('[رسوم عدم الإرجاع]', '[Non-return fee]'), BunoColors.error),
              _FeeRow(tr('لو رجّعته دلوقتي', 'If you return it now'), tr('[السقف اليومي] بس', 'Only [daily cap]'), BunoColors.secondary),
            ],
            if (stage == LateStage.kept) ...[
              const SizedBox(height: BunoSpace.s2),
              BunoInfoRow(tr('رسوم عدم الإرجاع', 'Non-return fee'), tr('[المبلغ]', '[Amount]'), divider: true),
              BunoInfoRow(tr('اتخصم من', 'Taken from'), tr('رصيد المحفظة', 'Wallet balance')),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.stage, required this.labels});

  final LateStage stage;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final s in LateStage.values) ...[
          if (s.index > 0) const SizedBox(width: BunoSpace.s1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: s.index <= stage.index ? lateStageColor(s) : BunoDark.border,
                    borderRadius: BorderRadius.circular(BunoRadius.pill),
                  ),
                ),
                const SizedBox(height: BunoSpace.s1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: BunoText(
                    labels[s.index],
                    style: BunoType.caption.copyWith(
                      fontSize: 11,
                      color: s == stage ? lateStageColor(s) : BunoDark.text_secondary,
                      fontWeight: s == stage ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BunoSpace.s1),
      child: Row(
        children: [
          Expanded(child: BunoText(label, style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary))),
          BunoText(value, style: BunoType.bodySm.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
