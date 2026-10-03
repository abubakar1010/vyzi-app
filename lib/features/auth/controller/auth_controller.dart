import 'package:get/get.dart';
import 'package:vyzi/core/services/auth_service.dart';
import 'package:vyzi/core/services/notification_service.dart';
import 'package:vyzi/core/services/social_auth_service.dart';
import 'package:vyzi/core/services/storage_service.dart';
import 'package:vyzi/features/legal/controller/legal_controller.dart';
import 'package:vyzi/features/notifications/controller/notification_controller.dart';
import 'package:vyzi/core/exceptions/app_exceptions.dart';
import 'package:vyzi/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _auth = AuthService();
  final SocialAuthService _socialAuth = SocialAuthService();

  var isLoading = false.obs;
  var error = ''.obs;

  /// Registers user and returns the response map on success.
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    String? phone,
    required String role,
    String? companyName,
    String? partitaIva,
    String? codiceFiscale,
    String? referralCode,
    bool acceptedTerms = true,
  }) async {
    isLoading.value = true;
    error.value = '';
    try {
      final res = await _auth.register(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        role: role,
        companyName: companyName,
        partitaIva: partitaIva,
        codiceFiscale: codiceFiscale,
        referralCode: referralCode,
        acceptedTerms: acceptedTerms,
      );
      return res;
    } on AppException catch (e) {
      error.value = e.message;
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String code,
    required String type,
  }) async {
    isLoading.value = true;
    error.value = '';
    try {
      final res = await _auth.verifyOtp(email: email, code: code, type: type);
      return res;
    } on AppException catch (e) {
      error.value = e.message;
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    error.value = '';
    try {
      final res = await _auth.login(email: email, password: password);

      // Persist tokens if present
      final data = res['data'] as Map<String, dynamic>?;
      if (data != null) {
        final accessToken = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        final user = data['user'] as Map<String, dynamic>?;

        final storage = Get.find<StorageService>();
        if (accessToken != null) await storage.setString(StorageKeys.authToken, accessToken);
        if (refreshToken != null) await storage.setString(StorageKeys.refreshToken, refreshToken);
        if (user != null) {
          if (user['id'] != null) await storage.setString(StorageKeys.userId, user['id'].toString());
          if (user['email'] != null) await storage.setString(StorageKeys.userEmail, user['email'].toString());
          if (user['firstName'] != null) await storage.setString(StorageKeys.userName, user['firstName'].toString());
          if (user['role'] != null) await storage.setString(StorageKeys.userRole, user['role'].toString());
        }
        await storage.setBool(StorageKeys.isLoggedIn, true);

        // Register FCM push token after successful login
        Get.find<NotificationService>().registerToken();
      }

      return res;
    } on AppException catch (e) {
      error.value = e.message;
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Performs social login: provider sign-in -> Firebase ID token -> backend auth -> persist tokens.
  ///
  /// [role] is the account type picked on the sign-up screen (`personal` or
  /// `business`). The backend applies it only when this call creates the
  /// account; the sign-in screen leaves it null. Without it a business user
  /// who tapped "Continue with Google" was silently given a personal account.
  ///
  /// [allowSignUp] false makes this login-only: the API answers 404 instead of
  /// creating an account for a social profile it does not know. The sign-in
  /// screen passes it, because the account type is chosen at sign-up and never
  /// changes afterwards — an account created from a screen that cannot ask the
  /// question would be stuck on the personal default for good.
  ///
  /// [acceptedTerms] is true when the screen showed the privacy and terms
  /// consent line; the backend then records the acceptance, and the user is
  /// not stopped by the acceptance prompt once inside the app.
  ///
  /// Throws [SocialAuthCancelledException] when the user backs out of the
  /// provider sheet — callers must treat that as "do nothing" and must not
  /// navigate. Any other failure throws with a localized [error] message set.
  Future<void> socialLogin(
    SocialProvider provider, {
    String? role,
    bool allowSignUp = true,
    bool acceptedTerms = false,
  }) async {
    // A second tap while the provider sheet is still open starts a competing
    // request, which on Android cancels the one already in flight. Reject the
    // re-entrant call the same way a user cancellation is rejected, so the
    // caller neither navigates nor shows an error.
    if (isLoading.value) {
      throw SocialAuthCancelledException(
        'auth.social.error.cancelled'.tr,
        'reentrant-call',
      );
    }

    isLoading.value = true;
    error.value = '';
    try {
      final idToken = await _socialAuth.signIn(provider);

      final Map<String, dynamic> res;
      try {
        res = await _auth.socialLogin(
          idToken: idToken,
          role: role,
          allowSignUp: allowSignUp,
          acceptedTerms: acceptedTerms,
        );
      } catch (_) {
        // The provider leg succeeded, so the device is now signed in to
        // Firebase and to Google with no app session behind it. Left that way
        // the next tap re-uses the silent Google session and fails again the
        // same way, and `logout()` — the only other caller of `signOut()` —
        // is unreachable because the user never got in. Undo the half-login
        // before the error travels on.
        await _socialAuth.signOut();
        rethrow;
      }

      final data = res['data'] as Map<String, dynamic>?;
      if (data != null) {
        final accessToken = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        final user = data['user'] as Map<String, dynamic>?;

        final storage = Get.find<StorageService>();
        if (accessToken != null) await storage.setString(StorageKeys.authToken, accessToken);
        if (refreshToken != null) await storage.setString(StorageKeys.refreshToken, refreshToken);
        if (user != null) {
          if (user['id'] != null) await storage.setString(StorageKeys.userId, user['id'].toString());
          if (user['email'] != null) await storage.setString(StorageKeys.userEmail, user['email'].toString());
          if (user['firstName'] != null) await storage.setString(StorageKeys.userName, user['firstName'].toString());
          if (user['role'] != null) await storage.setString(StorageKeys.userRole, user['role'].toString());
        }
        await storage.setBool(StorageKeys.isLoggedIn, true);

        // Register FCM push token after successful social login
        Get.find<NotificationService>().registerToken();
      }
    } on SocialAuthCancelledException {
      // Not a failure — leave `error` empty so no message is surfaced.
      rethrow;
    } on AppException catch (e) {
      error.value = e.message;
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    isLoading.value = true;
    error.value = '';
    try {
      final res = await _auth.forgotPassword(email: email);
      return res;
    } on AppException catch (e) {
      error.value = e.message;
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    isLoading.value = true;
    error.value = '';
    try {
      final res = await _auth.resetPassword(resetToken: resetToken, newPassword: newPassword);
      return res;
    } on AppException catch (e) {
      error.value = e.message;
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Revokes the refresh token on the server, clears all local auth data,
  /// and navigates to the sign-in screen.
  Future<void> logout() async {
    final storage = Get.find<StorageService>();

    // Remove FCM push token before clearing auth (needs auth header for API call)
    try {
      await Get.find<NotificationService>().removePushToken();
    } catch (_) {}

    // Fire-and-forget server logout — don't block on network
    final token = storage.getString(StorageKeys.refreshToken);
    if (token != null && token.isNotEmpty) {
      _auth.logoutFromServer(refreshToken: token).ignore();
    }

    await _socialAuth.signOut();

    // The consent controller is permanent, so without this the next account to
    // sign in on this device would inherit the previous user's acceptances.
    if (Get.isRegistered<LegalController>()) {
      Get.find<LegalController>().reset();
    }

    // Same reasoning for notifications: the controller is permanent, so
    // without this the next account would open to the previous user's unread
    // badge and notification list.
    NotificationController.reset();

    await storage.remove(StorageKeys.authToken);
    await storage.remove(StorageKeys.refreshToken);
    await storage.remove(StorageKeys.userId);
    await storage.remove(StorageKeys.userName);
    await storage.remove(StorageKeys.userEmail);
    await storage.remove(StorageKeys.userRole);
    await storage.setBool(StorageKeys.isLoggedIn, false);
    Get.offAllNamed(AppRoutes.signInScreen);
  }

  Future<Map<String, dynamic>> refreshToken({required String refreshToken}) async {
    isLoading.value = true;
    error.value = '';
    try {
      final res = await _auth.refreshToken(refreshToken: refreshToken);

      // update stored tokens
      final data = res['data'] as Map<String, dynamic>?;
      if (data != null) {
        final accessToken = data['accessToken'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;
        final storage = Get.find<StorageService>();
        if (accessToken != null) await storage.setString(StorageKeys.authToken, accessToken);
        if (newRefreshToken != null) await storage.setString(StorageKeys.refreshToken, newRefreshToken);
      }

      return res;
    } on AppException catch (e) {
      error.value = e.message;
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}
