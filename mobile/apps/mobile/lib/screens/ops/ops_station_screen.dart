import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_ops.dart';
import '../../data/mock_rental.dart';
import '../../l10n/buno_locale.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_bay_tile.dart' show chargeColor;
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_charge_bar.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text.dart';
import 'ops_scaffold.dart';

/// One station's 8 bays for the ops team (reference 93): unit id, charge,
/// temperature, health, and a lock on bays out of service. Tap a bay to
/// select it, then open or lock it; "نقل" moves units to another station.
/// Takes the station code (String) as `arguments`; default the first.
class OpsStationScreen extends StatefulWidget {
  const OpsStationScreen({super.key, this.code});

  final String? code;

  @override
  State<OpsStationScreen> createState() => _OpsStationScreenState();
}

class _OpsStationScreenState extends State<OpsStationScreen> {
  late final Station _station = stationByCode(widget.code) ?? mockStations.first;

  /// Starts on the first locked bay (the hot one), if any.
  late int? _selected = () {
    final i = MockOps.baysOf(_station).indexWhere((b) => b.locked);
    return i < 0 ? null : i;
  }();

  void _setLocked(bool locked) {
    final i = _selected;
    if (i == null) return;
    MockOps.setLocked(_station, i, locked);
  }

  @override
  Widget build(BuildContext context) {
    final s = _station;
    return OpsSubScaffold(
      title: () => s.name,
      subtitle: () {
        final online = MockOps.isOnline(s);
        return Row(
          children: [
            Flexible(
              child: OpsSubtitle(
                online
                    ? tr('${s.code} · آخر نبضة من ${MockOps.lastBeatSeconds} ث', '${s.code} · last beat ${MockOps.lastBeatSeconds}s ago')
                    : s.code,
              ),
            ),
            Text(' · ', style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary)),
            Text(
              online ? tr('متصلة', 'Online') : tr('مش متصلة', 'Offline'),
              style: BunoType.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: online ? BunoColors.success : BunoDark.text_secondary,
              ),
            ),
          ],
        );
      },
      children: (context) {
        final bays = MockOps.baysOf(s);
        return [
          for (var row = 0; row < bays.length; row += 2) ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = row; i < row + 2 && i < bays.length; i++) ...[
                    if (i > row) const SizedBox(width: BunoSpace.s3),
                    Expanded(
                      child: _BayCard(
                        bay: bays[i],
                        selected: _selected == i,
                        onTap: () => setState(() => _selected = _selected == i ? null : i),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: BunoSpace.s3),
          ],
        ];
      },
      bottom: (context) {
        final i = _selected;
        final bay = i == null ? null : MockOps.bay(s, i);
        return Row(
          children: [
            Expanded(
              child: _Action(
                label: tr('افتح خانة', 'Open bay'),
                icon: BunoIcons.lock,
                onPressed: bay != null && bay.locked ? () => _setLocked(false) : null,
              ),
            ),
            const SizedBox(width: BunoSpace.s3),
            Expanded(
              child: _Action(
                label: tr('اقفل خانة', 'Lock bay'),
                icon: BunoIcons.lock,
                onPressed: bay != null && !bay.locked ? () => _setLocked(true) : null,
              ),
            ),
            const SizedBox(width: BunoSpace.s3),
            Expanded(
              child: _Action(
                label: tr('نقل', 'Move'),
                icon: opsEndArrow(context),
                onPressed: s.readyCount == 0
                    ? null
                    : () {
                        MockOps.rebalance.start(from: s);
                        Navigator.of(context).pushNamed(AppRoutes.opsRebalance);
                      },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Secondary button, faded while it does nothing.
class _Action extends StatelessWidget {
  const _Action({required this.label, required this.icon, required this.onPressed});

  final String label;
  final BunoIcons icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: BunoSecondaryButton(
        label: label,
        icon: icon,
        iconColor: BunoDark.text_primary,
        compact: true,
        labelSize: 15,
        labelWeight: FontWeight.w700,
        onPressed: onPressed,
      ),
    );
  }
}

class _BayCard extends StatelessWidget {
  const _BayCard({required this.bay, required this.selected, required this.onTap});

  final OpsBay bay;
  final bool selected;
  final VoidCallback onTap;

  static const _minHeight = 128.0;

  @override
  Widget build(BuildContext context) {
    final unit = bay.unit;
    final number = bay.index + 1;
    final border = selected
        ? BunoColors.primary
        : bay.hot
            ? BunoColors.error
            : BunoDark.border;
    final lock = bay.locked ? tr('مقفولة', 'locked') : tr('شغّالة', 'in service');
    return Semantics(
      selected: selected,
      button: true,
      label: unit == null
          ? tr('خانة $number فاضية، $lock', 'Bay $number empty, $lock')
          : tr('خانة $number، ${unit.id}، ${bay.charge}%، $lock', 'Bay $number, ${unit.id}, ${bay.charge}%, $lock'),
      excludeSemantics: true,
      child: BunoPressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: _minHeight),
          padding: const EdgeInsets.all(BunoSpace.s4),
          decoration: BoxDecoration(
            color: BunoDark.card,
            borderRadius: BorderRadius.circular(BunoRadius.lg),
            border: Border.all(color: border, width: selected ? BunoStroke.defaultWidth : BunoStroke.hairline),
          ),
          child: unit == null
              ? Center(
                  child: Text(
                    tr('فاضية', 'Empty'),
                    style: BunoType.body.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: BunoText(
                            tr('خانة $number', 'Bay $number'),
                            maxLines: 1,
                            style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary),
                          ),
                        ),
                        if (bay.locked) const BunoIcon(BunoIcons.lock, size: BunoSize.iconSm, color: BunoColors.error),
                      ],
                    ),
                    BunoText(unit.id, maxLines: 1, style: BunoType.title.copyWith(fontWeight: FontWeight.w700)),
                    BunoText(
                      '${bay.charge}%',
                      style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w700, color: chargeColor(bay.charge)),
                    ),
                    const SizedBox(height: BunoSpace.s1),
                    BunoChargeBar(value: bay.charge! / 100, width: double.infinity, color: chargeColor(bay.charge)),
                    const SizedBox(height: BunoSpace.s2),
                    Row(
                      children: [
                        BunoText(
                          opsDegrees(bay.temperature!),
                          style: BunoType.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: bay.hot ? BunoColors.error : BunoDark.text_secondary,
                          ),
                        ),
                        const Spacer(),
                        BunoText(
                          tr('صحة ${bay.health}%', 'Health ${bay.health}%'),
                          maxLines: 1,
                          style: BunoType.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: bay.worn ? BunoColors.warning : BunoDark.text_secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
