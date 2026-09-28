import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/core/services/notification_service.dart';
import 'package:vyzi/core/services/storage_service.dart';

/// Italian first: the app starts in Italian and only switches to English when
/// the user picks it. The device language is deliberately not consulted.
class LanguageController extends GetxController {
  final currentLocale = const Locale('it', 'IT').obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  void _loadSavedLanguage() {
    final storage = Get.find<StorageService>();
    final savedLang = storage.getString(StorageKeys.selectedLanguage);
    if (savedLang != null) {
      final locale = _getLocaleFromCode(savedLang);
      currentLocale.value = locale;
    }
  }

  void changeLanguage(String langCode) {
    final locale = _getLocaleFromCode(langCode);
    currentLocale.value = locale;
    Get.updateLocale(locale);

    final storage = Get.find<StorageService>();
    storage.setString(StorageKeys.selectedLanguage, langCode);

    if (Get.isRegistered<NotificationService>()) {
      Get.find<NotificationService>().updateChannelLanguage(currentLanguageCode);
    }
    syncToServer();
  }

  /// Stores the app language on the account.
  ///
  /// Push notifications are rendered by the server in the language saved on
  /// the account, which defaults to Italian — so without this an English user
  /// would keep receiving Italian pushes. A failure is only logged: the next
  /// sign-in or language change sends it again.
  Future<void> syncToServer() async {
    final storage = Get.find<StorageService>();
    if (!(storage.getBool(StorageKeys.isLoggedIn) ?? false)) return;
    try {
      await ApiService().patch(
        ApiConstants.myPreferences,
        data: {'language': currentLanguageCode == 'en' ? 'english' : 'italiano'},
      );
    } catch (e) {
      debugPrint('Failed to sync the language preference: $e');
    }
  }

  Locale _getLocaleFromCode(String code) {
    switch (code) {
      case 'en':
        return const Locale('en', 'US');
      case 'it':
      default:
        return const Locale('it', 'IT');
    }
  }

  String get currentLanguageCode {
    return currentLocale.value.languageCode;
  }
}
