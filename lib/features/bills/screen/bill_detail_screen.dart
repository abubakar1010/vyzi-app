import 'package:vyzi/core/exceptions/app_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/features/bills/models/bill_model.dart';
import 'package:vyzi/features/home/sign_contract/sign_contract.dart';
import 'package:vyzi/features/my_utility/service_details_screen.dart';
import 'package:vyzi/features/request/models/case_model.dart';
import 'package:vyzi/features/request/replace_document/replace_document_screen.dart';
import 'package:vyzi/routes/app_routes.dart';
import 'package:vyzi/core/localization/system_messages.dart';

/// Secondary and tertiary text on this screen. AppColors flattens every
/// text token to pure black, which the design calls for greys.
const Color _mutedText = Color(0xFF6E6E7A);
const Color _subtleText = Color(0xFF9A9AA6);

/// How far a milestone on the submission timeline has got. `failed` is the
/// KO / terminated stop, which only ever lands on the last row.
enum _StepState { done, current, pending, failed }

/// One milestone of a switch, as the customer follows it.
class _Milestone {
  final IconData icon;
  final String titleKey;
  final String subtitleKey;

  const _Milestone({
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
  });
}

/// The five milestones every switch passes through, in order. The KO /
/// terminated stop is not one of them: it is appended, and only to the
/// requests that actually ended there.
const List<_Milestone> _switchMilestones = [
  _Milestone(
    icon: Icons.check,
    titleKey: 'bills.detail.timeline.sent_title',
    subtitleKey: 'bills.detail.timeline.sent_subtitle',
  ),
  _Milestone(
    icon: Icons.search,
    titleKey: 'bills.detail.timeline.analyzed_title',
    subtitleKey: 'bills.detail.timeline.analyzed_subtitle',
  ),
  _Milestone(
    icon: Icons.draw_outlined,
    titleKey: 'bills.detail.timeline.contract_signed_title',
    subtitleKey: 'bills.detail.timeline.contract_signed_subtitle',
  ),
  _Milestone(
    icon: Icons.autorenew,
    titleKey: 'bills.detail.timeline.in_activation_title',
    subtitleKey: 'bills.detail.timeline.in_activation_subtitle',
  ),
  _Milestone(
    icon: Icons.verified_outlined,
    titleKey: 'bills.detail.timeline.activated_title',
    subtitleKey: 'bills.detail.timeline.activated_subtitle',
  ),
];

class BillDetailScreen extends StatefulWidget {
  final String billId;

  const BillDetailScreen({super.key, required this.billId});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  String _error = '';
  BillModel? _bill;
  CaseModel? _caseData;

  @override
  void initState() {
    super.initState();
    _fetchBillDetails();
  }

  Future<void> _fetchBillDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final url = ApiConstants.getMyBillDetails
          .replaceAll('{{billId}}', widget.billId);
      final response = await _api.get(url);
      final body = response.data as Map<String, dynamic>;

