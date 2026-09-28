import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/exceptions/app_exceptions.dart';
import 'package:vyzi/core/services/auth_service.dart';
import 'package:vyzi/routes/app_routes.dart';

class ForgotPasswordOtpController extends GetxController {
  static const int otpLength = 6;

  final otpController = TextEditingController();
  final otpFocusNode = FocusNode();

  /// Mirror of [otpController] text so the UI can react to it.
  var otpCode = ''.obs;
  var secondsRemaining = 60.obs;
  var sessionId = ''.obs;
  var isResending = false.obs;
  var isVerifying = false.obs;
  Timer? _timer;
  var email = ''.obs;
  final AuthService _auth = AuthService();

  @override
  void onInit() {
    super.onInit();
    readArguments();
  }

  /// Re-reads the route arguments and restarts the resend countdown.
  ///
  /// Called on every entry, not just on first build: `Get.put` returns the
  /// controller registered by an earlier pass through forgot-password, and its
  /// `onInit` will not fire a second time. Without this the screen keeps the
  /// previous run's email address and a countdown that has already expired.
  void readArguments() {
    final args = Get.arguments;
    if (args != null && args is Map) {
      if (args['email'] != null) email.value = args['email'].toString();
    }
    clearOtp();
    startTimer();
  }

  /// ✔ Keep the observable code in sync with the input field
  void onOtpChanged(String value) {
    otpCode.value = value;
  }

  /// ✔ Check if the full code has been entered
  bool isOtpComplete() => otpCode.value.length == otpLength;

  /// ✔ Wipe the entered code (used after a resend or a failed verification)
  void clearOtp({bool refocus = false}) {
    otpController.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
    otpCode.value = '';
    if (refocus) otpFocusNode.requestFocus();
  }

  /// Verify OTP and proceed to reset password
  Future<void> verifyAndProceed() async {
    if (isVerifying.value) return;

    final code = otpCode.value;
    if (code.length < otpLength) {
      Get.snackbar('auth.validation.error'.tr, 'auth.otp.error_incomplete'.tr);
      return;
    }

    isVerifying.value = true;
    try {
      final response = await _auth.verifyOtp(
        email: email.value,
        code: code,
        type: 'password_reset',
      );

      // The reset token is the only thing the next screen can act on: the code
      // has just been spent, so without a token there is nothing to reset with.
      // Navigating anyway landed the user on a password form that could only
      // ever fail.
      final data = response['data'] as Map<String, dynamic>?;
      final resetToken = data?['resetToken'] as String?;
      if (resetToken == null || resetToken.isEmpty) {
        clearOtp(refocus: true);
        Get.snackbar(
          'auth.validation.error'.tr,
          'auth.otp.verification_failed'.tr,
        );
        return;
      }

      Get.snackbar('auth.validation.success'.tr, 'auth.otp.verified_success'.tr);
      Get.toNamed(AppRoutes.resetPasswordScreen, arguments: {
        'email': email.value,
        'resetToken': resetToken,
      });
    } on AppException catch (e) {
      /// Wrong code — clear the boxes so the user can retype straight away
      clearOtp(refocus: true);
      Get.snackbar('auth.validation.error'.tr, e.message);
    } catch (_) {
      clearOtp(refocus: true);
      Get.snackbar('auth.validation.error'.tr, 'auth.otp.verification_failed'.tr);
    } finally {
      isVerifying.value = false;
    }
  }

  /// Resend OTP via API
  Future<void> resendCode() async {
    if (isResending.value) return;
    isResending.value = true;

    try {
      final response = await _auth.resendOtp(
        email: email.value,
        type: 'password_reset',
      );

      /// Clear previous OTP and put the cursor back on the first box
      clearOtp(refocus: true);

      /// Restart timer
      startTimer();

      // Same conditional wording as the email screen — the API cannot say
      // whether anything was actually sent without giving away who has an
      // account here.
      final data = response['data'];
      final message = (data is Map && data['message'] is String)
          ? data['message'] as String
          : 'auth.otp.resend_message'.tr;
      Get.snackbar('auth.otp.resend_title'.tr, message);
    } on AppException catch (e) {
      Get.snackbar('auth.validation.error'.tr, e.message);
    } catch (_) {
      Get.snackbar(
        'auth.validation.error'.tr,
        'auth.forgot_password.send_failed_error'.tr,
      );
    } finally {
      isResending.value = false;
    }
  }

  /// Start countdown timer for OTP resend
  void startTimer() {
    secondsRemaining.value = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    otpController.dispose();
    otpFocusNode.dispose();
    super.onClose();
  }
}
