import 'package:get/get.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/exceptions/app_exceptions.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/core/services/storage_service.dart';
import 'package:vyzi/features/legal/models/legal_document_model.dart';

/// Consent state for the signed-in user.
///
/// Two responsibilities: telling the app whether the user still owes an
/// acceptance (so the gate can be raised before they reach the home screen),
/// and recording the acceptance once they give it.
class LegalController extends GetxController {
  final ApiService _api = ApiService();

  /// Documents the user still has to accept, each with its full content.
  final RxList<LegalDocumentModel> pending = <LegalDocumentModel>[].obs;

  /// Every document that binds this account, content omitted. Backs the
  /// "accepted v2.1 on 3 March" line under each Settings entry.
  final RxList<LegalDocumentModel> documents = <LegalDocumentModel>[].obs;

  final RxBool isChecking = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxString error = ''.obs;

  /// Set when the server rejected an acceptance because the document was
  /// republished while the prompt was open. A flag rather than a check against
  /// the error text, which is translated and would stop matching in Italian.
  final RxBool versionConflict = false.obs;

  /// Guards against two launches racing to raise the gate — the navbar mounts
  /// and a token refresh can both ask within the same frame.
  bool _checkInFlight = false;

  bool get requiresAction => pending.isNotEmpty;

  String get _locale {
    try {
      return Get.find<StorageService>().getString(StorageKeys.selectedLanguage) ??
          'it';
    } catch (_) {
      return 'it';
    }
  }

  /// Whether there is a session to ask about.
  ///
  /// Every endpoint behind this controller is authenticated, so calling one
  /// while signed out is not merely useless: the 401 reaches the Dio
  /// interceptor, which finds no refresh token and force-logs-out. On the
  /// registration screen that replaces the half-filled form with sign-in and a
  /// "session expired" toast, for a user who never had a session to expire.
  bool get _isAuthenticated {
    try {
      final token =
          Get.find<StorageService>().getString(StorageKeys.authToken) ?? '';
      return token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Fetches the documents awaiting acceptance.
  ///
  /// Deliberately quiet on failure: a user who is offline, or hitting a server
  /// that has not been updated yet, must not be locked out of the app by a
  /// consent check that could not run. The gate is raised only on a definite
  /// "yes, something is pending".
  Future<bool> checkPending() async {
    if (!_isAuthenticated) {
      pending.clear();
      return false;
    }
    if (_checkInFlight) return requiresAction;
    _checkInFlight = true;
    isChecking.value = true;
    error.value = '';

    try {
      final response = await _api.get(
        ApiConstants.legalPending,
        queryParameters: {'locale': _locale},
      );
      final body = response.data as Map<String, dynamic>;

      if (body['success'] != true) {
        pending.clear();
        return false;
      }

      final data = body['data'] as Map<String, dynamic>? ?? const {};
      final raw = data['documents'] as List<dynamic>? ?? const [];

      pending.assignAll(
        raw
            .whereType<Map<String, dynamic>>()
            .map(LegalDocumentModel.fromJson)
            .toList(),
      );

      return pending.isNotEmpty;
    } catch (_) {
      pending.clear();
      return false;
    } finally {
      isChecking.value = false;
      _checkInFlight = false;
    }
  }

  /// Loads the acceptance status of every applicable document, for Settings.
  Future<void> loadDocuments() async {
    if (!_isAuthenticated) return;

    try {
      final response = await _api.get(
        ApiConstants.legalDocuments,
        queryParameters: {'locale': _locale},
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) return;

      final data = body['data'] as Map<String, dynamic>? ?? const {};
      final raw = data['documents'] as List<dynamic>? ?? const [];

      documents.assignAll(
        raw
            .whereType<Map<String, dynamic>>()
            .map(LegalDocumentModel.fromJson)
            .toList(),
      );
    } catch (_) {
      // Settings degrades to plain entries without the accepted-version line.
    }
  }

  /// Status for one slug, or null when it does not apply to this account.
  LegalDocumentModel? documentFor(String slug) {
    for (final doc in documents) {
      if (doc.slug == slug) return doc;
    }
    return null;
  }

  /// Records acceptance of [docs]. Returns true once nothing is outstanding.
  ///
  /// Unlike [checkPending] this surfaces failures: the user pressed a button
  /// and is waiting on it, and a silent no-op would leave them tapping Accept
  /// on a screen that never closes.
  Future<bool> accept(List<LegalDocumentModel> docs) async {
    if (docs.isEmpty) return true;

    isSubmitting.value = true;
    error.value = '';
    versionConflict.value = false;

    try {
      final response = await _api.post(
        ApiConstants.legalAccept,
        data: {
          'acceptances':
              docs.map((doc) => doc.toAcceptancePayload()).toList(),
        },
      );
      final body = response.data as Map<String, dynamic>;

      if (body['success'] != true) {
        error.value = 'legal.accept_failed'.tr;
        return false;
      }

      final data = body['data'] as Map<String, dynamic>? ?? const {};
      final remaining = data['documents'] as List<dynamic>? ?? const [];

      pending.assignAll(
        remaining
            .whereType<Map<String, dynamic>>()
            .map(LegalDocumentModel.fromJson)
            .toList(),
      );

      return data['requiresAction'] != true;
    } on ServerException catch (e) {
      // 400 means a new version landed while the screen was open. Re-fetching
      // swaps in the newer document rather than leaving the user pressing
      // Accept against text the server will keep rejecting.
      if (e.statusCode == 400) {
        // Re-fetch first: checkPending clears `error` as it starts, so setting
        // the message before it would leave the caller with an empty error and
        // no idea the acceptance was refused.
        await checkPending();
        versionConflict.value = true;
        error.value = 'legal.version_changed'.tr;
      } else {
        error.value = e.message;
      }
      return false;
    } on AppException catch (e) {
      error.value = e.message;
      return false;
    } catch (_) {
      error.value = 'legal.accept_failed'.tr;
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Clears state on sign-out so the next account starts from a blank slate.
  void reset() {
    pending.clear();
    documents.clear();
    error.value = '';
    versionConflict.value = false;
  }
}
