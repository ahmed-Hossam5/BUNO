import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_settings.dart';
import '../../data/mock_sos.dart';
import '../../data/phone_battery.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_back_button.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_charge_ring.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/buno_text_link.dart';
import 'sos_avatar.dart';
import '../../l10n/buno_locale.dart';

/// Opens «إلحقني»: /sos/got once a friend has paid, else /sos.
void openSos(BuildContext context) => Navigator.of(context)
    .pushNamed(sosSession.state == SosState.paid ? AppRoutes.sosGot : AppRoutes.sos);

/// /sos (reference 50): the phone's charge, three friends (the first
/// pre-selected) and "ابعت ل`name`". Once sent it waits for the answer
/// with the sos animation; cancelling gives today's request back.
class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  /// How long the send icon plays before the screen turns to waiting.
  static const sendDelay = Duration(milliseconds: 600);

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  SosFriend _friend = mockSosFriends.first;

  /// Plays the send icon once per tap; null until the first one.
  Object? _sendKey;
  bool get _sending => _sendKey != null;

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sendKey = Object());
    final still = MediaQuery.of(context).disableAnimations || MockSettings.reduceMotion.value;
    if (!still) await Future<void>.delayed(SosScreen.sendDelay);
    if (!mounted) return;
    sosSession.send(_friend);
    setState(() => _sendKey = null);
  }

  void _whatsApp() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(tr('الإرسال على واتساب هيكون جاهز قريب', 'Sending on WhatsApp is coming soon')),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ));
  }

  void _simulatePaid() {
    sosSession.markPaid();
    Navigator.of(context).pushReplacementNamed(AppRoutes.sosGot);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: ListenableBuilder(
            listenable: Listenable.merge([sosSession, PhoneBattery.shared]),
            builder: (context, _) {
              final waiting = sosSession.state == SosState.waiting;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(tr('إلحقني', 'Help me out'), style: BunoType.title),
                      const Align(alignment: AlignmentDirectional.centerEnd, child: BunoBackButton()),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: BunoSpace.s6),
                      child: waiting ? _Waiting(friend: sosSession.friend!) : _ask(),
                    ),
                  ),
                  if (waiting) ...[
                    BunoTextLink(tr('إلغي الطلب', 'Cancel request'), onTap: sosSession.cancel),
                    if (kDebugMode)
                      BunoTextLink(tr('تجربة: صاحبك دفع', 'Test: friend paid'), onTap: _simulatePaid, color: BunoColors.info),
                  ] else ...[
                    BunoPrimaryButton(
                      label: tr('ابعت ل${_friend.name}', 'Send to ${_friend.name}'),
                      leading: BunoLottieIcon(name: 'send', playKey: _sendKey, color: BunoDark.on_primary),
                      onPressed: sosSession.canSendToday ? _send : null,
                    ),
                    const SizedBox(height: BunoSpace.s2),
                    BunoTextLink(tr('أو ابعت لينك على واتساب', 'Or send a link on WhatsApp'), onTap: _whatsApp),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _ask() {
    final percent = PhoneBattery.shared.reading.percent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Semantics(
            label: percent == null ? tr('بطارية موبايلك مش معروفة', "Your phone's battery is unknown") : tr('بطارية موبايلك $percent%', "Your phone's battery is $percent%"),
            excludeSemantics: true,
            child: BunoChargeRing(
              progress: (percent ?? 0) / 100,
              size: 112,
              strokeWidth: 8,
              color: BunoColors.error,
              child: BunoText(
                percent == null ? '--%' : '$percent%',
                style: BunoType.h2.copyWith(color: BunoColors.error),
              ),
            ),
          ),
        ),
        const SizedBox(height: BunoSpace.s5),
        BunoText(tr('ابعت لصاحب يلحقك', 'Ask a friend to help you out'), textAlign: TextAlign.center, style: BunoType.h2),
        const SizedBox(height: BunoSpace.s1),
        BunoText(
          sosSession.canSendToday
              ? tr('هيدفعلك بونو من محفظته، والخانة هتفتحلك انت.', "They'll pay for a Buno from their wallet, and the bay opens for you.")
              : tr('طلبت إلحقني النهارده خلاص. تقدر تطلب تاني بكرة.', 'You already asked for help today. You can ask again tomorrow.'),
          textAlign: TextAlign.center,
          style: BunoType.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            color: sosSession.canSendToday ? BunoDark.text_secondary : BunoColors.warning,
          ),
        ),
        const SizedBox(height: BunoSpace.s4),
        for (final (i, f) in mockSosFriends.indexed)
          _FriendRow(
            friend: f,
            selected: f == _friend,
            divider: i < mockSosFriends.length - 1,
            onTap: _sending ? null : () => setState(() => _friend = f),
          ),
      ],
    );
  }
}

/// One friend: avatar, name, note, and the selection circle at the end.
class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.friend, required this.selected, required this.divider, required this.onTap});

  final SosFriend friend;
  final bool selected;
  final bool divider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: BunoPressable(
        onTap: onTap,
        semanticLabel: tr('${friend.name}، ${friend.note}', '${friend.name}, ${friend.note}'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: BunoSpace.s3),
          decoration: BoxDecoration(
            border: divider ? const Border(bottom: BorderSide(color: BunoDark.divider)) : null,
          ),
          child: Row(
            children: [
              SosAvatar(friend.initial, size: 48),
              const SizedBox(width: BunoSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BunoText(friend.name, maxLines: 1, style: BunoType.title.copyWith(fontWeight: FontWeight.w700)),
                    BunoText(
                      friend.note,
                      maxLines: 1,
                      style: BunoType.caption.copyWith(color: BunoDark.text_secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BunoSpace.s3),
              AnimatedContainer(
                duration: MediaQuery.of(context).disableAnimations ? Duration.zero : BunoMotion.fast,
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? BunoColors.primary : null,
                  border: selected ? null : Border.all(color: BunoDark.border, width: 2),
                ),
                child: selected
                    ? const Center(child: BunoIcon(BunoIcons.check, size: BunoSize.iconSm, color: BunoDark.on_primary))
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sent, waiting for [friend] to answer.
class _Waiting extends StatelessWidget {
  const _Waiting({required this.friend});

  final SosFriend friend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: BunoSpace.s8),
        const BunoLottieIcon(name: 'sos', size: 120, loop: true, color: BunoColors.error),
        const SizedBox(height: BunoSpace.s6),
        BunoText(tr('مستني ${friend.name} يرد', 'Waiting for ${friend.name} to answer'), textAlign: TextAlign.center, style: BunoType.h2),
        const SizedBox(height: BunoSpace.s1),
        BunoText(
          tr('بعتناله الطلب. أول ما يدفع هيوصلك إشعار وتروح تاخد.', "We sent the request. As soon as they pay, you'll be notified and can go take it."),
          textAlign: TextAlign.center,
          style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary),
        ),
      ],
    );
  }
}
