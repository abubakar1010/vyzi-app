import 'package:flutter/material.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/features/legal/screens/legal_document_screen.dart';
import 'package:vyzi/features/legal/widgets/privacy_shield_illustration.dart';

/// Privacy Policy, as shown from Settings.
///
/// A thin wrapper over [LegalDocumentScreen] — kept as a named class because
/// several call sites push `PrivacyPolicyScreen()` directly.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      slug: ApiConstants.slugPrivacyPolicy,
      titleKey: 'profile.settings.privacy',
      hero: PrivacyShieldIllustration(),
    );
  }
}
