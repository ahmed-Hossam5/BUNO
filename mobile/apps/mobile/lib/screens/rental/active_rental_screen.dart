import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app_routes.dart';
import '../../data/repositories.dart';
import '../../data/mock_rental.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_charge_bar.dart';
import '../../widgets/buno_charge_ring.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_logo.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_status_pill.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/buno_text_link.dart';
import 'late_return_banner.dart';
import '../../l10n/buno_locale.dart';

/// "ساعة و12 دقيقة" for [d] (whole minutes); [zero] under a minute.
String spokenDuration(Duration d, {String? zero}) {
  zero ??= tr('لسه بادئ', 'Just started');
  final h = d.inHours, m = d.inMinutes % 60;
  final hours = switch (h) {
    0 => '',
    1 => tr('ساعة', 'an hour'),
    2 => tr('ساعتين', 'two hours'),
    _ => tr('$h ساعات', '$h hours'),
  };
  if (m == 0) return hours.isEmpty ? zero : hours;
  final minutes = tr('$m دقيقة', '$m minutes');
  return hours.isEmpty ? minutes : tr('$hours و$minutes', '$hours and $minutes');
}

/// Active rental — Brand Board page 10. The timer counts from
/// [rentalSession]'s startedAt; without an active rental it shows
/// [initialElapsed]. Past 23 h a late-return banner shows (references
/// 44–47); at 24 h the rental closes and the unit is the user's. Other
/// values are mock data.
class ActiveRentalScreen extends StatefulWidget {
  const ActiveRentalScreen({
    super.key,
    this.initialElapsed = const Duration(hours: 1, minutes: 12),
    this.unitId = 'PB-0417',
    this.ringProgress = 0.655,
    this.bankCharge = 0.64,
  });

  final Duration initialElapsed;

  /// Shown without a rental; otherwise the rented unit's tag.
  final String unitId;

  /// Share of the ring filled (the reference shows ~65%).
  final double ringProgress;
  final double bankCharge;

  @override
  State<ActiveRentalScreen> createState() => _ActiveRentalScreenState();
}

class _ActiveRentalScreenState extends State<ActiveRentalScreen> {
  static const _gutter = 22.0;

  /// The hour-warning sheet opens when the timer reaches this.
  static const _warnAt = Duration(minutes: 50);

  late Duration _elapsed = _sessionElapsed ?? widget.initialElapsed;
  Timer? _ticker;

  /// Length of [rentalSession]'s rental; null before pickup.
  static Duration? get _sessionElapsed => rentalSession.duration;

  /// Late stage of the session's rental, or of the mock timer without one.
  LateStage? get _stage =>
      rentalSession.startedAt == null ? LateStage.reachedAt(_elapsed) : rentalSession.lateStage;

  bool get _kept => _stage == LateStage.kept;

