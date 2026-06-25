import 'package:flutter/material.dart';

abstract final class NekoColors {
  static const background = Color(0xFFFFF8F0);
  static const surface = Color(0xFFFFF0E0);
  static const primary = Color(0xFFF28C4B);
  static const primaryPressed = Color(0xFFD9742E);
  static const secondary = Color(0xFFFBBF85);
  static const accent = Color(0xFFE8745A);
  static const textPrimary = Color(0xFF2E1F14);
  static const textSecondary = Color(0xFF8C6B58);
  static const success = Color(0xFF7BC67E);
  static const error = Color(0xFFD64545);
  static const surfaceOverlay = Color(0x732E1F14);

  static const cardShadow = BoxShadow(
    color: Color(0x1FF28C4B),
    blurRadius: 24,
    offset: Offset(0, 4),
  );

  static const focusGlow = BoxShadow(
    color: Color(0x40F28C4B),
    blurRadius: 16,
    offset: Offset(0, 2),
  );
}
