import 'package:flutter/material.dart';

import '../../data/mock_ops.dart';
import '../../l10n/buno_locale.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text.dart';
import 'ops_home_screen.dart' show openOpsTask;
import 'ops_scaffold.dart';

/// Operations mode, "المهام" tab (reference 92): every task [opsTasks]
/// generates from the mock state, most urgent first, with a filter chip per
/// type that has tasks.
class OpsTasksScreen extends StatefulWidget {
  const OpsTasksScreen({super.key});

  static const navIndex = 1;

  @override
  State<OpsTasksScreen> createState() => _OpsTasksScreenState();
}

class _OpsTasksScreenState extends State<OpsTasksScreen> {
  /// Null = all.
  OpsTaskType? _filter;

  @override
  Widget build(BuildContext context) {
    return OpsTabScaffold(
      navIndex: OpsTasksScreen.navIndex,
      title: tr('المهام', 'Tasks'),
      subtitle: () {
        final n = opsTasks().length;
        return tr('$n مفتوحة · مرتّبة بالأهمية', '$n open · most urgent first');
      },
      children: (context) {
        final all = opsTasks();
        final types = [for (final t in OpsTaskType.values) if (all.any((x) => x.type == t)) t];
        final filter = types.contains(_filter) ? _filter : null;
        final shown = filter == null ? all : all.where((t) => t.type == filter).toList();
        return [
          Wrap(
            spacing: BunoSpace.s2,
            runSpacing: BunoSpace.s2,
            children: [
              _FilterChip(
                label: tr('الكل', 'All'),
                count: all.length,
                selected: filter == null,
                onTap: () => setState(() => _filter = null),
              ),
              for (final t in types)
                _FilterChip(
                  label: t.chip,
                  count: all.where((x) => x.type == t).length,
                  selected: filter == t,
                  onTap: () => setState(() => _filter = t),
                ),
            ],
          ),
          const SizedBox(height: BunoSpace.s5),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: BunoSpace.s8),
              child: Column(
                children: [
                  const BunoLottieIcon(name: 'success', size: 64, playKey: true),
                  const SizedBox(height: BunoSpace.s3),
                  Text(tr('مفيش مهام', 'No tasks'), style: BunoType.title),
                  Text(
                    tr('كل حاجة تمام دلوقتي.', 'Everything is fine right now.'),
                    style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary),
                  ),
                ],
              ),
            )
          else
            for (final t in shown) ...[
              _TaskCard(task: t),
              const SizedBox(height: BunoSpace.s3),
            ],
        ];
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.count, required this.selected, required this.onTap});

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: BunoPressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: BunoSize.touchMin),
          padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s4),
          decoration: BoxDecoration(
            color: selected ? BunoColors.primary : null,
            borderRadius: BorderRadius.circular(BunoRadius.pill),
            border: Border.all(color: selected ? BunoColors.primary : BunoDark.border),
          ),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: BunoText(
              '$label $count',
              style: BunoType.bodySm.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? BunoDark.on_primary : BunoDark.text_primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final OpsTask task;

  Widget _icon(BuildContext context, Color color) => switch (task.type) {
        OpsTaskType.safety => BunoLottieIcon(name: 'temperature', size: BunoSize.iconMd, color: color),
        OpsTaskType.transfer => BunoIcon(opsEndArrow(context), size: BunoSize.iconMd, color: color),
        OpsTaskType.maintenance => BunoLottieIcon(name: 'settings', size: BunoSize.iconMd, color: color),
        OpsTaskType.late => BunoLottieIcon(name: 'clock', size: BunoSize.iconMd, color: color),
        OpsTaskType.wallet => BunoIcon(BunoIcons.receipt, size: BunoSize.iconMd, color: color),
      };

  @override
  Widget build(BuildContext context) {
    final color = opsTaskColor(task.type);
    final meta = task.meta;
    return OpsCard(
      semanticLabel: '${task.type.label}, ${task.title}',
      borderColor: task.type == OpsTaskType.safety ? color : BunoDark.border,
      padding: const EdgeInsets.all(BunoSpace.s5),
      onTap: () => openOpsTask(context, task),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(BunoRadius.md),
            ),
            alignment: Alignment.center,
            child: _icon(context, color),
          ),
          const SizedBox(width: BunoSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.type.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w700, color: color),
                      ),
                    ),
                    if (meta != null) ...[
                      const SizedBox(width: BunoSpace.s2),
                      BunoText(meta, maxLines: 1, style: BunoType.caption.copyWith(color: BunoDark.text_secondary)),
                    ],
                  ],
                ),
                BunoText(task.title, maxLines: 2, style: BunoType.title.copyWith(fontWeight: FontWeight.w700, height: 1.4)),
                const SizedBox(height: BunoSpace.s1),
                BunoText(task.detail, maxLines: 3, style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
