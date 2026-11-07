import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../data/mock_rental.dart';
import '../../l10n/buno_locale.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_bay_tile.dart' show chargeColor;
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_charge_ring.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/map_markers.dart';

/// Home's bottom sheet: [base] always shows; dragging up (or tapping the
/// handle) reveals [extra] above the map, up to [maxExtra] high.
class HomeSheet extends StatefulWidget {
  const HomeSheet({
    super.key,
    required this.base,
    required this.extra,
    required this.maxExtra,
    required this.onBaseHeight,
    this.tint,
    this.startExpanded = false,
  });

  final Widget base;
  final Widget extra;
  final double maxExtra;

  /// Reports the collapsed sheet's height after layout, so the map can keep
  /// the ring above it.
  final ValueChanged<double> onBaseHeight;

  /// Colour mixed into the sheet (red while the phone is low).
  final Color? tint;
  final bool startExpanded;

  @override
  State<HomeSheet> createState() => _HomeSheetState();
}

class _HomeSheetState extends State<HomeSheet> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: BunoMotion.slow, value: widget.startExpanded ? 1 : 0);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _settle(bool open) {
    final target = open ? 1.0 : 0.0;
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = target;
    } else {
      _c.animateTo(target, curve: BunoMotion.easing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tint = widget.tint;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (d) => _c.value -= (d.primaryDelta ?? 0) / math.max(widget.maxExtra, 1),
      onVerticalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        _settle(v.abs() > 300 ? v < 0 : _c.value > 0.5);
      },
      child: Container(
        decoration: BoxDecoration(
          color: tint == null ? BunoDark.card : Color.alphaBlend(tint.withValues(alpha: 0.07), BunoDark.card),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(BunoRadius.xxl)),
          border: Border(
            top: BorderSide(color: tint == null ? BunoDark.border : tint.withValues(alpha: 0.35)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SizeReporter(
              onSize: (s) => widget.onBaseHeight(s.height + 1),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(BunoSpace.s5, BunoSpace.s1, BunoSpace.s5, BunoSpace.s4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) => Semantics(
                        button: true,
                        label: _c.value > 0.5 ? tr('اقفل', 'Collapse') : tr('افتح باقي المحطات', 'Show more stations'),
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _settle(_c.value < 0.5),
                          child: SizedBox(
                            height: 24,
                            child: Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: BunoDark.text_disabled,
                                  borderRadius: BorderRadius.circular(BunoRadius.pill),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    widget.base,
                  ],
                ),
              ),
            ),
            if (widget.maxExtra > 0)
              SizeTransition(
                sizeFactor: _c,
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: widget.maxExtra),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(BunoSpace.s5, 0, BunoSpace.s5, BunoSpace.s4),
                    child: widget.extra,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Calls [onSize] after a frame whenever its child's size changes.
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, required super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(BuildContext context, _RenderSizeReporter renderObject) => renderObject.onSize = onSize;
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _last) return;
    final s = _last = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onSize(s));
  }
}

/// Nearest station (reference 99): name, walk and ready count, its best
/// charge and bays; the main button (reserve when low or a bay is held,
/// else scan); shortcut chips.
class HomeStationBody extends StatelessWidget {
  const HomeStationBody({
    super.key,
    required this.station,
    required this.reserve,
    required this.askFriend,
    required this.onScan,
    required this.onReserve,
    required this.onAskFriend,
    required this.onAll,
    required this.onFavorites,
    required this.onReturnSpace,
    this.nearest = true,
  });

  final Station station;
  final bool reserve;

  /// False when the user picked [station] (search, map): no "أقرب محطة".
  final bool nearest;

  /// Swaps "فيها مكان للإرجاع" for "اطلب من صاحبك" (reference 100).
  final bool askFriend;
  final VoidCallback onScan;
  final VoidCallback onReserve;
  final VoidCallback onAskFriend;
  final VoidCallback onAll;
  final VoidCallback onFavorites;
  final VoidCallback onReturnSpace;

