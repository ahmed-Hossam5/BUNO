import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';

import '../data/mock_settings.dart';
import '../theme/buno_tokens_ext.dart';

/// Renders one of the animated Buno icons in assets/lottie/.
///
/// At rest the icon shows its last frame. It plays once when it first loads
/// with a non-null [playKey] and each time [playKey] changes after that, or
/// loops while [loop] is true. When the platform asks for reduced
/// motion (MediaQuery.disableAnimations), or the in-app setting
/// [MockSettings.reduceMotion] is on, it always shows the last frame.
class BunoLottieIcon extends StatefulWidget {
  const BunoLottieIcon({
    super.key,
    required this.name,
    this.size = BunoSize.iconMd,
    this.loop = false,
    this.playKey,
    this.color,
  });

  /// File name in assets/lottie/, without the `.json` extension.
  final String name;
  final double size;
  final bool loop;

  /// Tints every fill and stroke. Null keeps the colors drawn in the file.
  final Color? color;

  /// Any value; the icon plays once on load when this is non-null, and
  /// whenever it changes.
  final Object? playKey;

  String get asset => 'assets/lottie/$name.json';

  @override
  State<BunoLottieIcon> createState() => _BunoLottieIconState();
}

class _BunoLottieIconState extends State<BunoLottieIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1,
  );
  bool _loaded = false;
  bool _platformReduceMotion = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    MockSettings.reduceMotion.addListener(_updateReduceMotion);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _platformReduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _updateReduceMotion();
  }

  void _updateReduceMotion() {
    final reduceMotion = _platformReduceMotion || MockSettings.reduceMotion.value;
    if (reduceMotion != _reduceMotion) {
      _reduceMotion = reduceMotion;
      _sync();
    }
  }

  @override
  void didUpdateWidget(BunoLottieIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loop != oldWidget.loop) {
      _sync();
    } else if (widget.playKey != oldWidget.playKey) {
      _playOnce();
    }
  }

  void _onLoaded(LottieComposition composition) {
    _controller.duration = composition.duration;
    _loaded = true;
    _sync();
    if (widget.playKey != null) _playOnce();
  }

  /// Puts the controller in the resting or looping state for the current
  /// [BunoLottieIcon.loop] and reduced-motion settings.
  void _sync() {
    if (!_loaded || _reduceMotion || !widget.loop) {
      _controller.value = 1;
    } else {
      _controller.repeat();
    }
  }

  void _playOnce() {
    if (!_loaded || _reduceMotion || widget.loop) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    MockSettings.reduceMotion.removeListener(_updateReduceMotion);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final lottie = Lottie.asset(
      widget.asset,
      controller: _controller,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      onLoaded: _onLoaded,
      errorBuilder: (context, error, stackTrace) =>
          SizedBox.square(dimension: widget.size),
    );
    // The kit's shapes are unnamed, so Lottie's key-path color delegates
    // can't target them; tint the rendered output like BunoIcon does.
    if (color == null) return lottie;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: lottie,
    );
  }
}
