import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  // Keys
  static const String _accessTokenKey = 'token';
  static const String _isLoginKey = 'isLogin';
  static const String _userIdKey = 'userId';
  static const String _userEmailKey = 'userEmail';
  static const String _userPhoneKey = 'userPhone';
  static const String _userFirstNameKey = 'userFirstName';
  static const String _userLastNameKey = 'userLastName';
  static const String _fcmTokenKey = 'fcmToken';
  static const String _profileImageKey = 'profileImage';



  static Future<void> saveUserData({
    required String token,
    required String userId,
    required String email,
    required String phone,
    required String firstName,
    required String lastName,
    required String fcmToken,

  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userPhoneKey, phone);
    await prefs.setString(_userFirstNameKey, firstName);
    await prefs.setString(_userLastNameKey, lastName);
    await prefs.setString(_fcmTokenKey, fcmToken);
    await prefs.setBool(_isLoginKey, true);
  }

  /// ✅ Save token only
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
    await prefs.setBool(_isLoginKey, true);
  }

  /// ✅ Save FCM token only
  static Future<void> saveFcmToken(String fcmToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, fcmToken);
  }


  // 🔹 Getters
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneKey);
  }

  static Future<String?> getUserFirstName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userFirstNameKey);
  }

  static Future<String?> getUserLastName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userLastNameKey);
  }

  static Future<String?> getProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileImageKey);
  }

  // Setters
  static Future<void> saveProfileImage(String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImageKey, imageUrl);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoginKey) ?? false;
  }

  /// Remove FCM token
  static Future<void> removeFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fcmTokenKey);
  }

  /// ✅ Clear all stored data
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
