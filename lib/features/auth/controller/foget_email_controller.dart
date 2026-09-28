
import 'package:vyzi/core/exceptions/app_exceptions.dart';
import 'package:vyzi/core/services/auth_service.dart';
import 'package:vyzi/features/auth/screen/forgot_otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordController extends GetxController {
  final emailController = TextEditingController();
  final AuthService _auth = AuthService();
  var isLoading = false.obs;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<void> forgetPass() async {
    final email = emailController.text.trim();

    if (!_emailPattern.hasMatch(email)) {
      Get.snackbar('auth.validation.error'.tr, 'auth.forgot_password.email_error'.tr);
      return;
    }

    isLoading.value = true;
    try {
      final response = await _auth.forgotPassword(email: email);

      // The API answers identically for a registered address, an unknown one
      // and one still inside its cooldown — on purpose, so this screen cannot
      // be used to find out who has an account. So the message has to stay
      // conditional: the old copy here promised "OTP sent to your email" even
      // when nothing had been sent, which is exactly the lie it reads as when
      // the address was mistyped.
      final data = response['data'];
      final message = (data is Map && data['message'] is String)
          ? data['message'] as String
          : 'auth.forgot_password.otp_sent_success'.tr;

      Get.to(() => ForgotPasswordOtpScreen(), arguments: {'email': email});
      Get.snackbar('auth.validation.success'.tr, message);
    } on AppException catch (e) {
      Get.snackbar('auth.validation.error'.tr, e.message);
    } catch (_) {
      Get.snackbar(
        'auth.validation.error'.tr,
        'auth.forgot_password.send_failed_error'.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}
