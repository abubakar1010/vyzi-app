import 'dart:ui';
import 'package:get/get.dart';
import 'package:vyzi/core/services/storage_service.dart';

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
