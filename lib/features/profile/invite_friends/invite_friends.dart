import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/utils/number_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'invite_controller.dart';

class InviteScreen extends StatelessWidget {
  InviteScreen({super.key});

  final InviteController _controller = Get.put(InviteController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Obx(() => _buildBody()),
    );
  }

  // ─────────────────────────────────────────────
  //  BODY (loading / error / content)
  // ─────────────────────────────────────────────

  Widget _buildBody() {
    if (_controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.errorMessage.value != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48.sp, color: AppColors.textSecondary),
              SizedBox(height: 12.h),
              Text(
                _controller.errorMessage.value!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () => _controller.fetchReferralData(),
                child: Text('common.retry'.tr),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _buildReferralCard(),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _buildRewardRow(),
          ),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'profile.invite.stats_title'.tr,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                height: 1.22,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _buildStatisticsCard(),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _buildEarningsCard(),
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  APP BAR
  // ─────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded,
            color: AppColors.textDark, size: 22.sp),
        onPressed: () => Get.back(),
      ),
      title: Text(
        'profile.invite.title'.tr,
        style: TextStyle(
          fontSize: 17.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
          height: 1.22,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HERO SECTION  (icon + title + subtitle)
  // ─────────────────────────────────────────────

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: EdgeInsets.only(top: 30.h, bottom: 10.h),
      child: Column(
        children: [
          // Gift icon in teal circle
          Container(
            width: 64.w,
            height: 64.w,
            decoration: const BoxDecoration(
              color: Color(0xFFE0F7F4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.card_giftcard_rounded,
              size: 32.sp,
              color: const Color(0xFF00B8A0),
            ),
          ),

          SizedBox(height: 16.h),

          Text(
            'profile.invite.hero_title'.tr,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              height: 1.22,
            ),
          ),

          SizedBox(height: 8.h),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              'profile.invite.hero_desc'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  REFERRAL LINK CARD
  // ─────────────────────────────────────────────

  Widget _buildReferralCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Label ──
          Text(
            'profile.invite.link_label'.tr,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.22,
            ),
          ),

          SizedBox(height: 10.h),

          // ── Link row with copy icon ──
          Container(
            padding:
            EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
            decoration: BoxDecoration(
              color: AppColors.invitebg,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _controller.referralLink.value,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                      height: 1.22,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () => _controller.copyLink(),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _controller.isCopied.value
                        ? Icon(
                      Icons.check_rounded,
                      key: const ValueKey('check'),
                      color: AppColors.linkGreen,
                      size: 20.sp,
                    )
                        : Icon(
                      Icons.copy_rounded,
                      key: const ValueKey('copy'),
                      color: AppColors.primaryColor,
                      size: 20.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 14.h),

          // ── Share link button ──
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton.icon(
              onPressed: () => _controller.shareLink(),
              icon: Icon(Icons.share_rounded, size: 18.sp),
              label: Text(
                'profile.invite.share_link'.tr,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.22,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.background,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  REWARD ROW  (You earn | Friend gets)
  // ─────────────────────────────────────────────

  Widget _buildRewardRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildRewardCard(
              icon: Icons.person_add_alt_1_rounded,
              iconBg: AppColors.greenAlpha10,
              iconColor: AppColors.green200,
              topLabel: 'profile.invite.you_earn'.tr,
              amount: _controller.youEarn,
              bottomLabel: 'profile.invite.you_earn_when'.tr,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildRewardCard(
              icon: Icons.group_rounded,
              iconBg: AppColors.primary100,
              iconColor: AppColors.accentBlue,
              topLabel: 'profile.invite.friend_gets'.tr,
              amount: _controller.friendGets,
              bottomLabel: 'profile.invite.friend_gets_when'.tr,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String topLabel,
    required String amount,
    required String bottomLabel,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.invitebg,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: iconColor, size: 20.sp),
          ),

          SizedBox(height: 12.h),

          // Top label
          Text(topLabel,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.22,
            ),
          ),

          SizedBox(height: 6.h),

          // Amount
          Text(
            amount,
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              height: 1.22,
            ),
          ),

          SizedBox(height: 8.h),

          // Bottom label
          Text(
            bottomLabel,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  STATISTICS CARD
  // ─────────────────────────────────────────────

  Widget _buildStatisticsCard() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildStatRow(
            icon: Icons.mail_outline_rounded,
            iconBg: AppColors.primary100,
            iconColor: AppColors.accentBlue,
            title: 'profile.invite.invites_sent'.tr,
            subtitle: 'profile.invite.invites_sent_desc'.tr,
            value: _controller.invitesSent.value,
            isLast: false,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildStatRow(
            icon: Icons.check_circle_outline_rounded,
            iconBg: AppColors.greenAlpha10,
            iconColor: AppColors.green200,
            title: 'profile.invite.completed'.tr,
            subtitle: 'profile.invite.completed_desc'.tr,
            value: _controller.completedInvites.value,
            isLast: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required int value,
    required bool isLast,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: iconColor, size: 20.sp),
          ),
          SizedBox(width: 14.w),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    height: 1.22,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.22,
                  ),
                ),
              ],
            ),
          ),

          // Value badge
          Container(
            padding:
            EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: AppColors.primary100,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryColor,
                height: 1.22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TOTAL EARNINGS CARD
  // ─────────────────────────────────────────────

  Widget _buildEarningsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: label + AVAILABLE badge ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'profile.invite.earnings_title'.tr,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  height: 1.22,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.greenAlpha10,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.linkGreen,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      _controller.earningsStatus.value,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenText,
                        height: 1.22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          // ── Amount ──
          Text(
            formatMoney(_controller.totalEarnings.value),
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              height: 1.22,
            ),
          ),

          SizedBox(height: 2.h),

          Text(
            _controller.earningsType,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.22,
            ),
          ),

          SizedBox(height: 16.h),

          // ── Progress bar ──
          _buildProgressBar(),
        ],
      ),
    );
  }

  // ── Progress bar with Amazon arrow style ──
  Widget _buildProgressBar() {
    final progress = (_controller.totalEarnings.value /
            ApiConstants.referralEarningsMilestone)
        .clamp(0.0, 1.0);

    return Column(
      children: [
        // Bar
        Stack(
          children: [
            // Track
            Container(
              height: 6.h,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            // Fill — computed from actual earnings
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 6.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9900),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 6.h),

        // Arrow label at progress position
        Align(
          alignment: Alignment((progress * 2) - 1, 0),
          child: Column(
            children: [
              const Icon(Icons.arrow_upward_rounded,
                  size: 14, color: Color(0xFFFF9900)),
              Text(
                _controller.progressAmount.value,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFF9900),
                  height: 1.22,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
