import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_status_pill.dart';
import '../../widgets/buno_title_bar.dart';
import '../../l10n/buno_locale.dart';

enum ScanMethod { qr, nfc, code }

/// /scan/methods (reference 38_scan_methods): QR (fastest), NFC, or typing
/// the station code. Tapping a card selects it; the CTA opens that way.
class ScanMethodsScreen extends StatefulWidget {
  const ScanMethodsScreen({super.key});

  /// Back to the /scan underneath, or a fresh /scan when there is none
  /// (shared with /scan/nfc).
  static void openScan(BuildContext context) {
    final nav = Navigator.of(context);
    var found = false;
    nav.popUntil((r) {
      found = r.settings.name == AppRoutes.scan;
      return found || r.isFirst;
    });
    if (!found) nav.pushNamed(AppRoutes.scan);
  }

  @override
  State<ScanMethodsScreen> createState() => _ScanMethodsScreenState();
}

class _ScanMethodsScreenState extends State<ScanMethodsScreen> {
  ScanMethod _method = ScanMethod.qr;

  void _go() {
    switch (_method) {
      case ScanMethod.qr:
        ScanMethodsScreen.openScan(context);
      case ScanMethod.nfc:
        Navigator.of(context).pushNamed(AppRoutes.scanNfc);
      case ScanMethod.code:
        Navigator.of(context).pushNamed(AppRoutes.scanCode);
    }
  }

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
              BunoTitleBar(tr('تفتح المحطة إزاي؟', 'How do you want to open the station?')),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: BunoSpace.s6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MethodCard(
                        lottie: 'qr',
                        title: tr('امسح الـ QR', 'Scan the QR'),
                        subtitle: tr('شغال على كل الموبايلات', 'Works on every phone'),
                        tag: tr('الأسرع', 'Fastest'),
                        selected: _method == ScanMethod.qr,
                        onTap: () => setState(() => _method = ScanMethod.qr),
                      ),
                      const SizedBox(height: BunoSpace.s3),
                      _MethodCard(
                        lottie: 'nfc',
                        title: tr('قرّب الموبايل (NFC)', 'Tap your phone (NFC)'),
                        subtitle: tr('لو موبايلك فيه NFC', 'If your phone has NFC'),
                        selected: _method == ScanMethod.nfc,
                        onTap: () => setState(() => _method = ScanMethod.nfc),
                      ),
                      const SizedBox(height: BunoSpace.s3),
                      _MethodCard(
                        lottie: 'edit',
                        title: tr('اكتب كود المحطة', 'Enter the station code'),
                        subtitle: tr('لو الكاميرا مش شغالة', "If the camera isn't working"),
                        selected: _method == ScanMethod.code,
                        onTap: () => setState(() => _method = ScanMethod.code),
                      ),
                      const SizedBox(height: BunoSpace.s5),
                      Text(
                        tr('كل الطرق بتوصل لنفس الخطوة: المحطة بتتأكد إن الطلب منك قبل ما تفتح.', 'Every way leads to the same step: the station checks the request is yours before it opens.'),
                        style: BunoType.bodySm.copyWith(
                          color: BunoDark.text_secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              BunoPrimaryButton(
                label: switch (_method) {
                  ScanMethod.qr => tr('امسح الـ QR', 'Scan the QR'),
                  ScanMethod.nfc => tr('قرّب الموبايل', 'Tap your phone'),
                  ScanMethod.code => tr('اكتب الكود', 'Enter the code'),
                },
                icon: _method == ScanMethod.qr ? BunoIcons.scan : null,
                onPressed: _go,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.lottie,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.tag,
  });

  final String lottie;
  final String title;
  final String subtitle;
  final String? tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.of(context).disableAnimations ? Duration.zero : BunoMotion.base;
    return Semantics(
      selected: selected,
      child: BunoPressable(
        semanticLabel: title,
        onTap: onTap,
        child: AnimatedContainer(
          duration: duration,
          padding: const EdgeInsets.all(BunoSpace.s4),
          decoration: BoxDecoration(
            color: BunoDark.card,
            borderRadius: BorderRadius.circular(BunoRadius.lg),
            border: Border.all(
              color: selected ? BunoColors.primary : BunoDark.card,
              width: BunoStroke.defaultWidth,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: duration,
                width: BunoSize.avatarMd,
                height: BunoSize.avatarMd,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? BunoColors.primary_soft : BunoDark.elevated,
                  borderRadius: BorderRadius.circular(BunoRadius.md),
                ),
                child: BunoLottieIcon(
                  name: lottie,
                  size: BunoSize.iconMd,
                  color: selected ? BunoColors.primary : BunoDark.text_primary,
                  playKey: selected,
                ),
              ),
              const SizedBox(width: BunoSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: BunoType.title),
                    Text(
                      subtitle,
                      style: BunoType.caption.copyWith(color: BunoDark.text_secondary),
                    ),
                  ],
                ),
              ),
              if (tag != null) ...[
                const SizedBox(width: BunoSpace.s2),
                BunoStatusPill(tag!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
