import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/repositories.dart';
import '../../data/mock_rental.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_empty_state.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_step_row.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/buno_text_link.dart';
import '../../widgets/buno_title_bar.dart';
import '../../l10n/buno_locale.dart';

/// /unlocking (reference 06_unlocking): the bay number and four stages that
/// complete in order while [rentalSession] goes unlocking → released. Back is
/// disabled; once the bay is open it moves on to /release. A debug-only link
/// simulates a stuck bay (reference 29_state_bay_stuck): retry restarts the
/// stages, back cancels the rental.
class UnlockingScreen extends StatefulWidget {
  const UnlockingScreen({super.key});

  /// Mock pace of the stages.
  static const stageDuration = Duration(milliseconds: 800);

  @override
  State<UnlockingScreen> createState() => _UnlockingScreenState();
}

class _Stage {
  const _Stage(this.title, this.detail, [this.lottie]);

  final String title;
  final String detail;
  final String? lottie;
}

class _UnlockingScreenState extends State<UnlockingScreen> {
  /// Stage the bay is waiting on until [rentalSession] reports released.
  static const _lockStage = 2;

  /// Index of the current stage; earlier ones are done. Equals the stage
  /// count once all are done.
  int _current = 0;
  Timer? _timer;

  /// The bay didn't open (simulated); stages are on hold.
  bool _stuck = false;

  @override
  void initState() {
    super.initState();
    // Opened directly (`--route /unlocking`): unlock the mock's best bay.
    final s = rentalSession.state;
    if (s == RentalState.idle || s == RentalState.returned) {
      final station = Repos.stations.all.first;
      unawaited(rentalSession.unlock(station, station.bestBayIndex!));
    }
    rentalSession.addListener(_onSession);
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    rentalSession.removeListener(_onSession);
    super.dispose();
  }

  bool get _released => rentalSession.state == RentalState.released;

  void _onSession() {
    if (_released && _timer == null && !_stuck) _schedule();
  }

  /// Advances one stage per [UnlockingScreen.stageDuration], holding on the
  /// lock stage until the bay is released.
  void _schedule() {
    _timer = null;
    if (_current >= _lockStage && !_released) return;
    _timer = Timer(UnlockingScreen.stageDuration, () {
      if (!mounted) return;
      if (_current == _stages.length - 1) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.release);
        return;
      }
      setState(() => _current++);
      _schedule();
    });
  }

  void _simulateStuck() {
    _timer?.cancel();
    _timer = null;
    setState(() => _stuck = true);
  }

  void _retry() {
    setState(() {
      _stuck = false;
      _current = 0;
    });
    _schedule();
  }

  /// Leaving a stuck bay cancels the rental; nothing was charged.
  void _onPop(bool didPop, Object? _) {
    if (didPop) rentalSession.reset();
  }

  List<_Stage> get _stages => [
        _Stage(tr('الطلب اتبعت', 'Request sent'), tr('من موبايلك للسيرفر', 'From your phone to the server'), 'shield'),
        _Stage(tr('المحطة استلمت الأمر', 'Station got the command'), tr('${rentalSession.station?.code ?? ''} · متصلة', '${rentalSession.station?.code ?? ''} · online')),
        _Stage(tr('القفل بيفتح', 'Lock opening'), tr('عادةً أقل من ثانيتين', 'Usually under two seconds'), 'unlock'),
        _Stage(tr('اسحب الوحدة', 'Pull the unit'), tr('الحساس هيأكد إنها خرجت', "The sensor will confirm it's out")),
      ];

  @override
  Widget build(BuildContext context) {
    final bay = (rentalSession.bayIndex ?? 0) + 1;
    final stages = _stages;
    if (_stuck) {
      return PopScope(
        canPop: true,
        onPopInvokedWithResult: _onPop,
        child: Scaffold(
          backgroundColor: BunoDark.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
              child: BunoEmptyState(
                header: BunoTitleBar(tr('الخانة', 'Bay')),
                icon: const BunoLottieIcon(name: 'unlock', size: 40, color: BunoColors.warning, playKey: 0),
                title: tr('الخانة مفتحتش', "The bay didn't open"),
                body: tr('خانة #$bay مستجابتش، ومفيش فلوس اتخصمت. ', "Bay #$bay didn't respond, and nothing was charged. ") +
                    tr('جرّب تاني، ولو فضلت مقفولة اطلب من موظف المكان يفتحها بكود المساعدة.', 'Try again. If it stays locked, ask the staff to open it with the help code.'),
                actionLabel: tr('جرّب تاني', 'Try again'),
                onAction: _retry,
                linkLabel: tr('عندي مشكلة', 'I have a problem'),
                onLink: () => Navigator.of(context).pushNamed(AppRoutes.report),
              ),
            ),
          ),
        ),
      );
    }
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: BunoDark.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: BunoSize.touchMin,
                  child: Center(child: Text(tr('بنفتح الخانة', 'Opening the bay'), style: BunoType.title)),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: BunoSpace.s6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('خانة', 'Bay'),
                            style: BunoType.bodySm.copyWith(
                              color: BunoDark.text_secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Semantics(
                            label: tr('خانة $bay', 'Bay $bay'),
                            excludeSemantics: true,
                            child: BunoText(
                              '#$bay',
                              style: BunoType.display.copyWith(
                                fontSize: 72,
                                height: 1.15,
                                color: BunoColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: BunoSpace.s5),
                          for (var i = 0; i < stages.length; i++)
                            BunoStepRow(
                              title: stages[i].title,
                              detail: stages[i].detail,
                              lottie: stages[i].lottie,
                              status: i < _current
                                  ? BunoStepStatus.done
                                  : i == _current
                                      ? BunoStepStatus.current
                                      : BunoStepStatus.next,
                              last: i == stages.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (kDebugMode)
                  BunoTextLink(tr('تجربة: الخانة علقت', 'Test: bay stuck'), onTap: _simulateStuck, color: BunoColors.info),
                Text(
                  tr('مفيش فلوس بتتخصم غير لما الوحدة تخرج فعلًا.', "Nothing is charged until the unit is actually out."),
                  textAlign: TextAlign.center,
                  style: BunoType.caption.copyWith(color: BunoDark.text_secondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
