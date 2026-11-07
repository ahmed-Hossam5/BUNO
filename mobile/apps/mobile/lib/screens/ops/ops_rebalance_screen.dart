import 'package:flutter/material.dart';

import '../../data/mock_ops.dart';
import '../../data/mock_rental.dart';
import '../../l10n/buno_locale.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_step_row.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/buno_text_link.dart';
import '../auth/auth_scaffold.dart' show showBunoToast;
import 'ops_scaffold.dart';

/// Moving units between stations (reference 94): open the planned bays,
/// check the units as they come out, walk, drop them in empty bays. From
/// the moment they are taken out the units are with the operator
/// ([OpsRebalance.carried]), in neither station, until dropped. Opened
/// directly, it plans [opsSuggestedMove]. State lives in [MockOps.rebalance].
class OpsRebalanceScreen extends StatefulWidget {
  const OpsRebalanceScreen({super.key});

  @override
  State<OpsRebalanceScreen> createState() => _OpsRebalanceScreenState();
}

class _OpsRebalanceScreenState extends State<OpsRebalanceScreen> {
  final _run = MockOps.rebalance;

  @override
  void initState() {
    super.initState();
    if (!_run.started) _run.start();
  }

  void _drop() {
    final to = _run.to;
    final n = _run.dropAll();
    showBunoToast(context, tr('اتنقلت $n وحدات لـ${to.name}', '$n units moved to ${to.name}'));
    if (_run.carried.isEmpty) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final run = _run;
    return OpsSubScaffold(
      listenTo: run,
      title: () => run.started ? tr('نقل ${run.count} وحدات', 'Move ${run.count} units') : tr('نقل وحدات', 'Move units'),
      subtitle: () => OpsSubtitle(
        run.started ? tr('من ${run.from.name} لـ${run.to.name}', 'From ${run.from.name} to ${run.to.name}') : '',
      ),
      children: (context) {
        if (!run.started) return const [];
        final ids = run.carried.map((c) => c.unit.id).join(' · ');
        final n = run.count;
        final steps = [
          (
            tr('افتح ${opsBayList(run.bays)}', 'Open ${opsBayList(run.bays)}'),
            tr('المحطة بتفتحهم واحدة ورا التانية.', 'The station opens them one after another.'),
            'unlock',
          ),
          (
            tr('اتأكد من الوحدات', 'Check the units'),
            run.carried.isEmpty
                ? tr('طلّعهم والمحطة هتقرا كل وحدة.', 'Take them out; the station reads each one.')
                : tr('اتقرت $n من $n: $ids', 'Read $n of $n: $ids'),
            'scan',
          ),
          (
            tr('امشي لـ${run.to.name}', 'Walk to ${run.to.name}'),
            tr('الوحدات مسجّلة معاك لحد ما ترجّعها.', 'The units are on your name until you drop them.'),
            'navigate',
          ),
          (
            tr('حطهم في أي خانات فاضية', 'Put them in any empty bays'),
            tr('المحطة بتقرا كل وحدة وتسجّلها.', 'The station reads and logs each unit.'),
            'download',
          ),
        ];
        return [
          _Route(run: run),
          const SizedBox(height: BunoSpace.s6),
          if (run.bays.isEmpty && run.carried.isEmpty)
            Text(
              tr('مفيش وحدات جاهزة زيادة للنقل دلوقتي.', 'No spare ready units to move right now.'),
              style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary),
            )
          else
            for (final step in RebalanceStep.values)
              BunoStepRow(
                title: steps[step.index].$1,
                detail: steps[step.index].$2,
                lottie: steps[step.index].$3,
                last: step == RebalanceStep.drop,
                status: step.index < run.step.index
                    ? BunoStepStatus.done
                    : step == run.step
                        ? BunoStepStatus.current
                        : BunoStepStatus.next,
              ),
        ];
      },
      bottom: (context) {
        if (!run.started) return const SizedBox.shrink();
        final button = switch (run.step) {
          RebalanceStep.open => BunoPrimaryButton(
              label: tr('افتح الخانات', 'Open the bays'),
              icon: BunoIcons.lock,
              onPressed: run.bays.isEmpty ? null : run.openBays,
            ),
          RebalanceStep.verify => BunoPrimaryButton(
              label: tr('خدت الوحدات', 'I took the units'),
              icon: BunoIcons.check,
              onPressed: run.takeOut,
            ),
          RebalanceStep.walk => BunoPrimaryButton(
              label: tr('وصلت ${run.to.name}', 'At ${run.to.name}'),
              icon: BunoIcons.scan,
              onPressed: run.arrive,
            ),
          RebalanceStep.drop => BunoPrimaryButton(
              label: tr('حطّيتهم', 'Dropped them'),
              icon: BunoIcons.check,
              onPressed: _drop,
            ),
        };
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            button,
            const SizedBox(height: BunoSpace.s2),
            BunoTextLink(
              tr('مشكلة في النقل؟', 'Problem with the move?'),
              onTap: () => showBunoToast(context, tr('البلاغات هتكون جاهزة قريب', 'Reports are coming soon')),
            ),
          ],
        );
      },
    );
  }
}

/// From → to, each with its ready units before → after the move.
class _Route extends StatelessWidget {
  const _Route({required this.run});

  final OpsRebalance run;

  @override
  Widget build(BuildContext context) {
    final n = run.count;
    final count = BunoType.caption.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary);
    Widget end(String label, Station s, int before, int after, CrossAxisAlignment align) => Column(
          crossAxisAlignment: align,
          children: [
            Text(label, style: BunoType.caption.copyWith(color: BunoDark.text_secondary)),
            Text(s.name, maxLines: 2, textAlign: align == CrossAxisAlignment.end ? TextAlign.end : TextAlign.start, style: BunoType.title.copyWith(fontWeight: FontWeight.w700)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BunoText('$before', style: count),
                const SizedBox(width: BunoSpace.s1),
                BunoIcon(opsEndArrow(context), size: BunoSize.iconSm, color: BunoDark.text_secondary),
                const SizedBox(width: BunoSpace.s1),
                BunoText('$after', style: count),
              ],
            ),
          ],
        );
    return OpsCard(
      color: BunoDark.elevated,
      borderColor: BunoDark.elevated,
      padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s5, vertical: BunoSpace.s4),
      child: Row(
        children: [
          Expanded(child: end(tr('من', 'From'), run.from, run.fromReadyBefore, run.fromReadyBefore - n, CrossAxisAlignment.start)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s3),
            child: BunoIcon(opsEndArrow(context), size: BunoSize.iconLg, color: BunoColors.info),
          ),
          Expanded(child: end(tr('لـ', 'To'), run.to, run.toReadyBefore, run.toReadyBefore + n, CrossAxisAlignment.end)),
        ],
      ),
    );
  }
}
