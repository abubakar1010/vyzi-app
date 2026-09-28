import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart' hide Response;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/selected_file.dart';
import 'select_utility_controller.dart';

enum UploadMethod { uploadFile, scanFile, sendEmail }

class UploadBillController extends GetxController {
  // ─── Single-file state (used by camera/scan flow) ──────
  final Rx<UploadMethod?> selectedMethod = Rx<UploadMethod?>(null);
  final Rx<XFile?> selectedFile = Rx<XFile?>(null);

  // Upload state (single-file)
  final RxDouble uploadProgress = 0.0.obs;
  final RxBool isUploading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString uploadedBillId = ''.obs;
  final RxBool uploadSuccess = false.obs;

  // ─── Multi-file state ──────────────────────────────────
  final RxList<SelectedFile> selectedFiles = <SelectedFile>[].obs;
  final RxBool isBatchUploading = false.obs;
  final RxBool batchUploadCompleted = false.obs;
  final RxBool isCancelled = false.obs;
  final RxInt currentUploadIndex = 0.obs;

  // Re-entry guard for uploadAllFiles()
  Completer<void>? _uploadCompleter;

  // ─── Constants ─────────────────────────────────────────
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxFileCount = 10;
  static const List<String> allowedExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'heic',
    'webp',
  ];

  // Stored utility type for auto-upload triggers
  UtilityType? _utilityType;

  /// Must be called before file selection so auto-upload knows the bill type.
  void init(UtilityType type) {
    _utilityType = type;
  }

  // ─── Single-file methods ──────────────────────────────

  void selectMethod(UploadMethod method) {
    selectedMethod.value = method;
  }

  void setSelectedFile(XFile file) {
    selectedFile.value = file;
    errorMessage.value = '';
    uploadSuccess.value = false;

    // Auto-trigger upload immediately
    if (_utilityType != null) {
      uploadBill(_utilityType!);
    }
  }

  void removeFile() {
    selectedFile.value = null;
    errorMessage.value = '';
    uploadSuccess.value = false;
    uploadedBillId.value = '';
  }

  bool validateFile(XFile file) {
    final ext = file.name.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      errorMessage.value = 'upload_bill.invalid_file_type'.tr;
      return false;
    }
    return true;
  }

  Future<bool> validateFileSize(XFile file) async {
    final fileSize = await File(file.path).length();
    if (fileSize > maxFileSizeBytes) {
      errorMessage.value = 'upload_bill.file_too_large'.tr;
      return false;
    }
    return true;
  }

  String get selectedFileName {
    final file = selectedFile.value;
    if (file == null) return '';
    return file.name;
  }

  String get selectedFileSize {
    final file = selectedFile.value;
    if (file == null) return '';
    try {
      final bytes = File(file.path).lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      }
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return '';
    }
  }

  // ─── Upload (single-file) ─────────────────────────────

  Future<void> uploadBill(UtilityType utilityType) async {
    final file = selectedFile.value;
    if (file == null) {
      errorMessage.value = 'upload_bill.no_files_selected'.tr;
      return;
    }

    if (!validateFile(file)) return;
    if (!await validateFileSize(file)) return;

    final billType =
        utilityType == UtilityType.luce ? 'electricity' : 'gas';

    isUploading.value = true;
    uploadProgress.value = 0.0;
    errorMessage.value = '';

    try {
      final data = <String, dynamic>{
        'billType': billType,
      };

      final multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: file.name,
      );
      final response = await ApiService().uploadFileWithProgress(
        ApiConstants.uploadBills,
        file: multipartFile,
        data: data,
        onSendProgress: (sent, total) {
          if (total > 0) {
            uploadProgress.value = sent / total;
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        final respBody = responseData is Map &&
                responseData.containsKey('data')
            ? responseData['data']
            : responseData;

        uploadedBillId.value = respBody?['id']?.toString() ?? '';
        uploadSuccess.value = true;
        debugPrint('Bill uploaded successfully: ${uploadedBillId.value}');
      } else {
        errorMessage.value = 'upload_bill.upload_failed'.tr;
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      errorMessage.value = 'upload_bill.upload_failed'.tr;
    } finally {
      isUploading.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════
  //  MULTI-FILE METHODS
  // ═══════════════════════════════════════════════════════

  // ─── 2.1 / 2.2: Add files with validation ─────────────

  /// Picks multiple files using file_picker and adds them to selectedFiles.
  /// Returns the number of files actually added.
  Future<int> pickMultipleFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'heic', 'webp'],
      );

      if (result == null || result.files.isEmpty) return 0;

      final added = addFiles(result.files);

      // Auto-trigger upload after adding files
      if (added > 0 && _utilityType != null) {
        await uploadAllFiles(_utilityType!);
      }

      return added;
    } on Exception catch (e) {
      debugPrint('File picker error: $e');
      // Handle permission denied or storage access errors
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

  /// Validates and adds files to the selectedFiles list.
  /// Handles duplicate detection, type validation, size validation,
  /// and max count enforcement.
  int addFiles(List<PlatformFile> files) {
    final List<String> skippedDuplicates = [];
    final List<String> skippedInvalid = [];
    final List<String> skippedOversized = [];
    int skippedOverLimit = 0;
    int added = 0;

    for (final file in files) {
      if (file.path == null) continue;

      // Max count check
      if (selectedFiles.length >= maxFileCount) {
        skippedOverLimit += (files.length - files.indexOf(file));
        break;
      }

      final ext = file.extension?.toLowerCase() ?? '';
      final name = file.name;
      final size = file.size;

      // Type validation
      if (!allowedExtensions.contains(ext)) {
        skippedInvalid.add(name);
        continue;
      }

      // Size validation
      if (size > maxFileSizeBytes) {
        final sizeMb = (size / (1024 * 1024)).toStringAsFixed(1);
        skippedOversized.add('$name ($sizeMb MB)');
        continue;
      }

      // Duplicate detection (name + size)
      final isDuplicate = selectedFiles.any(
        (existing) => existing.name == name && existing.sizeBytes == size,
      );
      if (isDuplicate) {
        skippedDuplicates.add(name);
        continue;
      }

      // Create SelectedFile
      final selectedFile = SelectedFile(
        id: '${DateTime.now().microsecondsSinceEpoch}_$added',
        path: file.path!,
        name: name,
        sizeBytes: size,
        extension: ext,
      );

      selectedFiles.add(selectedFile);
      added++;

      // Generate thumbnail asynchronously for images
      if (selectedFile.isImage) {
        _generateThumbnail(selectedFile);
      }
    }

    // Show feedback messages
    _showValidationFeedback(
      skippedDuplicates: skippedDuplicates,
      skippedInvalid: skippedInvalid,
      skippedOversized: skippedOversized,
      skippedOverLimit: skippedOverLimit,
    );

    return added;
  }

  /// Adds photos captured from MultiCaptureScreen to the multi-file list.
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
      _generateThumbnail(selected);
    }

    // Auto-trigger upload after adding captured photos
    if (selectedFiles.isNotEmpty && _utilityType != null) {
      await uploadAllFiles(_utilityType!);
    }
  }

  /// Adds a camera-captured photo to the multi-file list.
  /// Returns true if the photo was added successfully.
  Future<bool> addCameraPhoto(XFile photo) async {
    if (selectedFiles.length >= maxFileCount) {
      Get.snackbar(
        'upload_bill.file_validation_title'.tr,
        'upload_bill.max_files_reached'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final file = File(photo.path);
    final size = await file.length();
    final name = photo.name;
    final ext = name.split('.').last.toLowerCase();

    if (size > maxFileSizeBytes) {
      Get.snackbar(
        'upload_bill.file_validation_title'.tr,
        'upload_bill.file_too_large'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final selected = SelectedFile(
      id: '${DateTime.now().microsecondsSinceEpoch}_cam',
      path: photo.path,
      name: name,
      sizeBytes: size,
      extension: ext,
    );

    selectedFiles.add(selected);
    _generateThumbnail(selected);
    return true;
  }

  void _showValidationFeedback({
    required List<String> skippedDuplicates,
    required List<String> skippedInvalid,
    required List<String> skippedOversized,
    required int skippedOverLimit,
  }) {
    final messages = <String>[];

    if (skippedDuplicates.isNotEmpty) {
      messages.add(
        'upload_bill.skipped_duplicates'
            .trParams({'files': skippedDuplicates.join(', ')}),
      );
    }
    if (skippedInvalid.isNotEmpty) {
      messages.add(
        'upload_bill.skipped_invalid'
            .trParams({'files': skippedInvalid.join(', ')}),
      );
    }
    if (skippedOversized.isNotEmpty) {
      messages.add(
        'upload_bill.skipped_oversized'
            .trParams({'files': skippedOversized.join(', ')}),
      );
    }
    if (skippedOverLimit > 0) {
      messages.add(
        'upload_bill.skipped_over_limit'
            .trParams({'count': skippedOverLimit.toString()}),
      );
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

  // ─── 2.3: Remove file ────────────────────────────────

  void removeFileById(String fileId) {
    final index = selectedFiles.indexWhere((f) => f.id == fileId);
    if (index == -1) return;
    final file = selectedFiles[index];
    if (file.status == FileUploadStatus.uploaded) return;
    selectedFiles.removeAt(index);
  }

  // ─── 2.4: Clear all files ────────────────────────────

  void clearAllFiles() {
    selectedFiles.clear();
    isBatchUploading.value = false;
    batchUploadCompleted.value = false;
    isCancelled.value = false;
    currentUploadIndex.value = 0;
    final c = _uploadCompleter;
    _uploadCompleter = null;
    c?.complete();
  }

  // ─── 2.5: Computed getters ───────────────────────────

  List<SelectedFile> get pendingFiles =>
      selectedFiles.where((f) => f.status == FileUploadStatus.pending).toList();

  List<SelectedFile> get failedFiles =>
      selectedFiles.where((f) => f.status == FileUploadStatus.failed).toList();

  List<SelectedFile> get uploadedFilesMulti =>
      selectedFiles.where((f) => f.status == FileUploadStatus.uploaded).toList();

  bool get canStartUpload =>
      selectedFiles.isNotEmpty &&
      !isBatchUploading.value &&
      pendingFiles.isNotEmpty;

  int get totalFileCount => selectedFiles.length;

  double get overallProgress {
    if (selectedFiles.isEmpty) return 0.0;
    final completed = selectedFiles
        .where((f) =>
            f.status == FileUploadStatus.uploaded ||
            f.status == FileUploadStatus.failed)
        .length;
    return completed / selectedFiles.length;
  }

  bool get isAtFileLimit => selectedFiles.length >= maxFileCount;

  // ─── 3.4: Thumbnail generation ────────────────────────

  Future<void> _generateThumbnail(SelectedFile file) async {
    try {
      final imageFile = File(file.path);
      final bytes = await imageFile.readAsBytes();

      // Decode and resize to 200x200 max
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 200,
        targetHeight: 200,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
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

  // ─── 4.1: Batch upload ───────────────────────────────

  /// Processes all pending files sequentially.
  /// The first file creates the bill via POST /bills/upload.
  /// Subsequent files attach to that bill via POST /bills/:id/files.
  Future<void> uploadAllFiles(UtilityType utilityType) async {
    // Re-entry guard: if already running, await the existing operation
    if (_uploadCompleter != null) {
      await _uploadCompleter!.future;
      return;
    }
    _uploadCompleter = Completer<void>();

    final billType =
        utilityType == UtilityType.luce ? 'electricity' : 'gas';

    isBatchUploading.value = true;
    batchUploadCompleted.value = false;
    isCancelled.value = false;

    try {
      // Find or use existing bill ID from a previously uploaded file
      String? billId;
      for (final file in selectedFiles) {
        if (file.status == FileUploadStatus.uploaded &&
            file.uploadedBillId != null &&
            file.uploadedBillId!.isNotEmpty) {
          billId = file.uploadedBillId;
          break;
        }
      }

      for (int i = 0; i < selectedFiles.length; i++) {
        if (isCancelled.value) break;

        final file = selectedFiles[i];
        if (file.status == FileUploadStatus.uploaded) continue;
        if (file.status != FileUploadStatus.pending &&
            file.status != FileUploadStatus.failed) {
          continue;
        }

        currentUploadIndex.value = i;

        if (billId == null) {
          // First file: create the bill
          billId = await _processFirstFile(i, billType);
          // If bill creation failed, stop — remaining files stay pending for retry
          if (billId == null) break;
        } else {
          // Subsequent files: attach to existing bill
          await _processAdditionalFile(i, billId);
        }
      }
    } finally {
      isBatchUploading.value = false;
      batchUploadCompleted.value = true;
      final c = _uploadCompleter;
      _uploadCompleter = null;
      c?.complete();
    }
  }

  // ─── 4.2: First file — creates the bill ──────────────

  Future<String?> _processFirstFile(int index, String billType) async {
    try {
      _updateFileStatus(index, FileUploadStatus.uploading);

      final file = selectedFiles[index];
      final data = <String, dynamic>{'billType': billType};

      final multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: file.name,
      );
      final response = await ApiService().uploadFileWithProgress(
        ApiConstants.uploadBills,
        file: multipartFile,
        data: data,
        onSendProgress: (sent, total) {
          if (total > 0) {
            _updateFile(index, (f) => f.copyWith(
              progress: sent / total,
            ));
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        final respBody = responseData is Map &&
                responseData.containsKey('data')
            ? responseData['data']
            : responseData;

        final billId = respBody?['id']?.toString() ?? '';
        uploadedBillId.value = billId;
        _updateFile(index, (f) => f.copyWith(
          status: FileUploadStatus.uploaded,
          uploadedBillId: billId,
          progress: 1.0,
        ));
        debugPrint('Bill created: ${file.name} → bill $billId');
        return billId.isNotEmpty ? billId : null;
      } else {
        _updateFile(index, (f) => f.copyWith(
          status: FileUploadStatus.failed,
          errorMessage: 'upload_bill.upload_failed'.tr,
        ));
        return null;
      }
    } catch (e) {
      debugPrint('Upload failed for ${selectedFiles[index].name}: $e');
      _updateFile(index, (f) => f.copyWith(
        status: FileUploadStatus.failed,
        errorMessage: _getErrorMessage(e),
      ));
      return null;
    }
  }

  // ─── 4.2b: Additional files — attach to existing bill ──

  Future<void> _processAdditionalFile(int index, String billId) async {
    try {
      _updateFileStatus(index, FileUploadStatus.uploading);

      final file = selectedFiles[index];

      final multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: file.name,
      );
      final response = await ApiService().uploadFileWithProgress(
        ApiConstants.addFileToBill(billId),
        file: multipartFile,
        onSendProgress: (sent, total) {
          if (total > 0) {
            _updateFile(index, (f) => f.copyWith(
              progress: sent / total,
            ));
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _updateFile(index, (f) => f.copyWith(
          status: FileUploadStatus.uploaded,
          uploadedBillId: billId,
          progress: 1.0,
        ));
        debugPrint('File attached: ${file.name} → bill $billId');
      } else {
        _updateFile(index, (f) => f.copyWith(
          status: FileUploadStatus.failed,
          errorMessage: 'upload_bill.upload_failed'.tr,
        ));
      }
    } catch (e) {
      debugPrint('Upload failed for ${selectedFiles[index].name}: $e');
      _updateFile(index, (f) => f.copyWith(
        status: FileUploadStatus.failed,
        errorMessage: _getErrorMessage(e),
      ));
    }
  }

  // ─── 4.5: Retry single file ──────────────────────────

  Future<void> retrySingleFile(
      String fileId, UtilityType utilityType) async {
    final billType =
        utilityType == UtilityType.luce ? 'electricity' : 'gas';
    final index = selectedFiles.indexWhere((f) => f.id == fileId);
    if (index == -1) return;

    final file = selectedFiles[index];
    if (file.status != FileUploadStatus.failed) return;

    // Reset to pending state
    _updateFile(index, (f) => f.copyWith(
      status: FileUploadStatus.pending,
      progress: 0.0,
      errorMessage: null,
    ));

    isBatchUploading.value = true;
    isCancelled.value = false;

    // Check if a bill was already created by a previous file
    final existingBillId = _findExistingBillId();
    if (existingBillId != null) {
      await _processAdditionalFile(index, existingBillId);
    } else {
      await _processFirstFile(index, billType);
    }

    isBatchUploading.value = false;
  }

  // ─── 4.6: Retry all failed ───────────────────────────

  Future<void> retryAllFailed(UtilityType utilityType) async {
    final billType =
        utilityType == UtilityType.luce ? 'electricity' : 'gas';

    // Reset all failed files to pending
    for (int i = 0; i < selectedFiles.length; i++) {
      if (selectedFiles[i].status == FileUploadStatus.failed) {
        _updateFile(i, (f) => f.copyWith(
          status: FileUploadStatus.pending,
          progress: 0.0,
          errorMessage: null,
        ));
      }
    }

    isBatchUploading.value = true;
    batchUploadCompleted.value = false;
    isCancelled.value = false;

    String? billId = _findExistingBillId();

    for (int i = 0; i < selectedFiles.length; i++) {
      if (isCancelled.value) break;
      if (selectedFiles[i].status != FileUploadStatus.pending) continue;
      currentUploadIndex.value = i;

      if (billId == null) {
        billId = await _processFirstFile(i, billType);
        if (billId == null) break;
      } else {
        await _processAdditionalFile(i, billId);
      }
    }

    isBatchUploading.value = false;
    batchUploadCompleted.value = true;
  }

  String? _findExistingBillId() {
    for (final file in selectedFiles) {
      if (file.status == FileUploadStatus.uploaded &&
          file.uploadedBillId != null &&
          file.uploadedBillId!.isNotEmpty) {
        return file.uploadedBillId;
      }
    }
    return uploadedBillId.value.isNotEmpty ? uploadedBillId.value : null;
  }

  // ─── 4.7: Cancel upload ──────────────────────────────

  void cancelBatchUpload() {
    isCancelled.value = true;
  }

  // ─── Helpers ─────────────────────────────────────────

  void _updateFileStatus(int index, FileUploadStatus status) {
    if (index >= 0 && index < selectedFiles.length) {
      selectedFiles[index] = selectedFiles[index].copyWith(status: status);
    }
  }

  void _updateFile(
      int index, SelectedFile Function(SelectedFile) updater) {
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

  // ─── Clear ───────────────────────────────────────────

  void clearState() {
    selectedMethod.value = null;
    selectedFile.value = null;
    uploadProgress.value = 0.0;
    isUploading.value = false;
    errorMessage.value = '';
    uploadedBillId.value = '';
    uploadSuccess.value = false;
    clearAllFiles();
  }
}
