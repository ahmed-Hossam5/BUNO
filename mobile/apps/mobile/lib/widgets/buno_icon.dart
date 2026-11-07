import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/buno_tokens_ext.dart';

/// The Buno UI icons shipped in buno-design-system/icons (24x24 grid,
/// 2px stroke, `currentColor`). Only the ones used on this screen are bundled.
enum BunoIcons {
  profile('profile'),
  battery('battery'),
  batteryLow('battery-low'),
  batteryFull('battery-full'),
  charging('charging'),
  location('location'),
  scan('scan'),
  home('home'),
  history('history'),
  wallet('wallet'),
  close('close'),
  warning('warning'),
  receipt('receipt'),
  mail('mail'),
  lock('lock'),
  back('back'),
  forward('forward'),
  check('check'),
  plus('plus'),
  creditCard('credit-card'),
  edit('edit'),
  logout('logout'),
  language('language'),
  help('help'),
  terms('terms'),
  privacy('privacy'),
  notifications('notifications'),
  powerBank('power-bank'),
  search('search'),
  locate('locate'),
  walk('walk');

  const BunoIcons(this.fileName);
  final String fileName;

  String get asset => 'assets/icons/icon-$fileName.svg';
}

/// Renders a supplied Buno SVG icon at one of the three allowed sizes.
class BunoIcon extends StatelessWidget {
  const BunoIcon(
    this.icon, {
    super.key,
    required this.color,
    this.size = BunoSize.iconMd,
  }) : assert(
          size == BunoSize.iconSm ||
              size == BunoSize.iconMd ||
              size == BunoSize.iconLg,
          'Allowed visible icon sizes are 18 / 22 / 28',
        );

  final BunoIcons icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      icon.asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
