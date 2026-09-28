import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vyzi/core/localization/app_translations.dart';
import 'package:vyzi/features/auth/create_account.dart';

/// Picking "Business" on the onboarding screen sent `role: business` to an API
/// that requires `companyName` and `partitaIva` with it — and the sign-up form
/// asked for neither. Every business registration came back 400 and the app
/// showed a generic "registration failed", so a business account could not be
/// created from the app at all.
///
/// These tests pin the fields to the role that needs them.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(Get.reset);

  testWidgets('a business sign-up asks for the company name and VAT',
      (tester) async {
    await _pumpRegister(tester, role: 'business');

    expect(find.text('Company Name *'), findsOneWidget);
    expect(find.text('VAT Number *'), findsOneWidget);
  });

  /// The company's VAT number is what sign-up cannot create the account
  /// without. The person's own code is asked for on the personal-data screen
  /// and on the switch request form — for a company exactly as for a private
  /// customer — so neither role is stopped at the sign-up form for it.
  testWidgets('neither role is asked for a tax code at sign-up',
      (tester) async {
    await _pumpRegister(tester, role: 'business');
    expect(find.text('Tax Code *'), findsNothing);

    await _pumpRegister(tester, role: 'personal');
    expect(find.text('Tax Code *'), findsNothing);
  });

  /// A company is reached at its certified address, so the sign-up form names
  /// the field for what it wants. Nothing validates the difference — a PEC and
  /// an ordinary mailbox are the same string — which is exactly why the label
  /// has to carry it.
  ///
  /// Two tests rather than one that pumps twice: the role is read from
  /// `Get.arguments`, which only a fresh `Get.reset` between tests clears.
  testWidgets('a business sign-up asks for the PEC, not an email',
      (tester) async {
    await _pumpRegister(tester, role: 'business');

    expect(find.text('PEC (certified email) *'), findsOneWidget);
    expect(find.text('Email Address *'), findsNothing);
  });

  testWidgets('a personal sign-up still asks for an ordinary email',
      (tester) async {
    await _pumpRegister(tester, role: 'personal');

    expect(find.text('Email Address *'), findsOneWidget);
    expect(find.text('PEC (certified email) *'), findsNothing);
  });

  testWidgets('a personal sign-up does not', (tester) async {
    await _pumpRegister(tester, role: 'personal');

    expect(find.text('Company Name *'), findsNothing);
    expect(find.text('VAT Number *'), findsNothing);
  });

  testWidgets('the company fields are required, and validated locally',
      (tester) async {
    await _pumpRegister(tester, role: 'business');

    // Fill everything except the company block, so those are the only things
    // that can still be wrong.
    await _fillCommonFields(tester, role: 'business');
    await _acceptTerms(tester);
    await _submit(tester);

    // findsWidgets, not findsOneWidget: CustomTextField keeps the built-in
    // TextFormField error (styled to zero height) as well as the visible one
    // it draws underneath, so the message is in the tree twice.
    expect(find.text('Company name is required'), findsWidgets);
    expect(find.text('VAT number is required'), findsWidgets);
  });

  testWidgets('a VAT number that is not a real one is rejected',
      (tester) async {
    await _pumpRegister(tester, role: 'business');

    await _fillCommonFields(tester, role: 'business');
    await tester.enterText(
        _fieldWithLabel(tester, 'Company Name *'), 'Rossi Srl');
    await tester.enterText(_fieldWithLabel(tester, 'VAT Number *'), '123');
    await _acceptTerms(tester);
    await _submit(tester);

    expect(
      find.text('Enter a valid VAT number — 11 digits, and the last one must match the rest.'),
      findsWidgets,
    );

    // The right length with the wrong check digit is what a typo actually
    // produces, and it used to sail through to the API.
    await tester.enterText(
        _fieldWithLabel(tester, 'VAT Number *'), '12345678901');
    await _submit(tester);

    expect(
      find.text('Enter a valid VAT number — 11 digits, and the last one must match the rest.'),
      findsWidgets,
    );
  });

  testWidgets('the VAT field accepts only digits, capped at 11',
      (tester) async {
    await _pumpRegister(tester, role: 'business');

    final vat = _fieldWithLabel(tester, 'VAT Number *');
    await tester.enterText(vat, 'IT 1234-5678-901234');
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextFormField>(vat).controller!.text,
      '12345678901',
    );
  });
}

// ── Harness ─────────────────────────────────────────────────────────────────

/// The editable field sitting under a given floating label.
Finder _fieldWithLabel(WidgetTester tester, String label) {
  return find.descendant(
    of: find.ancestor(
      of: find.text(label),
      matching: find.byType(Column),
    ).first,
    matching: find.byType(TextFormField),
  );
}

/// Ticks the consent box. The submit handler returns early while it is clear,
/// so validation never runs without this.
Future<void> _acceptTerms(WidgetTester tester) async {
  final box = find.byType(AnimatedContainer).first;
  await tester.ensureVisible(box);
  await tester.tap(box);
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Sign up'));
  await tester.tap(find.text('Sign up'));
  await tester.pumpAndSettle();
}

/// Fills the rows both roles share.
///
/// The email row is named for the account kind — a company is reached at its
/// PEC — so the finder has to follow the role the form was pumped with, or it
/// looks for a label that is not on screen.
Future<void> _fillCommonFields(
  WidgetTester tester, {
  String role = 'personal',
}) async {
  await tester.enterText(_fieldWithLabel(tester, 'First Name *'), 'Mario');
  await tester.enterText(_fieldWithLabel(tester, 'Last Name *'), 'Rossi');
  await tester.enterText(
      _fieldWithLabel(tester, _emailLabelFor(role)), 'mario@email.com');
  await tester.pumpAndSettle();
}

/// What the email row is called for a given role.
String _emailLabelFor(String role) =>
    role == 'business' ? 'PEC (certified email) *' : 'Email Address *';

Future<void> _pumpRegister(WidgetTester tester, {required String role}) async {
  tester.view
    ..physicalSize = const Size(392, 876)
    ..devicePixelRatio = 1.0
    ..padding = const FakeViewPadding(top: 47);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: _FakeAssetBundle(),
      child: ScreenUtilInit(
        designSize: const Size(392, 876),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          fallbackLocale: const Locale('en', 'US'),
          home: const SizedBox.shrink(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  Get.to(() => const RegisterScreen(), arguments: {'role': role});
  await tester.pumpAndSettle();
}

/// Serves a 1x1 transparent PNG for every asset so `Image.asset` resolves
/// without the real asset bundle, and an empty asset manifest so no resolution
/// variants are looked up.
class _FakeAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.view(Uint8List.fromList(_kTransparentPng).buffer);

  @override
  Future<String> loadString(String key, {bool cache = true}) async => '';

  @override
  Future<T> loadStructuredBinaryData<T>(
    String key,
    FutureOr<T> Function(ByteData data) parser,
  ) async {
    return parser(
        const StandardMessageCodec().encodeMessage(<String, Object>{})!);
  }
}

const List<int> _kTransparentPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];
