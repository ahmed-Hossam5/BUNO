import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_text_link.dart';
import '../../widgets/buno_title_bar.dart';
import 'scan_methods_screen.dart';
import '../../l10n/buno_locale.dart';

/// /scan/nfc (reference 39_nfc_tap): hold the phone on the station's NFC
/// mark. There is no NFC package yet, so a debug-only "simulate tap" stands
/// in for the read and opens /station for [debugCode].
class ScanNfcScreen extends StatelessWidget {
  const ScanNfcScreen({super.key});

  /// Station the debug tap pretends to read.
  static const debugCode = 'BUN-01';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BunoTitleBar(tr('قرّب موبايلك', 'Tap your phone')),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final size = math.min(200.0, math.min(c.maxWidth * 0.6, c.maxHeight - 150));
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: c.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Rings(size: math.max(size, 96)),
                            const SizedBox(height: BunoSpace.s7),
                            Text(
                              tr('ضهر الموبايل على علامة NFC', 'Back of the phone on the NFC mark'),
                              textAlign: TextAlign.center,
                              style: BunoType.h3,
                            ),
                            const SizedBox(height: BunoSpace.s1),
                            Text(
                              tr('على المحطة تحت الشاشة. خليه ثابت ثانية.', 'On the station under the screen. Hold it still for a second.'),
                              textAlign: TextAlign.center,
                              style: BunoType.bodySm.copyWith(
                                color: BunoDark.text_secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (kDebugMode) ...[
                BunoSecondaryButton(
                  label: tr('محاكاة لمس NFC (ديباج)', 'Simulate NFC tap (debug)'),
                  height: BunoSize.touchMin,
                  compact: true,
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.station, arguments: debugCode),
                ),
                const SizedBox(height: BunoSpace.s2),
              ],
              BunoTextLink(tr('امسح الـ QR بدل كده', 'Scan the QR instead'), onTap: () => ScanMethodsScreen.openScan(context)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three rings fading out from a green disc with the looping nfc icon.
class _Rings extends StatelessWidget {
  const _Rings({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    Widget ring(double f, double alpha) => Container(
          width: size * f,
          height: size * f,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: BunoColors.primary.withValues(alpha: alpha),
              width: BunoStroke.defaultWidth,
            ),
          ),
        );
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ring(1, 0.18),
          ring(0.71, 0.35),
          ring(0.46, 0.6),
          Container(
            width: size * 0.35,
            height: size * 0.35,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: BunoColors.primary,
              boxShadow: [BunoElevation.glow],
            ),
            child: BunoLottieIcon(
              name: 'nfc',
              loop: true,
              size: BunoSize.iconLg,
              color: BunoDark.on_primary,
            ),
          ),
        ],
      ),
    );
  }
}
