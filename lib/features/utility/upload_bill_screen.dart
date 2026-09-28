import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/features/home/email/email_bill_screen.dart';
import 'package:vyzi/features/utility/controller/select_utility_controller.dart';
import 'package:vyzi/features/utility/controller/upload_bill_controller.dart';
import 'package:flutter/material.dart';
import 'package:vyzi/core/constants/contact_constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'multi_capture_screen.dart';

class UploadBillScreen extends StatefulWidget {
  final UtilityType utilityType;

  const UploadBillScreen({super.key, required this.utilityType});

  @override
  State<UploadBillScreen> createState() => _UploadBillScreenState();
}

class _UploadBillScreenState extends State<UploadBillScreen> {
  final UploadBillController _controller = Get.put(UploadBillController());
  Worker? _uploadSuccessWorker;
  Worker? _batchCompleteWorker;

  @override
  void initState() {
    super.initState();
    _controller.init(widget.utilityType);

    // Navigate to bills list when single-file upload succeeds
    _uploadSuccessWorker = ever(_controller.uploadSuccess, (success) {
      if (success && mounted) {
        _showSuccessAndNavigate();
      }
    });

    // Navigate to bills list when batch upload completes
    _batchCompleteWorker = ever(_controller.batchUploadCompleted, (completed) {
      if (completed && mounted && _controller.uploadedFilesMulti.isNotEmpty) {
        _showSuccessAndNavigate();
      }
    });
  }

  @override
  void dispose() {
    _uploadSuccessWorker?.dispose();
    _batchCompleteWorker?.dispose();
    _controller.clearState();
    super.dispose();
  }

  String get _headingKey =>
      widget.utilityType == UtilityType.luce
          ? 'upload_bill.heading_electricity'
          : 'upload_bill.heading_gas';

  // ─────────────────────────────────────────────
  //  ACTIONS
  // ─────────────────────────────────────────────

