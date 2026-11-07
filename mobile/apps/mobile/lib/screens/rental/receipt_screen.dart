import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_rental.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_info_row.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_title_bar.dart';
import '../auth/auth_scaffold.dart' show showBunoToast;
import 'active_rental_screen.dart' show spokenDuration;
import 'rate_sheet.dart';
import '../../l10n/buno_locale.dart';

/// /receipt (reference 12_receipt): what was paid, where from and to, how
/// long, a 1–5 star rating, and a PDF button (not built yet). "تمام" ends
/// the session and goes home. Given a past [trip] (from /history) it shows
/// that trip instead and "تمام" just goes back. A kept unit (not returned
/// within 24 h) shows the no-return fee instead of the hourly lines.
class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key, this.trip});

  final FinishedTrip? trip;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  static const _pdfWidth = 112.0;

  int _rating = 0;
  bool _reasonsSent = false;

  void _done() {
    if (widget.trip != null) {
      Navigator.of(context).pop();
      return;
    }
    if (rentalSession.state != RentalState.active) rentalSession.reset();
    AppRoutes.enterApp(context);
  }

  /// 3 stars or less asks what went wrong ([showRateSheet]), until sent once.
  Future<void> _rate(int n) async {
    setState(() => _rating = n);
    if (n > 3 || _reasonsSent) return;
    final sent = await showRateSheet(context, rating: n);
    if (sent != true || !mounted) return;
    _reasonsSent = true;
    showBunoToast(context, tr('شكرًا، وصلتنا ملاحظتك', 'Thanks, we got your feedback'));
  }

  void _pdf() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(tr('ملف الـ PDF هيكون جاهز قريب', 'The PDF is coming soon')),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final duration = trip?.duration ?? rentalSession.duration;
    final from = trip?.station ?? rentalSession.station;
    final to = trip?.returnStation ?? rentalSession.returnStation;
    final kept = trip?.kept ?? rentalSession.state == RentalState.kept;
    final secondary = BunoType.bodySm.copyWith(color: BunoDark.text_secondary, fontWeight: FontWeight.w600);
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BunoTitleBar(tr('الإيصال', 'Receipt')),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: BunoSpace.s5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(tr('اتدفع', 'Paid'), textAlign: TextAlign.center, style: secondary),
                      Text(tr('[السعر]', '[Price]'), textAlign: TextAlign.center, style: BunoType.display),
                      Text(tr('من المحفظة', 'From wallet'), textAlign: TextAlign.center, style: secondary),
                      const SizedBox(height: BunoSpace.s4),
                      BunoInfoRow(tr('خدته من', 'Picked up at'), from?.name ?? tr('[اسم المكان]', '[Place name]'), divider: true),
                      BunoInfoRow(tr('رجّعته في', 'Returned at'), kept ? tr('الوحدة بقت معاك', 'You kept the unit') : to?.name ?? tr('[اسم المكان]', '[Place name]'), divider: true),
                      BunoInfoRow(
                        tr('المدة', 'Duration'),
                        kept
                            ? tr('24 ساعة', '24 hours')
                            : duration == null
                                ? tr('[المدة]', '[Duration]')
                                : spokenDuration(duration, zero: tr('أقل من دقيقة', 'Under a minute')),
                        divider: true,
                      ),
                      if (kept)
                        BunoInfoRow(tr('رسوم عدم الإرجاع', 'Non-return fee'), tr('[المبلغ]', '[Amount]'))
                      else ...[
                        BunoInfoRow(tr('أول ساعة', 'First hour'), tr('[السعر]', '[Price]'), divider: true),
                        BunoInfoRow(tr('الدقايق الزيادة', 'Extra minutes'), tr('[السعر]', '[Price]')),
                      ],
                      const SizedBox(height: BunoSpace.s5),
                      Text(tr('قيّم الرحلة', 'Rate the trip'), textAlign: TextAlign.center, style: secondary),
                      const SizedBox(height: BunoSpace.s2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var n = 1; n <= 5; n++)
                            _Star(
                              value: n,
                              filled: n <= _rating,
                              onTap: () => _rate(n),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(child: BunoPrimaryButton(label: tr('تمام', 'Done'), onPressed: _done)),
                  const SizedBox(width: BunoSpace.s3),
                  SizedBox(
                    width: _pdfWidth,
                    child: BunoSecondaryButton(
                      label: 'PDF',
                      height: BunoSize.buttonLg,
                      labelWeight: FontWeight.w700,
                      leading: const BunoLottieIcon(
                        name: 'download',
                        size: BunoSize.iconSm,
                        color: BunoDark.text_primary,
                      ),
                      onPressed: _pdf,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({required this.value, required this.filled, required this.onTap});

  final int value;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BunoPressable(
      onTap: onTap,
      semanticLabel: filled ? tr('$value من 5، متقيّم', '$value of 5, selected') : tr('$value من 5', '$value of 5'),
      child: SizedBox.square(
        dimension: BunoSize.buttonMd,
        child: Center(
          child: CustomPaint(
            size: const Size.square(BunoSize.iconLg),
            painter: _StarPainter(filled: filled),
          ),
        ),
      ),
    );
  }
}

/// Five-pointed star: solid green when [filled], grey outline otherwise.
class _StarPainter extends CustomPainter {
  const _StarPainter({required this.filled});

  final bool filled;

  /// Inner radius as a share of the outer one.
  static const _inner = 0.45;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = BunoStroke.defaultWidth;
    final centre = size.center(Offset.zero);
    final outer = size.shortestSide / 2 - stroke;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : outer * _inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = centre + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = filled ? BunoColors.primary : BunoDark.text_disabled
        ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.filled != filled;
}
