import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/services/auth_service.dart';
import 'package:vyzi/core/services/notification_service.dart';
import 'package:vyzi/core/services/storage_service.dart';
import 'package:vyzi/routes/app_routes.dart';
import 'package:vyzi/features/auth/controller/auth_controller.dart';

class CreateAccountOtpController extends GetxController {
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
  final AuthService _auth = AuthService();

  var email = ''.obs;

  @override
  void onInit() {
    super.onInit();
    startTimer();

    // Read passed arguments (email, type) if provided
    final args = Get.arguments;
    if (args != null && args is Map) {
      if (args['email'] != null) email.value = args['email'].toString();
    }
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

  /// Verify OTP for account creation
  Future<void> verifyAndProceed() async {
    if (isVerifying.value) return;

    final code = otpCode.value;
    if (code.length < otpLength) {
      Get.snackbar('auth.validation.error'.tr, 'auth.otp.error_incomplete'.tr);
      return;
    }

    isVerifying.value = true;
    final auth = Get.put(AuthController());
    try {
      final res = await auth.verifyOtp(email: email.value, code: code, type: 'email_verification');

      // Verifying the address completes sign-up and the API hands back a
      // session with it. Everything below hangs off the access token actually
      // being there: marking the app logged in without one used to drop the
      // new account on the home screen with no credentials, where the first
      // request 401'd and the interceptor forced it back out to login.
      final data = res['data'] as Map<String, dynamic>?;
      final accessToken = data?['accessToken'] as String?;

      if (accessToken == null || accessToken.isEmpty) {
        // An older backend that verifies but issues no session. The account is
        // valid, so send them to sign-in rather than into a broken session.
        Get.snackbar('auth.validation.success'.tr, 'auth.otp.verified_success'.tr);
        Get.offAllNamed(AppRoutes.signInScreen);
        return;
      }

      final storage = Get.find<StorageService>();
      final refreshToken = data?['refreshToken'] as String?;
      final user = data?['user'] as Map<String, dynamic>?;

      await storage.setString(StorageKeys.authToken, accessToken);
      if (refreshToken != null) {
        await storage.setString(StorageKeys.refreshToken, refreshToken);
      }
      if (user != null) {
        if (user['id'] != null) await storage.setString(StorageKeys.userId, user['id'].toString());
        if (user['email'] != null) await storage.setString(StorageKeys.userEmail, user['email'].toString());
        if (user['firstName'] != null) await storage.setString(StorageKeys.userName, user['firstName'].toString());
        // Business accounts branch on this all over the app. Sign-up never
        // stored it, so a business account behaved as a personal one until it
        // next signed in.
        if (user['role'] != null) await storage.setString(StorageKeys.userRole, user['role'].toString());
      }
      await storage.setBool(StorageKeys.isLoggedIn, true);

      // Same as the login path — the device cannot receive push until its FCM
      // token is registered against the account.
      Get.find<NotificationService>().registerToken();

      Get.snackbar('auth.validation.success'.tr, 'auth.otp.verified_success'.tr);
      Get.offAllNamed('/navbarScreen');
    } catch (e) {
      /// Wrong code — clear the boxes so the user can retype straight away
      clearOtp(refocus: true);
      Get.snackbar('auth.validation.error'.tr, auth.error.value.isNotEmpty ? auth.error.value : 'auth.otp.verification_failed'.tr);
    } finally {
      isVerifying.value = false;
    }
  }

  /// Resend OTP via API
  Future<void> resendCode() async {
    if (isResending.value) return;
    isResending.value = true;

    try {
      await _auth.resendOtp(email: email.value, type: 'email_verification');

      /// Clear previous OTP and put the cursor back on the first box
      clearOtp(refocus: true);

      /// Restart timer
      startTimer();

      Get.snackbar('auth.otp.resend_title'.tr, 'auth.otp.resend_message'.tr);
    } catch (e) {
      final message = e.toString();
      Get.snackbar('auth.validation.error'.tr, message);
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
