import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_exam.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_charge_ring.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/buno_title_bar.dart';
import '../auth/auth_scaffold.dart' show showBunoToast;
import '../../l10n/buno_locale.dart';

/// /exam/night (reference 56): the running study-night pack. The ring
/// fills from 8 pm to 8 am around the time left; the main button opens
/// /stations, "فكّرني" shows a snackbar.
class ExamNightScreen extends StatefulWidget {
  const ExamNightScreen({super.key});

  @override
  State<ExamNightScreen> createState() => _ExamNightScreenState();
}

class _ExamNightScreenState extends State<ExamNightScreen> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final left = studyNight.remaining;
    final time = '${_two(left.inHours)}:${_two(left.inMinutes % 60)}';
    final secondary = BunoType.bodySm.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary);
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BunoTitleBar(tr('ليلة المذاكرة', 'Study night')),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final ring = math.min(c.maxWidth * 0.62, c.maxHeight * 0.55).clamp(140.0, 240.0);
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: c.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Semantics(
                                label: tr('فاضل $time لحد 8 الصبح', '$time left until 8 am'),
                                excludeSemantics: true,
                                child: BunoChargeRing(
                                  progress: studyNight.progress,
                                  size: ring,
                                  strokeWidth: 14,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const BunoLottieIcon(name: 'moon', loop: true, color: BunoColors.primary),
                                      Text(
                                        time,
                                        textDirection: TextDirection.ltr,
                                        style: BunoType.number(BunoType.display).copyWith(
                                          fontSize: ring * 0.22,
                                          height: 1.15,
                                        ),
                                      ),
                                      BunoText(tr('لحد 8 الصبح', 'until 8 am'), style: BunoType.caption.copyWith(color: BunoDark.text_secondary)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: BunoSpace.s7),
                            BunoText(tr('الباقة شغالة', 'The pack is on'), textAlign: TextAlign.center, style: BunoType.h2),
                            const SizedBox(height: BunoSpace.s2),
                            BunoText(
                              tr('ذاكر براحتك. مش هتدفع أكتر من [السعر] مهما قعدت، ورجّع الوحدة قبل 8 الصبح في أي محطة.', "Study at your own pace. You won't pay more than [price] however long you stay; return the unit to any station before 8 am."),
                              textAlign: TextAlign.center,
                              style: secondary,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              BunoPrimaryButton(
                label: tr('ودّيني لأقرب محطة مفتوحة', 'Take me to the nearest open station'),
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.stations),
              ),
              // A text link, but through BunoText so 7:30 stays LTR in Sora.
              BunoPressable(
                onTap: () => showBunoToast(context, tr('هنفكّرك الساعة 7:30 الصبح', "We'll remind you at 7:30 am")),
                semanticLabel: tr('فكّرني الساعة 7:30 الصبح', 'Remind me at 7:30 am'),
                child: SizedBox(
                  height: BunoSize.touchMin,
                  child: Center(child: BunoText(tr('فكّرني الساعة 7:30 الصبح', 'Remind me at 7:30 am'), style: secondary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
