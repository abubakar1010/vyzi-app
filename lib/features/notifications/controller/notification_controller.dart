import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/notification_model.dart';

/// Owns the notification list and the unread badge count.
///
/// This is an app-lifetime singleton on purpose. The badge (home header) and
/// the notification list screen must read the *same* [unreadCount], and the
/// instance must not be torn down when a route is popped — with GetX's default
/// `SmartManagement.full`, a controller created by a plain `Get.put()` inside a
/// widget is linked to the route that built it and gets deleted with it. When
/// that happened the badge kept a dead instance while the screen registered a
/// fresh one, and the count silently stopped moving. Always reach the
/// controller through [to] (or the static helpers below) — never `Get.put()`.
class NotificationController extends GetxController with WidgetsBindingObserver {
  /// The single shared instance, created on first use and kept permanently.
  static NotificationController get to =>
      Get.isRegistered<NotificationController>()
          ? Get.find<NotificationController>()
          : Get.put(NotificationController(), permanent: true);

  /// The instance *if it already exists*. Used by callers that must not force
  /// it into existence — e.g. a push arriving before the user has signed in.
  static NotificationController? get _existing =>
      Get.isRegistered<NotificationController>()
          ? Get.find<NotificationController>()
          : null;

  /// A push just landed while the app was in the foreground.
  static void notifyPushReceived() => _existing?._onPushReceived();

  /// Something happened that may have changed the unread count (a push was
  /// tapped, a screen that consumes notifications was opened, …).
  static void notifyMayHaveChanged() =>
      _existing?.refreshUnreadCount(force: true);

  /// Drop every trace of the signed-in user's notifications.
  static void reset() => _existing?.clear();

  final _api = ApiService();

  final notifications = <NotificationModel>[].obs;
  final unreadCount = 0.obs;
  final isLoading = false.obs;
  final currentPage = 1.obs;
  final totalPages = 1.obs;
  final total = 0.obs;

  /// De-duplicates concurrent count fetches - resume, tab switch and a push can
  /// all fire within the same frame.
  Future<void>? _countInFlight;
  int _countRequestToken = 0;

  /// Whose notifications are currently in [notifications] / [unreadCount].
  /// The controller outlives a sign-out, and not every sign-out runs through
  /// `AuthController.logout()` - an expired refresh token force-logs-out from
  /// the Dio interceptor, which cannot call in here without a layering cycle.
  /// Comparing the stored user id on every read catches those paths too.
  String? _loadedForUserId;

  StorageService? get _storage =>
      Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;

  bool get _isLoggedIn => _storage?.getBool(StorageKeys.isLoggedIn) ?? false;

  String? get _currentUserId => _storage?.getString(StorageKeys.userId);

  /// Drops state that belongs to a different (or no) user before it can be
  /// shown to the current one.
  void _dropStateIfUserChanged() {
    final userId = _currentUserId;
    if (_loadedForUserId != userId) {
      _loadedForUserId = userId;
      clear();
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Pushes that arrived while the app was backgrounded are handled by a
    // separate isolate and can never touch this controller, so the count is
    // always stale on resume. Refetch it there.
    WidgetsBinding.instance.addObserver(this);
    fetchNotifications();
    refreshUnreadCount();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshUnreadCount(force: true);
    }
  }

