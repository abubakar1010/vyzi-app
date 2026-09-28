import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'core/services/cache_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/system_ui_service.dart';

import 'core/controllers/language_controller.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (must be before any Firebase service usage)
  await Firebase.initializeApp();

  // Register background message handler (must be top-level)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize cache service
  await CacheService().init();

  // Initialize and register StorageService as a singleton
  final storageService = StorageService();
  await storageService.init();
  Get.put<StorageService>(storageService, permanent: true);

  // Initialize deep link service (must be after StorageService)
  final deepLinkService = DeepLinkService();
  await deepLinkService.init();
  Get.put<DeepLinkService>(deepLinkService, permanent: true);

  // Initialize notification service (must be after Firebase + StorageService)
  final notificationService = NotificationService();
  await notificationService.init();
  Get.put<NotificationService>(notificationService, permanent: true);

  // Initialize language controller (must be after StorageService)
  Get.put(LanguageController(), permanent: true);

  // Register Italian locale for timeago
  timeago.setLocaleMessages('it', timeago.ItMessages());

  // Month and weekday names for dates written with DateFormat, in both
  // languages the app speaks.
  await initializeDateFormatting('it');
  await initializeDateFormatting('en');

  // Pre-cache Open Sans font - downloads once and caches for offline use
  GoogleFonts.config.allowRuntimeFetching = true;

  // Pre-load Open Sans font to cache it on first run
  try {
    await Future.wait([
      GoogleFonts.pendingFonts([GoogleFonts.openSans()]),
    ]);
  } catch (e) {
    // If offline or font loading fails, app will use fallback fonts
    debugPrint('Font pre-caching failed: $e');
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Enable edge-to-edge display
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Set system UI overlay style (theme-aware via SystemUiService)
  SystemUiService.setDefaultStyle();

  runApp(const MyApp());
}

