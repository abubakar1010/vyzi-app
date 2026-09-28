import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/utils/app_colors.dart';
import 'package:get/get.dart';


class UploadSection extends StatelessWidget {
  final VoidCallback onTap;

  const UploadSection({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryButton.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        painter: DottedBorderPainter(
          color: AppColors.borderGlobal.withOpacity(0.5),
          strokeWidth: 1.w,
          dashPattern: [8.w, 8.w],
          borderRadius: 12.r,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      AppAssets.upload,
                      width: 32.sp,
                      height: 32.sp,
                    ),
                    SizedBox(height: 12.h),
                     Text(
                      'home.upload_section.title'.tr,
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 8.h),
                     Text(
                      'home.upload_section.subtitle'.tr,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Text(
                          'home.upload_section.button'.tr,
                          style: TextStyle(
                            color: AppColors.background,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 2,
                child: Image.asset(
                  AppAssets.homeNew,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final double borderRadius;

  DottedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashPattern,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);

    for (PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      int i = 0;
      while (distance < metric.length) {
        final double len = dashPattern[i % dashPattern.length];
        if (draw) {
          canvas.drawPath(
            metric.extractPath(distance, distance + len),
            paint,
          );
        }
        distance += len;
        draw = !draw;
        i++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}

