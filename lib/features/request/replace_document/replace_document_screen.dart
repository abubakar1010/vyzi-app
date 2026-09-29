import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/exceptions/app_exceptions.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/features/request/models/case_model.dart';
import 'package:vyzi/features/utility/multi_capture_screen.dart';

/// Where the customer answers an admin who rejected an identity document.
///
/// Each rejected document gets its own slot, so every file sent back is tied
/// to the one it replaces — the server returns that document to review and
/// tells the admins. A slot takes several files, since a new ID often arrives
/// as a front and a back. Pops `true` once everything is sent.
class ReplaceDocumentScreen extends StatefulWidget {
  final String caseId;
  final List<CaseDocumentModel> rejected;

  const ReplaceDocumentScreen({
    super.key,
    required this.caseId,
    required this.rejected,
  });

  @override
  State<ReplaceDocumentScreen> createState() => _ReplaceDocumentScreenState();
}

class _PickedFile {
  final String path;
  final String name;

  _PickedFile(this.path, this.name);
}

class _ReplaceDocumentScreenState extends State<ReplaceDocumentScreen> {
  /// Same ceiling as the request form, per rejected document.
  static const int _maxFiles = 10;

  final ApiService _api = ApiService();
  late final Map<String, List<_PickedFile>> _files = {
    for (final doc in widget.rejected) doc.id: <_PickedFile>[],
  };
  bool _submitting = false;

  bool get _canSubmit =>
      !_submitting && _files.values.every((files) => files.isNotEmpty);

  Future<void> _pickFiles(String docId) async {
    final remaining = _maxFiles - _files[docId]!.length;
    if (remaining <= 0) return;
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );
      if (result == null) return;
      setState(() {
        for (final file in result.files.take(remaining)) {
          if (file.path == null) continue;
          _files[docId]!.add(_PickedFile(file.path!, file.name));
        }
      });
    } catch (e) {
      _showError(e is AppException ? e.message : 'system.unexpected'.tr);
    }
  }

  Future<void> _takePhotos(String docId) async {
    final paths =
        await Navigator.of(context, rootNavigator: true).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => MultiCaptureScreen(
          existingCount: _files[docId]!.length,
          maxCount: _maxFiles,
          title: 'request.form.id_camera_title'.tr,
        ),
      ),
    );
    if (paths == null || paths.isEmpty || !mounted) return;
    setState(() {
      for (final path in paths) {
        _files[docId]!
            .add(_PickedFile(path, path.split(RegExp(r'[/\\]')).last));
      }
    });
  }

  /// Uploads each file, then attaches it to the case as the replacement for
  /// its rejected document. A file already attached is not sent twice if the
  /// customer retries after a failure part-way through.
  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);

    try {
      for (final entry in _files.entries) {
        final docId = entry.key;
        for (final file in List<_PickedFile>.from(entry.value)) {
          final upload = await _api.uploadFile(
            ApiConstants.fileUpload,
            file: await MultipartFile.fromFile(file.path, filename: file.name),
          );
          final uploadBody = upload.data as Map<String, dynamic>;
          final url = (uploadBody['data'] as Map<String, dynamic>?)?['url'];
          if (uploadBody['success'] != true || url is! String || url.isEmpty) {
            throw ServerException(
              uploadBody['message']?.toString() ?? '',
              uploadBody['statusCode'] as int?,
            );
          }

          final attach = await _api.post(
            ApiConstants.caseDocuments(widget.caseId),
            data: {
              'documentType': 'identity_document',
              'fileUrl': url,
              'fileName': file.name,
              'replacesDocumentId': docId,
            },
          );
          final attachBody = attach.data as Map<String, dynamic>;
          if (attachBody['success'] != true) {
            throw ServerException(
              attachBody['message']?.toString() ?? '',
              attachBody['statusCode'] as int?,
            );
          }
          if (mounted) setState(() => entry.value.remove(file));
        }
      }

      Get.snackbar(
        'case.document.replace.sent_title'.tr,
        'case.document.replace.sent_body'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.linkGreen,
        colorText: Colors.white,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _showError(e is AppException ? e.message : 'system.unexpected'.tr);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'auth.validation.error'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'case.document.replace.title'.tr,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                children: [
                  Text(
                    'case.document.replace.intro'.tr,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  for (final doc in widget.rejected) ...[
                    _documentCard(doc),
                    SizedBox(height: 14.h),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              child: SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    disabledBackgroundColor: AppColors.divider,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _submitting
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'case.document.replace.submit'.tr,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _documentCard(CaseDocumentModel doc) {
    final files = _files[doc.id]!;
    final canAdd = !_submitting && files.length < _maxFiles;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insert_drive_file_outlined,
                  size: 18.sp, color: Colors.red.shade400),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  doc.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'case.document.replace.reason'.tr}: ${doc.rejectionReasonLabel}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
                if ((doc.rejectionNote ?? '').isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    doc.rejectionNote!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.red.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 12.h),
          if (files.isNotEmpty) ...[
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                for (var i = 0; i < files.length; i++)
                  _fileChip(files[i].name,
                      onRemove: _submitting
                          ? null
                          : () => setState(() => files.removeAt(i))),
              ],
            ),
            SizedBox(height: 10.h),
          ],
          Row(
            children: [
              Expanded(
                child: _addButton(
                  icon: Icons.photo_camera_rounded,
                  label: 'request.form.take_photo_button'.tr,
                  enabled: canAdd,
                  onTap: () => _takePhotos(doc.id),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _addButton(
                  icon: Icons.upload_rounded,
                  label: 'request.form.upload_file_button'.tr,
                  enabled: canAdd,
                  onTap: () => _pickFiles(doc.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fileChip(String name, {VoidCallback? onRemove}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.greenAlpha10,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.linkGreen),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined,
              size: 12.sp, color: AppColors.linkGreen),
          SizedBox(width: 4.w),
          Text(
            name.length > 16 ? '${name.substring(0, 16)}...' : name,
            style: TextStyle(fontSize: 11.sp, color: AppColors.linkGreen),
          ),
          if (onRemove != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRemove,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Icon(Icons.close_rounded,
                    size: 12.sp, color: AppColors.linkGreen),
              ),
            ),
        ],
      ),
    );
  }

  Widget _addButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: enabled ? AppColors.background : AppColors.primary50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: enabled
                ? AppColors.primaryColor.withValues(alpha: 0.3)
                : AppColors.divider,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 24.sp,
                color: enabled
                    ? AppColors.primaryColor
                    : AppColors.textSecondary),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: enabled ? AppColors.textDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
