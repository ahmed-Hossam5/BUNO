import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_rental.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_text.dart';
import 'active_rental_screen.dart' show spokenDuration;
import '../../l10n/buno_locale.dart';

/// /return/done (reference 11_done): the unit is back. The check plays once;
/// the button opens /receipt in place of this screen.
class ReturnDoneScreen extends StatelessWidget {
  const ReturnDoneScreen({super.key});

  static const _badge = 120.0;

  @override
  Widget build(BuildContext context) {
    final duration = rentalSession.duration;
    final durationText = duration == null ? tr('[المدة]', '[Duration]') : spokenDuration(duration, zero: tr('أقل من دقيقة', 'Under a minute'));
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: BunoSpace.s4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: _badge,
                            height: _badge,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: BunoColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [BunoElevation.glow],
                            ),
                            child: const BunoLottieIcon(
                              name: 'success',
                              size: _badge / 2,
                              color: BunoDark.on_primary,
                              playKey: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: BunoSpace.s6),
                        Text(tr('رجع مكانه', 'Returned'), textAlign: TextAlign.center, style: BunoType.h1),
                        const SizedBox(height: BunoSpace.s3),
                        Text(tr('[السعر]', '[Price]'), textAlign: TextAlign.center, style: BunoType.display),
                        BunoText(
                          tr('$durationText · من المحفظة', '$durationText · from wallet'),
                          textAlign: TextAlign.center,
                          style: BunoType.bodySm.copyWith(
                            color: BunoDark.text_secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              BunoPrimaryButton(
                label: tr('شوف الإيصال', 'See receipt'),
                onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.receipt),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
