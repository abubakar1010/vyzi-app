import 'package:vyzi/core/utils/app_assets.dart';

import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/widgets/custom_text_filled.dart';
import 'package:vyzi/core/widgets/primary_button.dart';
import 'package:vyzi/features/auth/controller/foget_email_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import '../../../../../core/appbar/custom_appbar.dart';



class ForgotPasswordScreen extends StatelessWidget {
  final ForgotPasswordController controller = Get.put(ForgotPasswordController());

  ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'auth.forgot_password.title'.tr,
        showBackButton: true,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),

          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Image.asset(AppAssets.logo, height: 64)),
                const SizedBox(height: 24),
                // ── Email ──────────────────────────
                _labeledField(
                  label: 'auth.forgot_password.email_label'.tr,
                  child: CustomTextField(
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    hintText: 'auth.forgot_password.email_hint'.tr,
                    validator: (v) =>
                    v == null || !v.contains('@') ? 'auth.forgot_password.email_error'.tr : null,
                  ),
                ),


                const SizedBox(height: 24),

                /// Button
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    title: 'auth.forgot_password.button'.tr,
                    onPress: controller.forgetPass,

                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        child,
      ],
    );
  }

}
