import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/app_styles.dart';

class UtilityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  /// Drawn before the subtitle - the energy type the row is about.
  final IconData? subtitleIcon;
  final String? logoUrl;
  final String? trailingText;
  final VoidCallback? onTap;

  const UtilityCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.subtitleIcon,
    this.logoUrl,
    this.trailingText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            SizedBox(
              height: 44.h,
              width: 44.w,
              child: _buildLogo(),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.body1.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Row(
                    children: [
                      if (subtitleIcon != null) ...[
                        Icon(
                          subtitleIcon,
                          size: 14.sp,
                          color: AppColors.primaryColor,
                        ),
                        SizedBox(width: 4.w),
                      ],
                      Flexible(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.body3
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText!,
                style: AppStyles.body1.copyWith(fontWeight: FontWeight.w800),
              ),
          ],
        ),
      ),
    );
  }

  /// The supplier's logo, or the generic mark when there is none to show.
  ///
  /// [logoUrl] is expected to be ready to load - the caller resolves a stored
  /// upload path against the API origin before handing it over.
  Widget _buildLogo() {
    final url = logoUrl;
    if (url == null || url.isEmpty) return _fallbackLogo();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        // Supplier logos are drawn for a white ground and most are transparent,
        // so they need one of their own rather than the card's grey.
        color: AppColors.background,
        padding: EdgeInsets.all(4.w),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _fallbackLogo(),
          // An empty tile while the logo loads, never the generic mark - a
          // placeholder that looks like a supplier icon reads as the wrong
          // supplier rather than as loading.
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _fallbackLogo() =>
      Image.asset(AppAssets.circle, fit: BoxFit.contain);
}