  Future<void> fetchNotifications({int page = 1}) async {
    _dropStateIfUserChanged();
    if (!_isLoggedIn) return;
    try {
      isLoading.value = true;
      final response = await _api.get(
        '${ApiConstants.notifications}?page=$page&limit=20',
      );

      final body = response.data as Map<String, dynamic>;
      if (body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        final items = (data['data'] as List<dynamic>?)
                ?.map((e) =>
                    NotificationModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

        if (page == 1) {
          notifications.value = items;
        } else {
          notifications.addAll(items);
        }

        final meta = data['meta'] as Map<String, dynamic>?;
        currentPage.value = meta?['page'] as int? ?? page;
        totalPages.value = meta?['totalPages'] as int? ?? 1;
        total.value = meta?['total'] as int? ?? 0;
      }
    } catch (e) {
      debugPrint('Failed to fetch notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Re-reads the unread count from the server. Safe to call often - the
  /// server is the only source of truth for the badge, and overlapping calls
  /// share one request.
  ///
  /// [force] chains a fresh request behind any in-flight one instead of
  /// joining it. Callers that have just changed the count must force: the
  /// in-flight reply was computed before their change and would undo it.
  Future<void> refreshUnreadCount({bool force = false}) {
    final inFlight = _countInFlight;
    if (inFlight != null && !force) return inFlight;

    final token = ++_countRequestToken;
    final next = (inFlight ?? Future<void>.value())
        .then((_) => _fetchUnreadCount())
        .whenComplete(() {
      if (_countRequestToken == token) _countInFlight = null;
    });
    _countInFlight = next;
    return next;
  }

  Future<void> _fetchUnreadCount() async {
    _dropStateIfUserChanged();
    if (!_isLoggedIn) {
      unreadCount.value = 0;
      return;
    }
    try {
      final response = await _api.get(ApiConstants.notificationsUnreadCount);
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        unreadCount.value = data['count'] as int? ?? 0;
      }
    } catch (e) {
      // Leave the last known count on screen — a dropped request is not
      // evidence that the user has nothing unread.
      debugPrint('Failed to fetch unread count: $e');
    }
  }

  /// A foreground push arrived. Show it on the badge immediately, then let the
  /// server confirm the real number.
  void _onPushReceived() {
    _dropStateIfUserChanged();
    if (!_isLoggedIn) return;
    unreadCount.value = unreadCount.value + 1;
    refreshUnreadCount(force: true);
    // The list, if the user opens it next, should already contain the new row.
    fetchNotifications();
  }

  Future<void> markAsRead(String id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    final wasUnread = index >= 0 && !notifications[index].isRead;

    // Optimistic: the badge moves on tap, not a round-trip later.
    if (wasUnread) _decrementUnread();

    try {
      final response = await _api.patch(ApiConstants.notificationMarkRead(id));
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == true) {
        final updated = NotificationModel.fromJson(
          body['data'] as Map<String, dynamic>,
        );
        final at = notifications.indexWhere((n) => n.id == id);
        if (at >= 0) notifications[at] = updated;
      } else if (wasUnread) {
        unreadCount.value = unreadCount.value + 1;
      }
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
      if (wasUnread) unreadCount.value = unreadCount.value + 1;
    }
  }

  Future<void> markAllAsRead() async {
    final previousCount = unreadCount.value;
    final previousItems = List<NotificationModel>.from(notifications);

    // Optimistic: clear the badge and grey the rows out straight away.
    unreadCount.value = 0;
    notifications.value = notifications.map(_asRead).toList();

    try {
      final response = await _api.patch(ApiConstants.notificationsMarkAllRead);
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == true) {
        // Reconcile with the server: read timestamps, and anything that
        // arrived between the optimistic flip and the response.
        await fetchNotifications(page: 1);
        await refreshUnreadCount(force: true);
      } else {
        notifications.value = previousItems;
        unreadCount.value = previousCount;
      }
    } catch (e) {
      debugPrint('Failed to mark all as read: $e');
      notifications.value = previousItems;
      unreadCount.value = previousCount;
    }
  }

  Future<void> loadMore() async {
    if (currentPage.value < totalPages.value) {
      await fetchNotifications(page: currentPage.value + 1);
    }
  }

  /// Re-reads both the list and the badge count.
  ///
  /// Named `refreshAll` rather than `refresh` because `GetxController` already
  /// has a `refresh()` (it notifies `GetBuilder` listeners); overriding it with
  /// a network call quietly breaks that.
  Future<void> refreshAll() async {
    await Future.wait([
      fetchNotifications(page: 1),
      refreshUnreadCount(force: true),
    ]);
  }

  /// Wipes user-scoped state. Called on logout — the controller is permanent,
  /// so without this the next account to sign in on this device would open to
  /// the previous user's badge count and list.
  void clear() {
    notifications.clear();
    unreadCount.value = 0;
    isLoading.value = false;
    currentPage.value = 1;
    totalPages.value = 1;
    total.value = 0;
  }

  void _decrementUnread() {
    if (unreadCount.value > 0) unreadCount.value = unreadCount.value - 1;
  }

  NotificationModel _asRead(NotificationModel n) => n.isRead
      ? n
      : NotificationModel(
          id: n.id,
          userId: n.userId,
          title: n.title,
          body: n.body,
          type: n.type,
          data: n.data,
          isRead: true,
          readAt: n.readAt ?? DateTime.now().toIso8601String(),
          createdAt: n.createdAt,
          updatedAt: n.updatedAt,
        );
}
