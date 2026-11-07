import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/repositories.dart';
import '../../data/mock_rental.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/buno_title_bar.dart';
import '../../l10n/buno_locale.dart';

/// Reserve a unit (reference 43), opened from home's main button when the
/// phone is below 20%. Holds the best ready bay at [station] (default: the
/// nearest with a ready unit) and replaces itself with /reserved.
class ReserveScreen extends StatelessWidget {
  const ReserveScreen({super.key, this.station});

  final Station? station;

  void _reserve(BuildContext context, Station station) {
    if (reservationSession.current == null) reservationSession.reserve(station);
    Navigator.of(context).pushReplacementNamed(AppRoutes.reserved);
  }

  @override
  Widget build(BuildContext context) {
    final s = station ?? Repos.stations.nearestReady() ?? Repos.stations.all.first;
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BunoTitleBar(tr('احجز وحدة', 'Reserve a unit')),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: BunoSpace.s5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StationCard(station: s),
                      const SizedBox(height: BunoSpace.s3),
                      const _HoldCard(),
                      const SizedBox(height: BunoSpace.s3),
                      const _RulesCard(),
                    ],
                  ),
                ),
              ),
              BunoPrimaryButton(
                label: tr('احجز وودّيني للمحطة', 'Reserve and take me there'),
                onPressed: s.bestBayIndex == null ? null : () => _reserve(context, s),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Station name, walk, ready units, and its eight bays with the one that
/// will be held marked by a lock.
class _StationCard extends StatelessWidget {
  const _StationCard({required this.station});

  final Station station;

  @override
  Widget build(BuildContext context) {
    final secondary = BunoType.bodySm.copyWith(color: BunoDark.text_secondary);
    return Container(
      padding: const EdgeInsets.all(BunoSpace.s5),
      decoration: BoxDecoration(
        color: BunoDark.card,
        borderRadius: BorderRadius.circular(BunoRadius.xl),
        border: Border.all(color: BunoDark.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BunoText(station.name, style: BunoType.title),
                BunoText(tr('[المسافة] · [الوقت] مشي', '[Distance] · [Time] walk'), style: secondary),
                BunoText(
                  tr('${station.readyCount} وحدات جاهزة', '${station.readyCount} units ready'),
                  style: BunoType.bodySm.copyWith(color: BunoColors.primary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: BunoSpace.s1),
                BunoText(tr('هنقفل خانة واحدة باسمك لحد ما توصل.', "We'll hold one bay in your name until you arrive."), style: secondary),
              ],
            ),
          ),
          const SizedBox(width: BunoSpace.s4),
          _BayGrid(bays: station.bays.length, held: station.bestBayIndex),
        ],
      ),
    );
  }
}

/// Station front: bays in two rows of four, bay 1 at the start; [held]
/// gets a green outline and a lock.
class _BayGrid extends StatelessWidget {
  const _BayGrid({required this.bays, required this.held});

  final int bays;
  final int? held;

  static const _cellWidth = 22.0;
  static const _cellHeight = 40.0;
  static const _gap = BunoSpace.s1;

  Widget _cell(int i) {
    final isHeld = i == held;
    return Container(
      width: _cellWidth,
      height: _cellHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isHeld ? BunoColors.primary_soft : BunoDark.surface,
        borderRadius: BorderRadius.circular(BunoRadius.xs),
        border: Border.all(
          color: isHeld ? BunoColors.primary : BunoDark.border,
          width: isHeld ? BunoStroke.defaultWidth : BunoStroke.hairline,
        ),
      ),
      child: isHeld ? const BunoIcon(BunoIcons.lock, size: BunoSize.iconSm, color: BunoColors.primary) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final perRow = (bays / 2).ceil();
    Widget row(int from) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = from; i < from + perRow && i < bays; i++) ...[
              if (i > from) const SizedBox(width: _gap),
              _cell(i),
            ],
          ],
        );
    return Semantics(
      label: held == null ? tr('مفيش خانة جاهزة', 'No bay ready') : tr('خانة ${held! + 1} هتتحجز ليك', 'Bay ${held! + 1} will be held for you'),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(BunoSpace.s2),
        decoration: BoxDecoration(
          color: BunoDark.background,
          borderRadius: BorderRadius.circular(BunoRadius.md),
          border: Border.all(color: BunoDark.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [row(0), const SizedBox(height: _gap * 2), row(perRow)],
        ),
      ),
    );
  }
}

/// Green card: how long the bay is held.
class _HoldCard extends StatelessWidget {
  const _HoldCard();

  static const _badge = 56.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BunoSpace.s5),
      decoration: BoxDecoration(
        color: BunoColors.primary,
        borderRadius: BorderRadius.circular(BunoRadius.xl),
      ),
      child: Row(
        children: [
          Container(
            width: _badge,
            height: _badge,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: BunoDark.on_primary, width: BunoStroke.emphasis),
            ),
            child: const BunoIcon(BunoIcons.lock, size: BunoSize.iconLg, color: BunoDark.on_primary),
          ),
          const SizedBox(width: BunoSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BunoText(tr('[المدة] محجوزة ليك', 'Held for you for [duration]'), style: BunoType.title.copyWith(color: BunoDark.on_primary)),
                BunoText(
                  tr('كفاية تمشي [الوقت] للمحطة براحتك', 'Enough to walk the [time] to the station calmly'),
                  style: BunoType.bodySm.copyWith(color: BunoDark.on_primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The reservation rules, each with a check.
class _RulesCard extends StatelessWidget {
  const _RulesCard();

  static List<String> get _rules => [
    tr('العدّاد بتاع الإيجار مش بيبدأ غير لما تمسح وتاخد الوحدة', "The rental timer doesn't start until you scan and take the unit"),
    tr('لو مجتش في [المدة]، الحجز بيتلغي لوحده', "If you don't come within [duration], the reservation cancels itself"),
    tr('حجز واحد بس في نفس الوقت', 'Only one reservation at a time'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BunoSpace.s4),
      decoration: BoxDecoration(
        color: BunoDark.card,
        borderRadius: BorderRadius.circular(BunoRadius.lg),
        border: Border.all(color: BunoDark.border),
      ),
      child: Column(
        children: [
          for (final (i, rule) in _rules.indexed) ...[
            if (i > 0) const SizedBox(height: BunoSpace.s3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: BunoIcon(BunoIcons.check, size: BunoSize.iconSm, color: BunoColors.primary),
                ),
                const SizedBox(width: BunoSpace.s2),
                Expanded(
                  child: BunoText(rule, style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
