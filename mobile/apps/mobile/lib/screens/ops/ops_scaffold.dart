import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_ops.dart';
import '../../l10n/buno_locale.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_back_button.dart';
import '../../widgets/buno_bottom_nav.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text.dart';

/// Gutter of every ops screen (same as the user tabs).
const opsGutter = 24.0;

/// Bottom-nav items of operations mode, in [AppRoutes.opsTabs] order.
List<BunoNavItem> get opsNavItems => [
      BunoNavItem(icon: BunoIcons.home, label: tr('اليوم', 'Today')),
      BunoNavItem(icon: BunoIcons.check, label: tr('المهام', 'Tasks')),
      BunoNavItem(icon: BunoIcons.location, label: tr('المحطات', 'Stations')),
      BunoNavItem(icon: BunoIcons.notifications, label: tr('البلاغات', 'Reports')),
    ];

/// Arrow pointing toward the end side (left in Arabic, right in English).
BunoIcons opsEndArrow(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl ? BunoIcons.back : BunoIcons.forward;

/// The amber "تشغيل" pill that marks every ops header. With [onTap] it is a
/// button (the tab screens use it to leave ops mode).
class OpsPill extends StatelessWidget {
  const OpsPill({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: BunoColors.warning,
        borderRadius: BorderRadius.circular(BunoRadius.pill),
      ),
      child: Text(
        tr('تشغيل', 'Ops'),
        style: BunoType.caption.copyWith(height: 1.2, fontWeight: FontWeight.w700, color: BunoDark.on_primary),
      ),
    );
    if (onTap == null) return pill;
    return BunoPressable(
      onTap: onTap,
      semanticLabel: tr('وضع التشغيل، اضغط للخروج', 'Ops mode, tap to leave'),
      child: SizedBox(height: BunoSize.touchMin, child: Center(child: pill)),
    );
  }
}

/// Asks, then leaves ops mode for the app's home.
Future<void> confirmLeaveOps(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: BunoDark.elevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BunoRadius.xl)),
      title: Text(tr('تخرج من وضع التشغيل؟', 'Leave ops mode?'), style: BunoType.title),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(tr('لأ', 'No'), style: BunoType.body.copyWith(color: BunoDark.text_primary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(tr('اخرج', 'Leave'), style: BunoType.body.copyWith(fontWeight: FontWeight.w700, color: BunoColors.primary)),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) AppRoutes.leaveOps(context);
}

/// Title, a grey line under it, and [trailing] (the ops pill) at the end.
class _OpsHeader extends StatelessWidget {
  const _OpsHeader({required this.title, required this.subtitle, required this.trailing, this.back = false, this.titleSize = 22});

  final String title;
  final Widget subtitle;
  final Widget trailing;
  final bool back;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (back) ...[const BunoBackButton(), const SizedBox(width: BunoSpace.s3)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BunoText(title, maxLines: 1, style: BunoType.h1.copyWith(fontSize: titleSize, height: 1.3)),
              DefaultTextStyle.merge(
                style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary),
                child: subtitle,
              ),
            ],
          ),
        ),
        const SizedBox(width: BunoSpace.s2),
        trailing,
      ],
    );
  }
}

/// Grey one-line subtitle, numbers in Sora.
class OpsSubtitle extends StatelessWidget {
  const OpsSubtitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      BunoText(text, maxLines: 1, style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary));
}

/// Tab screen of operations mode: header ([title], [subtitle], pill that
/// leaves ops mode), then [children] in a list, with the ops bottom nav.
/// Rebuilds on [MockOps.changes].
class OpsTabScaffold extends StatelessWidget {
  const OpsTabScaffold({
    super.key,
    required this.navIndex,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final int navIndex;
  final String title;
  final String Function() subtitle;
  final List<Widget> Function(BuildContext context) children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BunoDark.background,
      bottomNavigationBar: BunoBottomNav(
        items: opsNavItems,
        currentIndex: navIndex,
        onSelected: (i) => AppRoutes.goToOpsTab(context, i, navIndex),
      ),
      body: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<int>(
          valueListenable: MockOps.changes,
          builder: (context, _, _) => ListView(
            padding: const EdgeInsets.fromLTRB(opsGutter, 21, opsGutter, BunoSpace.s6),
            children: [
              _OpsHeader(
                title: title,
                subtitle: OpsSubtitle(subtitle()),
                trailing: OpsPill(onTap: () => confirmLeaveOps(context)),
              ),
              const SizedBox(height: BunoSpace.s5),
              ...children(context),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sub-screen of operations mode: back button, [title] and [subtitle],
/// the ops pill; scrolling [children] and an optional [bottom]. Rebuilds
/// on [MockOps.changes] and [listenTo].
class OpsSubScaffold extends StatelessWidget {
  const OpsSubScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.bottom,
    this.listenTo,
  });

  final String Function() title;
  final Widget Function() subtitle;
  final List<Widget> Function(BuildContext context) children;
  final Widget Function(BuildContext context)? bottom;
  final Listenable? listenTo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([MockOps.changes, ?listenTo]),
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(opsGutter, BunoSpace.s3, opsGutter, 0),
                child: _OpsHeader(title: title(), subtitle: subtitle(), trailing: const OpsPill(), back: true, titleSize: 20),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(opsGutter, BunoSpace.s5, opsGutter, BunoSpace.s5),
                  children: children(context),
                ),
              ),
              if (bottom != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(opsGutter, 0, opsGutter, BunoSpace.s4),
                  child: bottom!(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded card used across the ops screens.
class OpsCard extends StatelessWidget {
  const OpsCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor = BunoDark.border,
    this.color = BunoDark.card,
    this.semanticLabel,
    this.padding = const EdgeInsets.all(BunoSpace.s4),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color borderColor;
  final Color color;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(BunoRadius.lg),
        border: Border.all(color: borderColor, width: BunoStroke.hairline),
      ),
      child: child,
    );
    return onTap == null ? card : BunoPressable(onTap: onTap, semanticLabel: semanticLabel, child: card);
  }
}

/// Colour of a station status.
Color opsStatusColor(OpsStationStatus s) => switch (s) {
      OpsStationStatus.offline => BunoDark.text_secondary,
      OpsStationStatus.empty => BunoColors.error,
      OpsStationStatus.full => BunoColors.warning,
      OpsStationStatus.ok => BunoColors.success,
    };

/// Colour of a task type.
Color opsTaskColor(OpsTaskType t) => switch (t) {
      OpsTaskType.safety => BunoColors.error,
      OpsTaskType.transfer => BunoColors.info,
      OpsTaskType.maintenance || OpsTaskType.late => BunoColors.warning,
      OpsTaskType.wallet => BunoColors.success,
    };
