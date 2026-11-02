import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/layout/adaptive.dart';
import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/features/activation_request/models/activation_request_model.dart';
import 'package:vyzi/features/home/sign_contract/sign_contract.dart';
import 'package:vyzi/features/my_utility/service_details_screen.dart';
import 'package:vyzi/features/request/models/case_model.dart';
import 'package:vyzi/features/request/replace_document/replace_document_screen.dart';

enum _StepState { done, current, pending }

/// One activation request as the customer follows it.
///
/// The offer is agreed by phone, so there are only four steps and never a list
/// of offers. KO and cancelled are stops of their own, shown only
/// on a request that ended there.
class ActivationRequestDetailScreen extends StatefulWidget {
  final String caseId;

  const ActivationRequestDetailScreen({super.key, required this.caseId});

  @override
  State<ActivationRequestDetailScreen> createState() =>
      _ActivationRequestDetailScreenState();
}

class _ActivationRequestDetailScreenState
    extends State<ActivationRequestDetailScreen> {
  static const _steps = ['request', 'contract', 'activation', 'active'];
  static const _icons = [
    Icons.search,
    Icons.draw_outlined,
    Icons.autorenew,
    Icons.verified_outlined,
  ];
  static const _muted = Color(0xFF6A7282);

  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _error;
  ActivationRequestModel? _request;
  CaseModel? _case;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _api.get(ApiConstants.getCaseDetails(widget.caseId));
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        final data = body['data'] as Map<String, dynamic>;
        _request = ActivationRequestModel.fromJson(data);
        _case = CaseModel.fromJson(data);
      } else {
        _error = 'activation_request.detail_error'.tr;
      }
    } catch (_) {
      _error = 'activation_request.detail_error'.tr;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _push(Widget screen) async {
    await NavHelper.push(screen);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'activation_request.detail_title'.tr,
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }
    final request = _request;
    final switchCase = _case;
    if (_error != null || request == null || switchCase == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'activation_request.detail_error'.tr),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: _load,
              child: Text('activation_request.retry'.tr),
            ),
          ],
        ),
      );
    }

    final reached = request.stepsReached(
      contractSent: switchCase.contractSentAt != null,
    );
    final rejected = request.isClosed
        ? const <CaseDocumentModel>[]
        : switchCase.documentsAwaitingReplacement;
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: Adaptive.page(
          context,
          EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
        ),
        children: [
          Text(
            request.title,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800),
          ),
          if (request.address.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              request.address.formatted,
              style: TextStyle(fontSize: 13.sp, color: _muted),
            ),
          ],
          if (rejected.isNotEmpty) ...[
            SizedBox(height: 16.h),
            _rejectedDocumentsBanner(request.id, rejected),
          ],
          SizedBox(height: 20.h),
          for (var i = 0; i < _steps.length; i++)
            _step(
              icon: _icons[i],
              title: 'activation_request.steps.${_steps[i]}_title'.tr,
              subtitle: 'activation_request.steps.${_steps[i]}_subtitle'.tr,
              state: _stateOf(i, reached, request),
              isLast: !request.isClosed && i == _steps.length - 1,
            ),
          if (request.isClosed)
            _closedStep(request),
          if (request.showsContract) ...[
            SizedBox(height: 16.h),
            _action(
              key: const ValueKey('activation_request.view_contract'),
              label: 'activation_request.view_contract'.tr,
              onTap: () => _push(SignContractScreen(caseId: request.id)),
            ),
          ],
          if (request.isLive) ...[
            SizedBox(height: 16.h),
            _action(
              key: const ValueKey('activation_request.view_utility'),
              label: 'activation_request.view_utility'.tr,
              onTap: () => _push(ServiceDetailsScreen(caseId: request.id)),
            ),
          ],
        ],
      ),
    );
  }

  _StepState _stateOf(int index, int reached, ActivationRequestModel request) {
    if (index < reached) return _StepState.done;
    if (request.isClosed || index > reached) return _StepState.pending;
    return _StepState.current;
  }

  /// Staff turned a document down and need a new one: the message that said so
  /// lands here, so the upload has to be reachable from here.
  Widget _rejectedDocumentsBanner(
    String caseId,
    List<CaseDocumentModel> rejected,
  ) {
    final accent = Colors.red.shade700;
    return InkWell(
      key: const ValueKey('activation_request.replace_document'),
      borderRadius: BorderRadius.circular(14.r),
      onTap: () => _push(ReplaceDocumentScreen(caseId: caseId, rejected: rejected)),
      child: Ink(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.badge_outlined, color: accent, size: 22.w),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'case.document.banner.title'.tr,
                    style: TextStyle(
                      color: accent,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    rejected.length == 1
                        ? '${rejected.first.rejectionReasonLabel} · ${'case.document.banner.subtitle'.tr}'
                        : 'case.document.banner.subtitle'.tr,
                    style: TextStyle(fontSize: 12.sp, color: _muted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: accent, size: 20.w),
          ],
        ),
      ),
    );
  }

  Widget _action({
    required Key key,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        key: key,
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _closedStep(ActivationRequestModel request) {
    return _StepRow(
      icon: Icons.close,
      title: request.statusLabel,
      subtitle: 'activation_request.steps.closed_subtitle'.tr,
      circle: AppColors.error,
      iconColor: Colors.white,
      titleColor: AppColors.error,
      subtitleColor: _muted,
      isLast: true,
    );
  }

  Widget _step({
    required IconData icon,
    required String title,
    required String subtitle,
    required _StepState state,
    required bool isLast,
  }) {
    final pending = state == _StepState.pending;
    return _StepRow(
      icon: state == _StepState.done ? Icons.check : icon,
      title: title,
      subtitle: subtitle,
      circle: switch (state) {
        _StepState.done => AppColors.green200,
        _StepState.current => const Color(0xFFFFF6E0),
        _StepState.pending => const Color(0xFFEFEFF3),
      },
      ring: state == _StepState.current ? const Color(0xFFEFC33F) : null,
      iconColor: switch (state) {
        _StepState.done => Colors.white,
        _StepState.current => const Color(0xFFDFB400),
        _StepState.pending => _muted,
      },
      titleColor: pending ? _muted : AppColors.textDark,
      subtitleColor: _muted,
      isLast: isLast,
    );
  }
}

class _StepRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color circle;
  final Color? ring;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;
  final bool isLast;

  const _StepRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.circle,
    this.ring,
    required this.iconColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
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
                    color: circle,
                    shape: BoxShape.circle,
                    border: ring == null
                        ? null
                        : Border.all(color: ring!, width: 2),
                  ),
                  child: Icon(icon, size: 18.sp, color: iconColor),
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
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(color: subtitleColor, fontSize: 12.sp),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
