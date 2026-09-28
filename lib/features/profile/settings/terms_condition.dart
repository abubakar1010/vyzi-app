import 'package:flutter/material.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/features/legal/screens/legal_document_screen.dart';

/// Terms & Conditions, as shown from Settings.
///
/// A thin wrapper over [LegalDocumentScreen] — kept as a named class because
/// several call sites push `TermsCondition()` directly.
class TermsCondition extends StatelessWidget {
  const TermsCondition({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      slug: ApiConstants.slugTermsConditions,
      titleKey: 'terms.title',
      heroAsset: 'assets/images/terms.webp',
    );
  }
}
