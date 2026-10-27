import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/layout/adaptive.dart';
import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/navbar/navbar_controller.dart';
import 'package:vyzi/core/utils/app_colors.dart';

/// Shown once an activation request is in: nothing else is asked of the
/// customer — a consultant calls them.
class ActivationRequestSuccessScreen extends StatelessWidget {
  const ActivationRequestSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Adaptive.gutters(context, 24, maxWidth: Adaptive.formWidth),
          child: Column(
            children: [
              SizedBox(height: 72.h),
              Container(
                width: 96.w,
                height: 96.w,
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 44.sp),
              ),
              SizedBox(height: 28.h),
              Text(
                'activation_request.success_title'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 10.h),
              Text(
                'activation_request.success_subtitle'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, height: 1.45),
              ),
              SizedBox(height: 40.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    NavHelper.switchTab(NavTabs.request);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'activation_request.success_view_requests'.tr,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'activation_request.success_back_home'.tr,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
