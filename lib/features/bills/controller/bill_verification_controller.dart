import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart' hide Response;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../utility/models/selected_file.dart';
import '../models/bill_verification_model.dart';

/// Drives the customer's response to an admin verification request.
///
/// The customer only sends documents — there is no manual field entry. File
/// selection, validation and upload mirror the bill upload flow so both screens
/// behave identically.
class BillVerificationController extends GetxController {
  final String billId;
  BillVerificationController(this.billId);

  final Rx<BillVerificationModel?> verification =
      Rx<BillVerificationModel?>(null);
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  // Form state
  final RxString userMessage = ''.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool submitSuccess = false.obs;

  // Multi-file upload state — same model as the bill upload flow.
  final RxList<SelectedFile> selectedFiles = <SelectedFile>[].obs;
  final RxList<String> uploadedFileIds = <String>[].obs;
  final RxBool isUploading = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final RxString fileError = ''.obs;

  // Verification history
  final RxList<BillVerificationModel> verificationHistory =
      <BillVerificationModel>[].obs;

  static const int maxFileCount = 10;
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const List<String> allowedExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'heic',
    'webp',
  ];

  @override
  void onInit() {
    super.onInit();
    fetchVerification();
    fetchVerificationHistory();
  }

  Future<void> fetchVerification() async {
    isLoading.value = true;
    error.value = '';

    try {
      final response = await ApiService().get(
        ApiConstants.getBillVerification(billId),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final body = data is Map && data.containsKey('data')
            ? data['data']
            : data;

        if (body != null && body is Map<String, dynamic>) {
          final pending = BillVerificationModel.fromJson(body);
          // A contract request is answered by re-uploading the signed contract
          // on the sign-contract screen — never by sending bill documents here.
          verification.value = pending.isContract ? null : pending;
        } else {
          verification.value = null;
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch verification: $e');
      error.value = 'verification.load_failed'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchVerificationHistory() async {
    try {
      final response = await ApiService().get(
        ApiConstants.getBillVerificationHistory(billId),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final list = data is Map && data.containsKey('data')
            ? data['data']
            : data;

        if (list is List) {
          verificationHistory.value = list
              .map((e) =>
                  BillVerificationModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch verification history: $e');
    }
  }

  // ─── File selection ────────────────────────────────────

  List<SelectedFile> get pendingFiles =>
      selectedFiles.where((f) => f.status == FileUploadStatus.pending).toList();

  List<SelectedFile> get failedFiles =>
      selectedFiles.where((f) => f.status == FileUploadStatus.failed).toList();

  List<SelectedFile> get uploadedFiles =>
      selectedFiles.where((f) => f.status == FileUploadStatus.uploaded).toList();

  bool get isAtFileLimit => selectedFiles.length >= maxFileCount;

  double get overallProgress {
    if (selectedFiles.isEmpty) return 0.0;
    final completed = selectedFiles
        .where((f) =>
            f.status == FileUploadStatus.uploaded ||
            f.status == FileUploadStatus.failed)
        .length;
    return completed / selectedFiles.length;
  }

  /// Opens the system file picker. Mirrors `UploadBillController.pickMultipleFiles`.
  Future<int> pickFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );
      if (result == null || result.files.isEmpty) return 0;
      return addFiles(result.files);
    } on Exception catch (e) {
      debugPrint('File picker error: $e');
      final msg = e.toString().toLowerCase();
      if (msg.contains('permission') || msg.contains('denied')) {
        Get.snackbar(
          'upload_bill.permission_required_title'.tr,
          'upload_bill.permission_required_message'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
      } else if (msg.contains('security') || msg.contains('access')) {
        Get.snackbar(
          'upload_bill.file_validation_title'.tr,
          'upload_bill.error_storage_access'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return 0;
    }
  }

  /// Validates and adds picked files: max count, extension, size and duplicates.
  int addFiles(List<PlatformFile> files) {
    final List<String> skippedDuplicates = [];
    final List<String> skippedInvalid = [];
    final List<String> skippedOversized = [];
    int skippedOverLimit = 0;
    int added = 0;

    for (final file in files) {
      if (file.path == null) continue;

      if (selectedFiles.length >= maxFileCount) {
        skippedOverLimit += (files.length - files.indexOf(file));
        break;
      }

      final ext = file.extension?.toLowerCase() ?? '';
      final name = file.name;
      final size = file.size;

      if (!allowedExtensions.contains(ext)) {
        skippedInvalid.add(name);
        continue;
      }

      if (size > maxFileSizeBytes) {
        final sizeMb = (size / (1024 * 1024)).toStringAsFixed(1);
        skippedOversized.add('$name ($sizeMb MB)');
        continue;
      }

      final isDuplicate = selectedFiles.any(
        (existing) => existing.name == name && existing.sizeBytes == size,
      );
      if (isDuplicate) {
        skippedDuplicates.add(name);
        continue;
      }

      final selectedFile = SelectedFile(
        id: '${DateTime.now().microsecondsSinceEpoch}_$added',
        path: file.path!,
        name: name,
        sizeBytes: size,
        extension: ext,
      );

      selectedFiles.add(selectedFile);
      added++;
      fileError.value = '';

      if (selectedFile.isImage) {
        _generateThumbnail(selectedFile);
      }
    }

    _showValidationFeedback(
      skippedDuplicates: skippedDuplicates,
      skippedInvalid: skippedInvalid,
      skippedOversized: skippedOversized,
      skippedOverLimit: skippedOverLimit,
    );

    return added;
  }

  /// Adds photos returned by `MultiCaptureScreen`.
  Future<void> addCapturedPhotoPaths(List<String> paths) async {
    for (final path in paths) {
      if (selectedFiles.length >= maxFileCount) break;

      final file = File(path);
      final size = await file.length();
      final name = path.split('/').last;
      final ext = name.split('.').last.toLowerCase();

      if (size > maxFileSizeBytes) continue;

      final selected = SelectedFile(
        id: '${DateTime.now().microsecondsSinceEpoch}_cam',
        path: path,
        name: name,
        sizeBytes: size,
        extension: ext,
      );

      selectedFiles.add(selected);
      fileError.value = '';
      _generateThumbnail(selected);
    }
  }

  void _showValidationFeedback({
    required List<String> skippedDuplicates,
    required List<String> skippedInvalid,
    required List<String> skippedOversized,
    required int skippedOverLimit,
  }) {
    final messages = <String>[];

    if (skippedDuplicates.isNotEmpty) {
      messages.add('upload_bill.skipped_duplicates'
          .trParams({'files': skippedDuplicates.join(', ')}));
    }
    if (skippedInvalid.isNotEmpty) {
      messages.add('upload_bill.skipped_invalid'
          .trParams({'files': skippedInvalid.join(', ')}));
    }
    if (skippedOversized.isNotEmpty) {
      messages.add('upload_bill.skipped_oversized'
          .trParams({'files': skippedOversized.join(', ')}));
    }
    if (skippedOverLimit > 0) {
      messages.add('upload_bill.skipped_over_limit'
          .trParams({'count': skippedOverLimit.toString()}));
    }

    if (messages.isNotEmpty) {
      Get.snackbar(
        'upload_bill.file_validation_title'.tr,
        messages.join('\n'),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  }

  void removeFileById(String fileId) {
    final index = selectedFiles.indexWhere((f) => f.id == fileId);
    if (index == -1) return;
    if (selectedFiles[index].status == FileUploadStatus.uploaded) return;
    selectedFiles.removeAt(index);
  }

  void clearAllFiles() {
    selectedFiles.clear();
    uploadedFileIds.clear();
    uploadProgress.value = 0.0;
    isUploading.value = false;
  }

  Future<void> _generateThumbnail(SelectedFile file) async {
    try {
      final bytes = await File(file.path).readAsBytes();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 200,
        targetHeight: 200,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      if (byteData != null) {
        final index = selectedFiles.indexWhere((f) => f.id == file.id);
        if (index != -1) {
          selectedFiles[index] = selectedFiles[index].copyWith(
            thumbnail: byteData.buffer.asUint8List(),
          );
        }
      }
    } catch (e) {
      debugPrint('Thumbnail generation failed for ${file.name}: $e');
    }
  }

  void _updateFile(int index, SelectedFile Function(SelectedFile) updater) {
    if (index >= 0 && index < selectedFiles.length) {
      selectedFiles[index] = updater(selectedFiles[index]);
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'upload_bill.error_network'.tr;
      }
      if (error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'upload_bill.error_timeout'.tr;
      }
      final statusCode = error.response?.statusCode;
      if (statusCode != null && statusCode >= 500) {
        return 'upload_bill.error_server'.tr;
      }
    }
    if (error is FileSystemException) {
      return 'upload_bill.error_file_access'.tr;
    }
    return 'upload_bill.upload_failed'.tr;
  }

  // ─── Upload ────────────────────────────────────────────

  /// Uploads every pending/failed file and attaches it to this verification
  /// round. Returns true when nothing is left in a failed state.
  Future<bool> uploadFiles() async {
    if (selectedFiles.isEmpty) return true;

    isUploading.value = true;
    uploadProgress.value = 0.0;

    final verificationId = verification.value?.id;
    var url = ApiConstants.addFileToBill(billId);
    if (verificationId != null && verificationId.isNotEmpty) {
      url += '?verificationId=$verificationId';
    }

    try {
      for (var i = 0; i < selectedFiles.length; i++) {
        final file = selectedFiles[i];
        if (file.status == FileUploadStatus.uploaded) continue;
        if (file.status != FileUploadStatus.pending &&
            file.status != FileUploadStatus.failed) {
          continue;
        }

        _updateFile(
          i,
          (f) => f.copyWith(
            status: FileUploadStatus.uploading,
            progress: 0.0,
            errorMessage: '',
          ),
        );

        try {
          final multipartFile = await MultipartFile.fromFile(
            file.path,
            filename: file.name,
          );

          final response = await ApiService().uploadFileWithProgress(
            url,
            file: multipartFile,
            onSendProgress: (sent, total) {
              if (total > 0) {
                final fileProgress = sent / total;
                _updateFile(i, (f) => f.copyWith(progress: fileProgress));
                uploadProgress.value =
                    (i + fileProgress) / selectedFiles.length;
              }
            },
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = response.data;
            final body =
                data is Map && data.containsKey('data') ? data['data'] : data;
            if (body is Map && body['id'] != null) {
              uploadedFileIds.add(body['id'].toString());
            }
            _updateFile(
              i,
              (f) => f.copyWith(
                status: FileUploadStatus.uploaded,
                progress: 1.0,
              ),
            );
          } else {
            _updateFile(
              i,
              (f) => f.copyWith(
                status: FileUploadStatus.failed,
                errorMessage: 'upload_bill.upload_failed'.tr,
              ),
            );
          }
        } catch (e) {
          debugPrint('Upload failed for ${file.name}: $e');
          _updateFile(
            i,
            (f) => f.copyWith(
              status: FileUploadStatus.failed,
              errorMessage: _getErrorMessage(e),
            ),
          );
        }
      }

      uploadProgress.value = 1.0;
      return failedFiles.isEmpty;
    } finally {
      isUploading.value = false;
    }
  }

  /// Retries a single failed upload.
  Future<void> retryFile(String fileId) async {
    final index = selectedFiles.indexWhere((f) => f.id == fileId);
    if (index == -1) return;
    if (selectedFiles[index].status != FileUploadStatus.failed) return;
    _updateFile(
      index,
      (f) => f.copyWith(status: FileUploadStatus.pending, errorMessage: ''),
    );
    await uploadFiles();
  }

  // ─── Submit ────────────────────────────────────────────

  /// True once the customer has added (or already uploaded) at least one document.
  bool get hasDocuments =>
      selectedFiles.isNotEmpty || uploadedFileIds.isNotEmpty;

  bool get canSubmit =>
      verification.value != null &&
      hasDocuments &&
      !isSubmitting.value &&
      !isUploading.value;

  bool validate() {
    fileError.value = '';
    if (selectedFiles.isEmpty && uploadedFileIds.isEmpty) {
      fileError.value = 'verification.file_required'.tr;
      return false;
    }
    return true;
  }

  Future<void> submit() async {
    if (!validate()) {
      Get.snackbar(
        'verification.missing_documents_title'.tr,
        'verification.file_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSubmitting.value = true;

    try {
      // Send the files first, then register the response.
      final allUploaded = await uploadFiles();

      if (!allUploaded && uploadedFileIds.isEmpty) {
        Get.snackbar(
          'upload_bill.upload_failed'.tr,
          'verification.upload_retry'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final body = <String, dynamic>{};
      if (userMessage.value.trim().isNotEmpty) {
        body['message'] = userMessage.value.trim();
      }
      if (uploadedFileIds.isNotEmpty) {
        body['fileIds'] = uploadedFileIds.toList();
      }

      final response = await ApiService().post(
        ApiConstants.submitBillVerification(billId),
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        submitSuccess.value = true;
        Get.snackbar(
          'verification.submitted_title'.tr,
          'verification.submitted_message'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Verification submit failed: $e');
      Get.snackbar(
        'verification.error_title'.tr,
        'verification.submit_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  void clearState() {
    userMessage.value = '';
    submitSuccess.value = false;
    isSubmitting.value = false;
    fileError.value = '';
    clearAllFiles();
  }
}
