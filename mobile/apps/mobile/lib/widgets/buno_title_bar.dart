import 'package:flutter/widgets.dart';

import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import 'buno_back_button.dart';

/// Sub-screen header: [title] centred, back button at the end (as on
/// /release). An optional [icon] sits before the title.
class BunoTitleBar extends StatelessWidget {
  const BunoTitleBar(this.title, {super.key, this.icon});

  final String title;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Align(alignment: AlignmentDirectional.centerEnd, child: BunoBackButton()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BunoSize.buttonLg),
          child: icon == null
              ? Text(title, textAlign: TextAlign.center, maxLines: 1, style: BunoType.title)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon!,
                    const SizedBox(width: BunoSpace.s2),
                    Flexible(child: Text(title, maxLines: 1, style: BunoType.title)),
                  ],
                ),
        ),
      ],
    );
  }
}
