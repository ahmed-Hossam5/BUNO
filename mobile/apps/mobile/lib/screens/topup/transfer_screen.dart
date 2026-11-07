import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_routes.dart';
import '../../data/mock_topup.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/buno_text_field.dart';
import '../auth/auth_scaffold.dart' show showBunoToast;
import 'topup_screen.dart';
import '../../l10n/buno_locale.dart';

/// Picks the receipt photo; null when the user cancels.
typedef ReceiptPicker = Future<XFile?> Function();

Future<XFile?> _pickFromGallery() =>
    ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);

/// /topup/transfer (reference 17_transfer): where to send the money (with a
/// copy button), the receipt photo and the reference number. "ابعت
/// للمراجعة" needs one of the two and opens /topup/pending.
class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key, required this.request, this.pickReceipt = _pickFromGallery});

  final TopupRequest request;

  /// Swapped in tests; defaults to the photo library via image_picker.
  final ReceiptPicker pickReceipt;

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _reference = TextEditingController();
  Uint8List? _receipt;
  int _copies = 0;

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  bool get _canSend => _receipt != null || _reference.text.trim().isNotEmpty;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.request.method.account));
    if (!mounted) return;
    setState(() => _copies++);
    showBunoToast(context, tr('اتنسخ', 'Copied'));
  }

  Future<void> _pick() async {
    final file = await widget.pickReceipt();
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _receipt = bytes);
  }

  void _send() => Navigator.of(context).pushNamed(AppRoutes.topupPending, arguments: widget.request);

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TopupHeader(request.method.title),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: BunoSpace.s6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AccountCard(
                        label: request.method.payTo(request.amount),
                        account: request.method.account,
                        copies: _copies,
                        onCopy: _copy,
                      ),
                      const SizedBox(height: BunoSpace.s4),
                      _ReceiptBox(image: _receipt, onTap: _pick),
                      const SizedBox(height: BunoSpace.s5),
                      BunoTextField(
                        label: tr('رقم العملية', 'Transaction number'),
                        hint: tr('مثلًا 8821340', 'e.g. 8821340'),
                        icon: BunoIcons.receipt,
                        controller: _reference,
                        ltrContent: true,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: BunoSpace.s3),
                      BunoText(
                        tr('بنراجع التحويل في خلال 15 دقيقة.', 'We review transfers within 15 minutes.'),
                        style: BunoType.caption.copyWith(color: BunoDark.text_secondary),
                      ),
                    ],
                  ),
                ),
              ),
              BunoPrimaryButton(label: tr('ابعت للمراجعة', 'Send for review'), onPressed: _canSend ? _send : null),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.label, required this.account, required this.copies, required this.onCopy});

  final String label;
  final String account;

  /// Times copied; each change plays the copy animation.
  final int copies;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(BunoSpace.s5, BunoSpace.s4, BunoSpace.s3, BunoSpace.s4),
      decoration: BoxDecoration(
        color: BunoDark.card,
        borderRadius: BorderRadius.circular(BunoRadius.lg),
        border: Border.all(color: BunoDark.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BunoText(label, style: BunoType.caption.copyWith(color: BunoDark.text_secondary)),
                const SizedBox(height: BunoSpace.s1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    account,
                    textDirection: TextDirection.ltr,
                    style: BunoType.number(BunoType.h2),
                  ),
                ),
              ],
            ),
          ),
          BunoPressable(
            onTap: onCopy,
            semanticLabel: tr('نسخ', 'Copy'),
            child: SizedBox(
              height: BunoSize.touchMin,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BunoLottieIcon(
                      name: 'copy',
                      size: BunoSize.iconSm,
                      color: BunoColors.primary,
                      playKey: copies == 0 ? null : copies,
                    ),
                    const SizedBox(width: BunoSpace.s1),
                    Text(
                      tr('نسخ', 'Copy'),
                      style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w600, color: BunoColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed upload box; shows the picked photo once there is one.
class _ReceiptBox extends StatelessWidget {
  const _ReceiptBox({required this.image, required this.onTap});

  final Uint8List? image;
  final VoidCallback onTap;

  static const _height = 150.0;

  @override
  Widget build(BuildContext context) {
    final picked = image != null;
    return BunoPressable(
      onTap: onTap,
      semanticLabel: picked ? tr('غيّر صورة الإيصال', 'Change receipt photo') : tr('ارفع صورة الإيصال', 'Upload receipt photo'),
      child: CustomPaint(
        painter: _DashedBorder(color: picked ? BunoColors.primary : BunoDark.border),
        child: SizedBox(
          height: _height,
          child: picked
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(BunoRadius.lg),
                      child: Image.memory(
                        image!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                    PositionedDirectional(
                      bottom: BunoSpace.s3,
                      start: BunoSpace.s3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s3, vertical: BunoSpace.s1),
                        decoration: BoxDecoration(
                          color: BunoDark.background.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(BunoRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const BunoIcon(BunoIcons.check, size: BunoSize.iconSm, color: BunoColors.primary),
                            const SizedBox(width: BunoSpace.s1),
                            Text(tr('اترفعت · غيّرها', 'Uploaded · change'), style: BunoType.caption),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const BunoIcon(BunoIcons.receipt, color: BunoColors.primary),
                    const SizedBox(height: BunoSpace.s3),
                    Text(tr('ارفع صورة الإيصال', 'Upload receipt photo'), style: BunoType.title.copyWith(fontSize: 15)),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color});

  final Color color;

  static const _dash = 6.0;
  static const _gap = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(BunoRadius.lg),
    ).deflate(BunoStroke.hairline / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = BunoStroke.hairline;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
