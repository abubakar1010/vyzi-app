import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vyzi/core/utils/app_colors.dart';

class ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final VoidCallback? onTap;
  final bool showBadge;
  final String? badgeText;

  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    this.onTap,
    this.showBadge = false,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: const Color(0xFFD2D2D2),
            width: 1.22,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Asset Image ──
                Image.asset(
                  image,
                  width: 56.w,
                  height: 56.h,
                  fit: BoxFit.contain,
                ),

                SizedBox(width: 14.w),

                // ── Title + Subtitle ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),

                      SizedBox(height: 4.h),

                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12.sp,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8.w),

                // ── Right Chevron ──
                SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textDark,
                    size: 24,
                  ),
                ),
              ],
            ),

            // ── Badge ──
            if (showBadge)
              Positioned(
                top: -20.h,
                right: -6.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    badgeText ?? 'Nuovo',
                    style: TextStyle(
                      color: AppColors.background,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
