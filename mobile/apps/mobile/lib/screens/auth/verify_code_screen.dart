import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_auth.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_text_field.dart';
import 'auth_scaffold.dart';
import '../../l10n/buno_locale.dart';

/// Code verification — Brand Board page 6, sending the code to the e-mail
/// used at sign-up instead of a phone number. A good code continues to
/// /permissions, clearing the auth screens behind it.
class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({super.key, this.resendAfter = const Duration(seconds: 42)});

  final Duration resendAfter;

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _code = TextEditingController();
  late int _secondsLeft = widget.resendAfter.inSeconds;
  Timer? _timer;
  bool _busy = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = widget.resendAfter.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) t.cancel();
      setState(() => _secondsLeft -= 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_code.text.length < 4) {
      setState(() => _error = true);
      return;
    }
    setState(() => _busy = true);
    final ok = await MockAuth.verifyCode(_code.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = !ok;
    });
    if (ok) Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.permissions, (_) => false);
  }

  Future<void> _resend() async {
    await MockAuth.resendCode();
    if (!mounted) return;
    _startTimer();
    showBunoToast(context, tr('بعتنالك كود جديد', 'We sent you a new code'));
  }

  @override
  Widget build(BuildContext context) {
    final email = MockAuth.pendingEmail.isEmpty ? 'name@email.com' : MockAuth.pendingEmail;
    final mm = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final ss = (_secondsLeft % 60).toString().padLeft(2, '0');
    final hint = BunoType.body.copyWith(color: BunoDark.text_secondary);

    return AuthScaffold(
      footer: AuthFooter(
        question: tr('إيميلك غلط؟', 'Wrong email?'),
        action: BunoTextLink(
          tr('غيّر الإيميل', 'Change email'),
          style: BunoType.body.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ),
      children: [
        const SizedBox(height: 43),
        Center(
          child: Container(
            width: 97,
            height: 97,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BunoDark.card,
              borderRadius: BorderRadius.circular(BunoRadius.xxl),
              border: Border.all(color: BunoDark.border),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: BunoColors.primary.withValues(alpha: 0.35), blurRadius: 16),
                ],
              ),
              child: const BunoIcon(BunoIcons.powerBank, size: BunoSize.iconLg, color: BunoColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 17),
        Text(tr('اكتب الكود', 'Enter the code'), textAlign: TextAlign.center, style: BunoType.h1.copyWith(fontSize: 28, height: 1.3)),
        const SizedBox(height: 16),
        Text(tr('بعتنالك كود من 4 أرقام على', 'We sent a 4-digit code to'), textAlign: TextAlign.center, style: hint),
        Text(
          email,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          style: BunoType.body.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 32),
        Center(
          child: BunoOtpField(
            controller: _code,
            hasError: _error,
            onChanged: (_) {
              if (_error) setState(() => _error = false);
            },
            onCompleted: (_) => _confirm(),
          ),
        ),
        if (_error) ...[
          const SizedBox(height: 10),
          Text(
            tr('الكود مش صح، جرّب تاني', "That code isn't right, try again"),
            textAlign: TextAlign.center,
            style: BunoType.caption.copyWith(color: BunoColors.error),
          ),
        ],
        const SizedBox(height: 17.7),
        Center(
          child: _secondsLeft > 0
              ? Text.rich(
                  TextSpan(
                    style: hint,
                    children: [
                      TextSpan(text: tr('مجاش الكود؟ إعادة الإرسال بعد ', "Didn't get it? Resend in ")),
                      TextSpan(
                        text: '\u2066$mm:$ss\u2069',
                        style: const TextStyle(
                          fontFamily: BunoFonts.sora,
                          fontWeight: FontWeight.w700,
                          color: BunoColors.primary,
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tr('مجاش الكود؟ ', "Didn't get it? "), style: hint),
                    BunoTextLink(tr('ابعته تاني', 'Send again'), style: hint, onTap: _resend),
                  ],
                ),
        ),
        const SizedBox(height: 21.4),
        BunoPrimaryButton(label: tr('تأكيد', 'Confirm'), loading: _busy, onPressed: _confirm),
      ],
    );
  }
}
