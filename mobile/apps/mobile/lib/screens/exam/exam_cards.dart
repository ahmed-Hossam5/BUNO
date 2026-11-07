import 'package:flutter/material.dart';

import '../../data/mock_exam.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_status_pill.dart';
import '../../widgets/buno_text.dart';
import '../../l10n/buno_locale.dart';

/// Home's top area in exam week (reference 55): the next exam's countdown
/// and the study-night pack. [onNight] starts the pack and opens
/// /exam/night (or just opens it once running).
class ExamHomeCards extends StatelessWidget {
  const ExamHomeCards({super.key, required this.onNight});

  final VoidCallback onNight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: BunoStatusPill(tr('أسبوع الامتحانات', 'Exam week'), color: BunoColors.warning),
        ),
        const SizedBox(height: BunoSpace.s3),
        const _NextExamCard(),
        const SizedBox(height: BunoSpace.s3),
        _StudyNightCard(active: studyNight.active, onTap: onNight),
      ],
    );
  }
}

BoxDecoration _card({Color border = BunoDark.border, Color color = BunoDark.card}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(BunoRadius.xl),
      border: Border.all(color: border),
    );

class _NextExamCard extends StatelessWidget {
  const _NextExamCard();

  @override
  Widget build(BuildContext context) {
    final secondary = BunoType.caption.copyWith(color: BunoDark.text_secondary);
    return Semantics(
      label: tr('امتحانك الجاي ${MockExam.subject} بعد ${MockExam.daysLeft} يوم', 'Your next exam, ${MockExam.subject}, is in ${MockExam.daysLeft} days'),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(BunoSpace.s4),
        decoration: _card(),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BunoText(tr('امتحانك الجاي', 'Your next exam'), style: secondary),
                  BunoText(MockExam.subject, maxLines: 1, style: BunoType.title.copyWith(fontWeight: FontWeight.w700)),
                  BunoText(MockExam.details, maxLines: 1, style: secondary),
                ],
              ),
            ),
            const SizedBox(width: BunoSpace.s3),
            Column(
              children: [
                BunoText('${MockExam.daysLeft}', style: BunoType.h1.copyWith(color: BunoColors.warning, height: 1.1)),
                BunoText(tr('يوم', 'days'), style: secondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyNightCard extends StatelessWidget {
  const _StudyNightCard({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BunoSpace.s4),
      decoration: _card(border: BunoColors.primary_deep, color: BunoColors.primary_soft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BunoText(
            active ? tr('باقة ليلة المذاكرة · شغالة', 'Study-night pack · active') : tr('باقة ليلة المذاكرة', 'Study-night pack'),
            style: BunoType.caption.copyWith(fontWeight: FontWeight.w700, color: BunoColors.primary),
          ),
          const SizedBox(height: BunoSpace.s1),
          BunoText(
            tr('من 8 بالليل لـ 8 الصبح بسعر واحد', 'From 8 pm to 8 am for one price'),
            style: BunoType.title.copyWith(fontWeight: FontWeight.w700),
          ),
          BunoText(tr('[السعر] بدل الحساب بالساعة', '[Price] instead of paying by the hour'), style: BunoType.caption.copyWith(color: BunoDark.text_secondary)),
          const SizedBox(height: BunoSpace.s3),
          // Secondary: home's one primary button stays at the bottom.
          BunoSecondaryButton(
            label: active ? tr('شوف الباقة', 'See the pack') : tr('فعّل الباقة الليلة', 'Turn on the pack tonight'),
            height: BunoSize.touchMin,
            labelWeight: FontWeight.w700,
            leading: const BunoLottieIcon(name: 'moon', size: BunoSize.iconSm, playKey: true, color: BunoColors.primary),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
