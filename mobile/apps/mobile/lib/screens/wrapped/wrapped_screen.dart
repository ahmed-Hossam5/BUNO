import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_routes.dart';
import '../../data/mock_settings.dart';
import '../../data/mock_wrapped.dart';
import '../../l10n/buno_locale.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_logo.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text.dart';

/// Last month with Buno as three story pages (references 66–68): hours
/// charged, stations visited, then a card to share. Tap the end side (or
/// swipe) for the next page, the start side for the previous one. Pages
/// advance on their own unless motion is reduced. Mock numbers.
class WrappedScreen extends StatefulWidget {
  const WrappedScreen({super.key, this.month});

  /// Defaults to [MockWrapped.month].
  final MonthWrapped? month;

  static const pageCount = 3;

  /// Time each page stays before the next one.
  static const storyDuration = Duration(seconds: 6);

  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen> with SingleTickerProviderStateMixin {
  static const _last = WrappedScreen.pageCount - 1;

  final _pages = PageController();
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: WrappedScreen.storyDuration,
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed && _auto) _go(_index + 1);
    });

  int _index = 0;
  bool _started = false;

  /// False under reduced motion, where the bar fills at once and stays.
  bool _auto = false;

  MonthWrapped get _month => widget.month ?? MockWrapped.month;

  bool get _still => MediaQuery.of(context).disableAnimations || MockSettings.reduceMotion.value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _runProgress();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _pages.dispose();
    super.dispose();
  }

  /// Fills the current page's bar: over [WrappedScreen.storyDuration], or at
  /// once under reduced motion (no auto-advance then).
  void _runProgress() {
    _auto = !_still;
    if (!_auto) {
      _progress.value = 1;
    } else {
      _progress.forward(from: 0);
    }
  }

  void _go(int page) {
    if (page < 0 || page > _last || page == _index) return;
    if (_still) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(page, duration: BunoMotion.slow, curve: BunoMotion.easing);
    }
  }

  void _onPageChanged(int page) {
    setState(() => _index = page);
    _runProgress();
  }

  void _onTapUp(TapUpDetails d, double width) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final x = d.localPosition.dx;
    final startSide = rtl ? x > width * 2 / 3 : x < width / 3;
    _go(startSide ? _index - 1 : _index + 1);
  }

  void _close() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed(AppRoutes.home);
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final onGreen = _index == 0;
    final ink = onGreen ? BunoDark.on_primary : BunoDark.text_primary;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: onGreen ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: BunoDark.background,
        body: Stack(
          children: [
            LayoutBuilder(
              builder: (context, c) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _onTapUp(d, c.maxWidth),
                child: PageView(
                  controller: _pages,
                  onPageChanged: _onPageChanged,
                  children: [
                    _HoursPage(month: _month, still: _still),
                    _StationsPage(month: _month, still: _still),
                    _SharePage(
                      month: _month,
                      onShare: () => _toast(tr('الكارت جاهز للستوري', 'Your card is ready for your story')),
                      onSave: () => _toast(tr('اتحفظ في الصور', 'Saved to your photos')),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(_gutter, BunoSpace.s2, _gutter - 11, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 11),
                      child: AnimatedBuilder(
                        animation: _progress,
                        builder: (context, _) => _StoryBars(index: _index, progress: _progress.value, ink: ink),
                      ),
                    ),
                    const SizedBox(height: BunoSpace.s2),
                    Row(
                      children: [
                        _Logo(ink: ink, height: 40),
                        const Spacer(),
                        BunoPressable(
                          onTap: _close,
                          semanticLabel: tr('اقفل', 'Close'),
                          child: SizedBox.square(
                            dimension: BunoSize.touchMin,
                            child: Center(child: BunoIcon(BunoIcons.close, size: BunoSize.iconMd, color: ink)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Side margin of every page.
const _gutter = 22.0;

/// Room the bars and top bar take above each page's content.
const _chrome = 72.0;

/// One bar per page, filled up to the current one.
class _StoryBars extends StatelessWidget {
  const _StoryBars({required this.index, required this.progress, required this.ink});

  final int index;
  final double progress;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tr('صفحة ${index + 1} من ${WrappedScreen.pageCount}', 'Page ${index + 1} of ${WrappedScreen.pageCount}'),
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < WrappedScreen.pageCount; i++) ...[
            if (i > 0) const SizedBox(width: BunoSpace.s1),
            Expanded(
              child: Container(
                height: 3,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(BunoRadius.pill),
                ),
                child: FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: i < index ? 1 : (i == index ? progress : 0),
                  child: ColoredBox(color: ink),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The Buno logo, tinted to [ink] on the green page.
class _Logo extends StatelessWidget {
  const _Logo({required this.ink, required this.height});

  final Color ink;
  final double height;

  @override
  Widget build(BuildContext context) {
    final logo = BunoLogo(height: height, glow: false);
    if (ink == BunoDark.text_primary) return logo;
    return ColorFiltered(colorFilter: ColorFilter.mode(ink, BlendMode.srcIn), child: logo);
  }
}

/// A count that runs up from zero, or shows [value] at once when [still].
class _CountUp extends StatelessWidget {
  const _CountUp({required this.value, required this.still, required this.builder});

  final int value;
  final bool still;
  final Widget Function(int shown) builder;

  @override
  Widget build(BuildContext context) {
    if (still) return builder(value);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: BunoMotion.easing,
      builder: (context, v, _) => builder(v.round()),
    );
  }
}

/// A big number with its word beside it, sharing a baseline.
class _BigStat extends StatelessWidget {
  const _BigStat({required this.number, required this.word, required this.size, required this.color, this.wordColor, this.glow = false});

  final String number;
  final String word;
  final double size;
  final Color color;
  final Color? wordColor;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        BunoText(
          number,
          maxLines: 1,
          style: BunoType.display.copyWith(
            fontSize: size,
            height: 1,
            color: color,
            letterSpacing: -0.04 * size,
            shadows: glow ? [Shadow(color: color.withValues(alpha: 0.45), blurRadius: 32)] : null,
          ),
        ),
        const SizedBox(width: BunoSpace.s3),
        Flexible(child: BunoText(word, maxLines: 1, style: BunoType.h2.copyWith(color: wordColor ?? color))),
      ],
    );
  }
}

/// Page 1 (reference 66): hours charged and a bar per day.
class _HoursPage extends StatelessWidget {
  const _HoursPage({required this.month, required this.still});

  final MonthWrapped month;
  final bool still;

  static const _ink = BunoDark.on_primary;

  @override
  Widget build(BuildContext context) {
    final soft = _ink.withValues(alpha: 0.72);
    return ColoredBox(
      color: BunoColors.primary,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(_gutter, _chrome, _gutter, BunoSpace.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BunoText(
                  tr('شهرك مع بونو · [الشهر]', 'Your month with Buno · [Month]'),
                  style: BunoType.title.copyWith(color: soft),
                ),
                BunoText(tr('شحنت وانت ماشي', 'You charged on the go'), style: BunoType.h1.copyWith(color: _ink)),
                const SizedBox(height: BunoSpace.s2),
                _CountUp(
                  value: month.hoursCharged,
                  still: still,
                  builder: (n) => _BigStat(
                    number: '$n',
                    word: tr('ساعة', 'hours'),
                    size: (c.maxHeight * 0.18).clamp(72.0, 150.0),
                    color: _ink,
                  ),
                ),
                const SizedBox(height: BunoSpace.s3),
                BunoText(
                  tr(
                    'في ${month.rentals} مرة تأجير، ومن غير ما تقعد جنب فيشة ولا دقيقة.',
                    'Over ${month.rentals} rentals, without sitting by a socket for a minute.',
                  ),
                  style: BunoType.body.copyWith(fontWeight: FontWeight.w600, color: soft),
                ),
                const Spacer(),
                SizedBox(
                  height: (c.maxHeight * 0.22).clamp(72.0, 160.0),
                  child: _DailyBars(minutes: month.dailyMinutes, color: _ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One bar per day, day 1 on the left like any time axis, labelled 1, 15
/// and the last day.
class _DailyBars extends StatelessWidget {
  const _DailyBars({required this.minutes, required this.color});

  final List<int> minutes;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final most = minutes.fold<int>(1, math.max);
    final days = minutes.length;
    final active = minutes.where((m) => m > 0).length;
    final label = BunoType.caption.copyWith(color: color.withValues(alpha: 0.72));
    Widget dayLabel(int day) => Align(
          alignment: Alignment(((day - 0.5) / days) * 2 - 1, 0),
          child: BunoText('$day', style: label),
        );
    return Semantics(
      label: tr('شحنت في $active يوم من $days', 'You charged on $active of $days days'),
      excludeSemantics: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final m in minutes)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: FractionallySizedBox(
                          heightFactor: m == 0 ? 0.04 : (m / most).clamp(0.08, 1.0),
                          alignment: Alignment.bottomCenter,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: m == 0 ? color.withValues(alpha: 0.25) : color,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(BunoRadius.xs / 2)),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: BunoSpace.s2),
            SizedBox(
              height: 20,
              child: Stack(children: [dayLabel(1), dayLabel(15), dayLabel(days)]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page 2 (reference 67): stations visited on a little map, the favourite
/// one, and how often the phone died.
class _StationsPage extends StatelessWidget {
  const _StationsPage({required this.month, required this.still});

  final MonthWrapped month;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final dead = month.deadPhonePercent;
    return ColoredBox(
      color: BunoDark.background,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(_gutter, _chrome, _gutter, BunoSpace.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BunoText(tr('لفّيت على', 'You went around'), style: BunoType.h1),
                _CountUp(
                  value: month.stationsVisited,
                  still: still,
                  builder: (n) => _BigStat(
                    number: '$n',
                    word: tr('محطات', 'stations'),
                    size: (c.maxHeight * 0.15).clamp(64.0, 120.0),
                    color: BunoColors.primary,
                    wordColor: BunoDark.text_primary,
                    glow: true,
                  ),
                ),
                const SizedBox(height: BunoSpace.s4),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: _RouteMap(stops: month.stationsVisited),
                  ),
                ),
                const SizedBox(height: BunoSpace.s4),
                _InfoCard(
                  leading: const BunoIcon(BunoIcons.location, size: BunoSize.iconMd, color: BunoColors.primary),
                  title: month.favoriteStation.name,
                  subtitle: tr(
                    'محطتك المفضلة · ${month.favoriteRentals} رحلات منها',
                    'Your favourite · ${month.favoriteRentals} rentals from here',
                  ),
                ),
                const SizedBox(height: BunoSpace.s3),
                _InfoCard(
                  leading: BunoText(
                    '$dead%',
                    style: BunoType.title.copyWith(fontWeight: FontWeight.w700, color: BunoColors.primary),
                  ),
                  title: dead == 0
                      ? tr('عمرك ما وصلت لـ 0%', 'Your phone never hit 0%')
                      : tr('وصلت لـ 0% في $dead% بس من الأيام', 'You hit 0% on just $dead% of days'),
                  subtitle: dead == 0 ? tr('ولا مرة طول الشهر', 'Not once all month') : tr('بونو كان قريب', 'Buno was close by'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Numbered stops joined by a dotted line over two streets (not a real map).
class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.stops});

  final int stops;

  /// Where each stop sits, as fractions of the card.
  static const _points = [
    Offset(0.18, 0.37), Offset(0.42, 0.24), Offset(0.66, 0.50), //
    Offset(0.30, 0.68), Offset(0.58, 0.80), Offset(0.84, 0.28),
  ];

  static const _node = 30.0;

  @override
  Widget build(BuildContext context) {
    final points = _points.take(stops.clamp(0, _points.length)).toList();
    return Semantics(
      label: tr('خريطة المحطات اللي زرتها', 'Map of the stations you visited'),
      excludeSemantics: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: BunoDark.card,
            borderRadius: BorderRadius.circular(BunoRadius.xl),
            border: Border.all(color: BunoDark.border),
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final size = c.biggest;
              Offset at(Offset f) => Offset(f.dx * size.width, f.dy * size.height);
              return Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _MapPainter([for (final p in points) at(p)]))),
                  for (final (i, p) in points.indexed)
                    Positioned(
                      left: at(p).dx - _node / 2,
                      top: at(p).dy - _node / 2,
                      width: _node,
                      height: _node,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: BunoDark.background,
                          shape: BoxShape.circle,
                          border: Border.all(color: BunoColors.primary, width: BunoStroke.emphasis),
                        ),
                        child: Center(
                          child: BunoText(
                            '${i + 1}',
                            style: BunoType.caption.copyWith(fontWeight: FontWeight.w700, color: BunoColors.primary, height: 1),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final street = Paint()..color = BunoDark.border.withValues(alpha: 0.7);
    const w = 16.0;
    canvas
      ..drawRect(Rect.fromLTWH(size.width * 0.3 - w / 2, 0, w, size.height), street)
      ..drawRect(Rect.fromLTWH(size.width * 0.68 - w / 2, 0, w, size.height), street)
      ..drawRect(Rect.fromLTWH(0, size.height * 0.55 - w / 2, size.width, w), street);

    final dot = Paint()..color = BunoColors.primary.withValues(alpha: 0.8);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      final length = (b - a).distance;
      for (var d = 0.0; d <= length; d += 7) {
        canvas.drawCircle(Offset.lerp(a, b, d / length)!, 1.6, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.points != points;
}

/// Rounded card with a round badge at the start and two lines.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.leading, required this.title, required this.subtitle});

  final Widget leading;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BunoSpace.s4),
      decoration: BoxDecoration(
        color: BunoDark.card,
        borderRadius: BorderRadius.circular(BunoRadius.xl),
        border: Border.all(color: BunoDark.border),
      ),
      child: Row(
        children: [
          Container(
            width: BunoSize.avatarMd,
            height: BunoSize.avatarMd,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: BunoColors.primary_soft, shape: BoxShape.circle),
            child: leading,
          ),
          const SizedBox(width: BunoSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BunoText(title, maxLines: 1, style: BunoType.title.copyWith(fontWeight: FontWeight.w700)),
                BunoText(subtitle, maxLines: 1, style: BunoType.caption.copyWith(color: BunoDark.text_secondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Page 3 (reference 68): the card to share, with share and save.
class _SharePage extends StatelessWidget {
  const _SharePage({required this.month, required this.onShare, required this.onSave});

  final MonthWrapped month;
  final VoidCallback onShare;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: BunoDark.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(_gutter, _chrome, _gutter, BunoSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BunoText(
                tr('شير شهرك', 'Share your month'),
                textAlign: TextAlign.center,
                style: BunoType.title.copyWith(fontWeight: FontWeight.w700, color: BunoDark.text_secondary),
              ),
              const SizedBox(height: BunoSpace.s4),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: ShareCard.size.aspectRatio,
                    child: FittedBox(child: ShareCard(month: month)),
                  ),
                ),
              ),
              const SizedBox(height: BunoSpace.s5),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: BunoPrimaryButton(
                      label: tr('شير على الستوري', 'Share to story'),
                      leading: const BunoLottieIcon(name: 'share', color: BunoDark.on_primary),
                      onPressed: onShare,
                    ),
                  ),
                  const SizedBox(width: BunoSpace.s3),
                  Expanded(
                    flex: 2,
                    child: BunoSecondaryButton(
                      label: tr('حفظ', 'Save'),
                      height: BunoSize.buttonLg,
                      labelWeight: FontWeight.w700,
                      leading: const BunoLottieIcon(name: 'download', size: BunoSize.iconSm, color: BunoDark.text_primary),
                      onPressed: onSave,
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

/// The story card, laid out at [size] and scaled to fit.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.month});

  final MonthWrapped month;

  static const size = Size(300, 470);
  static const _ink = BunoDark.on_primary;

  @override
  Widget build(BuildContext context) {
    final dead = month.deadPhonePercent;
    return Container(
      width: size.width,
      height: size.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: BunoColors.primary, borderRadius: BorderRadius.circular(36)),
      child: Stack(
        children: [
          // Part of the logo's ring, as decoration.
          PositionedDirectional(
            end: -70,
            bottom: -120,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: BunoDark.on_primary.withValues(alpha: 0.07), width: 44),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(BunoSpace.s6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const _Logo(ink: _ink, height: 36),
                    const Spacer(),
                    BunoText(
                      tr('[الشهر]', '[Month]'),
                      style: BunoType.caption.copyWith(fontWeight: FontWeight.w700, color: _ink.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
                const Spacer(),
                _CardStat(value: '${month.hoursCharged}', label: tr('ساعة شحن وانا ماشي', 'hours charged on the go')),
                _CardStat(value: '${month.stationsVisited}', label: tr('محطات', 'stations')),
                _CardStat(value: '$dead%', label: dead == 0 ? tr('ولا مرة', 'dead days') : tr('من الأيام', 'of days')),
                const Spacer(),
                BunoText(
                  tr('الدنيا زحمة؟ خد بونو.', 'Busy day? Take a Buno.'),
                  style: BunoType.title.copyWith(fontWeight: FontWeight.w700, color: _ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  const _CardStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        BunoText(
          value,
          maxLines: 1,
          style: BunoType.display.copyWith(fontSize: 60, height: 1.15, letterSpacing: -2, color: ShareCard._ink),
        ),
        const SizedBox(width: BunoSpace.s3),
        Flexible(
          child: BunoText(label, maxLines: 1, style: BunoType.title.copyWith(fontWeight: FontWeight.w700, color: ShareCard._ink)),
        ),
      ],
    );
  }
}
