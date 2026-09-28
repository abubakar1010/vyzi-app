import 'package:get/get.dart';

import 'package:flutter/material.dart';

import '../../features/bills/screen/bill_detail_screen.dart';
import '../../features/home/sign_contract/sign_contract.dart';
import '../../features/request/request_offers_focus.dart';
import '../../routes/app_routes.dart';
import '../navbar/nav_helper.dart';
import '../navbar/navbar_controller.dart';

/// Where a notification opens, in one place.
///
/// A customer can act on the same notification three ways — a push tapped from
/// the system tray, the heads-up popup shown while the app is open, and a row
/// in the Notifications section — and each of those used to carry its own copy
/// of the destination table. They had already drifted: the list screen sat on a
/// row it had no route for, while a tapped push opened the notification centre.
/// One table means a destination can only be wrong everywhere at once.
class NotificationRouter {
  NotificationRouter._();

  /// Route a tapped push, whose payload is the FCM `data` map. Every value in
  /// it is a string — FCM will not carry anything else — including the `type`
  /// the server copies in from the notification row.
  static void openFromPush(Map<String, dynamic> data) {
    open(
      type: _string(data['type']) ?? 'general',
      data: data,
      // A push with a type this build does not know still has to go somewhere.
      fallbackToNotificationCentre: true,
    );
  }

  /// Route a row tapped in the Notifications section, where the type is a
  /// column of its own and the deep-link keys are in `data`.
  static void openFromList({
    required String type,
    Map<String, dynamic>? data,
  }) {
    // The list *is* the notification centre, so an unknown type stays put
    // rather than pushing a second copy of the screen the tap came from.
    open(type: type, data: data, fallbackToNotificationCentre: false);
  }

  static void open({
    required String type,
    Map<String, dynamic>? data,
    bool fallbackToNotificationCentre = false,
  }) {
    final payload = data ?? const <String, dynamic>{};
    final billId = _string(payload['billId']);
    final ticketId = _string(payload['ticketId']);

    switch (type) {
      // "New offers recommended for you". The offers themselves are the point
      // of the message, so this lands on the list of them — not on the request
      // detail, which only reports that they were sent.
      case 'offer_available':
        openOffersForBill(billId);
        break;
      // `bill_analyzed` and `bill_updated` are both retired triggers. They
      // stay in the table because rows already delivered still carry them.
      case 'bill_analyzed':
      case 'bill_updated':
      case 'bill_verification':
      case 'activation_complete':
        _toScreen(billId, (id) => BillDetailScreen(billId: id),
            fallbackToNotificationCentre);
        break;
      // "Your contract is ready to sign" — the signing screen carries the
      // supplier's instructions and the walkthrough.
      // `contract_verification` is never sent any more; notifications already
      // delivered still route here.
      case 'contract_verification':
      case 'contract_status':
        _toScreen(billId, (id) => SignContractScreen(billId: id),
            fallbackToNotificationCentre);
        break;
      case 'case_update':
        _toScreen(billId, (id) => BillDetailScreen(billId: id),
            fallbackToNotificationCentre);
        break;
      case 'referral_status':
        Get.toNamed(AppRoutes.inviteFriendsScreen);
        break;
      case 'support_reply':
        _toRoute(AppRoutes.ticketDetailScreen, ticketId,
            fallbackToNotificationCentre);
        break;
      default:
        if (fallbackToNotificationCentre) {
          Get.toNamed(AppRoutes.notificationsScreen);
        }
    }
  }

  /// Open Request → Your Offers, showing the offers sent for [billId].
  ///
  /// The scope is parked before the tab is switched to, so a tab mounting for
  /// the first time — the cold start out of a tapped push — already has it.
  static void openOffersForBill(String? billId) {
    if (billId != null && billId.isNotEmpty) {
      RequestOffersFocus.requestBill(billId);
    }
    _returnToShell();
    NavHelper.switchTab(NavTabs.request);
  }

  /// Bring the tab shell back to the front, from wherever the tap happened.
  ///
  /// A notification can be acted on from three places at once: a full-screen
  /// route pushed on the root navigator (a bill detail opened from an earlier
  /// notification), a screen pushed inside a tab (the Notifications section is
  /// pushed onto the Home tab), or the shell itself. Switching tabs without
  /// clearing those would move the tab underneath a page that stays on top.
  ///
  /// Nothing happens when the shell is not in the stack at all — a cold start
  /// still on the splash, or a signed-out session. The parked scope is what
  /// carries the intent across; the tab applies it when it mounts.
  static void _returnToShell() {
    if (!NavHelper.returnToShell()) return;
    NavHelper.popToRoot();
  }

  /// Open the screen [build]s from the notification's id inside the request
  /// tab, or fall back to the notification centre when there is no id.
  ///
  /// These open inside the shell rather than on top of it: a bill detail
  /// pushed onto the root navigator carries no bottom bar, and the screens it
  /// leads on to — the signing screen, the service details — would be pushed
  /// onto a tab navigator hidden behind it.
  static void _toScreen(
    String? billId,
    Widget Function(String id) build,
    bool fallback,
  ) {
    if (billId != null && billId.isNotEmpty) {
      NavHelper.openInTab(NavTabs.request, build(billId));
    } else if (fallback) {
      Get.toNamed(AppRoutes.notificationsScreen);
    }
  }

  /// Push [route] with [argument], or fall back to the notification centre
  /// when the notification carries no id to open.
  static void _toRoute(String route, String? argument, bool fallback) {
    if (argument != null && argument.isNotEmpty) {
      Get.toNamed(route, arguments: argument);
    } else if (fallback) {
      Get.toNamed(AppRoutes.notificationsScreen);
    }
  }

  /// FCM stringifies every payload value, so a push id arrives as a string
  /// while the same key read off a stored notification is whatever the server
  /// wrote. Anything that is neither is not an id.
  static String? _string(dynamic value) => value is String ? value : null;
}
