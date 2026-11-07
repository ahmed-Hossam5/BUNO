import 'package:flutter/material.dart';

import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import '../widgets/buno_back_button.dart';
import '../widgets/buno_text.dart';
import '../l10n/buno_locale.dart';

/// Stand-in for a route whose screen isn't built yet (/topup, /unlocking).
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, this.detail});

  final String title;

  /// Optional line under the title, e.g. the amount passed to /topup.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Align(
                alignment: AlignmentDirectional.centerEnd,
                child: BunoBackButton(),
              ),
              const SizedBox(height: BunoSpace.s4),
              Text(title, style: BunoType.h1),
              if (detail != null) ...[
                const SizedBox(height: BunoSpace.s1),
                BunoText(
                  detail!,
                  style: BunoType.title.copyWith(color: BunoColors.primary),
                ),
              ],
              const SizedBox(height: BunoSpace.s3),
              Text(
                tr('الشاشة دي هتكون جاهزة في الخطوة الجاية.', 'This screen will be ready in the next step.'),
                style: BunoType.body.copyWith(color: BunoDark.text_secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
