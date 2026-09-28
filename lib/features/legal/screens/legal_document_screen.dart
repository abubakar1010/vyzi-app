import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/features/legal/controller/legal_controller.dart';
import 'package:vyzi/features/legal/models/legal_document_model.dart';
import 'package:vyzi/features/legal/widgets/legal_html_content.dart';
import 'package:vyzi/features/profile/settings/controller/static_page_controller.dart';

/// One legal document, rendered natively.
///
/// Backs both Privacy Policy and Terms & Conditions — the two differ only in
/// slug, heading and artwork, so they share this screen rather than two
/// near-identical copies.
///
/// For documents that require consent it also shows which version the user
/// accepted and when, read from [LegalController]. That line is what turns a
/// wall of text into something a user can check: "I agreed to v2.0, this is
/// v2.1".
class LegalDocumentScreen extends StatefulWidget {
  final String slug;

  /// Translation key for the app-bar heading.
  final String titleKey;

  /// Optional hero artwork above the document — a bundled image, or a widget
  /// for the screens whose illustration is drawn rather than shipped as a PNG.
  final String? heroAsset;
  final Widget? hero;

  const LegalDocumentScreen({
    super.key,
    required this.slug,
    required this.titleKey,
    this.heroAsset,
    this.hero,
  });

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  static const _ink = Color(0xFF1A1A2E);
  static const _bg = Colors.white;

  late final StaticPageController _pageController;
  LegalController? _legal;

  @override
  void initState() {
    super.initState();

    _pageController = Get.put(
      StaticPageController(slug: widget.slug),
      tag: widget.slug,
    );

    // Registered does not mean signed in: the controller is put down
    // permanently by LegalGate and survives logout, so loadDocuments() checks
    // for a token itself and no-ops without one. The document text comes from
    // the public static-pages endpoint either way; only the "you accepted
    // v2.1" line needs a session.
    if (Get.isRegistered<LegalController>()) {
      _legal = Get.find<LegalController>();
      if (_legal!.documents.isEmpty) {
        _legal!.loadDocuments();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (_pageController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_pageController.notFound.value) {
            return _MessageState(
              icon: Icons.info_outline,
              message: 'static_page.not_available'.tr,
            );
          }
          if (_pageController.error.value.isNotEmpty) {
            return _MessageState(
              icon: Icons.error_outline,
              message: 'static_page.error'.tr,
              actionLabel: 'static_page.retry'.tr,
              onAction: _pageController.fetchPage,
            );
          }

          final page = _pageController.page.value;
          if (page == null) return const SizedBox.shrink();

          final status = _legal?.documentFor(widget.slug);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.hero != null) ...[
                  const SizedBox(height: 8),
                  widget.hero!,
                ] else if (widget.heroAsset != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        widget.heroAsset!,
                        width: double.infinity,
                        height: 172,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  page.title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    height: 1.25,
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(height: 12),
                  _MetaRow(status: status),
                  const SizedBox(height: 14),
                  _AcceptanceBanner(status: status),
                ],
                const SizedBox(height: 18),
                const Divider(height: 1, color: Color(0xFFEDEDF2)),
                const SizedBox(height: 18),
                LegalHtmlContent(html: page.content),
              ],
            ),
          );
        }),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left, color: _ink, size: 28),
        ),
      ),
      title: Text(
        widget.titleKey.tr,
        style: const TextStyle(
          color: _ink,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Version chip and publication date.
class _MetaRow extends StatelessWidget {
  final LegalDocumentModel status;

  const _MetaRow({required this.status});

  @override
  Widget build(BuildContext context) {
    final published = status.publishedAt ?? status.updatedAt;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${'legal.version'.tr} ${status.version}',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ),
        if (published != null)
          Text(
            '${'legal.updated_on'.tr} ${formatLegalDate(published)}',
            style: const TextStyle(
              color: Color(0xFF8E8EA0),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

/// "You accepted v2.0 — a newer version is in force" / "You accepted v2.1".
class _AcceptanceBanner extends StatelessWidget {
  final LegalDocumentModel status;

  const _AcceptanceBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final outstanding = status.needsAcceptance;
    final accent =
        outstanding ? const Color(0xFFB26A00) : const Color(0xFF1B8A5A);
    final background =
        outstanding ? const Color(0xFFFFF6E6) : const Color(0xFFEAF7F1);

    final String label;
    if (!outstanding && status.acceptedAt != null) {
      label = 'legal.accepted_on'.trParams({
        'version': status.acceptedVersion ?? status.version,
        'date': formatLegalDate(status.acceptedAt!),
      });
    } else if (status.isUpdate) {
      label = 'legal.pending_update'.trParams({
        'accepted': status.acceptedVersion ?? '—',
        'current': status.version,
      });
    } else {
      label = 'legal.not_yet_accepted'.tr;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            outstanding ? Icons.info_outline : Icons.verified_outlined,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: accent,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dates follow the app language: `20 agosto 2026` in Italian, `20 August 2026`
/// in English, rather than a locale-blind `20/08/2026`.
String formatLegalDate(DateTime date) {
  final locale = Get.locale?.languageCode == 'en' ? 'en' : 'it';
  try {
    return DateFormat('d MMMM y', locale).format(date.toLocal());
  } catch (_) {
    return DateFormat('dd/MM/yyyy').format(date.toLocal());
  }
}