  @override
  void initState() {
    super.initState();
    rentalSession.addListener(_onSession);
    // Ticks every second so the minute turns over on time; rebuilds only
    // when the shown minute changes.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_kept) return;
      rentalSession.closeIfOverdue();
      final next = _sessionElapsed ?? _elapsed + const Duration(seconds: 1);
      if (_elapsed < _warnAt && next >= _warnAt && next < const Duration(hours: 1)) _showHourWarning();
      if (next.inMinutes != _elapsed.inMinutes) {
        setState(() => _elapsed = next);
      } else {
        _elapsed = next;
      }
    });
  }

  @override
  void dispose() {
    rentalSession.removeListener(_onSession);
    _ticker?.cancel();
    super.dispose();
  }

  void _onSession() {
    if (!mounted) return;
    // Another screen may change the session while building (e.g. the
    // receipt resets it); rebuild after that frame.
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) => _onSession());
      return;
    }
    setState(() => _elapsed = _sessionElapsed ?? _elapsed);
  }

  /// Debug: jumps the rental's clock to the next late stage.
  void _jumpToNextLateStage() {
    final stage = _stage;
    final next = stage == null ? LateStage.reminder : LateStage.values[stage.index + 1];
    if (rentalSession.state == RentalState.active) {
      rentalSession.debugJumpTo(next.at);
    } else {
      setState(() => _elapsed = next.at);
    }
  }

  /// After the kept-unit banner: clears the closed rental and goes home.
  void _done() {
    if (rentalSession.state == RentalState.kept) rentalSession.reset();
    AppRoutes.enterApp(context);
  }

  void _showHourWarning() {
    if (!mounted) return;
    showHourWarningSheet(context);
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stage;
    final kept = stage == LateStage.kept;
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(_gutter, 20, _gutter, 0),
                      child: _Header(unitId: rentalSession.unit?.id ?? widget.unitId, closed: kept),
                    ),
                    if (stage != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(_gutter, BunoSpace.s5, _gutter, 0),
                        child: LateReturnBanner(stage: stage, remaining: LateStage.kept.at - _elapsed),
                      ),
                    const SizedBox(height: 38),
                    Center(
                      child: BunoChargeRing(
                        progress: widget.ringProgress,
                        size: 196,
                        child: _TimerReadout(elapsed: _elapsed),
                      ),
                    ),
                    const SizedBox(height: 25),
                    _CostCard(bankCharge: widget.bankCharge),
                    const SizedBox(height: 18.7),
                    const _NearestStationCard(),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(_gutter, 24, _gutter, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (kept)
                            BunoPrimaryButton(label: tr('تمام', 'OK'), onPressed: _done)
                          else
                            BunoPrimaryButton(
                              label: tr('رجّعه', 'Return it'),
                              icon: BunoIcons.powerBank,
                              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.returnUnit),
                            ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: BunoSecondaryButton(
                                  label: tr('فيه مشكلة؟', 'A problem?'),
                                  icon: BunoIcons.warning,
                                  iconColor: BunoColors.warning,
                                  height: BunoSize.touchMin,
                                  compact: true,
                                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.report),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: BunoSecondaryButton(
                                  label: tr('تفاصيل الحساب', 'Cost details'),
                                  icon: BunoIcons.receipt,
                                  height: BunoSize.touchMin,
                                  compact: true,
                                  onPressed: () => _toast(tr('تفاصيل الحساب', 'Cost details')),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: BunoSpace.s2),
                          BunoTextLink(
                            tr('الوحدة اللي معاك', 'Your unit'),
                            onTap: () => Navigator.of(context).pushNamed(AppRoutes.rentalUnit),
                          ),
                          if (kDebugMode) ...[
                            const SizedBox(height: BunoSpace.s2),
                            BunoTextLink(tr('تجربة: تنبيه الساعة', 'Test: hour alert'), onTap: _showHourWarning, color: BunoColors.info),
                            if (!kept) ...[
                              const SizedBox(height: BunoSpace.s2),
                              BunoTextLink(tr('تجربة: تأخير', 'Test: late'), onTap: _jumpToNextLateStage, color: BunoColors.info),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.unitId, this.closed = false});

  final String unitId;

  /// The rental closed at 24 h ([LateStage.kept]).
  final bool closed;

  static const _logoHeight = 24.4;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final nudge = BunoLogo.inkEndInset * _logoHeight / 120;
    return Row(
      children: [
        Transform.translate(
          offset: Offset(rtl ? nudge : -nudge, 0),
          child: const BunoLogo(height: _logoHeight),
        ),
        const Spacer(),
        BunoStatusPill('${closed ? tr('الإيجار اتقفل', 'Rental closed') : tr('إيجار شغّال', 'Active rental')} · $unitId'),
      ],
    );
  }
}

/// "01:12" in Sora inside the ring, with the spelled-out duration below.
class _TimerReadout extends StatelessWidget {
  const _TimerReadout({required this.elapsed});

  final Duration elapsed;

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h = elapsed.inHours, m = elapsed.inMinutes % 60;
    return Semantics(
      label: tr('مدة الإيجار ${spokenDuration(elapsed)}', 'Rental time ${spokenDuration(elapsed)}'),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 5.4),
          Text(
            '${_two(h)}:${_two(m)}',
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              fontFamily: BunoFonts.sora,
              fontWeight: FontWeight.w700,
              fontSize: 46,
              height: 1,
              letterSpacing: -0.03 * 46,
              color: BunoDark.text_primary,
            ),
          ),
          const SizedBox(height: 9.4),
          BunoText(
            spokenDuration(elapsed),
            style: BunoType.bodySm.copyWith(height: 1.2, color: BunoDark.text_secondary),
          ),
        ],
      ),
    );
  }
}

/// Cost so far, per-minute rate, time to the daily cap, power-bank charge.
class _CostCard extends StatelessWidget {
  const _CostCard({required this.bankCharge});

  final double bankCharge;