      if (body['success'] == true) {
        _bill = BillModel.fromJson(body['data'] as Map<String, dynamic>);
        // Plus the case behind it, on the statuses that have a use for one.
        await _fetchCaseByBill();
      } else {
        _error = SystemMessages.resolve(body['message']);
      }
    } catch (e) {
      _error = (e is AppException ? e.message : 'system.unexpected'.tr);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// The statuses whose contract lives on its own screen — the banner links
  /// through to it, and the case behind the bill is what fills it in.
  static const _contractStatuses = {
    'contract_sent',
    'awaiting_activation',
    'activated',
  };

  /// The two stops: an analysis that failed, and a switch that was called off.
  static const _stoppedStatuses = {'error', 'cancelled'};

  /// From here on the request is about the offer the customer accepted, so the
  /// supply card names that offer's supplier rather than the one on the bill.
  static const _acceptedOfferStatuses = {'offer_accepted', ..._contractStatuses};

  Future<void> _fetchCaseByBill() async {
    // An accepted offer needs the case for the supplier it was accepted from,
    // the contract statuses for the banner too; the stops need it to tell how
    // far the request had got before it stopped.
    final status = _bill?.status;
    if (status == null ||
        (!_acceptedOfferStatuses.contains(status) &&
            !_stoppedStatuses.contains(status))) {
      return;
    }

    try {
      final response =
          await _api.get(ApiConstants.getCaseByBill(widget.billId));
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        _caseData = CaseModel.fromJson(body['data'] as Map<String, dynamic>);
      }
    } catch (_) {
      // Non-critical — contract card just won't show
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _fetchBillDetails,
                        child: Text('common.retry'.tr),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 40,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Padding(
          padding: EdgeInsets.only(left: 12),
          child:
              Icon(Icons.chevron_left, color: AppColors.textDark, size: 28),
        ),
      ),
      title: Text(
        'bills.detail.title'.tr,
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildContent() {
    final bill = _bill!;
    final showContract =
        _caseData != null && _contractStatuses.contains(bill.status);

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      children: [
        _processingHeroCard(bill),
        SizedBox(height: 14.h),
        if (_utilityCard(bill) case final card?) ...[
          card,
          SizedBox(height: 14.h),
        ],
        // ── Verification & contract ──
        // Anything the customer may have to act on sits directly under the
        // supply it belongs to, above the submission timeline.
        if (bill.status == 'verification_required')
          _verificationRequiredBanner(bill),
        if (_caseData?.documentsAwaitingReplacement case final rejected?
            when rejected.isNotEmpty)
          _documentRejectedBanner(_caseData!.id, rejected),
        if (showContract) ...[
          _contractBanner(bill),
          SizedBox(height: 14.h),
        ],
        _submissionCard(bill),
        if (_showInfoBanner(bill.status)) ...[
          SizedBox(height: 14.h),
          _infoBanner(),
        ],
      ],
    );
  }

  // ── Processing Hero ──
  // Opens the screen with one plain-language line about where the switch
  // stands, so the customer knows whether anything is expected of them.
  Widget _processingHeroCard(BillModel bill) {
    late final IconData icon;
    late final String title;
    late final String description;

    switch (bill.status) {
      case 'activated':
        icon = Icons.verified_outlined;
        title = 'bills.detail.hero.done_title'.tr;
        description = 'bills.detail.hero.done_desc'.tr;
        break;
      case 'error':
      case 'cancelled':
        icon = Icons.error_outline;
        title = 'bills.detail.hero.attention_title'.tr;
        description = _statusMessage(bill.status);
        break;
      default:
        icon = Icons.description_outlined;
        title = 'request.details.processing_title'.tr;
        description = 'request.details.processing_desc'.tr;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28.sp),
          ),
          SizedBox(height: 14.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _mutedText,
              fontSize: 13.sp,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Utility Card ──
  // The supply this request is about. Once an offer is accepted it names the
  // supplier of that offer, with the offer's name under it; before then, the
  // supplier read off the bill. Null — no card — while that supplier isn't
  // known, rather than a card that says "unknown supplier".
  Widget? _utilityCard(BillModel bill) {
    final offer = _caseData?.selectedOffer;
    final offerSupplier = offer?.supplier?.name?.trim();

    final String supplierName;
    final String? logoUrl;
    String? offerName;
    if (offerSupplier != null && offerSupplier.isNotEmpty) {
      supplierName = offerSupplier;
      logoUrl = offer!.supplier!.logoUrl;
      offerName = offer.name?.trim();
      if (offerName != null && offerName.isEmpty) offerName = null;
    } else if (_acceptedOfferStatuses.contains(bill.status)) {
      // The bill's supplier is the one being left — naming it here would be
      // the wrong answer, so wait for the case to carry the offer.
      return null;
    } else {
      final billSupplier = bill.knownSupplierName;
      if (billSupplier == null) return null;
      supplierName = billSupplier;
      logoUrl = bill.supplier?.logoUrl;
    }

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.divider, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSupplierLogo(logoUrl, bill.billTypeIcon),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(bill.billTypeIcon,
                        size: 15.sp, color: AppColors.primaryColor),
                    SizedBox(width: 3.w),
                    Flexible(
                      child: Text(
                        bill.billTypeDisplay,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (bill.isEmailSource) ...[
                      SizedBox(width: 6.w),
                      _emailSourceChip(),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  supplierName,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (offerName != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    offerName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _mutedText,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emailSourceChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.email_outlined, size: 11, color: Color(0xFF6A1B9A)),
          SizedBox(width: 3),
          Text('bills.detail.via_email'.tr,
              style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF6A1B9A),
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ── Submission Card ──
  // When the request came in, and how far it has got along the five milestones
  // of a switch — plus the KO / terminated stop, on the requests that ended
  // there.
  Widget _submissionCard(BillModel bill) {
    final stopped = _hasStopped(bill);
    final states = _timelineStates(bill);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.divider, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'request.details.submission_date'.tr,
                      style: TextStyle(
                        color: _subtleText,
                        fontSize: 10.sp,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      bill.formattedDate,
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 140.w),
                child: _statusPill(bill),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          for (var i = 0; i < _switchMilestones.length; i++)
            _timelineStep(
              icon: _switchMilestones[i].icon,
              title: _switchMilestones[i].titleKey.tr,
              subtitle: _switchMilestones[i].subtitleKey.tr,
              state: states[i],
              isLast: !stopped && i == _switchMilestones.length - 1,
            ),
          if (stopped)
            _timelineStep(
              icon: Icons.close,
              title: 'bills.detail.timeline.ko_title'.tr,
              subtitle: _stopReason(bill),
              state: _StepState.failed,
              isLast: true,
            ),
        ],
      ),
    );
  }

  /// Where each of the five milestones stands: what the request has passed is
  /// done, the one after that is what we are working on, the rest are ahead.
  List<_StepState> _timelineStates(BillModel bill) {
    final stopped = _hasStopped(bill);
    final passed = stopped
        ? _milestonesPassedBeforeStop()
        : _milestonesPassed(bill.status);

    return List<_StepState>.generate(_switchMilestones.length, (index) {
      if (index < passed) return _StepState.done;
      // Nothing is in progress on a request that stopped — the KO row is where
      // it ended, so everything it never reached stays greyed out.
      if (stopped || index > passed) return _StepState.pending;
      return _StepState.current;
    });
  }

  /// How many of the five milestones the bill has passed.
  ///
  /// The analysis milestone lands on `verified`, not on `analyzed`: what the
  /// customer is told has been analysed is the data our experts confirmed, not
  /// what the extraction read off the file. The contract milestone lands on
  /// `awaiting_activation`, not on `contract_sent`, for the same reason — the
  /// customer signs with the supplier, outside the app, and the admin only
  /// moves the request on to activation once that signature is in.
  int _milestonesPassed(String status) {
    switch (status) {
      case 'activated':
        return 5;
      case 'awaiting_activation':
        return 3;
      case 'verified':
      case 'offer_sent':
      case 'offer_accepted':
      case 'contract_sent':
        return 2;
      default:
        // pending_email, uploaded, analyzing, analyzed, verification_review,
        // verification_required — the bill is in, the analysis is not settled.
        return 1;
    }
  }

  /// What a stopped request had reached before it stopped. The status only
  /// records the stop itself, so the case is the one tell left: a case exists
  /// from the moment the customer accepts an offer, which is well past the
  /// point where the bill was analysed.
  int _milestonesPassedBeforeStop() => _caseData == null ? 1 : 2;

  /// Whether the request stopped for good. The case status is read too: an
  /// admin can close a case from the CRM without the bill itself moving.
  bool _hasStopped(BillModel bill) {
    if (_stoppedStatuses.contains(bill.status)) return true;
    final caseStatus = _caseData?.status;
    return caseStatus == 'rejected' || caseStatus == 'cancelled';
  }

  /// Why it stopped, in the customer's words. A case closed from the CRM
  /// leaves the bill untouched, so that one falls back to the generic line.
  String _stopReason(BillModel bill) => _stoppedStatuses.contains(bill.status)
      ? _statusMessage(bill.status)
      : 'bills.detail.timeline.ko_subtitle'.tr;

  Widget _statusPill(BillModel bill) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bill.statusBgColor,
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: bill.statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              bill.statusDisplay,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: bill.statusColor,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required _StepState state,
    required bool isLast,
  }) {
    late final Color circleBg;
    late final Color iconColor;
    late final Color? ringColor;

    switch (state) {
      case _StepState.done:
        circleBg = AppColors.green200;
        iconColor = Colors.white;
        ringColor = null;
        break;
      case _StepState.current:
        circleBg = const Color(0xFFFFF6E0);
        iconColor = const Color(0xFFDFB400);
        ringColor = const Color(0xFFEFC33F);
        break;
      case _StepState.pending:
        circleBg = const Color(0xFFEFEFF3);
        iconColor = _subtleText;
        ringColor = null;
        break;
      case _StepState.failed:
        circleBg = AppColors.error;
        iconColor = Colors.white;
        ringColor = null;
        break;
    }

    final isMuted = state == _StepState.pending;
    final titleColor = state == _StepState.failed
        ? AppColors.error
        : isMuted
            ? _subtleText
            : AppColors.textDark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34.w,
            child: Column(
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: circleBg,
                    shape: BoxShape.circle,
                    border: ringColor == null
                        ? null
                        : Border.all(color: ringColor, width: 2),
                  ),
                  child: Icon(
                    state == _StepState.done ? Icons.check : icon,
                    size: 18.sp,
                    color: iconColor,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: EdgeInsets.symmetric(vertical: 4.h),
                      color: const Color(0xFFE2E2E8),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4.h, bottom: isLast ? 0 : 18.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isMuted ? _subtleText : _mutedText,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Banner ──
  // Only while the request is still being looked at — once it is with the
  // supplier, or has stopped, the 3-5 day promise no longer holds.
  bool _showInfoBanner(String status) =>
      !_contractStatuses.contains(status) &&
      !_stoppedStatuses.contains(status);

  Widget _infoBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFE6DAF7),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18.sp, color: AppColors.primaryColor),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'request.details.info_message'.tr,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 12.sp,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierLogo(String? logoUrl, IconData fallbackIcon) {
    Widget inner;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      final url = logoUrl.startsWith('http')
          ? logoUrl
          : '${ApiConstants.baseUrl}$logoUrl';
      inner = Padding(
        padding: EdgeInsets.all(6.w),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              Icon(fallbackIcon, color: AppColors.primaryColor, size: 24.sp),
        ),
      );
    } else {
      inner = Icon(fallbackIcon, color: AppColors.primaryColor, size: 24.sp);
    }

    return Container(
      width: 48.w,
      height: 48.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F7),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: inner,
    );
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'pending_email':
        return 'bills.detail.status_pending_email'.tr;
      case 'uploaded':
        return 'bills.detail.status_uploaded'.tr;
      case 'analyzing':
        return 'bills.detail.status_analyzing'.tr;
      case 'analyzed':
        return 'bills.detail.status_analyzed'.tr;
      case 'error':
        return 'bills.detail.status_error'.tr;
      case 'verification_required':
        return 'bills.detail.status_verification_required'.tr;
      case 'verification_review':
        return 'bills.detail.status_verification_review'.tr;
      case 'verified':
        return 'bills.detail.status_verified'.tr;
      case 'offer_sent':
        return 'bills.status_msg.offer_sent'.tr;
      case 'offer_accepted':
        return 'bills.detail.status_offer_accepted'.tr;
      case 'contract_sent':
        return 'bills.status_msg.contract_sent'.tr;
      case 'awaiting_activation':
        return 'bills.detail.status_awaiting_activation'.tr;
      case 'activated':
        return 'bills.status_msg.activated'.tr;
      case 'cancelled':
        return 'bills.status_msg.cancelled'.tr;
      default:
        return status;
    }
  }

  // ── Verification Required Banner ──
  // The admin needs a better copy of the bill itself.
  Widget _verificationRequiredBanner(BillModel bill) {
    return _actionRequiredBanner(
      title: 'bills.detail.verification_banner.title'.tr,
      subtitle: 'bills.detail.verification_banner.subtitle'.tr,
      icon: Icons.warning_amber_rounded,
      accent: Colors.orange.shade700,
      background: Colors.orange.shade50,
      border: Colors.orange.shade300,
      iconBackground: Colors.orange.shade100,
      onTap: () => Get.toNamed(
        AppRoutes.billVerificationScreen,
        arguments: bill.id,
      ),
    );
  }

  // ── Document Rejected Banner ──
  // An admin turned down an identity document and needs a new one.
  Widget _documentRejectedBanner(
    String caseId,
    List<CaseDocumentModel> rejected,
  ) {
    return _actionRequiredBanner(
      title: 'case.document.banner.title'.tr,
      subtitle: rejected.length == 1
          ? '${rejected.first.rejectionReasonLabel} · ${'case.document.banner.subtitle'.tr}'
          : 'case.document.banner.subtitle'.tr,
      icon: Icons.badge_outlined,
      accent: Colors.red.shade700,
      background: Colors.red.shade50,
      border: Colors.red.shade200,
      iconBackground: Colors.red.shade100,
      onTap: () async {
        final sent = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) =>
                ReplaceDocumentScreen(caseId: caseId, rejected: rejected),
          ),
        );
        if (sent == true && mounted) _fetchBillDetails();
      },
    );
  }

  Widget _actionRequiredBanner({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required Color background,
    required Color border,
    required Color iconBackground,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: accent, size: 22.w),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: accent.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16.w,
                color: accent.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Contract Banner ──
  // A single tap-through entry point. While the switch is still running that is
  // the sign-contract screen; once the supply is live it is the service
  // details, which is where an activated supply is described from then on.
  Widget _contractBanner(BillModel bill) {
    late final IconData icon;
    late final Color accent;
    late final Color background;
    late final Color border;
    late final String title;
    late final String subtitle;

    // Keyed off the bill status: signing happens with the supplier, so the
    // pipeline is the only thing that knows how far the switch has got.
    switch (bill.status) {
      case 'contract_sent':
        icon = Icons.draw_outlined;
        accent = AppColors.primaryColor;
        background = const Color(0xFFFAF5FF);
        border = const Color(0xFFE2D3F8);
        title = 'bills.detail.contract_banner.ready_title'.tr;
        subtitle = 'bills.detail.contract_banner.ready_subtitle'.tr;
        break;
      case 'awaiting_activation':
        icon = Icons.autorenew;
        accent = const Color(0xFF0288D1);
        background = const Color(0xFFE1F5FE);
        border = const Color(0xFFB3E5FC);
        title = 'bills.detail.contract_banner.in_activation_title'.tr;
        subtitle = 'bills.detail.contract_banner.in_activation_subtitle'.tr;
        break;
      case 'activated':
        icon = Icons.verified_outlined;
        accent = const Color(0xFF1B8A4A);
        background = const Color(0xFFDCFCE7);
        border = const Color(0xFFA7E9C4);
        title = 'bills.detail.contract_banner.active_title'.tr;
        subtitle = 'bills.detail.contract_banner.active_subtitle'.tr;
        break;
      default:
        icon = Icons.hourglass_bottom_rounded;
        accent = const Color(0xFFF57F17);
        background = const Color(0xFFFFF8E1);
        border = const Color(0xFFFFE082);
        title = 'bills.detail.contract_banner.preparing_title'.tr;
        subtitle = 'bills.detail.contract_banner.preparing_subtitle'.tr;
    }

    return GestureDetector(
      onTap: () async {
        if (bill.isActivated) {
          await NavHelper.push(ServiceDetailsScreen(billId: bill.id));
        } else {
          await NavHelper.push(SignContractScreen(billId: bill.id));
        }
        if (mounted) _fetchBillDetails();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: accent, size: 22.w),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMid,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16.w, color: accent.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

}
