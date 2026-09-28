import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Full-screen camera that stays open for continuous multi-photo capture.
/// Returns [List<String>] of captured file paths via [Navigator.pop].
class MultiCaptureScreen extends StatefulWidget {
  /// How many photos the caller already has (to enforce the global limit).
  final int existingCount;

  /// Maximum total photos allowed (existing + new).
  final int maxCount;

  const MultiCaptureScreen({
    super.key,
    required this.existingCount,
    required this.maxCount,
  });

  @override
  State<MultiCaptureScreen> createState() => _MultiCaptureScreenState();
}

class _MultiCaptureScreenState extends State<MultiCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  final List<String> _capturedPaths = [];
  bool _isInitializing = true;
  bool _hasError = false;
  bool _isCapturing = false;
  FlashMode _flashMode = FlashMode.auto;

  int get _remaining => widget.maxCount - widget.existingCount - _capturedPaths.length;
  bool get _isAtLimit => _remaining <= 0;
  int get _totalCaptured => widget.existingCount + _capturedPaths.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _isInitializing = true;
      _hasError = false;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _hasError = true;
          _isInitializing = false;
        });
        return;
      }

      // Prefer back camera
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      await controller.setFlashMode(_flashMode);

      if (!mounted) {
        controller.dispose();
        return;
      }

      _cameraController = controller;
      setState(() => _isInitializing = false);
    } on CameraException catch (e) {
      debugPrint('Camera init error: ${e.code} - ${e.description}');
      if (mounted) setState(() { _hasError = true; _isInitializing = false; });
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) setState(() { _hasError = true; _isInitializing = false; });
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (_isCapturing || _isAtLimit) return;

    setState(() => _isCapturing = true);

    try {
      final xFile = await controller.takePicture();
      _capturedPaths.add(xFile.path);

      if (_isAtLimit) {
        Get.snackbar(
          'upload_bill.file_validation_title'.tr,
          'upload_bill.camera_limit_reached'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } on CameraException catch (e) {
      debugPrint('Capture error: ${e.code} - ${e.description}');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _removePhoto(int index) {
    final path = _capturedPaths[index];
    setState(() => _capturedPaths.removeAt(index));
    // Delete temp file
    File(path).delete().catchError((_) => File(path));
  }

  void _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    FlashMode next;
    switch (_flashMode) {
      case FlashMode.auto:
        next = FlashMode.always;
        break;
      case FlashMode.always:
        next = FlashMode.off;
        break;
      default:
        next = FlashMode.auto;
    }

    try {
      await controller.setFlashMode(next);
      setState(() => _flashMode = next);
    } on CameraException catch (_) {}
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.off:
        return Icons.flash_off;
      default:
        return Icons.flash_auto;
    }
  }

  String get _flashLabel {
    switch (_flashMode) {
      case FlashMode.auto:
        return 'Auto';
      case FlashMode.always:
        return 'On';
      case FlashMode.off:
        return 'Off';
      default:
        return 'Auto';
    }
  }

  Future<void> _onClose() async {
    if (_capturedPaths.isEmpty) {
      Navigator.pop(context, <String>[]);
      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('upload_bill.camera_discard_title'.tr),
        content: Text(
          'upload_bill.camera_discard_message'
              .trParams({'count': _capturedPaths.length.toString()}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('upload_bill.camera_discard_no'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'upload_bill.camera_discard_yes'.tr,
              style: const TextStyle(color: Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );

    if (discard == true && mounted) {
      // Clean up temp files
      for (final path in _capturedPaths) {
        File(path).delete().catchError((_) => File(path));
      }
      Navigator.pop(context, <String>[]);
    }
  }

  void _onDone() {
    Navigator.pop(context, List<String>.from(_capturedPaths));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildCameraPreview()),
            if (_capturedPaths.isNotEmpty) _buildThumbnailStrip(),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        children: [
          IconButton(
            onPressed: _onClose,
            icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
          ),
          Expanded(
            child: Text(
              'upload_bill.camera_title'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Photo count badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: _isAtLimit
                  ? const Color(0xFFE53935).withOpacity(0.8)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              '$_totalCaptured / ${widget.maxCount}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_isInitializing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16.h),
            Text(
              'upload_bill.camera_initializing'.tr,
              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt_outlined,
                  color: Colors.white38, size: 64.sp),
              SizedBox(height: 16.h),
              Text(
                'upload_bill.camera_error'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
              SizedBox(height: 16.h),
              OutlinedButton(
                onPressed: _initCamera,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                child: Text('Retry', style: TextStyle(fontSize: 14.sp)),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _cameraController!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = controller.value.previewSize!;
        // previewSize is in landscape orientation (width > height),
        // so swap for portrait: aspect = sensorWidth / sensorHeight
        final cameraAspect = previewSize.height / previewSize.width;
        final widgetAspect = constraints.maxWidth / constraints.maxHeight;

        // Scale so the preview always fills the full width
        final scale = widgetAspect < cameraAspect
            ? constraints.maxHeight / (constraints.maxWidth / cameraAspect)
            : constraints.maxWidth / (constraints.maxHeight * cameraAspect);

        return ClipRect(
          child: Transform.scale(
            scale: scale > 1 ? scale : 1,
            child: Center(
              child: CameraPreview(controller),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThumbnailStrip() {
    return Container(
      color: Colors.black,
      height: 80.h,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        itemCount: _capturedPaths.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, index) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.file(
                  File(_capturedPaths[index]),
                  width: 60.w,
                  height: 60.h,
                  fit: BoxFit.cover,
                  cacheWidth: 120,
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: () => _removePhoto(index),
                  child: Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 12.sp),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Flash toggle
          GestureDetector(
            onTap: _toggleFlash,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_flashIcon, color: Colors.white, size: 24.sp),
                SizedBox(height: 4.h),
                Text(
                  _flashLabel,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Capture button
          GestureDetector(
            onTap: _isAtLimit ? null : _capturePhoto,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isAtLimit ? Colors.white24 : Colors.white,
                  width: 4,
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isCapturing
                      ? Colors.white38
                      : _isAtLimit
                          ? Colors.white12
                          : Colors.white,
                ),
              ),
            ),
          ),

          // Done button
          GestureDetector(
            onTap: _capturedPaths.isEmpty ? null : _onDone,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: _capturedPaths.isEmpty
                      ? Colors.white24
                      : const Color(0xFF1FC16B),
                  size: 28.sp,
                ),
                SizedBox(height: 4.h),
                Text(
                  'upload_bill.camera_done'.tr,
                  style: TextStyle(
                    color: _capturedPaths.isEmpty
                        ? Colors.white24
                        : Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
