import 'package:flutter/material.dart';

class BlinkContainer extends StatefulWidget {
  final Widget child;
  final bool isBlinking;
  final Color blinkColor;
  final Duration duration;

  const BlinkContainer({
    super.key,
    required this.child,
    this.isBlinking = false,
    this.blinkColor = const Color(0x334CAF50), // Soft green by default
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<BlinkContainer> createState() => _BlinkContainerState();
}

class _BlinkContainerState extends State<BlinkContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: widget.blinkColor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    if (widget.isBlinking) {
      _triggerBlink();
    }
  }

  @override
  void didUpdateWidget(covariant BlinkContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBlinking && !oldWidget.isBlinking) {
      _triggerBlink();
    }
  }

  void _triggerBlink() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(16), // Match standard card radius
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
