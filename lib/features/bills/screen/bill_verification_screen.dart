import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_colors.dart';
import '../../request/document_viewer_screen.dart';
import '../../utility/models/selected_file.dart';
import '../../utility/multi_capture_screen.dart';
import '../../utility/widgets/file_preview_card.dart';
import '../controller/bill_verification_controller.dart';
import '../models/bill_verification_model.dart';

/// Lets the customer answer an admin verification request by sending documents.
///
/// The picking experience deliberately mirrors the bill upload screen: an
/// "Upload File" card opening the system picker and a "Scan File" card opening
/// the multi-capture camera. There is no manual data entry — the admin reviews
/// the documents and updates the bill themselves.
class BillVerificationScreen extends StatefulWidget {
  const BillVerificationScreen({super.key});

  @override
  State<BillVerificationScreen> createState() => _BillVerificationScreenState();
}

class _BillVerificationScreenState extends State<BillVerificationScreen> {
  late final String _billId;
  late final BillVerificationController _controller;

  @override
  void initState() {
    super.initState();
    _billId = Get.arguments as String;
    _controller = Get.put(BillVerificationController(_billId));
  }

  @override
  void dispose() {
    _controller.clearState();
    Get.delete<BillVerificationController>();
    super.dispose();
  }

  Future<void> _openFilePicker() async {
    if (_controller.isUploading.value) return;
    if (_controller.isAtFileLimit) {
      Get.snackbar(
        'upload_bill.file_validation_title'.tr,
        'upload_bill.max_files_reached'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    await _controller.pickFiles();
  }

  Future<void> _openCamera() async {
    if (_controller.isUploading.value) return;

    final existingCount = _controller.selectedFiles.length;
    if (existingCount >= BillVerificationController.maxFileCount) {
      Get.snackbar(
        'upload_bill.file_validation_title'.tr,
        'upload_bill.max_files_reached'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final paths =
        await Navigator.of(context, rootNavigator: true).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => MultiCaptureScreen(
          existingCount: existingCount,
          maxCount: BillVerificationController.maxFileCount,
        ),
      ),
    );

    if (paths != null && paths.isNotEmpty) {
      await _controller.addCapturedPhotoPaths(paths);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('verification.title'.tr),
        centerTitle: true,
        elevation: 0,
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_controller.error.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 48.w, color: Colors.red.shade300),
                  SizedBox(height: 12.h),
                  Text(
                    _controller.error.value,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: _controller.fetchVerification,
                    child: Text('verification.retry'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        if (_controller.submitSuccess.value) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 64.w, color: const Color(0xFF1FC16B)),
                  SizedBox(height: 16.h),
                  Text(
                    'verification.submitted_title'.tr,
                    style:
                        TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'verification.submitted_message'.tr,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: Text('verification.done'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        final verification = _controller.verification.value;

        return Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (verification != null) ...[
                    _buildAdminMessage(verification),
                    SizedBox(height: 20.h),
                    _buildUploadSection(),
                    SizedBox(height: 20.h),
                    _buildMessageField(),
                    SizedBox(height: 24.h),
                    _buildSubmitButton(),
                    SizedBox(height: 24.h),
                  ],
                  if (_controller.verificationHistory.isNotEmpty) ...[
                    _VerificationHistory(
                      history: _controller.verificationHistory,
                      showTitle: verification != null,
                    ),
                  ] else if (verification == null) ...[
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 48.w, color: Colors.green),
                            SizedBox(height: 12.h),
                            Text(
                              'verification.none_pending'.tr,
                              style: TextStyle(
                                  fontSize: 16.sp, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 32.h),
                ],
              ),
            ),
            Obx(() => _controller.isUploading.value
                ? _buildUploadOverlay()
                : const SizedBox.shrink()),
          ],
        );
      }),
    );
  }

  // ─── Admin message ─────────────────────────────────────

  Widget _buildAdminMessage(BillVerificationModel verification) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 20.w, color: Colors.orange.shade700),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'verification.admin_message_title'.tr,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            verification.adminMessage,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.orange.shade900,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Upload section ────────────────────────────────────

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'verification.upload_documents'.tr,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Obx(() => Text(
                  '${_controller.selectedFiles.length}/${BillVerificationController.maxFileCount}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: _controller.isAtFileLimit
                        ? Colors.red
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                )),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          'verification.upload_hint'.tr,
          style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
        ),
        SizedBox(height: 12.h),

        // Same two-card picker as the bill upload screen.
        Row(
          children: [
            Expanded(
              child: _buildMethodCard(
                assetIcon: 'assets/icons/upload.webp',
                label: 'upload_bill.upload_file'.tr,
                sublabel: 'upload_bill.upload_formats'.tr,
                onTap: _openFilePicker,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildMethodCard(
                assetIcon: 'assets/icons/scannn.webp',
                label: 'upload_bill.scan_file'.tr,
                sublabel: 'upload_bill.scan_use_camera'.tr,
                onTap: _openCamera,
              ),
            ),
          ],
        ),

        // Selected files
        Obx(() {
          if (_controller.selectedFiles.isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: Column(
              children: _controller.selectedFiles
                  .map(
                    (file) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: FilePreviewCard(
                        file: file,
                        onRemove: file.status == FileUploadStatus.uploaded
                            ? null
                            : () => _controller.removeFileById(file.id),
                        onRetry: file.status == FileUploadStatus.failed
                            ? () => _controller.retryFile(file.id)
                            : null,
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        }),

        // Validation error
        Obx(() {
          if (_controller.fileError.value.isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              _controller.fileError.value,
              style: TextStyle(fontSize: 12.sp, color: Colors.red.shade600),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMethodCard({
    required String assetIcon,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFF5A1ABE), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(assetIcon, width: 56.w, height: 56.w, fit: BoxFit.contain),
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

  // ─── Message + submit ──────────────────────────────────

  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'verification.your_message'.tr,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'verification.your_message_hint'.tr,
            hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            contentPadding: EdgeInsets.all(14.w),
          ),
          onChanged: (value) => _controller.userMessage.value = value,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: _controller.canSubmit ? _controller.submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              // Without explicit disabled colours Material 3 falls back to a
              // near-invisible purple-on-purple label, which made the enabled
              // button look inactive.
              disabledBackgroundColor:
                  AppColors.primaryColor.withValues(alpha: 0.35),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: _controller.isSubmitting.value
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'verification.submit'.tr,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ));
  }

  // ─── Upload overlay ────────────────────────────────────

  Widget _buildUploadOverlay() {
    return AbsorbPointer(
      absorbing: true,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
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
                    color: Color(0xFF5A1ABE), strokeWidth: 3),
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
                Obx(() => ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: LinearProgressIndicator(
                        value: _controller.uploadProgress.value,
                        backgroundColor: const Color(0xFFE8E8E8),
                        color: const Color(0xFF5A1ABE),
                        minHeight: 8.h,
                      ),
                    )),
                SizedBox(height: 8.h),
                Obx(() => Text(
                      '${(_controller.uploadProgress.value * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5A1ABE),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Verification History ───────────────────────────────────

class _VerificationHistory extends StatelessWidget {
  final List<BillVerificationModel> history;
  final bool showTitle;

  const _VerificationHistory({
    required this.history,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Divider(color: Colors.grey.shade300),
          SizedBox(height: 12.h),
        ],
        Text(
          'verification.history_title'.tr,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 12.h),
        ...history.asMap().entries.map((entry) {
          final idx = entry.key;
          final v = entry.value;
          return _VerificationRoundCard(
            verification: v,
            roundNumber: idx + 1,
            isLast: idx == history.length - 1,
          );
        }),
      ],
    );
  }
}

class _VerificationRoundCard extends StatelessWidget {
  final BillVerificationModel verification;
  final int roundNumber;
  final bool isLast;

  const _VerificationRoundCard({
    required this.verification,
    required this.roundNumber,
    this.isLast = false,
  });

  Color get _typeColor => verification.isContract
      ? const Color(0xFF7061ED)
      : const Color(0xFF0288D1);

  Color get _statusColor {
    switch (verification.status) {
      case 'pending':
        return Colors.orange;
      case 'submitted':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (verification.status) {
      case 'pending':
        return 'verification.status_pending'.tr;
      case 'submitted':
        return 'verification.status_submitted'.tr;
      case 'resolved':
        return 'verification.status_resolved'.tr;
      default:
        return verification.status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The round label and both badges share whatever the date
                // leaves behind. A Wrap rather than a Row because the Italian
                // labels ("DOCUMENTO BOLLETTA", "IN ATTESA DI RISPOSTA") are
                // far too wide to sit on one line — they move to a second run
                // instead of overflowing the card.
                Expanded(
                  child: Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'verification.round'.trParams({
                          'number': roundNumber.toString(),
                        }),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      // The history mixes bill and contract requests, and they
                      // were answered on different screens — say which is which.
                      _buildBadge(
                        verification.isContract
                            ? 'verification.type_contract'.tr
                            : 'verification.type_bill'.tr,
                        _typeColor,
                      ),
                      _buildBadge(_statusLabel, _statusColor),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  _formatDate(verification.createdAt),
                  style:
                      TextStyle(fontSize: 11.sp, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Admin request
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'verification.admin_request'.tr,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        verification.adminMessage,
                        style: TextStyle(
                            fontSize: 13.sp, color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                ),

                // User response
                if (verification.status != 'pending') ...[
                  SizedBox(height: 10.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'verification.your_response'.tr,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        if (verification.userMessage != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            verification.userMessage!,
                            style: TextStyle(
                                fontSize: 13.sp, color: Colors.grey.shade800),
                          ),
                        ],
                        if (verification.files.isNotEmpty) ...[
                          SizedBox(height: 6.h),
                          Text(
                            'verification.uploaded_files'.trParams({
                              'count': verification.files.length.toString(),
                            }),
                            style: TextStyle(
                                fontSize: 11.sp, color: Colors.grey.shade500),
                          ),
                          SizedBox(height: 4.h),
                          ...verification.files.map((f) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 4.h),
                              child: GestureDetector(
                                onTap: () => _openFile(context, f),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8.r),
                                    border:
                                        Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        f.isImage
                                            ? Icons.image
                                            : Icons.picture_as_pdf,
                                        size: 18.w,
                                        color: f.isImage
                                            ? Colors.blue.shade400
                                            : Colors.red.shade400,
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              f.displayName,
                                              style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: Colors.grey.shade700),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (f.displaySize.isNotEmpty)
                                              Text(
                                                f.displaySize,
                                                style: TextStyle(
                                                    fontSize: 10.sp,
                                                    color:
                                                        Colors.grey.shade400),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.open_in_new,
                                        size: 16.w,
                                        color: AppColors.primaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                        if (verification.userMessage == null &&
                            verification.files.isEmpty)
                          Text(
                            'verification.no_details'.tr,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade400,
                            ),
                          ),
                      ],
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

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  void _openFile(BuildContext context, BillFileModel file) {
    final fileUrl = file.fileUrl;
    if (file.isImage) {
      // Open image in full-screen viewer
      final fullUrl = fileUrl.startsWith('http')
          ? fileUrl
          : '${ApiConstants.baseUrl}/${fileUrl.replaceAll(RegExp(r'^/'), '')}';
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _ImageViewerScreen(
            url: fullUrl,
            title: file.displayName,
          ),
        ),
      );
    } else {
      // Open PDF in DocumentViewerScreen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DocumentViewerScreen(
            url: fileUrl,
            title: file.displayName,
          ),
        ),
      );
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}

// ─── Image Viewer ──────────────────────────────────────────

class _ImageViewerScreen extends StatelessWidget {
  final String url;
  final String title;

  const _ImageViewerScreen({required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          title,
          style: TextStyle(fontSize: 16.sp),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_new, size: 20.w),
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (_, __, ___) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, size: 48.w, color: Colors.grey),
                SizedBox(height: 8.h),
                Text(
                  'verification.image_load_failed'.tr,
                  style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