  @override
  Widget build(BuildContext context) {
    final best = station.bestCharge ?? station.topCharge;
    final secondary = BunoType.bodySm.copyWith(color: BunoDark.text_secondary);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BunoText(nearest ? tr('أقرب محطة', 'Nearest station') : tr('المحطة اللي اخترتها', 'Selected station'), style: BunoType.caption.copyWith(color: BunoDark.text_secondary)),
                  BunoText(station.name, maxLines: 1, style: BunoType.h3.copyWith(fontWeight: FontWeight.w700)),
                  Row(
                    children: [
                      const BunoIcon(BunoIcons.walk, size: BunoSize.iconSm, color: BunoDark.text_secondary),
                      const SizedBox(width: BunoSpace.s1),
                      Flexible(
                        child: BunoText(
                          tr('${station.walkMinutes} د مشي · ${station.readyCount} جاهزين',
                              '${station.walkMinutes} min walk · ${station.readyCount} ready'),
                          style: secondary,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: BunoSpace.s3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                BunoText(best == null ? '--%' : '$best%', style: BunoType.h1.copyWith(color: chargeColor(best))),
                const SizedBox(height: BunoSpace.s1),
                BayBars(bays: station.bays),
              ],
            ),
          ],
        ),
        const SizedBox(height: BunoSpace.s4),
        if (reserve)
          BunoPrimaryButton(label: tr('احجزلي وودّيني', 'Reserve and take me'), icon: BunoIcons.location, onPressed: onReserve)
        else
          BunoPrimaryButton(
            label: tr('امسح وخد بونو', 'Scan and take a Buno'),
            leading: const BunoLottieIcon(name: 'scan', loop: true, color: BunoDark.on_primary),
            onPressed: onScan,
          ),
        const SizedBox(height: BunoSpace.s3),
        // All three stay visible: narrow phones scale the row down.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            children: [
              _ShortcutChip(label: tr('كل المحطات', 'All stations'), icon: BunoIcons.location, onTap: onAll),
              const SizedBox(width: BunoSpace.s2),
              _ShortcutChip(label: tr('المفضلة', 'Favourites'), onTap: onFavorites),
              const SizedBox(width: BunoSpace.s2),
              if (askFriend)
                _ShortcutChip(label: tr('اطلب من صاحبك', 'Ask a friend'), onTap: onAskFriend)
              else
                _ShortcutChip(label: tr('فيها مكان للإرجاع', 'Has return space'), onTap: onReturnSpace),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({required this.label, required this.onTap, this.icon});

  final String label;
  final BunoIcons? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BunoPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: BunoSize.touchMin,
        padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s4),
        decoration: BoxDecoration(
          color: BunoDark.background,
          borderRadius: BorderRadius.circular(BunoRadius.pill),
          border: Border.all(color: BunoDark.border, width: BunoStroke.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              BunoIcon(icon!, size: BunoSize.iconSm, color: BunoDark.text_secondary),
              const SizedBox(width: 6),
            ],
            BunoText(label, style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// One small bar per bay, bay 1 at the start, filled to its charge.
class BayBars extends StatelessWidget {
  const BayBars({super.key, required this.bays});

  final List<int?> bays;

  static const _width = 12.0;
  static const _height = 22.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tr('الخانات: ${bays.where((b) => b != null).length} فيها وحدات من ${bays.length}', 'Bays: ${bays.where((b) => b != null).length} of ${bays.length} have units'),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, charge) in bays.indexed) ...[
            if (i > 0) const SizedBox(width: BunoSpace.s1),
            Container(
              width: _width,
              height: _height,
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: BunoDark.border,
                borderRadius: BorderRadius.circular(BunoRadius.xs / 2),
              ),
              child: charge == null
                  ? null
                  : FractionallySizedBox(
                      widthFactor: 1,
                      heightFactor: (charge / 100).clamp(0.15, 1.0),
                      child: ColoredBox(color: chargeColor(charge)),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The running rental (reference 101): time against the first hour, cost so
/// far, where to return it, then "رجّعه" and "تفاصيل".
class HomeRentalBody extends StatelessWidget {
  const HomeRentalBody({
    super.key,
    required this.elapsed,
    required this.unitId,
    required this.returnStation,
    required this.onReturn,
    required this.onDetails,
  });

  final Duration elapsed;
  final String? unitId;
  final Station? returnStation;
  final VoidCallback onReturn;
  final VoidCallback onDetails;

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final time = '${_two(elapsed.inHours)}:${_two(elapsed.inMinutes % 60)}';
    final secondary = BunoType.caption.copyWith(color: BunoDark.text_secondary);
    final back = returnStation;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            BunoChargeRing(
              progress: elapsed.inMinutes / 60,
              size: 64,
              strokeWidth: 6,
              child: Text(
                time,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontFamily: BunoFonts.sora,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1,
                  color: BunoDark.text_primary,
                ),
              ),
            ),
            const SizedBox(width: BunoSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BunoText(
                    unitId == null ? tr('إيجار شغال', 'Active rental') : tr('إيجار شغال · $unitId', 'Active rental · $unitId'),
                    maxLines: 1,
                    style: secondary,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      BunoText(time, style: BunoType.h2),
                      const SizedBox(width: BunoSpace.s2),
                      Flexible(child: BunoText(tr('من أول ساعة', 'of the first hour'), maxLines: 1, style: secondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: BunoSpace.s2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                BunoText(tr('لحد دلوقتي', 'so far'), style: secondary),
                BunoText(tr('[السعر]', '[Price]'), style: BunoType.title.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
        if (back != null) ...[
          const SizedBox(height: BunoSpace.s4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s4, vertical: BunoSpace.s3),
            decoration: BoxDecoration(
              color: BunoDark.elevated,
              borderRadius: BorderRadius.circular(BunoRadius.lg),
            ),
            child: Row(
              children: [
                Expanded(
                  child: BunoText(
                    tr('رجّعه في ${back.name} · ${back.walkMinutes} د', 'Return at ${back.name} · ${back.walkMinutes} min'),
                    maxLines: 1,
                    style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: BunoSpace.s2),
                BunoText(
                  tr('${back.emptyCount} فاضيين', '${back.emptyCount} free'),
                  style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w700, color: BunoColors.primary),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: BunoSpace.s4),
        Row(
          children: [
            Expanded(flex: 3, child: BunoPrimaryButton(label: tr('رجّعه', 'Return it'), onPressed: onReturn)),
            const SizedBox(width: BunoSpace.s3),
            Expanded(flex: 2, child: BunoSecondaryButton(label: tr('تفاصيل', 'Details'), height: BunoSize.buttonLg, onPressed: onDetails)),
          ],
        ),
      ],
    );
  }
}

/// Revealed by dragging the sheet up: the other stations, nearest first.
class HomeOtherStations extends StatelessWidget {
  const HomeOtherStations({super.key, required this.stations, required this.onStation});

  final List<Station> stations;
  final ValueChanged<Station> onStation;

  @override
  Widget build(BuildContext context) {
    final secondary = BunoType.caption.copyWith(color: BunoDark.text_secondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BunoText(tr('محطات تانية قريبة', 'Other nearby stations'), style: secondary),
        for (final s in stations)
          BunoPressable(
            onTap: () => onStation(s),
            semanticLabel: s.name,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: BunoSpace.s2),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BunoText(s.name, maxLines: 1, style: BunoType.body.copyWith(fontWeight: FontWeight.w600)),
                        BunoText(
                          tr('${s.walkMinutes} د مشي · ${s.readyCount} جاهزين', '${s.walkMinutes} min walk · ${s.readyCount} ready'),
                          maxLines: 1,
                          style: secondary,
                        ),
                      ],
                    ),
                  ),
                  StationChargePin(charge: s.bestCharge),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
