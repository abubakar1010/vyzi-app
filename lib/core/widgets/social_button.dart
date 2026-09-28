

// ─────────────────────────────────────────────
//  Social Button
// ─────────────────────────────────────────────
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'primary_button.dart';

class SocialButton extends StatelessWidget {
  final String label;
  final Widget logo;
  final VoidCallback onPress;
  final double? borderRadius;

  const SocialButton({
    super.key,
    required this.label,
    required this.logo,
    required this.onPress,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      title: label,
      backgroundColor: Colors.white,
      borderColor: AppColors.dividerColor,
      onPress: onPress,
      prefixWidget: logo,
      borderRadius: borderRadius ?? 24.r,
      textStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
