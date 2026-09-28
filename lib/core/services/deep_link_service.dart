import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/services/storage_service.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/routes/app_routes.dart';

/// Handles incoming deep links (Universal Links / App Links) for the referral
/// flow. Parses referral codes from URLs like `https://domain/r/CODE`.
///
/// Cold-start links are stored as [pendingReferralCode] and consumed by the
/// splash screen. Warm-start links (app already running) navigate immediately.
class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  String? _pendingReferralCode;

  /// The referral code extracted from a deep link, if any.
  /// Consumed by the splash screen to decide navigation.
  String? get pendingReferralCode => _pendingReferralCode;

  /// Whether the splash screen has already navigated.
  /// Used to decide if warm-start links should navigate immediately.
  bool _splashCompleted = false;

  /// Call once from main.dart after services are initialized.
  Future<void> init() async {
    // 1. Check for stored deferred referral code (from previous install)
    final storage = Get.find<StorageService>();
    final storedCode = storage.getString(StorageKeys.pendingReferralCode);
    if (storedCode != null && storedCode.isNotEmpty) {
      _pendingReferralCode = storedCode;
    }

    // 2. Check initial link (cold start — app opened via deep link)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _extractReferralCode(initialUri);
      }
    } catch (e) {
      debugPrint('DeepLinkService: failed to get initial link: $e');
    }

    // 3. Listen for subsequent links (warm start — app already running)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        final code = _extractReferralCode(uri);
        if (code != null && _splashCompleted) {
          _processReferralCode(code);
        }
      },
      onError: (err) {
        debugPrint('DeepLinkService: link stream error: $err');
      },
    );
  }

  /// Mark the splash screen as done. After this, incoming links will
  /// navigate immediately instead of storing for later.
  void markSplashCompleted() {
    _splashCompleted = true;
  }

  /// Extract a referral code from a URI like `https://domain/r/ABC123`.
  /// Returns the code if found, stores it in [_pendingReferralCode].
  String? _extractReferralCode(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length == 2 && segments[0] == 'r') {
      final code = segments[1].trim().toUpperCase();
      if (code.isNotEmpty) {
        _pendingReferralCode = code;
        return code;
      }
    }
    return null;
  }

  /// Route based on auth state (used for warm-start links).
  void _processReferralCode(String code) {
    final storage = Get.find<StorageService>();
    final isLoggedIn = storage.getBool(StorageKeys.isLoggedIn) ?? false;
    final token = storage.getString(StorageKeys.authToken);

    if (isLoggedIn && token != null && token.isNotEmpty) {
      showReferralNotAvailableDialog();
    } else {
      // The account-type chooser rather than the sign-up form: the type is
      // picked there and nowhere else. The code travels with it and is filled
      // in on the form the chooser leads to.
      Get.offAllNamed(
        AppRoutes.onboardScreen,
        arguments: {'referralCode': code},
      );
    }
    _pendingReferralCode = null;
  }

  /// Show a dialog explaining that referral codes are only for new accounts.
  void showReferralNotAvailableDialog() {
    _pendingReferralCode = null;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'referral.not_available_title'.tr,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text('referral.not_available_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
            ),
            child: Text('common.ok'.tr),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  /// Clear any pending referral code from memory and storage.
  Future<void> clearPendingReferralCode() async {
    _pendingReferralCode = null;
    final storage = Get.find<StorageService>();
    await storage.remove(StorageKeys.pendingReferralCode);
  }

  /// Store a referral code for deferred deep linking (survives app restart).
  Future<void> storeDeferredReferralCode(String code) async {
    final storage = Get.find<StorageService>();
    await storage.setString(StorageKeys.pendingReferralCode, code);
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
