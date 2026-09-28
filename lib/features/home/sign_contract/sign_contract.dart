import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/features/my_utility/service_details_screen.dart';
import 'package:vyzi/features/request/document_viewer_screen.dart';
import 'package:vyzi/features/request/models/case_model.dart';


/// Everything the customer needs in order to sign their contract.
///
/// The signing itself happens with the supplier — by email, on their portal or
/// on paper — never in this app. So this screen carries no document and no
/// upload: it names the offer being signed, hands over the supplier's own
/// instructions, and offers the walkthrough. While the switch is running the
/// same screen reports its progress; once the supply is live it steps aside
/// entirely and hands over to the service details.
class SignContractScreen extends StatefulWidget {
  final String? billId;

  const SignContractScreen({super.key, this.billId});

  @override
  State<SignContractScreen> createState() => _SignContractScreenState();
}

class _SignContractScreenState extends State<SignContractScreen> {
  static const _mint = Color(0xFF64FBCB);
  static const _titleDark = Color(0xFF101828);
  static const _bodyGrey = Color(0xFF4A5565);
  static const _cardBorder = Color(0xFFE9EAEB);

  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _error;
  CaseModel? _caseData;

  /// Set the moment the case comes back activated and never cleared: the screen
  /// holds its spinner until the redirect has taken it off the stack, rather
  /// than flash a contract state the customer should not be seeing any more.
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();
    _fetchCase();
  }

  String? get _billId {
    if (widget.billId != null) return widget.billId;
    final args = Get.arguments;
    if (args is String) return args;
    if (args is Map && args['billId'] is String) {
      return args['billId'] as String;
    }
    return null;
  }

  /// The switch has been handed to the supplier but is not confirmed yet.
  bool get _isInActivation => _caseData?.isAwaitingActivation ?? false;

  bool get _isUtilityActivated => _caseData?.isActivated ?? false;

  Future<void> _fetchCase() async {
    final billId = _billId;
    if (billId == null) {
      setState(() {
        _error = 'sign_contract.error_missing_bill'.tr;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _api.get(ApiConstants.getCaseByBill(billId));
      final body = response.data as Map<String, dynamic>;

      if (body['success'] == true && body['data'] != null) {
        final switchCase =
            CaseModel.fromJson(body['data'] as Map<String, dynamic>);
        // An activated supply is described on the service details and nowhere
        // else, so this screen drops out of the flow the moment the switch is
        // confirmed. The guard sits here rather than at each caller because a
        // notification sent while the contract was still being signed can be
        // opened long after — by then this page must not be reachable at all.
        // Replacing the route keeps it out of the back stack too.
        if (switchCase.isActivated) {
          _isRedirecting = true;
          // Through this screen's own navigator, not Get's: pushed inside a
          // tab, `Get.off` would replace the whole shell instead of this page.
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => ServiceDetailsScreen(billId: billId),
              ),
            );
          }
          return;
        }
        _caseData = switchCase;
      } else {
        _error = 'sign_contract.error_load'.tr;
      }
    } catch (_) {
      _error = 'sign_contract.error_load'.tr;
    } finally {
      if (mounted && !_isRedirecting) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor))
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 40,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Icon(Icons.chevron_left, color: _titleDark, size: 28.sp),
        ),
      ),
      title: Text(
        'sign_contract.appbar_title'.tr,
        style: TextStyle(
          fontSize: 17.sp,
          fontWeight: FontWeight.w700,
          color: _titleDark,
          height: 1.22,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 44.sp, color: Colors.red.shade300),
            SizedBox(height: 12.h),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: _titleDark,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _fetchCase,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text('common.retry'.tr,
                  style: TextStyle(
                      fontSize: 13.sp, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final supplier = _caseData?.selectedOffer?.supplier;

    return RefreshIndicator(
      onRefresh: _fetchCase,
      color: AppColors.primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
        children: [
          _buildReadyCard(),
          SizedBox(height: 16.h),
          _buildSupplierCard(),
          if (supplier?.hasSigningGuideline == true) ...[
            SizedBox(height: 16.h),
            _buildGuidelineCard(supplier!),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  READY TO SIGN CARD
  // ─────────────────────────────────────────────

  /// The headline, driven by the case status. There is no contract record to
  /// read from any more — the case is the only thing that knows how far the
  /// switch has got.
  Widget _buildReadyCard() {
    final supplierName = _caseData?.selectedOffer?.supplier?.name;

    String pill;
    String title;
    String desc;
    Color pillColor;
    Color background;

    // Only a fallback: an activated case is redirected to the service details
    // before it ever gets drawn. Kept so a failed redirect still reads sensibly
    // rather than reporting the switch as merely "being prepared".
    if (_isUtilityActivated) {
      pill = 'sign_contract.pill_active'.tr;
      title = 'sign_contract.active_title'.tr;
      desc = 'sign_contract.active_desc'.tr;
      pillColor = const Color(0xFF1B8A4A);
      background = const Color(0xFFDCFCE7);
    } else if (_isInActivation) {
      pill = 'sign_contract.pill_in_activation'.tr;
      title = 'sign_contract.in_activation_title'.tr;
      desc = 'sign_contract.in_activation_desc'.tr;
      pillColor = const Color(0xFF0288D1);
      background = const Color(0xFFE1F5FE);
    } else if (_caseData?.status == 'contract_sent') {
      pill = 'sign_contract.action_required'.tr;
      title = 'sign_contract.ready_title'.tr;
      desc = supplierName != null
          ? 'sign_contract.ready_desc'.trParams({'supplier': supplierName})
          : 'sign_contract.ready_desc_generic'.tr;
      pillColor = AppColors.primaryColor;
      background = const Color(0xFFFAF5FF);
    } else if (_caseData?.status == 'cancelled' ||
        _caseData?.status == 'rejected') {
      pill = _caseData!.statusLabel;
      title = 'sign_contract.closed_title'.tr;
      desc = 'sign_contract.closed_desc'.tr;
      pillColor = const Color(0xFF757575);
      background = const Color(0xFFF5F5F5);
    } else {
      pill = 'sign_contract.pill_preparing'.tr;
      title = 'sign_contract.preparing_title'.tr;
      desc = 'sign_contract.preparing_desc'.tr;
      pillColor = const Color(0xFFF57F17);
      background = const Color(0xFFFFF8E1);
    }

    return _card(
      backgroundColor: background,
      borderColor: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              pill,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.22,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
              color: _titleDark,
              height: 1.22,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            desc,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: _bodyGrey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  SUPPLIER / OFFER CARD
  // ─────────────────────────────────────────────

  Widget _buildSupplierCard() {
    final offer = _caseData?.selectedOffer;
    final supplier = offer?.supplier;
    final savings = _caseData?.estimatedSavingsDisplay;
    // The activation date is only known once the admin has entered it, which
    // happens after the customer signs — so it is absent while they are still
    // being asked to.
    final activationDate = _caseData?.activationDate;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D2B6B), Color(0xFF4A35B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSupplierLogo(supplier),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'sign_contract.supplier_label'.tr,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.6),
                        height: 1.22,
                      ),
                    ),
                    Text(
                      supplier?.name ?? 'bills.supplier.unknown'.tr,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.22,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Divider(
              height: 1,
              thickness: 1,
              color: Colors.white.withValues(alpha: 0.15)),
          SizedBox(height: 16.h),
          _buildCardField(
            label: 'sign_contract.offer_name_label'.tr,
            value: offer?.name ?? 'case.detail.selected_offer'.tr,
            valueColor: _mint,
          ),
          if (activationDate != null) ...[
            SizedBox(height: 16.h),
            _buildCardField(
              label: 'sign_contract.activation_date_label'.tr,
              value: _formatDate(activationDate),
              valueColor: Colors.white,
            ),
          ],
          if (savings != null) ...[
            SizedBox(height: 16.h),
            _buildCardField(
              label: 'sign_contract.savings_label'.tr,
              value: savings,
              valueColor: Colors.white,
              suffix: 'sign_contract.savings_suffix'.tr,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupplierLogo(CaseSupplierModel? supplier) {
    final logoUrl = supplier?.logoUrl;
    final fallback = Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          (supplier?.name?.isNotEmpty == true)
              ? supplier!.name!.substring(0, 1).toUpperCase()
              : '?',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );

    if (logoUrl == null || logoUrl.isEmpty) return fallback;

    return Container(
      width: 40.w,
      height: 40.w,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.network(
          _absoluteUrl(logoUrl),
          width: 40.w,
          height: 40.w,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      ),
    );
  }

  Widget _buildCardField({
    required String label,
    required String value,
    required Color valueColor,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.6),
            height: 1.22,
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  height: 1.22,
                ),
              ),
            ),
            if (suffix != null) ...[
              SizedBox(width: 4.w),
              Text(
                suffix,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.6),
                  height: 1.22,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  SUPPLIER SIGNING GUIDELINE
  // ─────────────────────────────────────────────

  /// The supplier's own instructions, configured by the admin. This is the only
  /// place the customer learns how *this* supplier wants to be signed with, so
  /// it sits on its own rather than tucked inside another card.
  Widget _buildGuidelineCard(CaseSupplierModel supplier) {
    const accent = Color(0xFF7061ED);
    final instructions = supplier.signingInstructions;
    final docUrl = supplier.signingDocumentUrl;

    return _card(
      backgroundColor: Colors.white,
      borderColor: _cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_outlined, size: 20.sp, color: accent),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'case.detail.sign_guideline'.tr,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    color: _titleDark,
                    height: 1.22,
                  ),
                ),
              ),
            ],
          ),
          if (instructions != null) ...[
            SizedBox(height: 12.h),
            Text(
              instructions,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: _bodyGrey,
              ),
            ),
          ],
          if (docUrl != null) ...[
            SizedBox(height: 14.h),
            InkWell(
              onTap: () => _openGuidelineDocument(supplier),
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: accent.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    Icon(
                      supplier.signingDocumentIsPdf
                          ? Icons.picture_as_pdf
                          : Icons.insert_drive_file_outlined,
                      size: 22.sp,
                      color: accent,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'sign_contract.view_tutorial'.tr,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w800,
                          color: _titleDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.open_in_new, size: 16.sp, color: accent),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({
    required Widget child,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor ?? _cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // ─────────────────────────────────────────────
  //  ACTIONS
  // ─────────────────────────────────────────────

  void _openGuidelineDocument(CaseSupplierModel supplier) {
    final url = supplier.signingDocumentUrl;
    if (url == null || url.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(
          url: url,
          title: 'case.detail.sign_guideline'.tr,
          fileName: supplier.signingDocumentDisplayName,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────

  String _absoluteUrl(String url) => url.startsWith('http')
      ? url
      : '${ApiConstants.baseUrl}/${url.replaceAll(RegExp(r'^/'), '')}';

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }
}
