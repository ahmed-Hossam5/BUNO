import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_text.dart';
import '../auth/auth_scaffold.dart' show showBunoToast;
import 'account_scaffold.dart';
import '../../l10n/buno_locale.dart';

class _Faq {
  const _Faq(this.q, this.a);

  final String q;
  final String a;
}

/// Help (مساعدة, reference 23): searchable FAQ rows that expand, and
/// WhatsApp support as the primary action.
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  static List<_Faq> get _faqs => [
    _Faq(tr('الخانة مش بتفتح', "The bay won't open"), tr('اتأكد إن النت شغال وامسح الكود تاني. لو لسه قافلة، كلّمنا على واتساب وإحنا نفتحها من عندنا.', "Check that you're online and scan the code again. If it's still locked, message us on WhatsApp and we'll open it from our side.")),
    _Faq(tr('الباور بانك مش بيشحن', "The power bank isn't charging"), tr('جرّب كابل تاني من اللي فيه، ولو برضه مش بيشحن رجّعه لأقرب محطة وخد غيره من غير ما تدفع تاني.', "Try another of its cables. If it still won't charge, return it to the nearest station and take another one without paying again.")),
    _Faq(tr('اتحسب عليّا غلط', 'I was charged wrongly'), tr('افتح الإيصال من رحلاتي واضغط "في مشكلة"، وهنراجع المدة ونرجّعلك الفرق في المحفظة.', 'Open the receipt from My trips and tap "Report a problem". We\'ll check the time and refund the difference to your wallet.')),
    _Faq(tr('الشحن بتاعي لسه مجاش', "My top-up hasn't arrived"), tr('المراجعة بتاخد [المدة]. لو عدّت، ابعتلنا رقم العملية على واتساب.', 'Review takes [duration]. If that has passed, send us the transaction number on WhatsApp.')),
    _Faq(tr('أرجّع فين؟', 'Where do I return it?'), tr('في أي محطة بونو في الجامعة، مش لازم نفس المحطة اللي أخدت منها. شوف الخريطة لأقرب واحدة فاضية.', "At any Buno station on campus, not only the one you took it from. Check the map for the nearest one with a free bay.")),
    _Faq(tr('إزاي ألغي الاشتراك؟', 'How do I cancel my plan?'), tr('من الباقات اختار باقتك واضغط إلغاء. هتفضل شغالة لحد آخر الشهر.', 'In Plans, pick your plan and tap Cancel. It stays active until the end of the month.')),
  ];

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String _query = '';
  int? _open;

  @override
  Widget build(BuildContext context) {
    final q = _query.trim();
    final rows = [
      for (var i = 0; i < HelpScreen._faqs.length; i++)
        if (q.isEmpty || HelpScreen._faqs[i].q.contains(q) || HelpScreen._faqs[i].a.contains(q)) i,
    ];
    return AccountScaffold(
      title: tr('مساعدة', 'Help'),
      button: BunoPrimaryButton(
        label: tr('كلّمنا على واتساب', 'Message us on WhatsApp'),
        leading: const BunoLottieIcon(name: 'chat_typing', loop: true, color: BunoDark.on_primary),
        onPressed: () => showBunoToast(context, tr('بنفتح واتساب الدعم…', 'Opening support on WhatsApp…')),
      ),
      children: [
        _ShortcutsCard(rows: [
          _Shortcut(
            lottie: 'shield',
            label: tr('المحطة مليانة؟ علينا', 'Station full? On us'),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.guarantee),
          ),
          _Shortcut(
            lottie: 'gift',
            label: tr('إيجار الطوارئ', 'Emergency rental'),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.emergency),
          ),
        ]),
        const SizedBox(height: BunoSpace.s4),
        _SearchField(onChanged: (v) => setState(() => _query = v)),
        const SizedBox(height: BunoSpace.s3),
        for (final i in rows) ...[
          _FaqRow(
            faq: HelpScreen._faqs[i],
            open: _open == i,
            onTap: () => setState(() => _open = _open == i ? null : i),
          ),
          accountDivider,
        ],
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: BunoSpace.s6),
            child: Text(
              tr('مالقيناش سؤال زي ده، كلّمنا على واتساب.', "We couldn't find that question. Message us on WhatsApp."),
              textAlign: TextAlign.center,
              style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary),
            ),
          ),
      ],
    );
  }
}

/// Card of links to /guarantee and /emergency above the FAQ.
class _ShortcutsCard extends StatelessWidget {
  const _ShortcutsCard({required this.rows});

  final List<_Shortcut> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BunoDark.card,
        borderRadius: BorderRadius.circular(BunoRadius.lg),
        border: Border.all(color: BunoDark.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) accountDivider,
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.lottie, required this.label, required this.onTap});

  final String lottie;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s4, vertical: BunoSpace.s4),
          child: Row(
            children: [
              BunoLottieIcon(name: lottie, size: BunoSize.iconSm, color: BunoColors.primary),
              const SizedBox(width: BunoSpace.s3),
              Expanded(
                child: Text(label, style: BunoType.body.copyWith(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3)),
              ),
              BunoIcon(rtl ? BunoIcons.back : BunoIcons.forward, size: BunoSize.iconSm, color: BunoDark.text_disabled),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final style = BunoType.body.copyWith(height: 1.3);
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s4),
      decoration: BoxDecoration(
        color: BunoDark.card,
        borderRadius: BorderRadius.circular(BunoRadius.lg),
        border: Border.all(color: BunoDark.border),
      ),
      child: Row(
        children: [
          const BunoLottieIcon(name: 'search', size: BunoSize.iconSm, color: BunoDark.text_secondary),
          const SizedBox(width: BunoSpace.s3),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              cursorColor: BunoColors.primary,
              style: style,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration.collapsed(
                hintText: tr('دوّر في الأسئلة', 'Search questions'),
                hintStyle: style.copyWith(color: BunoDark.text_secondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqRow extends StatelessWidget {
  const _FaqRow({required this.faq, required this.open, required this.onTap});

  final _Faq faq;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    final duration = still ? Duration.zero : BunoMotion.base;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final answer = open
        ? Padding(
            padding: const EdgeInsetsDirectional.only(start: BunoSize.iconSm + BunoSpace.s3, top: BunoSpace.s2),
            child: BunoText(faq.a, style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary)),
          )
        : const SizedBox(width: double.infinity);
    return Semantics(
      button: true,
      expanded: open,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: BunoSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const BunoLottieIcon(name: 'help', size: BunoSize.iconSm, color: BunoDark.text_secondary),
                  const SizedBox(width: BunoSpace.s3),
                  Expanded(
                    child: Text(faq.q, style: BunoType.body.copyWith(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3)),
                  ),
                  AnimatedRotation(
                    turns: open ? (rtl ? -0.25 : 0.25) : 0,
                    duration: duration,
                    curve: BunoMotion.easing,
                    child: BunoIcon(
                      rtl ? BunoIcons.back : BunoIcons.forward,
                      size: BunoSize.iconSm,
                      color: BunoDark.text_disabled,
                    ),
                  ),
                ],
              ),
              // AnimatedSize can't run with a zero duration, so reduced
              // motion swaps the answer in directly.
              if (still)
                answer
              else
                AnimatedSize(
                  duration: BunoMotion.base,
                  curve: BunoMotion.easing,
                  alignment: AlignmentDirectional.topStart,
                  child: answer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
