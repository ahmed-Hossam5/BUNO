import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_rental.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_step_row.dart';
import '../../l10n/buno_locale.dart';

/// /verifying (reference 40_verifying): four server checks before the bay
/// opens — the code is Buno's, the station is online, the code is still
/// valid, the account and balance. Each takes [checkDuration] in the mock;
/// when all pass it unlocks [bayIndex] at [station] and replaces itself
/// with /unlocking. Back is disabled.
class VerifyingScreen extends StatefulWidget {
  const VerifyingScreen({super.key, required this.station, required this.bayIndex});

  final Station station;
  final int bayIndex;

  /// Mock time per check.
  static const checkDuration = Duration(milliseconds: 500);

  @override
  State<VerifyingScreen> createState() => _VerifyingScreenState();
}

class _VerifyingScreenState extends State<VerifyingScreen> {
  /// Index of the check in progress; equals the count once all passed.
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule() {
    _timer = Timer(VerifyingScreen.checkDuration, () {
      if (!mounted) return;
      if (_current == _checks.length - 1) {
        unawaited(rentalSession.unlock(widget.station, widget.bayIndex));
        Navigator.of(context).pushReplacementNamed(AppRoutes.unlocking);
        return;
      }
      setState(() => _current++);
      _schedule();
    });
  }

  List<(String, String)> get _checks => [
        (tr('الكود بتاع بونو', "It's a Buno code"), tr('موقّع من السيرفر، مش منسوخ', 'Signed by the server, not copied')),
        (tr('المحطة متصلة دلوقتي', 'The station is online now'), tr('${widget.station.code} · آخر نبضة من 3 ث', '${widget.station.code} · last heartbeat 3 s ago')),
        (tr('الكود لسه صالح', 'The code is still valid'), tr('بيتغير كل 30 ثانية', 'Changes every 30 seconds')),
        (tr('حسابك ورصيدك', 'Your account and balance'), tr('رصيدك يغطي أول ساعة', 'Your balance covers the first hour')),
      ];

  @override
  Widget build(BuildContext context) {
    final checks = _checks;
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
                  child: Center(child: Text(tr('بنتأكد من الطلب', 'Checking the request'), style: BunoType.title)),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: BunoSpace.s6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('قبل ما الخانة تفتح', 'before the bay opens'),
                            style: BunoType.bodySm.copyWith(
                              color: BunoDark.text_secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: BunoSpace.s5),
                          for (var i = 0; i < checks.length; i++)
                            BunoStepRow(
                              title: checks[i].$1,
                              detail: i == _current ? tr('بنراجع…', 'Checking…') : checks[i].$2,
                              lottie: 'shield',
                              status: i < _current
                                  ? BunoStepStatus.done
                                  : i == _current
                                      ? BunoStepStatus.current
                                      : BunoStepStatus.next,
                              last: i == checks.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Text(
                  tr('ده بيحمي من الأكواد المنسوخة والمحطات المزيفة.', 'This protects against copied codes and fake stations.'),
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
