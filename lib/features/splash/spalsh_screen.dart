import 'dart:convert';

import 'package:vyzi/core/utils/app_assets.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/services/deep_link_service.dart';
import 'package:vyzi/core/services/storage_service.dart';
import 'package:vyzi/features/auth/controller/auth_controller.dart';
import 'package:vyzi/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';



class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {


  @override
  void initState() {
    super.initState();
    _checkUserSession();
  }

  Future<void> _checkUserSession() async {
    await Future.delayed(const Duration(seconds: 3));

    final storage = Get.find<StorageService>();
    final deepLinkService = Get.find<DeepLinkService>();

    final isLoggedIn = storage.getBool(StorageKeys.isLoggedIn) ?? false;
    final authToken = storage.getString(StorageKeys.authToken);

    // Mark splash as done so future warm-start links navigate immediately
    deepLinkService.markSplashCompleted();

    if (isLoggedIn && authToken != null && authToken.isNotEmpty) {
      // Check if the access token is expired
      if (_isTokenExpired(authToken)) {
        // Access token expired — attempt silent refresh
        final refreshToken = storage.getString(StorageKeys.refreshToken);
        if (refreshToken != null && refreshToken.isNotEmpty) {
          try {
            final authController = Get.put(AuthController());
            await authController.refreshToken(refreshToken: refreshToken);
            // Refresh succeeded — proceed to home
            Get.offNamed(AppRoutes.navbarScreen);
            _handlePendingReferral(deepLinkService, loggedIn: true);
            return;
          } catch (_) {
            // Refresh failed — clean up and go to sign-in
            await _clearStaleSession(storage);
            _handlePendingReferral(deepLinkService, loggedIn: false);
            return;
          }
        } else {
          // No refresh token — clean up and go to sign-in
          await _clearStaleSession(storage);
          _handlePendingReferral(deepLinkService, loggedIn: false);
          return;
        }
      }

      // Access token still valid — go to home
      Get.offNamed(AppRoutes.navbarScreen);
      _handlePendingReferral(deepLinkService, loggedIn: true);
    } else {
      // No active session
      _handlePendingReferral(deepLinkService, loggedIn: false);
    }
  }

  /// Decodes a JWT and checks whether its `exp` claim is in the past.
  /// Returns `true` if expired or cannot be decoded (safe default).
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      String payload = parts[1];
      // Pad to a multiple of 4 for base64 decoding
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> claims = jsonDecode(decoded);
      final exp = claims['exp'] as int?;
      if (exp == null) return true;

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return true;
    }
  }

  /// Clears stale auth state when tokens are expired.
  Future<void> _clearStaleSession(StorageService storage) async {
    await storage.remove(StorageKeys.authToken);
    await storage.remove(StorageKeys.refreshToken);
    await storage.remove(StorageKeys.userId);
    await storage.remove(StorageKeys.userName);
    await storage.remove(StorageKeys.userRole);
    await storage.remove(StorageKeys.userEmail);
    await storage.remove(StorageKeys.fcmToken);
    await storage.setBool(StorageKeys.isLoggedIn, false);
  }

  /// Handles pending referral deep link navigation.
  void _handlePendingReferral(DeepLinkService deepLinkService, {required bool loggedIn}) {
    final pendingCode = deepLinkService.pendingReferralCode;
    if (loggedIn) {
      if (pendingCode != null && pendingCode.isNotEmpty) {
        deepLinkService.showReferralNotAvailableDialog();
        deepLinkService.clearPendingReferralCode();
      }
    } else {
      if (pendingCode != null && pendingCode.isNotEmpty) {
        deepLinkService.clearPendingReferralCode();
        // Through the account-type chooser, not straight at the sign-up form.
        // The type is picked there and nowhere else, and a referral link that
        // jumped the queue landed every invited company on a personal account
        // it could never change. The code rides along and is filled in for
        // them once they get to the form.
        Get.offNamed(
          AppRoutes.onboardScreen,
          arguments: {'referralCode': pendingCode},
        );
      } else {
        Get.offNamed(AppRoutes.warmOnboardScreen);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Image.asset(
          AppAssets.logo,
          width: 180.w,
          height: 180.h,
        ),
      ),
    );
  }
}