  /// Opens multi-file picker for "Upload File" method
  Future<void> _openMultiFilePicker() async {
    if (_controller.isBatchUploading.value) return;
    _controller.selectMethod(UploadMethod.uploadFile);

    if (_controller.isAtFileLimit) {
      Get.snackbar(
        'upload_bill.file_validation_title'.tr,
        'upload_bill.max_files_reached'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await _controller.pickMultipleFiles();
  }

  /// Opens custom camera for continuous multi-photo scanning session.
  Future<void> _openCamera() async {
    if (_controller.isBatchUploading.value) return;
    _controller.selectMethod(UploadMethod.scanFile);

    final existingCount = _controller.selectedFiles.length;
    if (existingCount >= UploadBillController.maxFileCount) {
      Get.snackbar(
        'upload_bill.file_validation_title'.tr,
        'upload_bill.max_files_reached'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final paths = await Navigator.of(context, rootNavigator: true).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => MultiCaptureScreen(
          existingCount: existingCount,
          maxCount: UploadBillController.maxFileCount,
        ),
      ),
    );

    if (paths != null && paths.isNotEmpty) {
      await _controller.addCapturedPhotoPaths(paths);
    }
  }

  void _showSuccessAndNavigate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFF1FC16B),
                size: 56.w,
              ),
              SizedBox(height: 16.h),
              Text(
                'upload_bill.submitted_success'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    NavHelper.popToRoot();
                    NavHelper.switchTab(0);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A1ABE),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                16.w, 24.h, 16.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Heading ──
                Text(
                  _headingKey.tr,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1.28,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'upload_bill.subtitle'.tr,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    height: 1.22,
                  ),
                ),
                SizedBox(height: 20.h),

                // ── Info banner ──
                _buildInfoBanner(),
                SizedBox(height: 20.h),

                // ── Upload / Scan cards ──
                _buildUploadScanRow(),
                SizedBox(height: 14.h),

                // ── Multi-file content (uploadFile & scanFile) or single-file ──
                Obx(() {
                  final method = _controller.selectedMethod.value;
                  if (method == UploadMethod.uploadFile ||
                      method == UploadMethod.scanFile) {
                    return _buildMultiFileContent();
                  }
                  return _buildSingleFileContent();
                }),

                SizedBox(height: 14.h),

                // ── OR divider ──
                _buildOrDivider(),
                SizedBox(height: 14.h),

                // ── Send Our Email card ──
                _buildEmailCard(),
                SizedBox(height: 24.h),

                // ── What we are looking for ──
                _buildLookingForCard(),
                SizedBox(height: 30.h),
              ],
            ),
          ),

          // ── Upload progress overlay ──
          Obx(() => (_controller.isUploading.value || _controller.isBatchUploading.value)
              ? _buildUploadOverlay()
              : const SizedBox.shrink()),
        ],
      ),
      ),
    );
  }

  // ─── Multi-file content ──────────────────────────────

  Widget _buildMultiFileContent() {
    // No inline content — the upload overlay handles the UI
    // and the ever() listener auto-navigates on completion
    return const SizedBox.shrink();
  }

  // ─── Single-file content (camera/scan flow) ──────────

  Widget _buildSingleFileContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File preview (if selected)
        Obx(() => _controller.selectedFile.value != null
            ? _buildFilePreview()
            : const SizedBox.shrink()),

        // Error message
        Obx(() => _controller.errorMessage.value.isNotEmpty
            ? _buildErrorMessage()
            : const SizedBox.shrink()),
      ],
    );
  }

  // ── AppBar ──
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded,
            color: Colors.black, size: 22.sp),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'upload_bill.appbar_title'.tr,
        style: TextStyle(
          fontSize: 17.sp,
          fontWeight: FontWeight.w800,
          color: Colors.black,
          height: 1.22,
        ),
      ),
    );
  }

  // ── Why we need it popup ──
  void _showWhyWeNeedItPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: const Color(0xFF5A1ABE),
                size: 40.w,
              ),
              SizedBox(height: 12.h),
              Text(
                'upload_bill.info_popup_title'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'upload_bill.info_popup_body'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A1ABE),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    'upload_bill.info_popup_close'.tr,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Info banner ──
  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEFF),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF5A1ABE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.help_outline_rounded,
                  color: Color(0xFF5A1ABE), size: 18),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'upload_bill.info_text'.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    height: 1.22,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: () => _showWhyWeNeedItPopup(context),
            child: Text(
              'upload_bill.info_link'.tr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF5A1ABE),
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF5A1ABE),
                height: 1.22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Upload File + Scan File row ──
  Widget _buildUploadScanRow() {
    return Obx(() => Row(
          children: [
            Expanded(
              child: _buildMethodCard(
                method: UploadMethod.uploadFile,
                assetIcon: 'assets/icons/upload.webp',
                label: 'upload_bill.upload_file'.tr,
                sublabel: 'upload_bill.upload_formats'.tr,
                onTap: _openMultiFilePicker,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildMethodCard(
                method: UploadMethod.scanFile,
                assetIcon: 'assets/icons/scannn.webp',
                label: 'upload_bill.scan_file'.tr,
                sublabel: 'upload_bill.scan_use_camera'.tr,
                onTap: _openCamera,
              ),
            ),
          ],
        ));
  }

  Widget _buildMethodCard({
    required UploadMethod method,
    required String assetIcon,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
  }) {
    final isSelected = _controller.selectedMethod.value == method;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 120.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: const Color(0xFF5A1ABE),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              assetIcon,
              width: 56.w,
              height: 56.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 10.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                height: 1.22,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.black,
                fontWeight: FontWeight.w700,
                height: 1.22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── File Preview Card (single-file) ──
  Widget _buildFilePreview() {
    final fileName = _controller.selectedFileName;
    final fileSize = _controller.selectedFileSize;
    final ext = fileName.split('.').last.toLowerCase();
    final isPdf = ext == 'pdf';

    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7FF),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFF5A1ABE), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: isPdf
                    ? const Color(0xFFFFEBEE)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                isPdf
                    ? Icons.picture_as_pdf_rounded
                    : Icons.image_rounded,
                color: isPdf
                    ? const Color(0xFFE53935)
                    : const Color(0xFF43A047),
                size: 24,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${ext.toUpperCase()} • $fileSize',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _controller.removeFile,
              child: Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFFE53935),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ── Error Message ──
  Widget _buildErrorMessage() {
    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE53935), size: 18),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _controller.errorMessage.value,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE53935),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Upload Progress Overlay (single-file) ──
  Widget _buildUploadOverlay() {
    return AbsorbPointer(
      absorbing: true,
      child: Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 40.w),
          padding: EdgeInsets.all(28.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF5A1ABE),
                strokeWidth: 3,
              ),
              SizedBox(height: 20.h),
              Text(
                'upload_bill.uploading'.tr,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16.h),
              Obx(() {
                final progress = _controller.isBatchUploading.value
                    ? _controller.overallProgress
                    : _controller.uploadProgress.value;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFE8E8E8),
                    color: const Color(0xFF5A1ABE),
                    minHeight: 8.h,
                  ),
                );
              }),
              SizedBox(height: 8.h),
              Obx(() {
                final progress = _controller.isBatchUploading.value
                    ? _controller.overallProgress
                    : _controller.uploadProgress.value;
                return Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5A1ABE),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    ),
    );
  }

  // ── OR divider ──
  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(
            child: Divider(color: Color(0xFF5A1ABE), thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            'upload_bill.or_divider'.tr,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.black,
              fontWeight: FontWeight.w900,
              height: 1.22,
            ),
          ),
        ),
        const Expanded(
            child: Divider(color: Color(0xFF5A1ABE), thickness: 1)),
      ],
    );
  }

  // ── Send Our Email card ──
  Widget _buildEmailCard() {
    return GestureDetector(
      onTap: () {
        _controller.selectMethod(UploadMethod.sendEmail);
        NavHelper.push(EmailBillScreen(
              billType:
                  widget.utilityType == UtilityType.luce ? 'electricity' : 'gas',
            ));
      },
      child: Obx(() => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: const Color(0xFF5A1ABE),
                width:
                    _controller.selectedMethod.value == UploadMethod.sendEmail
                        ? 2.0
                        : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8EF),
                    borderRadius: BorderRadius.circular(12.r),
                    border:
                        Border.all(color: const Color(0xFF5A1ABE), width: 1),
                  ),
                  child: const Icon(Icons.mail_outline_rounded,
                      color: Color(0xFF27AE60), size: 22),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'upload_bill.send_email'.tr,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          height: 1.22,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'upload_bill.send_email_address'.trParams({'email': ContactConstants.billInbox}),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          height: 1.22,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.black, size: 20),
              ],
            ),
          )),
    );
  }

  // ── What we are looking for card ──
  Widget _buildLookingForCard() {
    final bullets = [
      'upload_bill.looking_for_1'.tr,
      'upload_bill.looking_for_2'.tr,
      'upload_bill.looking_for_3'.tr,
      'upload_bill.looking_for_4'.tr,
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0FF),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFF5A1ABE), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'upload_bill.looking_for_title'.tr,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 1.22,
            ),
          ),
          SizedBox(height: 10.h),
          ...bullets.map(
            (b) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      height: 1.22,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        height: 1.22,
                      ),
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
}
