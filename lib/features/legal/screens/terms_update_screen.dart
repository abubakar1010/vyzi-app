import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/features/auth/controller/auth_controller.dart';
import 'package:vyzi/features/legal/controller/legal_controller.dart';
import 'package:vyzi/features/legal/models/legal_document_model.dart';
import 'package:vyzi/features/legal/screens/legal_document_screen.dart'
    show formatLegalDate;
import 'package:vyzi/features/legal/widgets/legal_html_content.dart';

/// The consent gate.
///
/// Raised when the account owes an acceptance — a document never agreed to, or
/// one republished at a newer version since the user last agreed. It is a
/// full-screen route with the system back gesture disabled, because "keep using
/// the app without accepting" is not one of the outcomes.
///
/// Documents are reviewed one at a time and each is recorded as it is accepted,
/// so a user who is interrupted halfway through two updated documents comes
/// back to one remaining, not both.
class TermsUpdateScreen extends StatefulWidget {
  const TermsUpdateScreen({super.key});

  @override
  State<TermsUpdateScreen> createState() => _TermsUpdateScreenState();
}

class _TermsUpdateScreenState extends State<TermsUpdateScreen> {
  final LegalController _legal = Get.find<LegalController>();
  final PageController _pages = PageController();

  /// Snapshot taken on mount: the live list shrinks as documents are accepted,
  /// and a PageView whose children disappear underneath it jumps around.
  late final List<LegalDocumentModel> _documents;

  int _index = 0;

  @override
  void initState() {
    super.initState();
    _documents = List<LegalDocumentModel>.from(_legal.pending);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _acceptCurrent() async {
    final document = _documents[_index];
    final done = await _legal.accept([document]);

    if (!mounted) return;

    if (!done && _legal.error.value.isNotEmpty) {
      final message = _legal.error.value;
      final republished = _legal.versionConflict.value;
      _legal.error.value = '';
      _legal.versionConflict.value = false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFB3261E),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // The document was republished while this screen was open. The controller
      // has already re-fetched it, so the honest move is to close and let the
      // gate re-open on the text that is actually in force.
      if (republished) {
        Navigator.of(context).pop(false);
      }
      return;
    }

    if (_index >= _documents.length - 1) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _index += 1);
    _pages.animateToPage(
      _index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'legal.decline_title'.tr,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
        content: Text(
          'legal.decline_body'.tr,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('legal.decline_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'legal.decline_confirm'.tr,
              style: const TextStyle(color: Color(0xFFB3261E)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _legal.reset();
      await Get.put(AuthController()).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_documents.isEmpty) {
      return const SizedBox.shrink();
    }

    final multiple = _documents.length > 1;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _Header(
                index: _index,
                total: _documents.length,
                showProgress: multiple,
                onLogout: _confirmLogout,
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _documents.length,
                  itemBuilder: (_, i) => _DocumentPage(
                    key: ValueKey(
                      '${_documents[i].slug}@${_documents[i].version}',
                    ),
                    document: _documents[i],
                    isLast: i == _documents.length - 1,
                    onAccept: _acceptCurrent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int index;
  final int total;
  final bool showProgress;
  final VoidCallback onLogout;

  const _Header({
    required this.index,
    required this.total,
    required this.showProgress,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.gavel_rounded,
                  size: 18,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'legal.gate_title'.tr,
                  style: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              TextButton(
                onPressed: onLogout,
                child: Text(
                  'legal.logout'.tr,
                  style: const TextStyle(
                    color: Color(0xFF8E8EA0),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (index + 1) / total,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFEDEDF2),
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'legal.step'.trParams({
                    'current': '${index + 1}',
                    'total': '$total',
                  }),
                  style: const TextStyle(
                    color: Color(0xFF8E8EA0),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One document: what changed, the full text, and the controls to accept it.
class _DocumentPage extends StatefulWidget {
  final LegalDocumentModel document;
  final bool isLast;
  final Future<void> Function() onAccept;

  const _DocumentPage({
    super.key,
    required this.document,
    required this.isLast,
    required this.onAccept,
  });

  @override
  State<_DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<_DocumentPage> {
  final ScrollController _scroll = ScrollController();
  final LegalController _legal = Get.find<LegalController>();

  /// Accepting is gated on having reached the end of the document. It is a low
  /// bar, but it is the difference between consent and a reflex tap.
  bool _reachedEnd = false;
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);

    // A document shorter than the viewport never scrolls, so there would be
    // nothing to reach the end of.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (_scroll.position.maxScrollExtent <= 8) {
        setState(() => _reachedEnd = true);
      }
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_reachedEnd || !_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 32) {
      setState(() => _reachedEnd = true);
    }
  }

  void _jumpToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final canAccept = _reachedEnd && _agreed;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scroll,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _VersionLine(document: document),
                    const SizedBox(height: 16),
                    if (document.changeSummary != null)
                      _ChangeSummaryCard(summary: document.changeSummary!),
                    if (document.changeSummary != null)
                      const SizedBox(height: 18),
                    const Divider(height: 1, color: Color(0xFFEDEDF2)),
                    const SizedBox(height: 16),
                    LegalHtmlContent(
                      html: document.content ?? '',
                      compact: true,
                    ),
                  ],
                ),
              ),
              if (!_reachedEnd)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _ScrollHint(onTap: _jumpToEnd),
                ),
            ],
          ),
        ),
        _AcceptBar(
          document: document,
          agreed: _agreed,
          reachedEnd: _reachedEnd,
          isLast: widget.isLast,
          onToggle: () => setState(() => _agreed = !_agreed),
          onScrollToEnd: _jumpToEnd,
          onAccept: canAccept ? widget.onAccept : null,
          isSubmitting: _legal.isSubmitting,
        ),
      ],
    );
  }
}

