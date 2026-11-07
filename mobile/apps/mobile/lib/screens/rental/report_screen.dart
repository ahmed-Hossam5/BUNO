import 'package:flutter/material.dart';

import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_title_bar.dart';
import '../../l10n/buno_locale.dart';

/// /report (reference 09_report): pick what went wrong, send, and go back
/// with a confirmation snackbar. Nothing is sent anywhere yet.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  static List<({String title, String detail, BunoIcons? icon, String? lottie})> get problems => [
    (
      title: tr('مش بيشحن', "Isn't charging"),
      detail: tr('متوصل بس النسبة مش بتزيد', "Plugged in but the percent isn't going up"),
      icon: BunoIcons.charging,
      lottie: null,
    ),
    (
      title: tr('سخن أو مكسور', 'Hot or broken'),
      detail: tr('متستخدموش وبلّغ فورًا', "Don't use it, report right away"),
      icon: null,
      lottie: 'temperature',
    ),
    (
      title: tr('ضاع مني', 'I lost it'),
      detail: tr('هنكلمك قبل أي رسوم', "We'll call you before any fee"),
      icon: null,
      lottie: 'search',
    ),
    (
      title: tr('المحطة مش بتستلم', "The station won't take it"),
      detail: tr('الخانة مش بتقفل أو مطفية', "The bay won't lock or is off"),
      icon: BunoIcons.lock,
      lottie: null,
    ),
  ];

  static String get sentMessage => tr('البلاغ وصل، هنكلمك قريب', "Report received, we'll call you soon");

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int? _selected;

  void _send() {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(ReportScreen.sentMessage),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
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
              BunoTitleBar(tr('فيه مشكلة؟', 'A problem?')),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: BunoSpace.s5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, p) in ReportScreen.problems.indexed) ...[
                        if (i > 0) const SizedBox(height: BunoSpace.s3),
                        _ProblemTile(
                          title: p.title,
                          detail: p.detail,
                          icon: p.icon,
                          lottie: p.lottie,
                          selected: i == _selected,
                          onTap: () => setState(() => _selected = i),
                        ),
                      ],
                      const SizedBox(height: BunoSpace.s4),
                      Row(
                        children: [
                          const BunoIcon(
                            BunoIcons.check,
                            size: BunoSize.iconSm,
                            color: BunoColors.primary,
                          ),
                          const SizedBox(width: BunoSpace.s2),
                          Expanded(
                            child: Text(
                              tr('العداد وقف من لحظة البلاغ.', 'The timer stopped when you reported.'),
                              style: BunoType.bodySm.copyWith(
                                color: BunoColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              BunoPrimaryButton(
                label: tr('ابعت البلاغ', 'Send report'),
                onPressed: _selected == null ? null : _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProblemTile extends StatelessWidget {
  const _ProblemTile({
    required this.title,
    required this.detail,
    required this.icon,
    required this.lottie,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String detail;
  final BunoIcons? icon;

  /// Animated icon name, used when [icon] is null.
  final String? lottie;
  final bool selected;
  final VoidCallback onTap;

  static const _badge = 44.0;

  @override
  Widget build(BuildContext context) {
    final colour = selected ? BunoColors.primary : BunoDark.text_primary;
    return BunoPressable(
      onTap: onTap,
      semanticLabel: selected ? tr('$title، مختار', '$title, selected') : title,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: MediaQuery.of(context).disableAnimations
              ? Duration.zero
              : BunoMotion.fast,
          padding: const EdgeInsets.all(BunoSpace.s4),
          decoration: BoxDecoration(
            color: BunoDark.card,
            borderRadius: BorderRadius.circular(BunoRadius.lg),
            border: Border.all(
              color: selected ? BunoColors.primary : BunoDark.card,
              width: BunoStroke.defaultWidth,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: BunoType.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      detail,
                      style: BunoType.caption.copyWith(
                        color: BunoDark.text_secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BunoSpace.s3),
              Container(
                width: _badge,
                height: _badge,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? BunoColors.primary_soft
                      : BunoDark.background,
                  borderRadius: BorderRadius.circular(BunoRadius.md),
                ),
                child: icon != null
                    ? BunoIcon(icon!, color: colour)
                    : BunoLottieIcon(
                        name: lottie!,
                        color: colour,
                        playKey: selected ? true : null,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
