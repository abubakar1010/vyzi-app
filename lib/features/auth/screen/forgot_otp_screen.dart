
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/utils/app_assets.dart';
import 'package:vyzi/core/widgets/otp_input_field.dart';
import 'package:vyzi/core/widgets/primary_button.dart';
import 'package:vyzi/features/auth/controller/forgot_otp_controller.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/appbar/custom_appbar.dart';




class ForgotPasswordOtpScreen extends StatefulWidget {
  const ForgotPasswordOtpScreen({super.key});

  @override
  State<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  late final ForgotPasswordOtpController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ForgotPasswordOtpController());
    // `Get.put` may hand back a controller from an earlier pass through this
    // flow, whose `onInit` will not run again — pick up this run's email and
    // restart the countdown. See `ForgotPasswordOtpController.readArguments`.
    controller.readArguments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'auth.otp.title'.tr,
        showBackButton: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ListView(
            children: [
              const SizedBox(height: 24),

              Center(child: Image.asset(AppAssets.logo, height: 64)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('auth.forgot_password.otp_sent_success'.tr),
              ),
              const SizedBox(height: 24),

              /// OTP Input Boxes
              Center(
                child: OtpInputField(
                  controller: controller.otpController,
                  focusNode: controller.otpFocusNode,
                  length: ForgotPasswordOtpController.otpLength,
                  boxHeight: 57,
                  fontSize: 22,
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
                        style: const TextStyle(fontSize: 14, fontFamily: 'Open Sans'),
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : null,
                    onPress: () {
                      if (isVerifying) return;
                      if (isReady) {
                        controller.verifyAndProceed();
                      } else {
                        Get.snackbar('auth.validation.error'.tr, 'auth.otp.error_incomplete'.tr);
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
