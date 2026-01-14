import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class ResponsiveDebouncerWrapper extends StatefulWidget {
  final Widget child;
  const ResponsiveDebouncerWrapper({super.key, required this.child});

  @override
  State<ResponsiveDebouncerWrapper> createState() => _ResponsiveDebouncerWrapperState();
}

class _ResponsiveDebouncerWrapperState extends State<ResponsiveDebouncerWrapper> {
  Timer? _debounceTimer;
  bool _isResizing = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // بدلاً من استدعاء _onResize مباشرة، ننتظر انتهاء الـ Frame الحالي
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onResize();
        });

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _isResizing ? 0.90 : 1.0,
          child: widget.child,
        );
      },
    );
  }

  void _onResize() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    // نتحقق أولاً إذا كانت الحالة تغيرت فعلاً لتجنب Rebuilds لا نهائية
    if (!_isResizing) {
      if (mounted) {
        setState(() {
          _isResizing = true;
        });
      }
    }

    _debounceTimer = Timer(const Duration(milliseconds: AppConstants.resizeDebounceMs), () {
      if (mounted) {
        setState(() {
          _isResizing = false;
        });
      }
    });
  }
}