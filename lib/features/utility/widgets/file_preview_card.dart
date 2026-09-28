import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../models/selected_file.dart';

class FilePreviewCard extends StatelessWidget {
  final SelectedFile file;
  final VoidCallback? onRemove;
  final VoidCallback? onRetry;

  const FilePreviewCard({
    super.key,
    required this.file,
    this.onRemove,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${'upload_bill.file_card'.tr}: ${file.name}, ${file.formattedSize}, $_statusLabel',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7FF),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: _borderColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail / Icon
            _buildThumbnail(),
            SizedBox(width: 10.w),

            // File info + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Text(
                        '${file.extension.toUpperCase()} • ${file.formattedSize}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _buildStatusBadge(),
                    ],
                  ),
                  // Progress bar during uploading
                  if (file.status == FileUploadStatus.uploading) ...[
                    SizedBox(height: 4.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: file.progress,
                        backgroundColor: const Color(0xFFE8E8E8),
                        color: const Color(0xFF5A1ABE),
                        minHeight: 4.h,
                      ),
                    ),
                  ],
                  // Error message if failed
                  if (file.status == FileUploadStatus.failed &&
                      file.errorMessage != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      file.errorMessage!,
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE53935),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Action buttons
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    const double size = 40;

    if (file.isImage && file.thumbnail != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Image.memory(
          file.thumbnail!,
          width: size.w,
          height: size.w,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        color: file.isPdf
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(
        file.isPdf
            ? Icons.picture_as_pdf_rounded
            : Icons.image_rounded,
        color: file.isPdf
            ? const Color(0xFFE53935)
            : const Color(0xFF43A047),
        size: 22,
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: _badgeBackgroundColor,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (file.status == FileUploadStatus.uploading)
            Padding(
              padding: EdgeInsets.only(right: 3.w),
              child: SizedBox(
                width: 8.w,
                height: 8.w,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: _badgeTextColor,
                ),
              ),
            ),
          if (file.status == FileUploadStatus.uploaded)
            Padding(
              padding: EdgeInsets.only(right: 3.w),
              child: Icon(
                Icons.check_circle_rounded,
                size: 10,
                color: _badgeTextColor,
              ),
            ),
          Text(
            _statusLabel,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              color: _badgeTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Retry button (failed only)
        if (file.status == FileUploadStatus.failed && onRetry != null)
          Semantics(
            label: 'upload_bill.retry_file'.tr,
            child: GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  color: const Color(0xFFFF9800),
                  size: 18,
                ),
              ),
            ),
          ),

        if (file.status == FileUploadStatus.failed && onRetry != null)
          SizedBox(width: 6.w),

        // Remove button (not for uploaded or actively processing)
        if (file.status != FileUploadStatus.uploaded &&
            file.status != FileUploadStatus.uploading &&
            onRemove != null)
          Semantics(
            label: 'upload_bill.remove_file'.tr,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: EdgeInsets.all(10.w),
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
          ),
      ],
    );
  }

  String get _statusLabel {
    switch (file.status) {
      case FileUploadStatus.pending:
        return 'upload_bill.status_pending'.tr;
      case FileUploadStatus.uploading:
        final pct = (file.progress * 100).toStringAsFixed(0);
        return '${'upload_bill.status_uploading'.tr} $pct%';
      case FileUploadStatus.uploaded:
        return 'upload_bill.status_uploaded'.tr;
      case FileUploadStatus.failed:
        return 'upload_bill.status_failed'.tr;
    }
  }

  Color get _borderColor {
    switch (file.status) {
      case FileUploadStatus.uploaded:
        return const Color(0xFF43A047);
      case FileUploadStatus.failed:
        return const Color(0xFFE53935);
      case FileUploadStatus.uploading:
        return const Color(0xFF5A1ABE);
      default:
        return const Color(0xFFE8E8E8);
    }
  }

  Color get _badgeBackgroundColor {
    switch (file.status) {
      case FileUploadStatus.pending:
        return const Color(0xFFF5F5F5);
      case FileUploadStatus.uploading:
        return const Color(0xFFE3F2FD);
      case FileUploadStatus.uploaded:
        return const Color(0xFFE8F5E9);
      case FileUploadStatus.failed:
        return const Color(0xFFFFEBEE);
    }
  }

  Color get _badgeTextColor {
    switch (file.status) {
      case FileUploadStatus.pending:
        return Colors.grey[600]!;
      case FileUploadStatus.uploading:
        return const Color(0xFF1976D2);
      case FileUploadStatus.uploaded:
        return const Color(0xFF2E7D32);
      case FileUploadStatus.failed:
        return const Color(0xFFE53935);
    }
  }
}
