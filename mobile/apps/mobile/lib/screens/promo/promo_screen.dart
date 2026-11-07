import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_routes.dart';
import '../../data/repositories.dart';
import '../../data/mock_promo.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_tab_header.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/buno_title_bar.dart';
import '../../l10n/buno_locale.dart';

/// /promo (reference 49_promo), from the wallet's "كود خصم": a ticket with
/// the code field, the result, and the user's offers. Amounts and dates stay
/// placeholders.
class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  final _code = TextEditingController();
  PromoResult? _result;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    if (_code.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    final result = await Repos.promo.redeem(_code.text);
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _result = result);
    if (result == PromoResult.added) _code.clear();
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
              BunoTitleBar(tr('كود الخصم', 'Promo code')),
              Expanded(
                child: ListenableBuilder(
                  listenable: Repos.promo,
                  builder: (context, _) => ListView(
                    padding: const EdgeInsets.symmetric(vertical: BunoSpace.s5),
                    children: [
                      _Ticket(
                        controller: _code,
                        onRedeem: _redeem,
                        onChanged: () => setState(() => _result = null),
                      ),
                      if (_result != null) ...[
                        const SizedBox(height: BunoSpace.s3),
                        _ResultBanner(result: _result!),
                      ],
                      const SizedBox(height: BunoSpace.s5),
                      BunoSectionTitle(tr('عروضك', 'Your offers')),
                      const SizedBox(height: BunoSpace.s2),
                      for (final o in Repos.promo.offers) ...[
                        _OfferRow(offer: o),
                        const SizedBox(height: BunoSpace.s3),
                      ],
                    ],
                  ),
                ),
              ),
              BunoPrimaryButton(
                label: tr('ادعي صاحب واكسبوا انتو الاتنين', 'Invite a friend and you both win'),
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.referral),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Green ticket: headline, a perforation with side notches, then the code
/// field and "فعّل".
class _Ticket extends StatelessWidget {
  const _Ticket({required this.controller, required this.onRedeem, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onRedeem;
  final VoidCallback onChanged;

  static const _notch = BunoSpace.s3;

  @override
  Widget build(BuildContext context) {
    final onPrimary = BunoType.caption.copyWith(color: BunoDark.on_primary);
    return Container(
      decoration: BoxDecoration(
        color: BunoColors.primary,
        borderRadius: BorderRadius.circular(BunoRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(BunoSpace.s5, BunoSpace.s5, BunoSpace.s5, BunoSpace.s3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('عندك كود؟', 'Have a code?'), style: onPrimary),
                      Text(
                        tr('اكتبه واكسب دقايق ببلاش', 'Enter it and get free minutes'),
                        style: BunoType.h3.copyWith(color: BunoDark.on_primary),
                      ),
                    ],
                  ),
                ),
                const BunoLottieIcon(name: 'gift', color: BunoDark.on_primary),
              ],
            ),
          ),
          Row(
            children: [
              _halfNotch(start: true),
              const Expanded(child: _DashedLine(color: BunoDark.on_primary)),
              _halfNotch(start: false),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(BunoSpace.s4),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: BunoSize.input,
                    padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: BunoDark.on_primary,
                      borderRadius: BorderRadius.circular(BunoRadius.md),
                    ),
                    child: TextField(
                      controller: controller,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      enableSuggestions: false,
                      cursorColor: BunoColors.primary,
                      onChanged: (_) => onChanged(),
                      onSubmitted: (_) => onRedeem(),
                      style: BunoType.number(BunoType.title).copyWith(letterSpacing: 1.5),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: tr('الكود', 'Code'),
                        hintTextDirection: Directionality.of(context),
                        hintStyle: BunoType.body.copyWith(color: BunoDark.text_disabled),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: BunoSpace.s3),
                BunoPressable(
                  onTap: onRedeem,
                  semanticLabel: tr('فعّل الكود', 'Apply code'),
                  child: Container(
                    height: BunoSize.input,
                    padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: BunoDark.on_primary,
                      borderRadius: BorderRadius.circular(BunoRadius.md),
                    ),
                    child: Text(
                      tr('فعّل', 'Apply'),
                      style: BunoType.title.copyWith(fontWeight: FontWeight.w700, color: BunoColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Half circle cut into the ticket's side, in the page colour.
  Widget _halfNotch({required bool start}) {
    const r = Radius.circular(_notch);
    return Container(
      width: _notch,
      height: _notch * 2,
      decoration: BoxDecoration(
        color: BunoDark.background,
        borderRadius: start
            ? const BorderRadiusDirectional.horizontal(end: r)
            : const BorderRadiusDirectional.horizontal(start: r),
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine({required this.color, this.axis = Axis.horizontal});

  final Color color;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final horizontal = axis == Axis.horizontal;
    return SizedBox(
      width: horizontal ? double.infinity : BunoStroke.defaultWidth,
      height: horizontal ? BunoStroke.defaultWidth : null,
      child: CustomPaint(painter: _DashPainter(color: color, axis: axis)),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.color, required this.axis});

  final Color color;
  final Axis axis;

  static const _dash = 6.0;
  static const _gap = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = BunoStroke.defaultWidth;
    final horizontal = axis == Axis.horizontal;
    final length = horizontal ? size.width : size.height;
    for (var x = _gap; x < length - _gap; x += _dash + _gap) {
      final end = (x + _dash).clamp(0, length - _gap).toDouble();
      horizontal
          ? canvas.drawLine(Offset(x, size.height / 2), Offset(end, size.height / 2), paint)
          : canvas.drawLine(Offset(size.width / 2, x), Offset(size.width / 2, end), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color || old.axis != axis;
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.result});

  final PromoResult result;

  @override
  Widget build(BuildContext context) {
    final ok = result == PromoResult.added;
    final color = ok ? BunoColors.secondary : BunoColors.error;
    final (title, body) = switch (result) {
      PromoResult.added => (tr('اتفعّل!', 'Applied!'), tr('${Repos.promo.lastAdded?.title ?? '[المدة] ببلاش'} على إيجارك الجاي', '${Repos.promo.lastAdded?.title ?? '[Duration] free'} on your next rental')),
      PromoResult.alreadyUsed => (tr('الكود ده اتفعّل قبل كده', 'This code was already used'), tr('كل كود ينفع مرة واحدة بس.', 'Each code works only once.')),
      PromoResult.invalid => (tr('الكود ده مش صحيح', "This code isn't valid"), tr('اتأكد من الحروف والأرقام وجرب تاني.', 'Check the letters and numbers and try again.')),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(BunoSpace.s4),
        decoration: BoxDecoration(
          color: ok ? BunoColors.primary_soft : BunoDark.card,
          borderRadius: BorderRadius.circular(BunoRadius.lg),
          border: Border.all(color: color, width: BunoStroke.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: BunoSize.buttonSm,
              height: BunoSize.buttonSm,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: BunoIcon(ok ? BunoIcons.check : BunoIcons.warning, size: BunoSize.iconSm, color: BunoDark.on_primary),
            ),
            const SizedBox(width: BunoSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: BunoType.title.copyWith(fontWeight: FontWeight.w700)),
                  BunoText(body, style: BunoType.caption.copyWith(color: BunoDark.text_secondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ticket-style row: what it is, a dashed tear line, then جاهز / انتهى.
class _OfferRow extends StatelessWidget {
  const _OfferRow({required this.offer});

  final PromoOffer offer;

  static const _stub = 72.0;

  @override
  Widget build(BuildContext context) {
    final expired = offer.expired;
    return Container(
      decoration: BoxDecoration(
        color: expired ? BunoDark.surface : BunoDark.card,
        borderRadius: BorderRadius.circular(BunoRadius.lg),
        border: Border.all(color: BunoDark.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(BunoSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BunoText(
                      offer.title,
                      style: BunoType.title.copyWith(
                        fontWeight: FontWeight.w700,
                        color: expired ? BunoDark.text_disabled : BunoDark.text_primary,
                      ),
                    ),
                    BunoText(
                      offer.source,
                      style: BunoType.caption.copyWith(color: expired ? BunoDark.text_disabled : BunoDark.text_secondary),
                    ),
                  ],
                ),
              ),
            ),
            const _DashedLine(color: BunoDark.text_disabled, axis: Axis.vertical),
            SizedBox(
              width: _stub,
              child: Center(
                child: Text(
                  expired ? tr('انتهى', 'Expired') : tr('جاهز', 'Ready'),
                  style: BunoType.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: expired ? BunoDark.text_disabled : BunoColors.secondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
