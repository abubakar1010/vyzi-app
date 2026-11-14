import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/utils/app_colors.dart';

/// Full-screen "Signing you in…" overlay for Google / Apple sign-in.
///
/// Put it over the screen for the whole social sign-in. While the provider's
/// own sheet is open it sits underneath that sheet; once the sheet closes, the
/// Firebase exchange and the backend login still take a few seconds, and this
/// is what the user sees instead of a login screen that looks frozen. It also
/// swallows taps and the back gesture, so a second sign-in cannot start.
class SocialAuthOverlay extends StatelessWidget {
  const SocialAuthOverlay({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: visible ? const _OverlayContent() : const SizedBox.shrink(),
      ),
    );
  }
}

class _OverlayContent extends StatelessWidget {
  const _OverlayContent();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ModalBarrier(dismissible: false, color: Colors.black38),
          Center(
            child: Semantics(
              liveRegion: true,
              label: 'auth.social.signing_in'.tr,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 40.w),
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 36.r,
                      height: 36.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'auth.social.signing_in'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'auth.social.signing_in_hint'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textMuted,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
