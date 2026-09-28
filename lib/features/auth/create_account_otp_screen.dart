import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/widgets/otp_input_field.dart';
import 'package:vyzi/core/widgets/primary_button.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vyzi/features/auth/create_account_otp_controller.dart';

import '../../../../../core/appbar/custom_appbar.dart';

class CreateAccountOtpScreen extends StatelessWidget {
  final CreateAccountOtpController controller = Get.put(
    CreateAccountOtpController(),
  );

  CreateAccountOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: 'auth.otp.title'.tr, showBackButton: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              /// OTP Input Boxes
              Center(
                child: OtpInputField(
                  controller: controller.otpController,
                  focusNode: controller.otpFocusNode,
                  length: CreateAccountOtpController.otpLength,
                  onChanged: controller.onOtpChanged,
                  onCompleted: (_) => controller.verifyAndProceed(),
                ),
              ),

              const SizedBox(height: 24),

              /// Resend Section (Right aligned now)
              Align(
                alignment: Alignment.centerRight,
                child: Obx(() {
                  if (controller.isResending.value) {
                    return const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  } else if (controller.secondsRemaining.value == 0) {
                    return GestureDetector(
                      onTap: controller.resendCode,
                      child: Text(
                        'auth.otp.resend'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryColor,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  } else {
                    final seconds = controller.secondsRemaining.value;
                    final timerText =
                        "00:${seconds.toString().padLeft(2, '0')}";
                    return RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Open Sans',
                        ),
                        children: [
                          TextSpan(
                            text: '${'auth.otp.resend'.tr} ',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: timerText,
                            style: const TextStyle(
                              color: AppColors.red100,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                }),
              ),

              const SizedBox(height: 32),

              /// Verify Button
              SizedBox(
                width: double.infinity,
                child: Obx(() {
                  final isReady = controller.isOtpComplete();
                  final isVerifying = controller.isVerifying.value;

                  return PrimaryButton(
                    title: 'auth.otp.button'.tr,
                    backgroundColor: isReady && !isVerifying
                        ? AppColors.primaryColor
                        : AppColors.primaryColor.withValues(alpha: 0.4),
                    prefixWidget: isVerifying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : null,
                    onPress: () {
                      if (isVerifying) return;
                      if (isReady) {
                        controller.verifyAndProceed();
                      } else {
                        Get.snackbar(
                          'auth.validation.error'.tr,
                          'auth.otp.error_incomplete'.tr,
                        );
                      }
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
