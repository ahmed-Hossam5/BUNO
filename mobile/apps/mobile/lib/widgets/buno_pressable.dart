import 'package:flutter/widgets.dart';

import '../theme/buno_tokens_ext.dart';

/// Pressed state from components.md: 92% scale and 88% opacity.
class BunoPressable extends StatefulWidget {
  const BunoPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<BunoPressable> createState() => _BunoPressableState();
}

class _BunoPressableState extends State<BunoPressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (widget.onTap != null && v != _pressed) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      enabled: widget.onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: BunoMotion.fast,
          curve: BunoMotion.easing,
          child: AnimatedOpacity(
            opacity: _pressed ? 0.88 : 1,
            duration: BunoMotion.fast,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
