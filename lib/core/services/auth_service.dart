import 'api_service.dart';
import '../constants/api_constants.dart';
import '../exceptions/app_exceptions.dart';

/// AuthService contains high-level auth API calls used by controllers.
/// Each method returns the parsed response map on success or throws AppException on error.
class AuthService {
  final ApiService _api = ApiService();

  /// Registers a new user.
  /// [role] should be either 'personal' or 'business'. [referralCode] is optional.
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
    final body = {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'role': role,
      // Required by the API whenever role is business — omitting them made
      // every business sign-up fail validation before it reached the database.
      if (companyName != null && companyName.isNotEmpty)
        'companyName': companyName,
      if (partitaIva != null && partitaIva.isNotEmpty) 'partitaIva': partitaIva,
      // The person's own tax code, which a business sign-up is required to
      // give. Without it the account reaches the switch request form with an
      // empty mandatory field the sign-up never mentioned, and the direct debit
      // mandate cannot be filed against anybody.
      if (codiceFiscale != null && codiceFiscale.isNotEmpty)
        'codiceFiscale': codiceFiscale,
      if (referralCode != null && referralCode.isNotEmpty) 'referralCode': referralCode,
      // The sign-up checkbox. Recorded server-side against the current terms
      // version, which is what stops the consent gate asking again the moment
      // the user reaches the home screen.
      'acceptedTerms': acceptedTerms,
    };

    try {
      final resp = await _api.post(ApiConstants.authRegister, data: body);
      final data = resp.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return data;
      }

      // API returned success=false — normalise error message
      final msg = _extractApiMessage(data);
      throw ServerException(msg, data['statusCode'] as int?);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ParsingException(e.toString());
    }
  }

  /// Verifies OTP (used for sign-up email verification and forgot-password flows)
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String code,
    required String type, // e.g. "email_verification"
  }) async {
    final body = {'email': email, 'code': code, 'type': type};
    try {
      final resp = await _api.post(ApiConstants.authVerifyOtp, data: body);
      final data = resp.data as Map<String, dynamic>;
      if (data['success'] == true) return data;
      final msg = _extractApiMessage(data);
      throw ServerException(msg, data['statusCode'] as int?);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ParsingException(e.toString());
    }
  }

  /// Login with email/password. Returns full response map including tokens on success.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final body = {'email': email, 'password': password};
    try {
      final resp = await _api.post(ApiConstants.authLogin, data: body);
      final data = resp.data as Map<String, dynamic>;
      if (data['success'] == true) return data;
      final msg = _extractApiMessage(data);
      throw ServerException(msg, data['statusCode'] as int?);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ParsingException(e.toString());
    }
  }

  /// Authenticates via social provider. Sends Firebase ID token to backend.
  ///
  /// [role] is the account type chosen on the sign-up screen. It is sent only
  /// when there is one to send — the sign-in screen has no such choice — and
  /// the backend applies it only when the call creates a new account.
  ///
  /// [allowSignUp] false makes the call login-only: with no account matching
  /// the social profile the API answers 404 rather than creating one. The
  /// sign-in screen sends it, because the account type is chosen at sign-up
  /// and never changes, and an account created from a screen with no such
  /// choice would be stuck on the personal default for good.
  Future<Map<String, dynamic>> socialLogin({
    required String idToken,
    String? role,
    bool allowSignUp = true,
  }) async {
    final body = <String, dynamic>{
      'idToken': idToken,
      if (role != null && role.isNotEmpty) 'role': role,
      if (!allowSignUp) 'allowSignUp': false,
    };
    try {
      final resp = await _api.post(ApiConstants.authSocialLogin, data: body);
      final data = resp.data as Map<String, dynamic>;
      if (data['success'] == true) return data;
      final msg = _extractApiMessage(data);
      throw ServerException(msg, data['statusCode'] as int?);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ParsingException(e.toString());
    }
  }

  /// Resends OTP code to the user's email.
  /// [type] should be 'email_verification' or 'password_reset'.
  Future<Map<String, dynamic>> resendOtp({
    required String email,
    required String type,
  }) async {
    final body = {'email': email, 'type': type};
    try {
      final resp = await _api.post(ApiConstants.authResendOtp, data: body);
      final data = resp.data as Map<String, dynamic>;
      if (data['success'] == true) return data;
      final msg = _extractApiMessage(data);
      throw ServerException(msg, data['statusCode'] as int?);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ParsingException(e.toString());
    }
  }

  /// Triggers forgot-password flow: sends reset code if email exists.
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    final body = {'email': email};
    try {
      final resp = await _api.post(ApiConstants.authForgotPassword, data: body);
      final data = resp.data as Map<String, dynamic>;
      if (data['success'] == true) return data;
      final msg = _extractApiMessage(data);
      throw ServerException(msg, data['statusCode'] as int?);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ParsingException(e.toString());
    }
  }

  /// Reset password using the resetToken handed back by verify-otp.
  ///
  /// [resetToken] is required. The previous fallback here posted
  /// `{email, newPassword}` without a code whenever the token was missing,
  /// which the API rejects outright — the user saw "could not reset password"
  /// with no way to tell that the app, not their code, was at fault. There is
  /// no valid fallback: this flow always goes through verify-otp first, and
  /// verify-otp spends the code, so the raw code cannot be replayed here.
  Future<Map<String, dynamic>> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    if (resetToken.isEmpty) {
      throw ServerException(
        'Your reset session has expired. Please request a new code.',
        400,
      );
    }
    final body = {'resetToken': resetToken, 'newPassword': newPassword};
    try {
      final resp = await _api.post(ApiConstants.authResetPassword, data: body);
      final data = resp.data as Map<String, dynamic>;
      if (data['success'] == true) return data;
      final msg = _extractApiMessage(data);
      throw ServerException(msg, data['statusCode'] as int?);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ParsingException(e.toString());
    }
  }

  /// Calls backend to revoke the refresh token on logout.
  Future<void> logoutFromServer({required String refreshToken}) async {
    try {
      await _api.post(ApiConstants.authLogout, data: {'refreshToken': refreshToken});
    } catch (_) {
      // Best-effort — don't block local logout if server call fails
    }
  }

  /// Refreshes access token using refresh token
  Future<Map<String, dynamic>> refreshToken({required String refreshToken}) async {
    final body = {'refreshToken': refreshToken};
    try {
      final resp = await _api.post(ApiConstants.authRefreshToken, data: body);
      final data = resp.data as Map<String, dynamic>;
      if (data['success'] == true) return data;
      final msg = _extractApiMessage(data);
      throw ServerException(msg, data['statusCode'] as int?);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ParsingException(e.toString());
    }
  }

  /// Utility to extract message text from API error payloads.
  String _extractApiMessage(Map<String, dynamic> data) {
    try {
      final msg = data['message'];
      if (msg == null) return 'Unknown error';
      if (msg is String) return msg;
      if (msg is List) return msg.map((e) => e.toString()).join(', ');
      return msg.toString();
    } catch (_) {
      return 'Unknown error';
    }
  }
}
