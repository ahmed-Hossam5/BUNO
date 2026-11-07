import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_loading.dart';
import '../../data/mock_rental.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_bottom_nav.dart';
import '../../widgets/buno_empty_state.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_skeleton.dart';
import '../../widgets/buno_tab_header.dart';
import '../../widgets/buno_text.dart';
import '../rental/active_rental_screen.dart' show spokenDuration;
import '../wallet/wallet_screen.dart' show bunoNavItems;
import '../../l10n/buno_locale.dart';

List<String> get _weekdays => [tr('الاتنين', 'Monday'), tr('التلات', 'Tuesday'), tr('الأربع', 'Wednesday'), tr('الخميس', 'Thursday'), tr('الجمعة', 'Friday'), tr('السبت', 'Saturday'), tr('الحد', 'Sunday')];

/// When a trip ended: "النهارده", "امبارح", a weekday within the last week,
/// else day/month.
String tripDay(DateTime ended, {DateTime? now}) {
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final days = today.difference(DateUtils.dateOnly(ended)).inDays;
  return switch (days) {
    0 => tr('النهارده', 'Today'),
    1 => tr('امبارح', 'Yesterday'),
    < 7 => _weekdays[ended.weekday - 1],
    _ => '${ended.day}/${ended.month}',
  };
}

/// رحلاتي (references 15_history, 33_state_no_history): totals, then the
/// finished trips from [RentalSession.history], newest first; a trip opens
/// its /receipt. Empty state when there are none, and a loading skeleton
/// (32_state_loading) for [mockLoadDelay] first. Costs stay placeholders.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, this.session});

  /// Defaults to [rentalSession].
  final RentalSession? session;

  static const _gutter = 24.0;
  static const _navIndex = 1;

  @override
  Widget build(BuildContext context) {
    final session = this.session ?? rentalSession;
    return Scaffold(
      backgroundColor: BunoDark.background,
      bottomNavigationBar: BunoBottomNav(
        items: bunoNavItems,
        currentIndex: _navIndex,
        onSelected: (i) => AppRoutes.goToTab(context, i, _navIndex),
      ),
      body: SafeArea(
        bottom: false,
        child: BunoLoadingGate(
          delay: mockLoadDelay,
          skeleton: const _Skeleton(gutter: _gutter),
          child: ListenableBuilder(
            listenable: session,
            builder: (context, _) {
              final trips = session.history;
              if (trips.isEmpty) return const _Empty(gutter: _gutter);
              final hours = trips.fold(Duration.zero, (sum, t) => sum + t.duration).inHours;
              final stations = {for (final t in trips) ...[t.station.id, if (t.returnStation != null) t.returnStation!.id]}.length;
              return ListView(
                padding: const EdgeInsets.fromLTRB(_gutter, 21, _gutter, 24),
                children: [
                  BunoTabHeader(title: tr('رحلاتي', 'My trips')),
                  const SizedBox(height: 19),
                  Row(
                    children: [
                      Expanded(child: _Stat(value: hours, label: tr('ساعة شحن', 'Hours charged'), highlight: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _Stat(value: trips.length, label: tr('إيجار', 'Rentals'))),
                      const SizedBox(width: 10),
                      Expanded(child: _Stat(value: stations, label: tr('محطات', 'Stations'))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final t in trips)
                    _TripRow(
                      trip: t,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.receipt, arguments: t),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.highlight = false});

  final int value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: BunoDark.card,
        borderRadius: BorderRadius.circular(BunoRadius.xl),
        border: Border.all(color: BunoDark.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BunoText(
            '$value',
            style: BunoType.h1.copyWith(
              fontSize: 28,
              height: 1.2,
              color: highlight ? BunoColors.primary : BunoDark.text_primary,
            ),
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BunoType.caption.copyWith(height: 1.3, fontWeight: FontWeight.w600, color: BunoDark.text_secondary),
          ),
        ],
      ),
    );
  }
}

class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip, required this.onTap});

  final FinishedTrip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = trip.kept
        ? tr('${tripDay(trip.endedAt)} · الوحدة بقت معاك', '${tripDay(trip.endedAt)} · You kept the unit')
        : '${tripDay(trip.endedAt)} · ${spokenDuration(trip.duration, zero: tr('أقل من دقيقة', 'Under a minute'))}';
    return BunoPressable(
      onTap: onTap,
      semanticLabel: tr('${trip.station.name}، $meta', '${trip.station.name}, $meta'),
      child: Container(
        height: 73,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: BunoDark.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.station.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BunoType.title.copyWith(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3),
                  ),
                  BunoText(
                    meta,
                    maxLines: 1,
                    style: BunoType.caption.copyWith(fontWeight: FontWeight.w400, height: 1.4, color: BunoDark.text_secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: BunoSpace.s3),
            Text(
              trip.kept ? tr('[المبلغ]', '[Amount]') : tr('[السعر]', '[Price]'),
              style: BunoType.body.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: trip.kept ? BunoColors.error : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header, stat cards and rows in grey while the trips "load".
class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.gutter});

  final double gutter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 21, gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BunoTabHeader(title: tr('رحلاتي', 'My trips')),
          const SizedBox(height: 19),
          Expanded(
            child: BunoSkeletonList(
              leading: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      const Expanded(child: BunoSkeletonBox(height: 94, radius: BunoRadius.xl)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// No trips yet: clock badge, a line of copy, and a way to find a station.
class _Empty extends StatelessWidget {
  const _Empty({required this.gutter});

  final double gutter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 21, gutter, 24),
      child: BunoEmptyState(
        header: BunoTabHeader(title: tr('رحلاتي', 'My trips')),
        icon: const BunoLottieIcon(name: 'clock', size: 40, color: BunoDark.text_secondary),
        title: tr('لسه مأجرتش', "You haven't rented yet"),
        body: tr('مفيش رحلات لسه، ومتخصمش منك أي فلوس. أول ما تاخد بونو، رحلاتك وإيصالاتك هتظهر هنا.', "No trips yet, and you haven't been charged. Once you take a Buno, your trips and receipts will show up here."),
        actionLabel: tr('دوّر على محطة', 'Find a station'),
        onAction: () => Navigator.of(context).pushNamed(AppRoutes.stations),
      ),
    );
  }
}
