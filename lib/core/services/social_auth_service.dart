import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../exceptions/app_exceptions.dart';

/// Supported social authentication providers.
enum SocialProvider { google, facebook, apple }

/// Handles provider-specific sign-in flows via Firebase Auth.
/// Returns the Firebase ID token string on success.
class SocialAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// The project's **web** OAuth client — the `client_type: 3` entry in
  /// `android/app/google-services.json`. Google mints the ID token with this
  /// client as its audience, so it must belong to the same Firebase project as
  /// `google-services.json` / `GoogleService-Info.plist`. If it ever diverges,
  /// sign-in fails with a configuration error on every device.
  static const String serverClientId =
      '703974828285-2od94eufnf121bgpomqtc2vfagk15t96.apps.googleusercontent.com';

  /// `GoogleSignIn.initialize()` must be called **exactly once per process**
  /// and be awaited before any other call — the plugin documents repeated
  /// calls as undefined behaviour. The future is therefore static and shared:
  /// concurrent callers await the same initialization, and a failed attempt
  /// clears it so the next sign-in can retry.
  static Future<void>? _googleInit;

  /// Whether Google sign-in has been initialized at least once, so [signOut]
  /// knows if it is safe to talk to the plugin.
  static bool get _googleReady => _googleInit != null;

  /// Signs in with the specified [provider] and returns a Firebase ID token.
  ///
  /// Throws [SocialAuthCancelledException] if the user aborted the flow, or
  /// [SocialAuthException] for any genuine failure.
  Future<String> signIn(SocialProvider provider) async {
    try {
      final UserCredential credential;
      switch (provider) {
        case SocialProvider.google:
          credential = await _signInWithGoogle();
        case SocialProvider.facebook:
          credential = await _signInWithFacebook();
        case SocialProvider.apple:
          credential = await _signInWithApple();
      }

      final idToken = await credential.user?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        _log('Firebase returned no ID token after ${provider.name} sign-in');
        throw SocialAuthException('auth.social.error.no_firebase_token'.tr);
      }
      return idToken;
    } on AppException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      _log('FirebaseAuthException on ${provider.name} sign-in: '
          'code=${e.code} message=${e.message}');
      throw SocialAuthException(
        _firebaseAuthMessage(e),
        'firebase:${e.code}',
      );
    } catch (e, stack) {
      _log('Unexpected error on ${provider.name} sign-in: $e\n$stack');
      throw SocialAuthException(
        'auth.social.error.generic'.tr,
        e.toString(),
      );
    }
  }

  /// Signs out from Firebase Auth and all social providers.
  Future<void> signOut() async {
    // Only reachable once Google sign-in has been initialized; calling the
    // plugin before `initialize()` is undefined behaviour.
    if (_googleReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        _log('Google signOut failed (ignored): $e');
      }
    }
    try {
      await FacebookAuth.instance.logOut();
    } catch (e) {
      _log('Facebook logOut failed (ignored): $e');
    }
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      _log('Firebase signOut failed (ignored): $e');
    }
  }

  // ── Google ──────────────────────────────────────────────

  Future<UserCredential> _signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      throw _mapGoogleException(e);
    }

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      // Google authenticated the user but issued no ID token, which means the
      // request carried no usable server client.
      _log('Google returned no ID token for ${account.email}. '
          'Verify that serverClientId ($serverClientId) is the web OAuth '
          'client (client_type 3) of this Firebase project.');
      throw SocialAuthException(
        'auth.social.error.configuration'.tr,
        'google:missing-id-token',
      );
    }

    return _firebaseAuth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  /// Initializes the Google sign-in plugin once per process.
  static Future<void> _ensureGoogleInitialized() async {
    // Both the caller that starts the initialization and the callers that
    // join an in-flight one await inside the same try, so a failure is
    // reported as a configuration error either way. Returning the shared
    // future directly let the second caller escape with the plugin's raw
    // PlatformException, which surfaced to the user as the generic
    // "something went wrong" instead of naming the real cause.
    final future = _googleInit ??= GoogleSignIn.instance.initialize(
      serverClientId: serverClientId,
    );

    try {
      await future;
    } catch (e) {
      // Allow a later attempt to initialize again. Guarded so a retry already
      // in flight is not discarded by a straggler awaiting the failed one.
      if (identical(_googleInit, future)) _googleInit = null;
      _log('GoogleSignIn.initialize() failed: $e');
      throw SocialAuthException(
        'auth.social.error.configuration'.tr,
        'google:initialize-failed: $e',
      );
    }
  }

  /// Translates a [GoogleSignInException] into a typed app exception.
  ///
  /// Every branch logs the raw code and description first: the Credential
  /// Manager SDK on Android surfaces several configuration problems as a
  /// cancellation or as [GoogleSignInExceptionCode.unknownError], so the raw
  /// values are the only way to tell a real user cancellation from a broken
  /// setup.
  AppException _mapGoogleException(GoogleSignInException e) {
    _log('GoogleSignInException code=${e.code.name} '
        'description=${e.description} details=${e.details}');

    final diagnostic = 'google:${e.code.name}: ${e.description ?? ''}';

    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        // Android reports misconfiguration (most often an unregistered signing
        // SHA-1) as a cancellation, so leave a breadcrumb for the next report.
        _log('If the user did not cancel, this is almost always a Google '
            'configuration problem — check that the signing SHA-1 of this '
            'build is registered for package com.vyzi in the Firebase '
            'console, then re-download google-services.json.');
        return SocialAuthCancelledException(
          'auth.social.error.cancelled'.tr,
          diagnostic,
        );

      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return SocialAuthException(
          'auth.social.error.configuration'.tr,
          diagnostic,
        );

      case GoogleSignInExceptionCode.uiUnavailable:
      case GoogleSignInExceptionCode.interrupted:
        return SocialAuthException(
          'auth.social.error.interrupted'.tr,
          diagnostic,
        );

      case GoogleSignInExceptionCode.unknownError:
      case GoogleSignInExceptionCode.userMismatch:
        // The Android SDK funnels "Developer console is not set up correctly"
        // (error 28444) and DEVELOPER_ERROR (10) through unknownError.
        return SocialAuthException(
          _looksLikeConfigurationError(e.description)
              ? 'auth.social.error.configuration'.tr
              : 'auth.social.error.generic'.tr,
          diagnostic,
        );
    }
  }

  /// Detects the Google/Play-Services strings that always mean "this app is not
  /// registered correctly", regardless of the error code they arrive under.
  static bool _looksLikeConfigurationError(String? description) {
    if (description == null) return false;
    final text = description.toLowerCase();
    return text.contains('28444') ||
        text.contains('developer console') ||
        text.contains('developer_error') ||
        text.contains('not set up correctly') ||
        text.contains('unregistered');
  }

  String _firebaseAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'auth.social.error.account_exists'.tr;
      case 'invalid-credential':
      case 'invalid-verification-code':
      case 'invalid-verification-id':
        return 'auth.social.error.configuration'.tr;
      case 'operation-not-allowed':
        return 'auth.social.error.provider_disabled'.tr;
      case 'user-disabled':
        return 'auth.social.error.user_disabled'.tr;
      case 'network-request-failed':
        return 'auth.social.error.network'.tr;
      default:
        // Firebase's own text is English and technical; it goes in the
        // diagnostic, never on screen.
        return 'auth.social.error.generic'.tr;
    }
  }

  // ── Facebook ────────────────────────────────────────────

  Future<UserCredential> _signInWithFacebook() async {
    final result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    if (result.status == LoginStatus.cancelled) {
      throw SocialAuthCancelledException(
        'auth.social.error.cancelled'.tr,
        'facebook:cancelled',
      );
    }
    if (result.status != LoginStatus.success || result.accessToken == null) {
      _log('Facebook login failed: status=${result.status} '
          'message=${result.message}');
      throw SocialAuthException(
        'auth.social.error.generic'.tr,
        'facebook:${result.status.name}: ${result.message ?? ''}',
      );
    }

    final credential = FacebookAuthProvider.credential(
      result.accessToken!.tokenString,
    );
    return _firebaseAuth.signInWithCredential(credential);
  }

  // ── Apple ───────────────────────────────────────────────

  Future<UserCredential> _signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final AuthorizationCredentialAppleID appleCredential;
    try {
      appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      _log('SignInWithAppleAuthorizationException code=${e.code} '
          'message=${e.message}');
      if (e.code == AuthorizationErrorCode.canceled) {
        throw SocialAuthCancelledException(
          'auth.social.error.cancelled'.tr,
          'apple:canceled',
        );
      }
      throw SocialAuthException(
        'auth.social.error.generic'.tr,
        'apple:${e.code.name}: ${e.message}',
      );
    }

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );
    return _firebaseAuth.signInWithCredential(oauthCredential);
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static void _log(String message) =>
      developer.log(message, name: 'SocialAuthService');
}
