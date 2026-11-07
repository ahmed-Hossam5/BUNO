import 'package:buno/screens/scan/scan_camera.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the real camera: no platform channels, and tests can
/// "show" it a QR with [detect].
class FakeScanCamera implements ScanCamera {
  static FakeScanCamera? last;
  ValueChanged<String>? _onCode;
  int torchToggles = 0;
  bool paused = false;

  FakeScanCamera() {
    last = this;
  }

  void detect(String code) => _onCode!(code);

  @override
  Widget preview(ValueChanged<String> onCode) {
    _onCode = onCode;
    return const ColoredBox(color: Color(0xFF202020));
  }

  @override
  Future<void> toggleTorch() async => torchToggles++;

  @override
  Future<void> pause() async => paused = true;

  @override
  Future<void> resume() async => paused = false;

  @override
  void dispose() {}
}

/// Makes /scan use [FakeScanCamera] for the current test.
void useFakeScanCamera() {
  ScanCamera.create = FakeScanCamera.new;
  addTearDown(() => ScanCamera.create = MobileScannerCamera.new);
}
