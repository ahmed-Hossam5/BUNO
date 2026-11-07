import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_auth.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_text_field.dart';
import 'apple_sign_in_button.dart';
import 'auth_scaffold.dart';
import '../../l10n/buno_locale.dart';

/// Login — Brand Board page 4, with e-mail instead of phone and only
/// "Sign in with Apple" (iCloud) as the social option.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _emailError;
  String? _passwordError;
  bool _busy = false;
  bool _appleBusy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _emailError = MockAuth.isValidEmail(_email.text) ? null : tr('اكتب إيميل صحيح', 'Enter a valid email');
      _passwordError = _password.text.isEmpty ? tr('اكتب كلمة السر', 'Enter your password') : null;
    });
    if (_emailError != null || _passwordError != null) return;
    setState(() => _busy = true);
    await MockAuth.signIn(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    AppRoutes.enterApp(context);
  }

  Future<void> _apple() async {
    setState(() => _appleBusy = true);
    await MockAuth.signInWithApple();
    if (!mounted) return;
    setState(() => _appleBusy = false);
    AppRoutes.enterApp(context);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      footer: AuthFooter(
        question: tr('معندكش حساب؟', "Don't have an account?"),
        action: BunoTextLink(
          tr('اعمل حساب', 'Sign up'),
          style: BunoType.body.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
          onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.signup),
        ),
      ),
      children: [
        const SizedBox(height: 38),
        AuthTitle(
          title: tr('أهلًا تاني', 'Welcome back'),
          subtitle: tr('سجّل دخولك وكمّل شحن من أقرب محطة بونو.', 'Log in and keep charging from the nearest Buno station.'),
        ),
        const SizedBox(height: 33.7),
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
          hint: '••••••••',
          icon: BunoIcons.lock,
          controller: _password,
          obscure: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          errorText: _passwordError,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 1.6),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: BunoTextLink(
            tr('نسيت كلمة السر؟', 'Forgot password?'),
            style: BunoType.body.copyWith(fontSize: 13),
            onTap: () => showBunoToast(context, tr('هنبعتلك لينك تغيّر بيه كلمة السر', "We'll send you a link to change your password")),
          ),
        ),
        const SizedBox(height: 2),
        BunoPrimaryButton(label: tr('تسجيل الدخول', 'Log in'), loading: _busy, onPressed: _submit),
        const SizedBox(height: 22),
        const BunoOrDivider(),
        const SizedBox(height: 16),
        AppleSignInButton(
          label: _appleBusy ? tr('جاري الدخول…', 'Logging in…') : tr('الدخول بـ Apple', 'Continue with Apple'),
          onPressed: _appleBusy ? null : _apple,
        ),
      ],
    );
  }
}
