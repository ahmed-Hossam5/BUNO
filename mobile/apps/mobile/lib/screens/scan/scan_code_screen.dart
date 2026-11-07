import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_routes.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_back_button.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/buno_text_field.dart';
import '../../l10n/buno_locale.dart';

/// Manual station code — reference 02_scan_manual_code. Six cells for a
/// `BUN-01` style code; Continue opens /station.
class ScanCodeScreen extends StatefulWidget {
  const ScanCodeScreen({super.key});

  /// Three letters, a dash, two digits.
  static final validCode = RegExp(r'^[A-Z]{3}-[0-9]{2}$');

  @override
  State<ScanCodeScreen> createState() => _ScanCodeScreenState();
}

class _ScanCodeScreenState extends State<ScanCodeScreen> {
  static const _gutter = 22.0;
  static const _length = 6;
  static const _gap = 8.0;

  static List<String> get _tips => [
    tr('نضّف عدسة الكاميرا', 'Clean the camera lens'),
    tr('قرّب الموبايل من الـ QR', 'Bring the phone closer to the QR'),
    tr('لو شاشة المحطة مطفية، بلّغنا', "If the station's screen is off, tell us"),
  ];

  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  bool get _valid => ScanCodeScreen.validCode.hasMatch(_code.text);
  bool get _wrong => _code.text.length == _length && !_valid;

  void _continue() => Navigator.of(context)
      .pushNamed(AppRoutes.station, arguments: _code.text);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_gutter, 18, _gutter, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: AlignmentDirectional.centerEnd,
                child: BunoBackButton(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(tr('اكتب كود المحطة', 'Enter the station code'), style: BunoType.h1),
                      const SizedBox(height: 4),
                      Text(
                        tr('مكتوب على المحطة تحت الـ QR.', 'Printed on the station under the QR.'),
                        style: BunoType.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: BunoDark.text_secondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, c) => Center(
                          child: BunoOtpField(
                            length: _length,
                            controller: _code,
                            hasError: _wrong,
                            keyboardType: TextInputType.visiblePassword,
                            autofillHints: null,
                            inputFormatters: [_StationCodeFormatter()],
                            cellGap: _gap,
                            cellWidth: math.min(
                              56,
                              (c.maxWidth - _gap * (_length - 1)) / _length,
                            ),
                            onCompleted: (_) {
                              if (_valid) FocusScope.of(context).unfocus();
                            },
                          ),
                        ),
                      ),
                      if (_wrong) ...[
                        const SizedBox(height: 8),
                        BunoText(
                          tr('الكود بيبقى زي BUN-01', 'The code looks like BUN-01'),
                          style: BunoType.caption.copyWith(
                            color: BunoColors.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      for (var i = 0; i < _tips.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              BunoText(
                                '${i + 1}',
                                style: BunoType.bodySm.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: BunoColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _tips[i],
                                  style: BunoType.bodySm.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: BunoDark.text_secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedOpacity(
                opacity: _valid ? 1 : 0.4,
                duration: BunoMotion.fast,
                child: BunoPrimaryButton(
                  label: tr('كمّل', 'Continue'),
                  onPressed: _valid ? _continue : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Upper-cases, keeps letters and digits, and puts the dash after the first
/// three characters, so `bun01` and `BUN-01` both become `BUN-01`.
class _StationCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var raw = newValue.text.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    if (raw.length > 5) raw = raw.substring(0, 5);
    final text = raw.length > 3
        ? '${raw.substring(0, 3)}-${raw.substring(3)}'
        : raw;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
