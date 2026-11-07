import 'package:flutter/widgets.dart';

import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import 'buno_icon.dart';
import 'buno_lottie_icon.dart';

class BunoNavItem {
  const BunoNavItem({required this.icon, required this.label});

  final BunoIcons icon;
  final String label;
}

/// Bottom navigation (components.md): 72 high, up to 4 items, icon 22 +
/// label, active item in `--color-primary`, 1px top border, safe-area
/// padding added below.
class BunoBottomNav extends StatelessWidget {
  const BunoBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<BunoNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: BunoDark.background,
        border: Border(
          top: BorderSide(color: BunoDark.border, width: BunoStroke.hairline),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: BunoSize.bottomNav,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final BunoNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? BunoColors.primary : BunoDark.text_secondary;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NavIcon(icon: item.icon, selected: selected, color: color),
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: BunoMotion.fast,
              style: BunoType.caption.copyWith(
                fontSize: 11,
                height: 1.2,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated assets in assets/lottie/ for the tab icons that have one.
const _navLottie = {
  BunoIcons.home: 'nav_home',
  BunoIcons.history: 'clock',
  BunoIcons.location: 'nav_map',
  BunoIcons.wallet: 'nav_wallet',
  BunoIcons.profile: 'nav_user',
};

/// Static [BunoIcon] while unselected, its Lottie animation while selected.
///
/// The Lottie icon stays mounted (hidden, tickers off) while the tab is
/// unselected and gets a playKey only while selected, so it plays once when
/// the tab becomes selected, and also when a nav is first built with the tab
/// already selected (each screen builds its own nav).
class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.selected,
    required this.color,
  });

  final BunoIcons icon;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final lottie = _navLottie[icon];
    if (lottie == null) return BunoIcon(icon, color: color);
    return SizedBox.square(
      dimension: BunoSize.iconMd,
      child: Stack(
        children: [
          Visibility(
            visible: selected,
            maintainState: true,
            child: BunoLottieIcon(
              name: lottie,
              playKey: selected ? true : null,
            ),
          ),
          if (!selected) BunoIcon(icon, color: color),
        ],
      ),
    );
  }
}
