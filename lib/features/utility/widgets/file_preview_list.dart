import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/upload_bill_controller.dart';
import '../models/selected_file.dart';
import 'file_preview_card.dart';

class FilePreviewList extends StatelessWidget {
  final UploadBillController controller;
  final VoidCallback? onRetry;
  final Function(String fileId)? onRetrySingle;

  const FilePreviewList({
    super.key,
    required this.controller,
    this.onRetry,
    this.onRetrySingle,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final files = controller.selectedFiles;

      if (files.isEmpty) {
        return _buildEmptyState();
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // File count header
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file_rounded,
                  size: 16,
                  color: const Color(0xFF5A1ABE),
                ),
                SizedBox(width: 6.w),
                Text(
                  'upload_bill.files_selected'
                      .trParams({'count': files.length.toString()}),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                if (files.length > 1 &&
                    !controller.isBatchUploading.value)
                  GestureDetector(
                    onTap: controller.clearAllFiles,
                    child: Text(
                      'upload_bill.clear_all'.tr,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE53935),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // File cards with animation
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 300.h),
            child: ListView.separated(
              shrinkWrap: true,
              physics: files.length > 3
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: files.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final file = files[index];
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: FilePreviewCard(
                    key: ValueKey(file.id),
                    file: file,
                    onRemove: () => controller.removeFileById(file.id),
                    onRetry: file.status == FileUploadStatus.failed
                        ? () => onRetrySingle?.call(file.id)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildEmptyState() {
    return Semantics(
      label: 'upload_bill.no_files_selected'.tr,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 32.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7FF),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: const Color(0xFFE8E8E8),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 40.w,
              color: Colors.grey[400],
            ),
            SizedBox(height: 10.h),
            Text(
              'upload_bill.no_files_selected'.tr,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'upload_bill.tap_to_select'.tr,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
