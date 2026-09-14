import 'package:flutter/material.dart';

/// Design tokens for the Eureka home experience, matched against the
/// reference mock-up: warm cream background, a deep red/orange hero banner
/// and a single bright-orange accent used for actions, badges and prices.
abstract final class AppColors {
  static const Color background = Color(0xFFFCEEDE);
  static const Color card = Colors.white;
  static const Color chipBackground = Color(0xFFF2E7DA);

  static const Color primary = Color(0xFFF3711B);
  static const Color primaryDark = Color(0xFFD65A0F);

  static const Color bannerStart = Color(0xFF7A140C);
  static const Color bannerEnd = Color(0xFFC7280F);

  static const Color textDark = Color(0xFF231A15);
  static const Color textGrey = Color(0xFF9C9188);

  static const Color badge = Color(0xFFE7452B);
  static const Color success = Color(0xFF2E9E5B);
  static const Color star = Color(0xFFFFB020);
}