  @override
  Widget build(BuildContext context) {
    final valueStyle = BunoType.body.copyWith(height: 1.2, fontWeight: FontWeight.w700);
    return _EdgeCard(
      inset: 3.3,
      padding: const EdgeInsets.fromLTRB(18.7, 5.5, 18.7, 11.6),
      child: Column(
        children: [
          _InfoRow(
            label: tr('دفعت لحد دلوقتي', 'Paid so far'),
            value: Text(tr('[السعر] جنيه', '[Price] EGP'), style: valueStyle.copyWith(color: BunoColors.primary)),
          ),
          _InfoRow(label: tr('كل دقيقة جاية', 'Each next minute'), value: Text(tr('[السعر] قرش', '[Price] pt'), style: valueStyle)),
          _InfoRow(label: tr('هتوصل للحد الأقصى بعد', "You'll hit the cap in"), value: Text(tr('[المدة]', '[Duration]'), style: valueStyle)),
          _InfoRow(
            label: tr('شحن البونو', 'Buno charge'),
            divider: false,
            value: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BunoLottieIcon(
                  name: 'buno_charging',
                  size: BunoSize.iconSm,
                  loop: true,
                ),
                const SizedBox(width: 6),
                BunoChargeBar(value: bankCharge),
                const SizedBox(width: 8),
                Text(
                  '${(bankCharge * 100).round()}%',
                  textDirection: TextDirection.ltr,
                  style: BunoType.number(BunoType.caption).copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: BunoColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.divider = true});

  final String label;
  final Widget value;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 43.5,
      decoration: divider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: BunoDark.border)),
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: BunoType.body.copyWith(height: 1.2, color: BunoDark.text_secondary),
            ),
          ),
          value,
        ],
      ),
    );
  }
}

class _NearestStationCard extends StatelessWidget {
  const _NearestStationCard();

  @override
  Widget build(BuildContext context) {
    return _EdgeCard(
      inset: 6.3,
      padding: const EdgeInsets.fromLTRB(14.4, 13, 14.4, 11.6),
      child: Row(
        children: [
          const BunoIcon(BunoIcons.location, color: BunoColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr('أقرب محطة ترجّع فيها', 'Nearest station to return to'),
                  style: BunoType.body.copyWith(fontSize: 14, height: 1.3, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4.7),
                BunoText(
                  tr('[اسم المكان] · [المسافة] · فيها [العدد] خانات فاضية', '[Place name] · [Distance] · [Count] free bays'),
                  maxLines: 1,
                  style: BunoType.caption.copyWith(
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                    color: BunoDark.text_secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card surface placed with the reference's small screen-edge inset (the
/// board draws these two cards almost full-bleed while their content keeps
/// the 22pt gutter).
class _EdgeCard extends StatelessWidget {
  const _EdgeCard({required this.inset, required this.padding, required this.child});

  final double inset;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: BunoDark.card,
          borderRadius: BorderRadius.circular(BunoRadius.xl),
          border: Border.all(color: BunoDark.border),
        ),
        child: child,
      ),
    );
  }
}

/// 08_hour_warning_sheet: ten minutes left in the first hour. The CTA opens
/// /return; "هكمّل الساعة التانية" just closes the sheet.
Future<void> showHourWarningSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: BunoDark.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(BunoRadius.xxl)),
    ),
    builder: (_) => const HourWarningSheet(),
  );
}

class HourWarningSheet extends StatelessWidget {
  const HourWarningSheet({super.key});

  static const _badge = 52.0;

  void _goReturn(BuildContext context) {
    final nav = Navigator.of(context);
    nav.pop();
    nav.pushNamed(AppRoutes.returnUnit);
  }

  @override
  Widget build(BuildContext context) {
    final station = Repos.stations.nearestReturn();
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, BunoSpace.s3, 22, BunoSpace.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: BunoDark.border,
                  borderRadius: BorderRadius.circular(BunoRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: BunoSpace.s5),
            Row(
              children: [
                Container(
                  width: _badge,
                  height: _badge,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BunoColors.warning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(BunoRadius.md),
                  ),
                  child: const BunoLottieIcon(
                    name: 'clock',
                    color: BunoColors.warning,
                    playKey: true,
                  ),
                ),
                const SizedBox(width: BunoSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BunoText(tr('فاضل 10 دقايق', '10 minutes left'), style: BunoType.h3),
                      Text(
                        tr('وتبدأ الساعة التانية.', 'until the next hour starts.'),
                        style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: BunoSpace.s4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s4, vertical: BunoSpace.s3),
              decoration: BoxDecoration(
                color: BunoDark.background,
                borderRadius: BorderRadius.circular(BunoRadius.lg),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('أقرب محطة فيها مكان', 'Nearest station with space'),
                          style: BunoType.caption.copyWith(color: BunoDark.text_secondary),
                        ),
                        Text(
                          station?.name ?? tr('[اسم المكان]', '[Place name]'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BunoType.body.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: BunoSpace.s3),
                  BunoText(
                    station == null ? tr('[الوقت] مشي', '[Time] walk') : tr('${station.walkMinutes} دقايق مشي', '${station.walkMinutes} min walk'),
                    style: BunoType.bodySm.copyWith(
                      color: BunoColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BunoSpace.s4),
            BunoPrimaryButton(label: tr('ودّيني أرجّعه', 'Take me to return it'), onPressed: () => _goReturn(context)),
            const SizedBox(height: BunoSpace.s2),
            BunoTextLink(tr('هكمّل الساعة التانية', "I'll keep it another hour"), onTap: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}
