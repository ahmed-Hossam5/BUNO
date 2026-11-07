import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/repositories.dart';
import '../../data/mock_rental.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_charge_ring.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/buno_text_link.dart';
import '../../widgets/buno_title_bar.dart';
import '../../l10n/buno_locale.dart';

/// The held bay counting down (reference 34). Reads [reservationSession];
/// opened directly without a reservation, it reserves at the nearest ready
/// station first. "وصلت؟ امسح" opens /scan; cancel or running out releases
/// the bay and goes home.
class ReservedScreen extends StatefulWidget {
  const ReservedScreen({super.key});

  @override
  State<ReservedScreen> createState() => _ReservedScreenState();
}

class _ReservedScreenState extends State<ReservedScreen> {
  Timer? _ticker;

  static Station get _fallbackStation => Repos.stations.nearestReady() ?? Repos.stations.all.first;

  @override
  void initState() {
    super.initState();
    // Reserving notifies listeners (home's button), so not mid-build.
    if (reservationSession.current == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && reservationSession.current == null) {
          setState(() => reservationSession.reserve(_fallbackStation));
        }
      });
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (reservationSession.expireIfDue()) {
        _leave(tr('خلص وقت الحجز والخانة اتفتحت لغيرك', 'Your hold expired and the bay is open to others'));
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _cancel() {
    reservationSession.cancel();
    _leave(tr('اتلغى الحجز', 'Reservation cancelled'));
  }

  void _leave(String message) {
    _ticker?.cancel();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final reservation = reservationSession.current;
    final station = reservation?.station ?? _fallbackStation;
    final bay = reservation?.bayIndex ?? station.bestBayIndex ?? 0;
    final hold = reservationSession.hold;
    final remaining = reservation == null ? hold : reservationSession.remaining;
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BunoTitleBar(tr('محجوزك', 'Your reservation')),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: BunoSpace.s5),
                    child: Column(
                      children: [
                        BunoChargeRing(
                          progress: hold == Duration.zero ? 0 : remaining.inMilliseconds / hold.inMilliseconds,
                          size: 212,
                          child: _Countdown(remaining: remaining),
                        ),
                        const SizedBox(height: BunoSpace.s7),
                        BunoText(tr('خانتك', 'Your bay'), style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary)),
                        BunoText(
                          '#${bay + 1}',
                          style: BunoType.display.copyWith(color: BunoColors.primary),
                        ),
                        BunoText(
                          tr('${station.name} · [الوقت] مشي', '${station.name} · [time] walk'),
                          textAlign: TextAlign.center,
                          style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              BunoPrimaryButton(
                label: tr('وصلت؟ امسح', 'Here? Scan'),
                icon: BunoIcons.scan,
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.scan),
              ),
              const SizedBox(height: BunoSpace.s2),
              BunoTextLink(tr('ألغي الحجز', 'Cancel reservation'), onTap: _cancel),
            ],
          ),
        ),
      ),
    );
  }
}

/// "07:24" in Sora inside the ring, "فاضل على الحجز" below.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.remaining});

  final Duration remaining;

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final m = remaining.inMinutes, s = remaining.inSeconds % 60;
    return Semantics(
      label: tr('فاضل على الحجز $m دقيقة و$s ثانية', 'Reservation ends in $m minutes and $s seconds'),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_two(m)}:${_two(s)}',
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
          const SizedBox(height: BunoSpace.s2),
          BunoText(tr('فاضل على الحجز', 'Hold ends in'), style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary)),
        ],
      ),
    );
  }
}
