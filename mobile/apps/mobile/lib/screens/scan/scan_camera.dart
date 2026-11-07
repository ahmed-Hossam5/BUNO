import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../theme/buno_tokens.dart';

/// The camera behind /scan. Tests swap [ScanCamera.create] for a fake so no
/// platform camera is touched.
abstract class ScanCamera {
  static ScanCamera Function() create = MobileScannerCamera.new;

  /// Full-screen preview; calls [onCode] with the raw text of each QR seen.
  Widget preview(ValueChanged<String> onCode);

  Future<void> toggleTorch();

  /// Stops the camera while another screen is on top, and restarts it.
  Future<void> pause();
  Future<void> resume();

  void dispose();
}

/// Real camera via `mobile_scanner`, QR codes only.
class MobileScannerCamera implements ScanCamera {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  Widget preview(ValueChanged<String> onCode) => MobileScanner(
    controller: _controller,
    onDetect: (capture) {
      for (final code in capture.barcodes) {
        final raw = code.rawValue;
        if (raw != null && raw.isNotEmpty) return onCode(raw);
      }
    },
    // No camera (denied, simulator): plain background; the manual-code link
    // stays on screen as the way forward.
    errorBuilder: (context, error) =>
        const ColoredBox(color: BunoDark.background),
  );

  @override
  Future<void> toggleTorch() => _controller.toggleTorch();

  @override
  Future<void> pause() => _controller.stop();

  @override
  Future<void> resume() => _controller.start();

  @override
  void dispose() => _controller.dispose();
}