class _VersionLine extends StatelessWidget {
  final LegalDocumentModel document;

  const _VersionLine({required this.document});

  @override
  Widget build(BuildContext context) {
    final published = document.publishedAt ?? document.updatedAt;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${'legal.version'.tr} ${document.version}',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (document.isUpdate && document.acceptedVersion != null)
          Text(
            'legal.replaces_version'.trParams({
              'version': document.acceptedVersion!,
            }),
            style: const TextStyle(
              color: Color(0xFF8E8EA0),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          )
        else if (published != null)
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

class _ChangeSummaryCard extends StatelessWidget {
  final String summary;

  const _ChangeSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 15,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 7),
              Text(
                'legal.whats_changed'.tr,
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: const TextStyle(
              color: Color(0xFF3C3C4E),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fades the tail of the document and offers a tap to jump to the end, so the
/// scroll requirement reads as a nudge rather than a trap.
class _ScrollHint extends StatelessWidget {
  final VoidCallback onTap;

  const _ScrollHint({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Purely decorative, and it sits over the document — letting it swallow
        // touches would make the last lines unscrollable.
        IgnorePointer(
          child: Container(
            height: 92,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF)],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'legal.scroll_to_end'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.keyboard_double_arrow_down_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AcceptBar extends StatelessWidget {
  final LegalDocumentModel document;
  final bool agreed;
  final bool reachedEnd;
  final bool isLast;
  final VoidCallback onToggle;
  final VoidCallback onScrollToEnd;
  final Future<void> Function()? onAccept;
  final RxBool isSubmitting;

  const _AcceptBar({
    required this.document,
    required this.agreed,
    required this.reachedEnd,
    required this.isLast,
    required this.onToggle,
    required this.onScrollToEnd,
    required this.onAccept,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDEDF2))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: reachedEnd ? onToggle : onScrollToEnd,
              behavior: HitTestBehavior.opaque,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 21,
                    height: 21,
                    decoration: BoxDecoration(
                      color: agreed
                          ? AppColors.primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: reachedEnd
                            ? AppColors.primaryColor
                            : const Color(0xFFC9C9D4),
                        width: 1.6,
                      ),
                    ),
                    child: agreed
                        ? const Icon(Icons.check,
                            size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'legal.accept_checkbox'.trParams({
                        'title': document.title,
                        'version': document.version,
                      }),
                      style: TextStyle(
                        color: reachedEnd
                            ? const Color(0xFF3C3C4E)
                            : const Color(0xFF9B9BAA),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSubmitting.value ? null : onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    disabledBackgroundColor: const Color(0xFFDEDDE8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isSubmitting.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          isLast
                              ? 'legal.accept_and_continue'.tr
                              : 'legal.accept_and_next'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
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
}
