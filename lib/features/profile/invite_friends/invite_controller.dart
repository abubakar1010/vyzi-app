import 'package:vyzi/core/exceptions/app_exceptions.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/services/referral_service.dart';
import 'package:vyzi/core/utils/number_format.dart';

class InviteController extends GetxController {
  final ReferralService _service = ReferralService();

  // ── Referral data ──
  final referralLink = ''.obs;
  final referralCode = ''.obs;

  // ── Reward amounts ──
  final String youEarn = ApiConstants.referralYouEarn;
  final String friendGets = ApiConstants.referralFriendGets;

  // ── Statistics ──
  final invitesSent = 0.obs;
  final completedInvites = 0.obs;

  // ── Earnings ──
  final totalEarnings = 0.0.obs;
  String get earningsType => 'profile.invite.earnings_type'.tr;
  final earningsStatus = ''.obs;
  final progressAmount = formatMoney(0).obs;

  // ── State ──
  final isLoading = false.obs;
  final isCopied = false.obs;
  final errorMessage = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    fetchReferralData();
  }

  /// Fetches the user's referral code, share link, and stats from the API.
  Future<void> fetchReferralData() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final codeData = await _service.getMyCode();
      referralCode.value = codeData.referralCode;
      referralLink.value = codeData.shareLink;
      invitesSent.value = codeData.stats.totalInvites;
      completedInvites.value = codeData.stats.rewarded;
      totalEarnings.value = codeData.stats.totalEarnings;
      earningsStatus.value =
          totalEarnings.value > 0 ? 'profile.invite.earnings_status'.tr : '';
      progressAmount.value = formatMoney(totalEarnings.value);
    } catch (e) {
      errorMessage.value = (e is AppException ? e.message : 'system.unexpected'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  // ── Copy referral link to clipboard ──
  Future<void> copyLink() async {
    if (referralLink.value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: referralLink.value));
    isCopied.value = true;
    await Future.delayed(const Duration(seconds: 2));
    isCopied.value = false;
  }

  // ── Share link via native share sheet ──
  Future<void> shareLink() async {
    if (referralLink.value.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(
        text: '${'profile.invite.share_text'.tr}: ${referralLink.value}',
      ),
    );
  }
}
