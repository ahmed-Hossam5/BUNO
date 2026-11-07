import 'package:flutter/material.dart';

import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_back_button.dart';
import '../../widgets/buno_logo.dart';

/// Shared frame of the auth screens (Brand Board pages 4–6): back button on
/// the trailing side, logo on the start side, scrollable content, and a
/// footer pinned to the bottom when there is room.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.children, this.footer, this.onBack});

  static const gutter = 24.0;

  final List<Widget> children;
  final Widget? footer;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 27),
                        child: _AuthHeader(onBack: onBack),
                      ),
                      ...children,
                      const Spacer(),
                      if (footer != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 16),
                          child: Center(child: footer),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({this.onBack});

  final VoidCallback? onBack;

  static const _logoHeight = 32.4;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final nudge = BunoLogo.inkEndInset * _logoHeight / 120;
    return SizedBox(
      height: BunoSize.touchMin,
      child: Row(
        children: [
          Transform.translate(
            offset: Offset(rtl ? nudge : -nudge, 0),
            child: const BunoLogo(height: _logoHeight),
          ),
          const Spacer(),
          // The 44pt target overhangs the 41pt circle; keep the circle on the gutter.
          Transform.translate(
            offset: Offset(rtl ? -1.5 : 1.5, 0),
            child: BunoBackButton(onPressed: onBack),
          ),
        ],
      ),
    );
  }
}

/// Screen title + one-line intro, start-aligned.
class AuthTitle extends StatelessWidget {
  const AuthTitle({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: BunoType.h1.copyWith(height: 1.3)),
        const SizedBox(height: 6),
        Text(subtitle, style: BunoType.body.copyWith(height: 1.4, color: BunoDark.text_secondary)),
      ],
    );
  }
}

/// "Question? <link>" footer line.
class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key, required this.question, required this.action});

  final String question;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(question, style: BunoType.body.copyWith(fontSize: 14, color: BunoDark.text_secondary)),
        const SizedBox(width: 4),
        action,
      ],
    );
  }
}

void showBunoToast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
}
