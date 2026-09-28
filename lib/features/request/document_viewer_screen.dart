import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/utils/app_colors.dart';

/// How the cached file should be rendered.
enum _DocKind { pdf, image, other }

/// Full-screen viewer for any document the backend stores under `/uploads/`.
///
/// The file is always downloaded to the local cache first, then rendered
/// according to its type: PDFs go through [PdfViewPinch], images through an
/// [InteractiveViewer], and anything else falls back to the system handler.
/// Nothing here can end in a silent no-op — every failure surfaces an error
/// state with a retry and a "save / open elsewhere" escape hatch.
class DocumentViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  /// Mime type reported by the backend, when known. Used together with the
  /// file extension to decide how to render the document.
  final String? mimeType;

  /// Stored file name, used for extension sniffing when [url] carries none.
  final String? fileName;

  const DocumentViewerScreen({
    super.key,
    required this.url,
    required this.title,
    this.mimeType,
    this.fileName,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  File? _cachedFile;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isDownloading = false;

  /// Only created for [_DocKind.pdf], once the file is on disk. Owns a native
  /// document handle, so it has to be closed in [dispose].
  PdfControllerPinch? _pdfController;

  late final String _fullUrl;
  late final _DocKind _kind;

  @override
  void initState() {
    super.initState();
    _fullUrl = widget.url.startsWith('http')
        ? widget.url
        : '${ApiConstants.baseUrl}/${widget.url.replaceAll(RegExp(r'^/'), '')}';
    _kind = _resolveKind();
    _loadDocument();
  }

  /// Trusts the mime type first, then falls back to the extension of the
  /// stored file name or of the URL itself.
  _DocKind _resolveKind() {
    final mime = widget.mimeType?.toLowerCase().trim();
    if (mime != null && mime.isNotEmpty) {
      if (mime == 'application/pdf') return _DocKind.pdf;
      if (mime.startsWith('image/')) return _DocKind.image;
    }

    // Strip any query string before looking at the extension.
    final candidates = [widget.fileName, widget.url]
        .whereType<String>()
        .map((v) => v.split('?').first.toLowerCase());

    for (final value in candidates) {
      if (value.endsWith('.pdf')) return _DocKind.pdf;
      if (value.endsWith('.jpg') ||
          value.endsWith('.jpeg') ||
          value.endsWith('.png') ||
          value.endsWith('.webp') ||
          value.endsWith('.gif') ||
          value.endsWith('.bmp') ||
          value.endsWith('.heic')) {
        return _DocKind.image;
      }
    }

    return _DocKind.other;
  }

  Future<void> _loadDocument() async {
    // Retry path: drop the handle from the previous attempt before opening
    // another one.
    _pdfController?.dispose();
    _pdfController = null;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final file = await DefaultCacheManager().getSingleFile(_fullUrl);

      // Opening the document is what actually fails on a corrupt or
      // password-protected PDF -- the OS renderer refuses encrypted files --
      // so it happens here, where the error state already exists, rather than
      // inside build().
      PdfControllerPinch? controller;
      if (_kind == _DocKind.pdf) {
        controller = PdfControllerPinch(
          document: PdfDocument.openFile(file.path),
        );
        await controller.document;
      }

      if (mounted) {
        setState(() {
          _cachedFile = file;
          _pdfController = controller;
          _isLoading = false;
        });
      } else {
        controller?.dispose();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadDocument() async {
    if (_cachedFile == null || _isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final dir = await getTemporaryDirectory();
      final fileName = widget.fileName?.isNotEmpty == true
          ? widget.fileName!
          : widget.url.split('/').last;
      final targetPath = '${dir.path}/$fileName';

      await _cachedFile!.copy(targetPath);

      if (mounted) {
        setState(() => _isDownloading = false);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(targetPath)], title: widget.title),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isDownloading = false);
        _snack('document_viewer.save_error_title'.tr,
            'document_viewer.save_error_message'.tr);
      }
    }
  }

  /// Last-resort handover to the OS. Never gated on [canLaunchUrl] alone —
  /// on Android 11+ that returns false unless the target intent is declared
  /// in the manifest, which used to make the tap look like a dead button.
  Future<void> _openExternally() async {
    final uri = Uri.parse(_fullUrl);
    for (final mode in const [
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
    ]) {
      try {
        if (await launchUrl(uri, mode: mode)) return;
      } catch (_) {
        // Try the next mode before giving up.
      }
    }
    if (mounted) {
      _snack('document_viewer.save_error_title'.tr,
          'document_viewer.open_external_error'.tr);
    }
  }

  void _snack(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
    );
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Images read best on a dark backdrop; documents keep the app background.
    final isImage = _kind == _DocKind.image;
    final chrome = isImage ? Colors.black : AppColors.background;
    final onChrome = isImage ? Colors.white : AppColors.textDark;

    return Scaffold(
      backgroundColor: chrome,
      appBar: AppBar(
        backgroundColor: chrome,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 40,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(Icons.chevron_left, color: onChrome, size: 28),
          ),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: onChrome,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_cachedFile != null)
            GestureDetector(
              onTap: _isDownloading ? null : _downloadDocument,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                child: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.download_rounded, color: onChrome, size: 22),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? _buildLoading()
            : _hasError || _cachedFile == null
                ? _buildError()
                : _buildViewer(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.purple, strokeWidth: 3),
    );
  }

  Widget _buildViewer() {
    switch (_kind) {
      case _DocKind.pdf:
        return _buildPdfViewer();
      case _DocKind.image:
        return _buildImageViewer();
      case _DocKind.other:
        return _buildUnsupported();
    }
  }

  Widget _buildPdfViewer() {
    final controller = _pdfController;
    if (controller == null) return _buildError();

    // PdfViewPinch scrolls continuously and pinch-zooms, matching the previous
    // enableSwipe + autoSpacing + swipeHorizontal:false behaviour.
    return PdfViewPinch(
      controller: controller,
      scrollDirection: Axis.vertical,
      onDocumentError: (_) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      },
    );
  }

  Widget _buildImageViewer() {
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.file(
          _cachedFile!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildError(),
        ),
      ),
    );
  }

  /// The file type has no in-app renderer — offer the OS handler and the
  /// share sheet instead of showing a blank screen.
  Widget _buildUnsupported() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_outlined,
                color: AppColors.purple, size: 48),
            const SizedBox(height: 12),
            Text(
              'document_viewer.unsupported'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: _openExternally,
                icon: const Icon(Icons.open_in_new, size: 16),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                label: Text(
                  'document_viewer.open_external'.tr,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              'document_viewer.error'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _loadDocument,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'common.retry'.tr,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: _openExternally,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.purple,
                      side: const BorderSide(color: AppColors.purple),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'document_viewer.open_external'.tr,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
