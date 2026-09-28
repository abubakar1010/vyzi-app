import 'dart:async';

import 'package:get/get.dart';

import '../../core/services/storage_service.dart';

/// The "show me the offers for *this* request" intent, raised by a notification
/// tap and consumed by the Request tab's Your Offers list.
///
/// It is a parked intent rather than a direct call because the tab is not
/// always there to be called. A push tapped while the app is terminated is
/// handled from `main()`, before `runApp` — three seconds before the splash
/// screen finishes its session check and mounts the navbar. Navigating then
/// only gets undone by the splash's own `Get.offNamed`. So the bill is parked
/// here and whoever mounts the tab next picks it up.
class RequestOffersFocus {
  RequestOffersFocus._();

  static final _events = StreamController<String>.broadcast();

  /// Fires on every request, the same bill twice included — a customer who
  /// taps the same notification again expects the list to scope again, which
  /// a value-based notifier would swallow.
  ///
  /// The event carries the bill id for readability only; listeners take the
  /// value from [take] so that consuming it always clears it.
  static Stream<String> get stream => _events.stream;

  static String? _pendingBillId;
  static String? _pendingForUserId;

  /// Scope the Your Offers list to [billId].
  static void requestBill(String billId) {
    if (billId.isEmpty) return;
    _pendingBillId = billId;
    _pendingForUserId = _currentUserId;
    _events.add(billId);
  }

  /// The parked bill, if it belongs to whoever is signed in now. Reading it
  /// clears it: an intent is acted on once and never replayed on the next tab
  /// switch.
  ///
  /// The owner check is what stops a notification tapped by one account from
  /// scoping the next account's offers to a bill it does not own — which would
  /// show an empty list with no explanation. It is checked on read rather than
  /// cleared on the way out because not every sign-out runs through
  /// `AuthController.logout()`; an expired refresh token forces one straight
  /// from the Dio interceptor.
  static String? take() {
    final billId = _pendingBillId;
    final owner = _pendingForUserId;
    clear();
    if (billId == null) return null;
    return owner == _currentUserId ? billId : null;
  }

  static void clear() {
    _pendingBillId = null;
    _pendingForUserId = null;
  }

  static String? get _currentUserId => Get.isRegistered<StorageService>()
      ? Get.find<StorageService>().getString(StorageKeys.userId)
      : null;
}
