import 'package:flutter/material.dart';

import '../../data/mock_rental.dart';
import '../../data/mock_settings.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_text.dart';
import 'account_scaffold.dart';
import '../../l10n/buno_locale.dart';

/// Notifications (reference 20). Mock list, after one notice per late-return
/// stage the current rental has reached (newest first); tapping a row marks
/// it read.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _read = <int>{};

  static const _tints = {
    'clock': BunoColors.warning,
    'warning': BunoColors.error,
    'battery_low': BunoColors.primary,
    'heart': BunoColors.secondary,
  };

  late final List<BunoNotification> _notifications = [
    for (final stage in rentalSession.lateStagesReached.reversed) lateNotification(stage, rentalSession.startedAt!),
    ...mockNotifications,
  ];

  @override
  Widget build(BuildContext context) {
    return AccountScaffold(
      title: tr('الإشعارات', 'Notifications'),
      titleIcon: const BunoLottieIcon(name: 'bell', playKey: true, color: BunoDark.text_primary),
      children: [
        for (var i = 0; i < _notifications.length; i++) ...[
          if (i > 0) accountDivider,
          _NotificationRow(
            n: _notifications[i],
            tint: _tints[_notifications[i].lottie] ?? BunoColors.secondary,
            unread: _notifications[i].unread && !_read.contains(i),
            onTap: () => setState(() => _read.add(i)),
          ),
        ],
        accountDivider,
      ],
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.n, required this.tint, required this.unread, required this.onTap});

  final BunoNotification n;
  final Color tint;
  final bool unread;
  final VoidCallback onTap;

  static const _dot = 8.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: unread ? tr('غير مقروء', 'Unread') : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: BunoSpace.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: BunoSize.touchMin,
                height: BunoSize.touchMin,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BunoDark.card,
                  borderRadius: BorderRadius.circular(BunoRadius.md),
                  border: Border.all(color: BunoDark.border),
                ),
                child: BunoLottieIcon(name: n.lottie, size: BunoSize.iconSm, playKey: unread, color: tint),
              ),
              const SizedBox(width: BunoSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BunoText(n.title,
                        maxLines: 1,
                        style: BunoType.title.copyWith(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3)),
                    BunoText(n.body,
                        maxLines: 2,
                        style: BunoType.bodySm.copyWith(height: 1.4, color: BunoDark.text_secondary)),
                  ],
                ),
              ),
              const SizedBox(width: BunoSpace.s2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  BunoText(n.time, style: BunoType.caption.copyWith(color: BunoDark.text_secondary)),
                  const SizedBox(height: BunoSpace.s2),
                  Container(
                    width: _dot,
                    height: _dot,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: unread ? BunoColors.primary : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Notice for a late-return [stage] (references 44–47), timed from the
/// rental's [startedAt].
BunoNotification lateNotification(LateStage stage, DateTime startedAt) {
  final at = startedAt.add(stage.at);
  final time = '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
  return switch (stage) {
    LateStage.reminder => BunoNotification(
        lottie: 'clock', title: tr('البونو لسه معاك', 'You still have the Buno'), body: tr('لو موبايلك اتشحن، رجّعه ووقّف العدّاد', 'If your phone is charged, return it and stop the timer'), time: time, unread: true),
    LateStage.warning => BunoNotification(
        lottie: 'clock', title: tr('فاضل نص ساعة', 'Half an hour left'), body: tr('بعدها تتحسب رسوم عدم الإرجاع', 'After that, the non-return fee applies'), time: time, unread: true),
    LateStage.lastChance => BunoNotification(
        lottie: 'warning', title: tr('آخر فرصة للإرجاع', 'Last chance to return'), body: tr('فاضل 6 دقايق قبل رسوم عدم الإرجاع', '6 minutes left before the non-return fee'), time: time, unread: true),
    LateStage.kept => BunoNotification(
        lottie: 'receipt', title: tr('الوحدة بقت بتاعتك', 'The unit is yours now'), body: tr('اتخصم [المبلغ] من رصيد المحفظة', '[Amount] was taken from your wallet'), time: time, unread: true),
  };
}
