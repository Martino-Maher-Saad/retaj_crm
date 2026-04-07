import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Wrapper ذكي يكتشف تغيير حجم الشاشة فقط لو الأبعاد تغيرت فعلاً،
/// ويتجنب إعادة البناء اللانهائية عبر مقارنة الـ constraints السابقة.
class ResponsiveDebouncerWrapper extends StatefulWidget {
  final Widget child;
  const ResponsiveDebouncerWrapper({super.key, required this.child});

  @override
  State<ResponsiveDebouncerWrapper> createState() =>
      _ResponsiveDebouncerWrapperState();
}

class _ResponsiveDebouncerWrapperState
    extends State<ResponsiveDebouncerWrapper> {
  Timer? _debounceTimer;
  bool _isResizing = false;

  // آخر أبعاد شافها الـ LayoutBuilder
  double? _lastWidth;
  double? _lastHeight;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleConstraints(BoxConstraints constraints) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;

    // لو نفس الأبعاد → لا داعي لأي شيء
    if (_lastWidth == w && _lastHeight == h) return;

    _lastWidth = w;
    _lastHeight = h;

    // أطلق الـ debounce خارج الـ build phase باستخدام microtask
    Future.microtask(() => _onResize());
  }

  void _onResize() {
    if (!mounted) return;

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (!_isResizing) {
      setState(() => _isResizing = true);
    }

    _debounceTimer =
        Timer(const Duration(milliseconds: AppConstants.resizeDebounceMs), () {
      if (mounted) {
        setState(() => _isResizing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // نكتشف التغيير بعد انتهاء الـ build بأمان
        _handleConstraints(constraints);

        // بدون AnimatedOpacity لأنها تسبب NEEDS-LAYOUT cascade
        // الشفافية بسيطة ومباشرة عبر Opacity
        return Opacity(
          opacity: _isResizing ? 0.92 : 1.0,
          child: widget.child,
        );
      },
    );
  }
}