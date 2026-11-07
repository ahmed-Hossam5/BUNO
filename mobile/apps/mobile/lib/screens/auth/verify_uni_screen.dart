import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_first_run.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_text_field.dart' show BunoTextField;
import '../../widgets/buno_text_link.dart';
import '../../widgets/buno_title_bar.dart';
import 'auth_scaffold.dart' show showBunoToast;
import '../../l10n/buno_locale.dart';

/// /verify-uni (reference 37_uni_verify), the last sign-up step and
/// optional: a `.edu.eg` e-mail gets the student tier. "ابعت لينك التأكيد"
/// keeps it in [MockFirstRun.uniEmail] (no mail is sent) and enters the app;
/// "مش طالب؟ تخطّى" enters without one.
class VerifyUniScreen extends StatefulWidget {
  const VerifyUniScreen({super.key});

  @override
  State<VerifyUniScreen> createState() => _VerifyUniScreenState();
}

class _VerifyUniScreenState extends State<VerifyUniScreen> {
  final _email = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _send() {
    final email = _email.text.trim();
    if (!isUniEmail(email)) {
      setState(() => _error = tr('اكتب إيميل الجامعة اللي آخره ‎.edu.eg', 'Enter your university email ending in .edu.eg'));
      return;
    }
    MockFirstRun.uniEmail = email;
    showBunoToast(context, tr('بعتنالك لينك التأكيد', 'We sent you the confirmation link'));
    AppRoutes.enterApp(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BunoTitleBar(''),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: BunoSpace.s5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(tr('إيميل الجامعة', 'University email'), style: BunoType.h1),
                      const SizedBox(height: BunoSpace.s1),
                      Text(
                        tr('الطلبة بياخدوا مستوى «طالب» وخصومات الباقات.', 'Students get the “Student” level and plan discounts.'),
                        style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: BunoSpace.s6),
                      BunoTextField(
                        label: tr('الإيميل', 'Email'),
                        hint: 'name@[uni].edu.eg',
                        icon: BunoIcons.mail,
                        controller: _email,
                        ltrContent: true,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.send,
                        autofillHints: const [AutofillHints.email],
                        errorText: _error,
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                        onSubmitted: (_) => _send(),
                      ),
                      const SizedBox(height: BunoSpace.s3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BunoIcon(BunoIcons.privacy, size: BunoSize.iconSm, color: BunoDark.text_secondary),
                          const SizedBox(width: BunoSpace.s2),
                          Expanded(
                            child: Text(
                              tr('هنبعت لينك تأكيد. مش هنبعت أي إعلانات على الإيميل ده.', "We'll send a confirmation link. We won't send any ads to this email."),
                              style: BunoType.caption.copyWith(color: BunoDark.text_secondary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              BunoPrimaryButton(label: tr('ابعت لينك التأكيد', 'Send confirmation link'), onPressed: _send),
              const SizedBox(height: BunoSpace.s2),
              BunoTextLink(tr('مش طالب؟ تخطّى', 'Not a student? Skip'), onTap: () => AppRoutes.enterApp(context)),
            ],
          ),
        ),
      ),
    );
  }
}
