import 'package:chatgpt_clone/utils/app_colors.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.scaffoldBgColor,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.scaffoldBgColor,
      elevation: 0,
    ),
  );
}
