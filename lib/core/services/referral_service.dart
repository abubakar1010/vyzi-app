import 'api_service.dart';
import '../constants/api_constants.dart';
import '../exceptions/app_exceptions.dart';
import '../../features/profile/invite_friends/models/referral_model.dart';

/// ReferralService handles referral-related API calls.
class ReferralService {
  final ApiService _api = ApiService();

  /// Fetches the user's referral code, share link, and stats.
  Future<ReferralCodeResponse> getMyCode() async {
    try {
      final resp = await _api.get(ApiConstants.getMyReferralCode);
      final data = resp.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return ReferralCodeResponse.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      }

      throw ServerException(_extractMessage(data));
    } on AppException {
      rethrow;
    } catch (e) {
      throw ParsingException(e.toString());
    }
  }

  /// Fetches the user's referral list.
  Future<List<ReferralItem>> getMyReferrals() async {
    try {
      final resp = await _api.get(ApiConstants.getListMyReferral);
      final data = resp.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final innerData = data['data'] as Map<String, dynamic>;
        final items = innerData['data'] as List;
        return items
            .map((e) => ReferralItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw ServerException(_extractMessage(data));
    } on AppException {
      rethrow;
    } catch (e) {
      throw ParsingException(e.toString());
    }
  }

  /// Creates a new referral invite.
  Future<void> createInvite({String? email, String? phone}) async {
    final body = <String, dynamic>{};
    if (email != null && email.isNotEmpty) body['referredEmail'] = email;
    if (phone != null && phone.isNotEmpty) body['referredPhone'] = phone;

    try {
      final resp = await _api.post(ApiConstants.createReferral, data: body);
      final data = resp.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw ServerException(_extractMessage(data));
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw ParsingException(e.toString());
    }
  }

  String _extractMessage(Map<String, dynamic> data) {
    final msg = data['message'];
    if (msg is String) return msg;
    if (msg is List) return msg.map((e) => e.toString()).join(', ');
    return 'Unknown error';
  }
}
