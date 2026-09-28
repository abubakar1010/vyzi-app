import 'package:vyzi/core/exceptions/app_exceptions.dart';
import 'package:vyzi/core/services/auth_service.dart';
import 'package:vyzi/features/auth/password_succesfull.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResetPasswordController extends GetxController {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final AuthService _auth = AuthService();

  var ispasswordHidden = true.obs;
  var isConfirmPasswordHidden = true.obs;
  var isLoading = false.obs;

  var email = ''.obs;
  var resetToken = ''.obs;

  @override
  void onInit() {
    super.onInit();
    readArguments();
  }

  /// Re-reads the route arguments and clears the form.
  ///
  /// Must be called every time the screen is entered, not just on first build.
  /// `Get.put` hands back the controller that is already registered, so on a
  /// second pass through forgot-password `onInit` never fires again and the
  /// controller keeps the *first* run's reset token — a token the server
  /// deleted the moment that first reset succeeded. The user got "could not
  /// reset password" on every attempt after the first one in a session.
  void readArguments() {
    final args = Get.arguments;
    if (args != null && args is Map) {
      email.value = args['email'] ?? '';
      resetToken.value = args['resetToken'] ?? '';
    }
    passwordController.clear();
    confirmPasswordController.clear();
  }

  void toggleNewPasswordVisibility() {
    ispasswordHidden.value = !ispasswordHidden.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
  }

  Future<void> resetPassword() async {
    final newPassword = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      Get.snackbar('auth.validation.error'.tr, 'auth.reset_password.empty_error'.tr);
      return;
    }

    if (newPassword.length < 8) {
      Get.snackbar('auth.validation.error'.tr, 'auth.reset_password.min_length_error'.tr);
      return;
    }

    if (!RegExp(r'[a-z]').hasMatch(newPassword)) {
      Get.snackbar('auth.validation.error'.tr, 'auth.reset_password.lowercase_error'.tr);
      return;
    }

    if (!RegExp(r'[A-Z]').hasMatch(newPassword)) {
      Get.snackbar('auth.validation.error'.tr, 'auth.reset_password.uppercase_error'.tr);
      return;
    }

    if (!RegExp(r'\d').hasMatch(newPassword)) {
      Get.snackbar('auth.validation.error'.tr, 'auth.reset_password.number_error'.tr);
      return;
    }

    if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"|,.<>/?\\]').hasMatch(newPassword)) {
      Get.snackbar('auth.validation.error'.tr, 'auth.reset_password.special_char_error'.tr);
      return;
    }

    if (newPassword != confirmPassword) {
      Get.snackbar('auth.validation.error'.tr, 'auth.reset_password.mismatch'.tr);
      return;
    }

    isLoading.value = true;
    try {
      await _auth.resetPassword(
        resetToken: resetToken.value,
        newPassword: newPassword,
      );
      Get.offAll(() => PasswordUpdateSuccessScreen());
      Get.snackbar('auth.validation.success'.tr, 'auth.reset_password.success_message'.tr);
    } on AppException catch (e) {
      // The server's own wording, not a blanket "could not reset password":
      // an expired token, a reused code and a password matching the current
      // one all need different things from the user, and the flat message left
      // them retyping the same password into the same dead session.
      Get.snackbar('auth.validation.error'.tr, e.message);
    } catch (_) {
      Get.snackbar('auth.validation.error'.tr, 'auth.reset_password.failed_error'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
