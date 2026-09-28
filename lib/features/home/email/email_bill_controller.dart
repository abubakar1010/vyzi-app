import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/constants/contact_constants.dart';
import 'package:vyzi/core/exceptions/app_exceptions.dart';
import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/features/home/email/email_bill_receive_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class EmailBillController extends GetxController {
  final email = ContactConstants.billInbox.obs;
  var isCreating = false.obs;

  String billType = 'electricity';

  /// Copy Email
  Future<void> copyEmail() async {
    await Clipboard.setData(ClipboardData(text: email.value));
    Get.snackbar(
      'common.copied'.tr,
      'home.email_bill.copied'.tr,
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
        Get.snackbar(
          'auth.validation.error'.tr,
          'home.email_bill.failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } on AppException catch (e) {
      Get.snackbar(
        'auth.validation.error'.tr,
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'auth.validation.error'.tr,
        'home.email_bill.failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isCreating.value = false;
    }
  }
}
