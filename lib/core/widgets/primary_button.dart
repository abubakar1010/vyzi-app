import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_colors.dart';
import '../utils/app_styles.dart';


class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.title,
    this.backgroundColor,
    this.borderColor = Colors.transparent,
    required this.onPress,
    this.textStyle,
    this.prefixWidget,
    this.borderRadius,
    this.height,
    this.width,
  });

  final String title;
  final Color? backgroundColor;
  final Color? borderColor;
  final TextStyle? textStyle;
  final VoidCallback onPress;
  final Widget? prefixWidget;
  final double? borderRadius;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final double radius = borderRadius ?? 12.r;
    final Color effectiveBackgroundColor = backgroundColor ?? AppColors.primaryColor;
    final TextStyle effectiveTextStyle = textStyle ?? AppStyles.buttonText;
    
    return Material(
      color: effectiveBackgroundColor,
      borderRadius: BorderRadius.circular(radius),
      elevation: 0,
      child: InkWell(
        splashColor: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(radius),
        onTap: onPress,
        child: Container(
          width: width ?? double.infinity,
          height: height ?? 52.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: borderColor != null && borderColor != Colors.transparent
                ? Border.all(color: borderColor!, width: 1.2)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (prefixWidget != null) ...[
                prefixWidget!,
                SizedBox(width: 10.w),
              ],
              Text(title, style: effectiveTextStyle),
            ],
          ),
        ),
      ),
    );
  }
}
