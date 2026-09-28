import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vyzi/core/utils/app_colors.dart';

/// Centralized service for managing system UI overlay styles.
///
/// Provides theme-aware configuration for status bar and navigation bar
/// appearance, ensuring proper icon visibility on both Android and iOS.
class SystemUiService {
  SystemUiService._();

  /// Applies the default system UI style based on [AppColors.background].
  ///
  /// Call this at app startup and whenever the theme changes.
  static void setDefaultStyle() {
    final style = styleForBackground(AppColors.background);
    SystemChrome.setSystemUIOverlayStyle(style);
  }

  /// Returns a [SystemUiOverlayStyle] with icon brightness computed from
  /// [backgroundColor] luminance.
  ///
  /// Use this for per-screen overrides via [AnnotatedRegion].
  static SystemUiOverlayStyle styleForBackground(Color backgroundColor) {
    // Dark icons on light backgrounds, light icons on dark backgrounds
    final iconBrightness = backgroundColor.computeLuminance() > 0.5
        ? Brightness.dark
        : Brightness.light;

    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: iconBrightness,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: iconBrightness,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }
}
