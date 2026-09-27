import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle titleHeader = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.goldPrimary,
    letterSpacing: 1.5,
  );

  static const TextStyle titleSubHeader = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 1.8,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle badgeText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.emeraldAccent,
    letterSpacing: 1.5,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: AppColors.backgroundDark,
    letterSpacing: 1.2,
  );
}
