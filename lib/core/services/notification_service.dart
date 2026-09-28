import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../features/notifications/controller/notification_controller.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';
import 'notification_router.dart';
import 'storage_service.dart';

/// Top-level background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message received: ${message.messageId}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'vyzi_default',
    'VYZI Notifications',
    description: 'Notifications from VYZI',
    importance: Importance.high,
  );

  /// Initialize FCM, local notifications, and request permissions.
  Future<void> init() async {
    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Initialize local notifications plugin
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Request notification permissions
    await _requestPermissions();

    // Set foreground notification presentation options (iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Listen for notification taps (app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification that launched the app (app was terminated)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Delay navigation to allow app to fully initialize
      Future.delayed(const Duration(seconds: 1), () {
        _handleNotificationTap(initialMessage);
      });
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _sendTokenToServer(newToken);
    });
  }

  /// Request notification permissions from the user.
  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  /// Register FCM token with the backend.
  Future<void> registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _sendTokenToServer(token);
      }
    } catch (e) {
      debugPrint('Failed to get/register FCM token: $e');
    }
  }

  /// Send the FCM token to the backend server.
  Future<void> _sendTokenToServer(String token) async {
    try {
      final storage = Get.find<StorageService>();
      final isLoggedIn = storage.getBool(StorageKeys.isLoggedIn) ?? false;
      if (!isLoggedIn) return;

      // Store locally
      await storage.setString(StorageKeys.fcmToken, token);

      // Register with backend
      final platform = Platform.isIOS ? 'ios' : 'android';
      await ApiService().post(
        ApiConstants.registerPushToken,
        data: {'token': token, 'platform': platform},
      );
      debugPrint('FCM token registered with backend');
    } catch (e) {
      debugPrint('Failed to send FCM token to server: $e');
    }
  }

  /// Remove the push token from the backend (call on logout).
  Future<void> removePushToken() async {
    try {
      final storage = Get.find<StorageService>();
      final token = storage.getString(StorageKeys.fcmToken) ?? '';
      if (token.isNotEmpty) {
        await ApiService().delete(ApiConstants.removePushToken(token));
        await storage.remove(StorageKeys.fcmToken);
      }
    } catch (e) {
      debugPrint('Failed to remove push token: $e');
    }
  }

  /// Handle foreground FCM messages — show a local notification.
  void _handleForegroundMessage(RemoteMessage message) {
    // The server persists the notification row before it sends the push, so
    // the badge can be moved as soon as the message lands. Data-only messages
    // count too, which is why this runs before the early return below.
    NotificationController.notifyPushReceived();

    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Handle notification tap when app is in background/foreground.
  void _handleNotificationTap(RemoteMessage message) {
    _navigateFromNotification(message.data);
  }

  /// Handle local notification tap.
  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      _navigateFromNotification({'type': 'general'});
      return;
    }
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateFromNotification(data);
    } catch (_) {
      // Fallback: treat payload as plain type string (backward compat)
      _navigateFromNotification({'type': payload});
    }
  }

  /// Navigate to the appropriate screen based on notification data.
  void _navigateFromNotification(Map<String, dynamic> data) {
    // Reached from a background tap, a terminated-app launch and a local
    // notification tap -- in the first two cases the push was handled by
    // another isolate, so this is the app's first chance to see it.
    NotificationController.notifyMayHaveChanged();

    NotificationRouter.openFromPush(data);
  }
}
