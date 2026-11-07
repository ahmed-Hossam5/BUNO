import 'package:flutter/material.dart';

import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text.dart';
import '../auth/auth_scaffold.dart' show showBunoToast;
import 'account_scaffold.dart';
import '../../l10n/buno_locale.dart';

class BunoPlan {
  const BunoPlan(this.name, this.blurb, {this.tag});

  final String name;
  final String blurb;
  final String? tag;
}

/// Plans (الباقات, reference 24). Prices stay placeholders; the middle plan
/// starts selected. Subscribe only shows a snackbar.
class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  static List<BunoPlan> get plans => [
    BunoPlan(tr('خفيف', 'Light'), tr('ساعات قليلة في الشهر', 'A few hours a month')),
    BunoPlan(tr('مريح', 'Comfort'), tr('لو بتستخدمه كل أسبوع', 'If you use it every week'), tag: tr('الأكتر', 'Popular')),
    BunoPlan(tr('الترم', 'Semester'), tr('طول الترم من غير ما تفكر', 'All semester, no second thoughts')),
  ];

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  int _selected = 1;

  @override
  Widget build(BuildContext context) {
    final plan = PlansScreen.plans[_selected];
    return AccountScaffold(
      title: tr('الباقات', 'Plans'),
      button: BunoPrimaryButton(
        label: tr('اشترك في «${plan.name}»', 'Subscribe to “${plan.name}”'),
        onPressed: () => showBunoToast(context, tr('اشتركت في «${plan.name}»', 'Subscribed to “${plan.name}”')),
      ),
      children: [
        for (var i = 0; i < PlansScreen.plans.length; i++) ...[
          if (i > 0) const SizedBox(height: BunoSpace.s3),
          _PlanCard(
            plan: PlansScreen.plans[i],
            selected: i == _selected,
            onTap: () => setState(() => _selected = i),
          ),
        ],
        const SizedBox(height: BunoSpace.s3),
        Text(
          tr('الأسعار هتتحدد من استخدام أول تجربة.', 'Prices will be set from the first trial.'),
          style: BunoType.caption.copyWith(color: BunoDark.text_secondary),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.selected, required this.onTap});

  final BunoPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? BunoDark.on_primary : BunoDark.text_primary;
    final muted = selected ? BunoDark.on_primary : BunoDark.text_secondary;
    return BunoPressable(
      onTap: onTap,
      semanticLabel: plan.name,
      child: AnimatedContainer(
        duration: MediaQuery.of(context).disableAnimations ? Duration.zero : BunoMotion.base,
        padding: const EdgeInsets.all(BunoSpace.s5),
        decoration: BoxDecoration(
          color: selected ? BunoColors.primary : BunoDark.card,
          borderRadius: BorderRadius.circular(BunoRadius.xl),
          border: Border.all(color: selected ? BunoColors.primary : BunoDark.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(plan.name, style: BunoType.h3.copyWith(color: fg, height: 1.3))),
                if (plan.tag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s2, vertical: 2),
                    decoration: BoxDecoration(
                      color: selected ? BunoDark.on_primary : BunoColors.primary_soft,
                      borderRadius: BorderRadius.circular(BunoRadius.pill),
                    ),
                    child: Text(plan.tag!, style: BunoType.caption.copyWith(fontWeight: FontWeight.w700, color: BunoColors.primary)),
                  ),
              ],
            ),
            Text(plan.blurb, style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w600, color: muted, height: 1.4)),
            const SizedBox(height: BunoSpace.s2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                BunoText(tr('[السعر]', '[Price]'), style: BunoType.h3.copyWith(color: fg, height: 1.2)),
                const SizedBox(width: BunoSpace.s1),
                Text(tr('/ شهر', '/ month'), style: BunoType.caption.copyWith(color: fg)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
