import 'package:flutter/widgets.dart';

/// Shared responsive helpers for the app so spacing and widths scale smoothly
/// across phones, tablets, and larger screens.
abstract final class AppResponsive {
  const AppResponsive._();

  static const double _phoneMaxWidth = 560;
  static const double _tabletMaxWidth = 720;
  static const double _phonePadding = 24;
  static const double _tabletPadding = 32;

  static double horizontalPadding(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width >= 820) return _tabletPadding;
    if (width >= 600) return 28;
    return _phonePadding;
  }

  static double maxContentWidth(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width >= 820) return _tabletMaxWidth;
    if (width >= 600) return _phoneMaxWidth;
    return width.clamp(0, _phoneMaxWidth);
  }

  static EdgeInsetsGeometry pagePadding(BuildContext context) {
    final double padding = horizontalPadding(context);
    return EdgeInsets.symmetric(horizontal: padding);
  }

  static EdgeInsetsGeometry screenPadding(BuildContext context) {
    final double padding = horizontalPadding(context);
    return EdgeInsets.fromLTRB(padding, 16, padding, 24);
  }

  static double bubbleMaxWidth(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width >= 900) return width * 0.6;
    if (width >= 600) return width * 0.72;
    return width * 0.82;
  }
}
