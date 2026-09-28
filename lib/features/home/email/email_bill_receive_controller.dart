import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:get/get.dart';

class EmailBillReceivedController extends GetxController {
  void goToRequests() {
    NavHelper.switchTab(1);
  }

  void backToHome() {
    NavHelper.popToRoot();
    NavHelper.switchTab(0);
  }
}
