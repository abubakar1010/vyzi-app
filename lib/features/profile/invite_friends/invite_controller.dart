import 'package:vyzi/core/exceptions/app_exceptions.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vyzi/core/services/referral_service.dart';
import 'package:vyzi/core/utils/number_format.dart';
import 'package:vyzi/features/profile/invite_friends/models/referral_model.dart';

class InviteController extends GetxController {
  final ReferralService _service = ReferralService();

  // ── Referral data ──
  final referralLink = ''.obs;
  final referralCode = ''.obs;

  // ── Reward amounts (configured on the server) ──
  final youEarn = ''.obs;
  final friendGets = ''.obs;

  /// The user's own reward for joining with an invite, if they did.
  final welcomeReward = Rxn<WelcomeReward>();

  // ── Statistics ──
  final invitesSent = 0.obs;
  final joinedInvites = 0.obs;
  final completedInvites = 0.obs;

  // ── The friends this user referred ──
  final referrals = <ReferralItem>[].obs;
  final referralsFailed = false.obs;

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
      final listFuture = _loadReferrals();
      final codeData = await _service.getMyCode();
      referralCode.value = codeData.referralCode;
      referralLink.value = codeData.shareLink;
      youEarn.value = formatMoney(codeData.rewards.referrerAmount);
      friendGets.value = formatMoney(codeData.rewards.friendAmount);
      welcomeReward.value = codeData.welcomeReward;
      invitesSent.value = codeData.stats.totalInvites;
      joinedInvites.value = codeData.stats.registered;
      // A friend's switch going live is what makes an invite count as done;
      // payment comes later and is shown under earnings.
      completedInvites.value = codeData.stats.qualified;
      totalEarnings.value = codeData.stats.totalEarnings;
      earningsStatus.value =
          totalEarnings.value > 0 ? 'profile.invite.earnings_status'.tr : '';
      progressAmount.value = formatMoney(totalEarnings.value);
      await listFuture;
    } catch (e) {
      errorMessage.value = (e is AppException ? e.message : 'system.unexpected'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  /// The referral list. A failure here leaves the rest of the screen usable.
  Future<void> _loadReferrals() async {
    referralsFailed.value = false;
    try {
      referrals.assignAll(await _service.getMyReferrals());
    } catch (_) {
      referrals.clear();
      referralsFailed.value = true;
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
