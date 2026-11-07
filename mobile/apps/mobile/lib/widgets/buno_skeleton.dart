import 'package:flutter/widgets.dart';

import '../theme/buno_tokens.dart';
import '../l10n/buno_locale.dart';

/// A grey placeholder block (reference 32_state_loading).
class BunoSkeletonBox extends StatelessWidget {
  const BunoSkeletonBox({super.key, this.width, required this.height, this.radius = BunoRadius.pill});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: BunoDark.card, borderRadius: BorderRadius.circular(radius)),
    );
  }
}

/// Placeholder list rows: a title bar, a shorter meta bar, a trailing value.
class BunoSkeletonList extends StatelessWidget {
  const BunoSkeletonList({super.key, this.rows = 5, this.leading});

  final int rows;

  /// Shown above the rows (stat cards, say).
  final Widget? leading;

  static const rowHeight = 73.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tr('بنحمّل', 'Loading'),
      excludeSemantics: true,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          ?leading,
          for (var i = 0; i < rows; i++)
            Container(
              height: rowHeight,
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: BunoDark.border))),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FractionallySizedBox(widthFactor: 0.55, child: BunoSkeletonBox(height: 14)),
                        SizedBox(height: BunoSpace.s2),
                        FractionallySizedBox(widthFactor: 0.35, child: BunoSkeletonBox(height: 10)),
                      ],
                    ),
                  ),
                  SizedBox(width: BunoSpace.s3),
                  BunoSkeletonBox(width: 52, height: 14),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Shows [skeleton] for [delay], then [child]. Runs once per State, so
/// rebuilds (filters, tab toggles) don't bring the skeleton back.
///
/// The wait is driven by a ticker rather than a Timer so widget tests'
/// pumpAndSettle waits it out. The skeleton itself doesn't move, so it
/// needs nothing extra for reduced motion.
class BunoLoadingGate extends StatefulWidget {
  const BunoLoadingGate({super.key, required this.delay, required this.skeleton, required this.child});

  final Duration delay;
  final Widget skeleton;
  final Widget child;

  @override
  State<BunoLoadingGate> createState() => _BunoLoadingGateState();
}

class _BunoLoadingGateState extends State<BunoLoadingGate> with SingleTickerProviderStateMixin {
  late final AnimationController _wait = AnimationController(
    vsync: this,
    duration: widget.delay,
    animationBehavior: AnimationBehavior.preserve,
  );
  late bool _loading = widget.delay > Duration.zero;

  @override
  void initState() {
    super.initState();
    if (_loading) {
      _wait.forward().whenComplete(() {
        if (mounted) setState(() => _loading = false);
      });
    }
  }

  @override
  void dispose() {
    _wait.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _loading ? widget.skeleton : widget.child;
}
