import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_auth.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_text_field.dart';
import 'apple_sign_in_button.dart';
import 'auth_scaffold.dart';
import '../../l10n/buno_locale.dart';

/// Sign-up — Brand Board page 5, with e-mail instead of phone and a
/// "Sign in with Apple" (iCloud) option under the main action.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _agreed = true;
  bool _busy = false;
  String? _nameError, _emailError, _passwordError, _termsError;
  late final _termsTap = TapGestureRecognizer()
    ..onTap = () => showBunoToast(context, tr('الشروط والأحكام', 'Terms and Conditions'));
  late final _privacyTap = TapGestureRecognizer()
    ..onTap = () => showBunoToast(context, tr('سياسة الخصوصية', 'Privacy Policy'));

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _nameError = _name.text.trim().isEmpty ? tr('اكتب اسمك', 'Enter your name') : null;
      _emailError = MockAuth.isValidEmail(_email.text)
          ? null
          : tr('اكتب إيميل صحيح', 'Enter a valid email');
      _passwordError = MockAuth.isValidPassword(_password.text)
          ? null
          : tr('كلمة السر لازم تكون 8 حروف على الأقل', 'Password must be at least 8 characters');
      _termsError = _agreed ? null : tr('لازم توافق على الشروط الأول', 'You need to accept the terms first');
    });
    final errors = [_nameError, _emailError, _passwordError, _termsError];
    if (errors.any((e) => e != null)) return;
    setState(() => _busy = true);
    await MockAuth.signUp(_name.text, _email.text, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pushNamed(AppRoutes.verify);
  }

  /// Apple has already confirmed the e-mail, so there's no code step: on
  /// to /permissions, clearing the auth screens behind it.
  Future<void> _apple() async {
    await MockAuth.signInWithApple();
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.permissions, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final link = BunoType.body.copyWith(fontSize: 13);
    return AuthScaffold(
      footer: AuthFooter(
        question: tr('عندك حساب بالفعل؟', 'Already have an account?'),
        action: BunoTextLink(
          tr('سجّل دخول', 'Log in'),
          style: BunoType.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          onTap: () =>
              Navigator.of(context).pushReplacementNamed(AppRoutes.login),
        ),
      ),
      children: [
        const SizedBox(height: 36),
        AuthTitle(
          title: tr('اعمل حساب', 'Create an account'),
          subtitle: tr('دقيقة واحدة وتبقى جاهز تاخد أول بونو.', "One minute and you're ready for your first Buno."),
        ),
        const SizedBox(height: 26.4),
        BunoTextField(
          label: tr('الاسم', 'Name'),
          hint: tr('اسمك بالكامل', 'Your full name'),
          icon: BunoIcons.profile,
          controller: _name,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          errorText: _nameError,
        ),
        const SizedBox(height: 16),
        BunoTextField(
          label: tr('الإيميل', 'Email'),
          hint: 'name@email.com',
          icon: BunoIcons.mail,
          controller: _email,
          ltrContent: true,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          errorText: _emailError,
        ),
        const SizedBox(height: 16),
        BunoTextField(
          label: tr('كلمة السر', 'Password'),
          hint: tr('8 حروف على الأقل', 'At least 8 characters'),
          icon: BunoIcons.lock,
          controller: _password,
          obscure: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          errorText: _passwordError,
        ),
        // The whole row toggles the box, so the 22pt checkbox keeps a full
        // touch target while sitting 10pt from its label as on the board.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _agreed = !_agreed),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: BunoSize.touchMin),
            child: Row(
              children: [
                Semantics(
                  checked: _agreed,
                  label: tr('موافق على الشروط والأحكام وسياسة الخصوصية', 'I agree to the Terms and Conditions and Privacy Policy'),
                  child: BunoCheckbox.bare(value: _agreed),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: link.copyWith(color: BunoDark.text_secondary),
                      children: [
                        TextSpan(text: tr('موافق على ', 'I agree to the ')),
                        TextSpan(
                          text: tr('الشروط والأحكام', 'Terms and Conditions'),
                          style: const TextStyle(
                            color: BunoColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: _termsTap,
                        ),
                        TextSpan(text: tr(' و', ' and ')),
                        TextSpan(
                          text: tr('سياسة الخصوصية', 'Privacy Policy'),
                          style: const TextStyle(
                            color: BunoColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: _privacyTap,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_termsError != null)
          Text(
            _termsError!,
            style: BunoType.caption.copyWith(color: BunoColors.error),
          ),
        const SizedBox(height: 10),
        BunoPrimaryButton(
          label: tr('إنشاء الحساب', 'Create account'),
          loading: _busy,
          onPressed: _submit,
        ),
        const SizedBox(height: 24),
        const BunoOrDivider(),
        const SizedBox(height: 24),
        AppleSignInButton(label: tr('التسجيل بـ Apple', 'Sign up with Apple'), onPressed: _apple),
      ],
    );
  }
}
