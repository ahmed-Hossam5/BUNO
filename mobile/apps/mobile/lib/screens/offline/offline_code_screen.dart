import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/mock_offline_code.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/buno_text_link.dart';
import '../../widgets/buno_title_bar.dart';
import '../../l10n/buno_locale.dart';

/// /offline-code (reference 27_offline_code): a six-digit code to type on
/// the station's screen. It changes every [offlineCodePeriod] and a bar
/// shows the time left; everything runs from the phone's clock.
class OfflineCodeScreen extends StatefulWidget {
  const OfflineCodeScreen({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  State<OfflineCodeScreen> createState() => _OfflineCodeScreenState();
}

class _OfflineCodeScreenState extends State<OfflineCodeScreen> {
  static const _tick = Duration(seconds: 1);
  static const _barWidth = 220.0;
  static const _barHeight = 6.0;

  late Timer _timer;
  late DateTime _now = widget.clock();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_tick, (_) => setState(() => _now = widget.clock()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = offlineCode(_now);
    final spaced = '${code.substring(0, 3)} ${code.substring(3)}';
    final remaining = offlineCodeRemaining(_now);
    final animate = !MediaQuery.of(context).disableAnimations;
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BunoTitleBar(tr('مفيش نت', 'No internet')),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: BunoSpace.s4),
                    child: Column(
                      children: [
                        Text(
                          tr('اكتب الكود ده على شاشة المحطة', "Type this code on the station's screen"),
                          textAlign: TextAlign.center,
                          style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: BunoSpace.s4),
                        Semantics(
                          label: tr('الكود ${code.split('').join(' ')}', "Code ${code.split('').join(' ')}"),
                          liveRegion: true,
                          excludeSemantics: true,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: BunoText(
                              spaced,
                              style: BunoType.display.copyWith(
                                fontSize: 56,
                                height: 1.15,
                                letterSpacing: 4,
                                color: BunoColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: BunoSpace.s5),
                        // Drains towards the start edge as the window runs out.
                        Container(
                          width: _barWidth,
                          height: _barHeight,
                          alignment: AlignmentDirectional.centerStart,
                          decoration: BoxDecoration(
                            color: BunoDark.elevated,
                            borderRadius: BorderRadius.circular(BunoRadius.pill),
                          ),
                          child: AnimatedContainer(
                            duration: animate ? _tick : Duration.zero,
                            width: _barWidth * remaining,
                            decoration: BoxDecoration(
                              color: BunoColors.primary,
                              borderRadius: BorderRadius.circular(BunoRadius.pill),
                            ),
                          ),
                        ),
                        const SizedBox(height: BunoSpace.s4),
                        BunoText(
                          tr('بيتغيّر كل ${offlineCodePeriod.inSeconds} ثانية. شغال من غير نت.', 'Changes every ${offlineCodePeriod.inSeconds} seconds. Works offline.'),
                          textAlign: TextAlign.center,
                          style: BunoType.caption.copyWith(color: BunoDark.text_secondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              BunoTextLink(tr('جرّب الاتصال تاني', 'Try connecting again'), onTap: () => Navigator.of(context).maybePop()),
            ],
          ),
        ),
      ),
    );
  }
}
