import 'package:flutter/material.dart';

import '../../theme/buno_tokens.dart';
import '../../widgets/buno_back_button.dart';
import '../../widgets/buno_logo.dart';

/// Frame of /guarantee and /emergency (references 62, 63): the logo at the
/// start, [trailing] and the back button at the end, scrolling [children],
/// and [buttons] pinned to the bottom (one primary, one secondary).
class SupportScaffold extends StatelessWidget {
  const SupportScaffold({super.key, required this.children, required this.buttons, this.trailing});

  final List<Widget> children;
  final List<Widget> buttons;
  final Widget? trailing;

  static const gutter = 24.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(gutter, BunoSpace.s4, gutter, 0),
              child: Row(
                children: [
                  const BunoLogo(height: 24, glow: false),
                  const Spacer(),
                  if (trailing != null) ...[trailing!, const SizedBox(width: BunoSpace.s2)],
                  const BunoBackButton(),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(gutter, BunoSpace.s5, gutter, BunoSpace.s6),
                children: children,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(gutter, 0, gutter, BunoSpace.s4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < buttons.length; i++) ...[
                    if (i > 0) const SizedBox(height: BunoSpace.s3),
                    buttons[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
