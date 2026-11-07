import 'package:flutter/material.dart';

import '../../data/mock_settings.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text_field.dart';
import '../auth/auth_scaffold.dart' show showBunoToast;
import 'account_scaffold.dart';
import '../../l10n/buno_locale.dart';

/// Edit profile (بياناتي, reference 22). Save writes [MockProfile], shows a
/// snackbar and pops back.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _name = TextEditingController(text: MockProfile.name);
  late final _phone = TextEditingController(text: MockProfile.phone);
  late final _email = TextEditingController(text: MockProfile.email);

  static const _avatar = 96.0;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() {
    MockProfile.name = _name.text.trim();
    MockProfile.phone = _phone.text.trim();
    MockProfile.email = _email.text.trim();
    showBunoToast(context, tr('اتحفظت بياناتك', 'Your details are saved'));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final initial = _name.text.trim().replaceAll('[', '');
    return AccountScaffold(
      title: tr('بياناتي', 'My details'),
      button: BunoPrimaryButton(label: tr('حفظ', 'Save'), onPressed: _save),
      children: [
        Center(
          child: Container(
            width: _avatar,
            height: _avatar,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: BunoDark.card),
            child: Text(
              initial.isEmpty ? tr('م', 'M') : initial.characters.first,
              style: BunoType.display.copyWith(color: BunoColors.primary, height: 1.2),
            ),
          ),
        ),
        const SizedBox(height: BunoSpace.s2),
        Center(
          child: BunoPressable(
            onTap: () => showBunoToast(context, tr('تغيير الصورة هييجي قريب', 'Changing the photo is coming soon')),
            semanticLabel: tr('غير الصورة', 'Change photo'),
            child: Padding(
              padding: const EdgeInsets.all(BunoSpace.s1),
              child: Text(tr('غير الصورة', 'Change photo'),
                  style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w700, color: BunoColors.primary)),
            ),
          ),
        ),
        const SizedBox(height: BunoSpace.s5),
        BunoTextField(
          label: tr('الاسم', 'Name'),
          hint: tr('[اسم المستخدم]', '[User name]'),
          icon: BunoIcons.profile,
          controller: _name,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: BunoSpace.s4),
        BunoTextField(
          label: tr('الموبايل', 'Phone'),
          hint: '+20 1X XXXX XXXX',
          controller: _phone,
          ltrContent: true,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: BunoSpace.s4),
        BunoTextField(
          label: tr('إيميل الجامعة', 'University email'),
          hint: 'name@[uni].edu.eg',
          icon: BunoIcons.mail,
          controller: _email,
          ltrContent: true,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}
