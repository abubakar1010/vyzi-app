// password_update_success_screen.dart
import 'package:vyzi/core/widgets/primary_button.dart';
import 'package:vyzi/core/utils/app_assets.dart';
import 'package:vyzi/features/auth/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';





class PasswordUpdateSuccessController extends GetxController {
  /// Handle navigation back to login
  void goToLogin() {
    Get.offAll(() => SignInScreen());
  }
}


class PasswordUpdateSuccessScreen extends StatelessWidget {
  final PasswordUpdateSuccessController controller =
  Get.put(PasswordUpdateSuccessController());

  PasswordUpdateSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(AppAssets.logo, height: 64),
                const SizedBox(height: 16),
                /// ✅ Logo/Image
                Image.asset(
                  "assets/images/success.webp", // your tick image
                  width: 190.w,
                  height: 190.h,
                  fit: BoxFit.contain,
                ),

                SizedBox(height: 24.h),

                /// Static Message
                Text(
                  'auth.success.title'.tr,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'auth.success.message'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: 32.h),

                /// Button
                PrimaryButton(
                  title: 'auth.success.button'.tr,
                  onPress: controller.goToLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
