import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/repositories.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_empty_state.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text_link.dart';
import '../../widgets/buno_title_bar.dart';
import 'scan_camera.dart';
import '../../l10n/buno_locale.dart';

/// Scan — reference 01_scan. Full-screen camera, glowing frame, torch and
/// close buttons, "type the code" and "other ways" links. A Buno station QR
/// opens /station; a web link that isn't Buno's shows the fake-QR warning
/// (reference 42_fake_qr); any other QR shows the scan-failed state
/// (reference 28_state_scan_fail).
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  /// Code the debug "simulate scan" button pretends to read.
  static const debugCode = 'BUN-01';

  /// True when [code] is a web link off buno.app: likely a sticker over the
  /// station's real QR.
  static bool isForeignLink(String code) {
    final uri = Uri.tryParse(code.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;
    final host = uri.host.toLowerCase();
    return host != 'buno.app' && !host.endsWith('.buno.app');
  }

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  static const _gutter = 22.0;

  late final ScanCamera _camera = ScanCamera.create();
  bool _torchOn = false;

  /// True while /station is open, so one QR opens it only once.
  bool _busy = false;

  /// The last QR wasn't a Buno station; the camera stays paused.
  bool _failed = false;

  /// The failed QR was someone else's link (fake-QR warning).
  bool _foreign = false;

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  Future<void> _onCode(String code) async {
    if (_busy) return;
    _busy = true;
    await _camera.pause();
    if (!mounted) return;
    final foreign = ScanScreen.isForeignLink(code);
    if (foreign || Repos.stations.byCode(code) == null) {
      setState(() {
        _failed = true;
        _foreign = foreign;
      });
      return;
    }
    await Navigator.of(context).pushNamed(AppRoutes.station, arguments: code);
    if (!mounted) return;
    await _camera.resume();
    _busy = false;
  }

  Future<void> _retry() async {
    setState(() => _failed = false);
    await _camera.resume();
    _busy = false;
  }

  Future<void> _typeCode() async {
    await Navigator.of(context).pushNamed(AppRoutes.scanCode);
    if (mounted) await _retry();
  }

  Future<void> _toggleTorch() async {
    await _camera.toggleTorch();
    if (mounted) setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    // The camera stays mounted under the failed state so retry just resumes it.
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCamera(context),
        if (_failed) _foreign ? _buildForeign() : _buildFailed(),
      ],
    );
  }

  Widget _buildForeign() {
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_gutter, 18, _gutter, 16),
          child: BunoEmptyState(
            header: BunoTitleBar(tr('المسح', 'Scan')),
            icon: const BunoLottieIcon(
              name: 'warning',
              size: 40,
              color: BunoColors.error,
              playKey: 0,
            ),
            title: tr('الكود ده مش بتاع بونو', "This isn't a Buno code"),
            body:
                tr('ممكن يكون ملزوق فوق الكود الأصلي. ', 'It may be stuck over the real code. ') +
                tr('متدفعش من أي لينك، وبلّغنا عشان نشيله.', "Don't pay through any link, and report it so we can remove it."),
            actionLabel: tr('بلّغ عن الكود', 'Report the code'),
            onAction: () => Navigator.of(context).pushNamed(AppRoutes.report),
            linkLabel: tr('امسح كود تاني', 'Scan another code'),
            onLink: _retry,
          ),
        ),
      ),
    );
  }

  Widget _buildFailed() {
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_gutter, 18, _gutter, 16),
          child: BunoEmptyState(
            header: BunoTitleBar(tr('المسح', 'Scan')),
            icon: const BunoLottieIcon(
              name: 'scan',
              size: 40,
              color: BunoColors.warning,
              playKey: 0,
            ),
            title: tr('الكود مش واضح', "The code isn't clear"),
            body:
                tr('ده مش كود محطة بونو، ومفيش فلوس اتخصمت. ', "That's not a Buno station code, and nothing was charged. ") +
                tr('قرّب الموبايل أو نضّف الكاميرا وجرّب تاني، ولو مش راضي اكتب كود المحطة.', "Move closer or clean the camera and try again. If it still won't scan, enter the station code."),
            actionLabel: tr('جرّب تاني', 'Try again'),
            onAction: _retry,
            linkLabel: tr('اكتب كود المحطة', 'Enter the station code'),
            onLink: _typeCode,
          ),
        ),
      ),
    );
  }

  Widget _buildCamera(BuildContext context) {
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _camera.preview(_onCode),
          // Darkens the edges so the frame and labels read on any picture.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.9,
                colors: [Color(0x330A0A0B), Color(0xCC0A0A0B)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_gutter, 18, _gutter, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      _RoundButton(
                        label: tr('قفل', 'Close'),
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const BunoIcon(
                          BunoIcons.close,
                          color: BunoDark.text_primary,
                        ),
                      ),
                      const Spacer(),
                      _RoundButton(
                        label: _torchOn ? tr('اطفي الكشاف', 'Turn off flashlight') : tr('نوّر الكشاف', 'Turn on flashlight'),
                        onTap: _toggleTorch,
                        child: BunoLottieIcon(
                          name: 'flashlight',
                          playKey: _torchOn,
                          size: BunoSize.iconSm,
                          color: _torchOn
                              ? BunoColors.primary
                              : BunoDark.text_primary,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final frame = math.min(
                          260.0,
                          math.min(c.maxWidth * 0.66, c.maxHeight - 90),
                        );
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            BunoLottieIcon(
                              name: 'scan',
                              loop: true,
                              size: frame,
                              color: BunoColors.primary,
                            ),
                            const SizedBox(height: 28),
                            Text(
                              tr('وجّه الكاميرا على الـ QR', 'Point the camera at the QR'),
                              textAlign: TextAlign.center,
                              style: BunoType.title,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (kDebugMode) ...[
                    BunoSecondaryButton(
                      label: tr('محاكاة مسح (ديباج)', 'Simulate scan (debug)'),
                      height: BunoSize.touchMin,
                      compact: true,
                      onPressed: () => _onCode(ScanScreen.debugCode),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Semantics(
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.scanCode),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: BunoSize.touchMin,
                        ),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            tr('مش راضي يمسح؟ اكتب الكود', "Won't scan? Enter the code"),
                            style: BunoType.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: BunoDark.text_secondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  BunoTextLink(
                    tr('طرق تانية للفتح', 'Other ways to open'),
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.scanMethods),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 44pt round control on the camera (close, torch).
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BunoPressable(
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        width: BunoSize.touchMin,
        height: BunoSize.touchMin,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: BunoDark.elevated,
          shape: BoxShape.circle,
        ),
        child: child,
      ),
    );
  }
}
