import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/exceptions/app_exceptions.dart';
import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/features/home/email/email_bill_receive_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class EmailBillController extends GetxController {
  var email = "bills@utility-analyzer.com".obs;
  var isCreating = false.obs;

  String billType = 'electricity';

  /// Copy Email
  void copyEmail() {
    Clipboard.setData(ClipboardData(text: email.value));
    Get.snackbar(
      "Copied",
      "Email copied to clipboard",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black,
      colorText: Colors.white,
    );
  }

  /// Button Action - create email bill request via API then navigate
  Future<void> onEmailSent() async {
    isCreating.value = true;
    try {
      final response = await ApiService().post(
        ApiConstants.createEmailBillRequest,
        data: {'billType': billType},
      );
      if (response.data['success'] == true) {
        NavHelper.push(EmailBillReceivedScreen());
      } else {
        final msg = response.data['message']?.toString() ?? 'Failed to create request';
        Get.snackbar(
          'Error',
          msg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } on AppException catch (e) {
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create email bill request',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isCreating.value = false;
    }
  }
}
