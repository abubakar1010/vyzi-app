import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys that contain sensitive data and must be stored in encrypted storage.
const _secureKeys = {StorageKeys.authToken, StorageKeys.refreshToken};

/// A clean-architecture wrapper around [SharedPreferences] for persistent
/// key-value storage, with [FlutterSecureStorage] for sensitive auth tokens.
///
/// [StorageService] is registered as a singleton in [DependencyInjection]
/// and is available app-wide via `Get.find<StorageService>()`.
///
/// **Supported Types:** `String`, `int`, `double`, `bool`, `List<String>`
///
/// **Usage:**
/// ```dart
/// final storage = Get.find<StorageService>();
///
/// // Write
/// await storage.setString(StorageKeys.authToken, 'abc123');
/// await storage.setBool(StorageKeys.isLoggedIn, true);
///
/// // Read
/// final token = storage.getString(StorageKeys.authToken);
/// final isLoggedIn = storage.getBool(StorageKeys.isLoggedIn) ?? false;
///
/// // Remove
/// await storage.remove(StorageKeys.authToken);
///
/// // Clear all stored data
/// await storage.clear();
/// ```
///
/// **Initialization:**
/// Called automatically via [DependencyInjection.init()] before the app runs.
/// Do not call [init] manually unless in tests.
class StorageService {
  late SharedPreferences _prefs;
  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // In-memory cache for secure values so getString can stay synchronous.
  final Map<String, String> _secureCache = {};

  /// Initializes the underlying [SharedPreferences] instance and preloads
  /// secure values into an in-memory cache for synchronous reads.
  ///
  /// This is called once during app startup via [DependencyInjection.init()].
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Preload secure keys into memory so getString remains synchronous.
    for (final key in _secureKeys) {
      final value = await _secure.read(key: key);
      if (value != null) _secureCache[key] = value;
    }
  }

  // ─── String ──────────────────────────────────────────────────────────────

  Future<bool> setString(String key, String value) {
    if (_secureKeys.contains(key)) {
      _secureCache[key] = value;
      return _secure.write(key: key, value: value).then((_) => true);
    }
    return _prefs.setString(key, value);
  }

  String? getString(String key) {
    if (_secureKeys.contains(key)) return _secureCache[key];
    return _prefs.getString(key);
  }

  // ─── Int ─────────────────────────────────────────────────────────────────

  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  int? getInt(String key) => _prefs.getInt(key);

  // ─── Double ──────────────────────────────────────────────────────────────

  Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);

  double? getDouble(String key) => _prefs.getDouble(key);

  // ─── Bool ────────────────────────────────────────────────────────────────

  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  bool? getBool(String key) => _prefs.getBool(key);

  // ─── List<String> ────────────────────────────────────────────────────────

  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  List<String>? getStringList(String key) => _prefs.getStringList(key);

  // ─── Utility ─────────────────────────────────────────────────────────────

  /// Returns `true` if [key] exists in storage.
  bool containsKey(String key) {
    if (_secureKeys.contains(key)) return _secureCache.containsKey(key);
    return _prefs.containsKey(key);
  }

  /// Removes a single [key] from storage.
  Future<bool> remove(String key) {
    if (_secureKeys.contains(key)) {
      _secureCache.remove(key);
      return _secure.delete(key: key).then((_) => true);
    }
    return _prefs.remove(key);
  }

  /// Removes all stored data. Use with caution.
  Future<bool> clear() async {
    _secureCache.clear();
    await _secure.deleteAll();
    return _prefs.clear();
  }

  /// Returns every key currently stored (SharedPreferences keys only).
  Set<String> getKeys() => _prefs.getKeys();
}

/// Predefined key constants for [StorageService].
///
/// Always use these constants instead of raw strings to avoid typos
/// and to have a single source of truth for all storage keys.
///
/// **Usage:**
/// ```dart
/// await storage.setString(StorageKeys.authToken, token);
/// final token = storage.getString(StorageKeys.authToken);
/// ```
///
/// Add new keys here as your feature set grows.
abstract class StorageKeys {
  StorageKeys._();

  // ─── Auth ─────────────────────────────────────────────────────────────────
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String isLoggedIn = 'is_logged_in';

  // ─── User ─────────────────────────────────────────────────────────────────
  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String userRole = 'user_role';

  // ─── App Settings ─────────────────────────────────────────────────────────
  static const String isDarkMode = 'is_dark_mode';
  static const String selectedLanguage = 'selected_language';
  static const String isFirstLaunch = 'is_first_launch';

  // ─── Onboarding ────────────────────────────────────────────────────────
  static const String hasSeenHome = 'has_seen_home';

  // ─── Deep Linking ──────────────────────────────────────────────────────
  static const String pendingReferralCode = 'pending_referral_code';

  // ─── Push Notifications ───────────────────────────────────────────────
  static const String fcmToken = 'fcm_token';
}

