import 'package:flutter/material.dart';

import '../../theme/buno_tokens.dart';
import '../../widgets/buno_title_bar.dart';

/// Shared frame of the account sub-screens (/notifications, /settings, …):
/// title bar, scrolling [children], and an optional [button] pinned to the
/// bottom (the screen's one primary action).
class AccountScaffold extends StatelessWidget {
  const AccountScaffold({
    super.key,
    required this.title,
    required this.children,
    this.titleIcon,
    this.button,
  });

  final String title;
  final Widget? titleIcon;
  final List<Widget> children;
  final Widget? button;

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
              child: BunoTitleBar(title, icon: titleIcon),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(gutter, BunoSpace.s5, gutter, BunoSpace.s6),
                children: children,
              ),
            ),
            if (button != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(gutter, 0, gutter, BunoSpace.s4),
                child: button,
              ),
          ],
        ),
      ),
    );
  }
}

/// Row divider used in the account lists.
const accountDivider = Divider(height: 1, thickness: 1, color: BunoDark.divider);
