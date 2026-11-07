import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_ops.dart';
import '../../data/mock_rental.dart';
import '../../l10n/buno_locale.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_tab_header.dart';
import '../../widgets/buno_text.dart';
import 'ops_scaffold.dart';

/// Operations mode, "اليوم" tab (reference 91): today's numbers, the hot
/// bay as a banner, every station with its status.
class OpsHomeScreen extends StatelessWidget {
  const OpsHomeScreen({super.key});

  static const navIndex = 0;

  static const _days = [
    Tr('الاتنين', 'Monday'), Tr('التلات', 'Tuesday'), Tr('الأربعاء', 'Wednesday'), Tr('الخميس', 'Thursday'),
    Tr('الجمعة', 'Friday'), Tr('السبت', 'Saturday'), Tr('الحد', 'Sunday'),
  ];

  static String _subtitle() {
    final now = DateTime.now();
    final shift = now.hour < 15 ? tr('وردية الصبح', 'Morning shift') : tr('وردية بالليل', 'Evening shift');
    return '${_days[now.weekday - 1].text} · $shift';
  }

  @override
  Widget build(BuildContext context) {
    return OpsTabScaffold(
      navIndex: navIndex,
      title: tr('النهارده', 'Today'),
      subtitle: _subtitle,
      children: (context) {
        final hot = opsTasks().where((t) => t.type == OpsTaskType.safety).toList();
        return [
          Row(
            children: [
              Expanded(child: _Stat(value: MockOps.rentalsToday, label: tr('إيجار النهارده', 'Rentals today'))),
              const SizedBox(width: BunoSpace.s3),
              Expanded(child: _Stat(value: MockOps.unitsOut, label: tr('وحدات برّه', 'Units out'))),
              const SizedBox(width: BunoSpace.s3),
              Expanded(
                child: _Stat(
                  value: MockOps.lateRentals.length,
                  label: tr('متأخر', 'Late'),
                  color: MockOps.lateRentals.isEmpty ? BunoDark.text_primary : BunoColors.warning,
                ),
              ),
            ],
          ),
          if (hot.isNotEmpty) ...[
            const SizedBox(height: BunoSpace.s4),
            _HotBanner(task: hot.first),
          ],
          const SizedBox(height: BunoSpace.s6),
          Row(
            children: [
              Expanded(child: BunoSectionTitle(tr('المحطات', 'Stations'))),
              BunoText(
                tr('آخر تحديث من ${MockOps.lastUpdateSeconds} ث', 'Updated ${MockOps.lastUpdateSeconds}s ago'),
                style: BunoType.caption.copyWith(color: BunoDark.text_secondary),
              ),
            ],
          ),
          const SizedBox(height: BunoSpace.s2),
          for (final s in mockStations) _StationRow(station: s),
        ];
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.color = BunoDark.text_primary});

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return OpsCard(
      padding: const EdgeInsetsDirectional.fromSTEB(BunoSpace.s4, BunoSpace.s3, BunoSpace.s3, BunoSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BunoText('$value', maxLines: 1, style: BunoType.h2.copyWith(color: color, height: 1.3)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: BunoType.caption.copyWith(color: BunoDark.text_secondary)),
        ],
      ),
    );
  }
}

/// Red banner: the station locked a hot bay. "شوف" opens the station.
class _HotBanner extends StatelessWidget {
  const _HotBanner({required this.task});

  final OpsTask task;

  @override
  Widget build(BuildContext context) {
    final s = task.station!;
    final bay = MockOps.baysOf(s).firstWhere((b) => b.hot);
    return BunoPressable(
      onTap: () => openOpsTask(context, task),
      semanticLabel: task.title,
      child: Container(
        padding: const EdgeInsets.all(BunoSpace.s4),
        decoration: BoxDecoration(
          color: BunoColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(BunoRadius.lg),
          border: Border.all(color: BunoColors.error, width: BunoStroke.defaultWidth),
        ),
        child: Row(
          children: [
            const BunoLottieIcon(name: 'temperature', size: BunoSize.iconLg, playKey: true, color: BunoColors.error),
            const SizedBox(width: BunoSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BunoText(
                    tr('خانة ${bay.index + 1} في ${s.name} اتقفلت', 'Bay ${bay.index + 1} at ${s.name} locked'),
                    maxLines: 2,
                    style: BunoType.body.copyWith(fontWeight: FontWeight.w700, color: BunoColors.error, height: 1.4),
                  ),
                  BunoText(
                    tr('حرارة ${opsDegrees(bay.temperature!)} · ${task.meta}', '${opsDegrees(bay.temperature!)} · ${task.meta}'),
                    maxLines: 1,
                    style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: BunoSpace.s3),
            Text(tr('شوف', 'View'), style: BunoType.body.copyWith(fontWeight: FontWeight.w700, color: BunoColors.error)),
          ],
        ),
      ),
    );
  }
}

class _StationRow extends StatelessWidget {
  const _StationRow({required this.station});

  final Station station;

  @override
  Widget build(BuildContext context) {
    final status = MockOps.statusOf(station);
    final color = opsStatusColor(status);
    return BunoPressable(
      semanticLabel: '${station.name}, ${status.label}',
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.opsStation, arguments: station.code),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: BunoSpace.s4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: BunoDark.divider, width: BunoStroke.hairline)),
        ),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: BunoSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(station.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: BunoType.body.copyWith(fontWeight: FontWeight.w700)),
                  BunoText(
                    tr('${station.code} · ${station.readyCount} جاهز · ${station.emptyCount} فاضي',
                        '${station.code} · ${station.readyCount} ready · ${station.emptyCount} empty'),
                    maxLines: 1,
                    style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: BunoSpace.s2),
            Text(status.label, style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

/// Where a task leads: its station's bays (safety, service), a rebalance
/// run (transfer), or a confirm that marks it done (late, wallet).
void openOpsTask(BuildContext context, OpsTask task) {
  switch (task.type) {
    case OpsTaskType.transfer:
      MockOps.rebalance.start(from: task.station, to: task.target);
      Navigator.of(context).pushNamed(AppRoutes.opsRebalance);
    case OpsTaskType.safety || OpsTaskType.maintenance:
      Navigator.of(context).pushNamed(AppRoutes.opsStation, arguments: task.station!.code);
    case OpsTaskType.late || OpsTaskType.wallet:
      _confirmDone(context, task);
  }
}

Future<void> _confirmDone(BuildContext context, OpsTask task) async {
  final late = task.type == OpsTaskType.late;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: BunoDark.elevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BunoRadius.xl)),
      title: BunoText(task.title, style: BunoType.title),
      content: Text(
        late
            ? tr('هنبعت للمستخدم تذكير إن الوقت قرب يخلص.', "We'll remind the user that time is almost up.")
            : tr('اتأكد إن التحويلات وصلت قبل ما تضيف الرصيد.', 'Check the transfers arrived before adding the balance.'),
        style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(tr('بعدين', 'Later'), style: BunoType.body.copyWith(color: BunoDark.text_primary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            late ? tr('ابعت تذكير', 'Send reminder') : tr('وصلت، ضيف الرصيد', 'Received, add it'),
            style: BunoType.body.copyWith(fontWeight: FontWeight.w700, color: BunoColors.primary),
          ),
        ),
      ],
    ),
  );
  if (ok == true) MockOps.markDone(task.id);
}
