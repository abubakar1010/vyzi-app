import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vyzi/core/utils/app_colors.dart';

/// Renders the HTML of a legal document as native Flutter widgets.
///
/// The admin editor emits `h2`/`h3`/`p`/`ul`/`ol`/`strong`/`a`, so those are
/// the tags styled here. Everything falls back to the body style rather than
/// being dropped, which keeps a stray `blockquote` or `table` readable instead
/// of invisible.
///
/// Shared by the Settings screens and the re-acceptance gate so both render the
/// same document identically — a user asked to accept something should be
/// looking at exactly what Settings would show them afterwards.
class LegalHtmlContent extends StatelessWidget {
  final String html;

  /// Slightly tighter type inside the acceptance sheet, where the document
  /// shares the screen with a summary card and the accept controls.
  final bool compact;

  const LegalHtmlContent({
    super.key,
    required this.html,
    this.compact = false,
  });

  static const _ink = Color(0xFF1A1A2E);
  static const _body = Color(0xFF3C3C4E);

  @override
  Widget build(BuildContext context) {
    final base = compact ? 13.5 : 14.5;

    return Html(
      data: html,
      onLinkTap: (url, _, __) async {
        if (url == null) return;
        final uri = Uri.tryParse(url);
        if (uri == null) return;
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      style: {
        'body': Style(
          fontSize: FontSize(base),
          lineHeight: LineHeight(1.6),
          color: _body,
          fontWeight: FontWeight.w500,
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        // The seeded documents open with an `h2` that repeats the page title,
        // which the screen header already shows. Hidden rather than deleted
        // from the content so the same HTML still reads correctly on the web.
        'h2': Style(display: Display.none),
        'h3': Style(
          fontSize: FontSize(compact ? 15 : 16),
          fontWeight: FontWeight.w800,
          color: _ink,
          margin: Margins.only(top: 26, bottom: 8),
          padding: HtmlPaddings.zero,
          lineHeight: LineHeight(1.35),
        ),
        'h4': Style(
          fontSize: FontSize(base + 0.5),
          fontWeight: FontWeight.w700,
          color: _ink,
          margin: Margins.only(top: 18, bottom: 6),
          padding: HtmlPaddings.zero,
        ),
        'p': Style(
          margin: Margins.only(bottom: 12),
          padding: HtmlPaddings.zero,
        ),
        'ul': Style(
          margin: Margins.only(bottom: 14, left: 2),
          padding: HtmlPaddings.only(left: 18),
        ),
        'ol': Style(
          margin: Margins.only(bottom: 14, left: 2),
          padding: HtmlPaddings.only(left: 18),
        ),
        'li': Style(
          margin: Margins.only(bottom: 7),
          padding: HtmlPaddings.zero,
          lineHeight: LineHeight(1.55),
        ),
        'strong': Style(fontWeight: FontWeight.w800, color: _ink),
        'b': Style(fontWeight: FontWeight.w800, color: _ink),
        'a': Style(
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w700,
          textDecoration: TextDecoration.underline,
        ),
      },
    );
  }
}
