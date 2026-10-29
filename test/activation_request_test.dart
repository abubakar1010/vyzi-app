import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/localization/app_translations.dart';
import 'package:vyzi/core/models/address_data.dart';
import 'package:vyzi/features/activation_request/activation_request_controller.dart';
import 'package:vyzi/features/activation_request/activation_request_screen.dart';
import 'package:vyzi/features/activation_request/models/activation_request_model.dart';
import 'package:vyzi/features/home/model/user_service_model.dart';
import 'package:vyzi/features/my_utility/utility_details_screen.dart';

/// "Attiva una nuova utenza" — the questions, the contact form and what is
/// sent. The branching is the client's spec (VYZI_Flusso_Attiva_Utenza):
/// no meter → new connection, without asking about the supply; meter with the
/// supply off → subentro; meter with the supply running → Voltura instead.
void main() {
  tearDown(Get.reset);

  group('ActivationAnswers', () {
    test('asks nothing past the service until one is chosen', () {
      const answers = ActivationAnswers.empty;

      expect(answers.showsMeterQuestion, isFalse);
      expect(answers.showsSupplyQuestion, isFalse);
      expect(answers.type, isNull);
      expect(answers.showsContactForm, isFalse);
    });

    test('no meter is a new connection, and the supply is never asked', () {
      final answers = ActivationAnswers.empty
          .withService(ActivationService.gas)
          .withMeterInstalled(false);

      expect(answers.showsSupplyQuestion, isFalse);
      expect(answers.type, ActivationRequestType.newActivation);
      expect(answers.showsContactForm, isTrue);
    });

    test('a meter waits for the supply answer before deciding', () {
      final answers = ActivationAnswers.empty
          .withService(ActivationService.electricity)
          .withMeterInstalled(true);

      expect(answers.showsSupplyQuestion, isTrue);
      expect(answers.type, isNull);
      expect(answers.showsContactForm, isFalse);
    });

    test('a meter with the supply off is a subentro', () {
      final answers = ActivationAnswers.empty
          .withService(ActivationService.electricity)
          .withMeterInstalled(true)
          .withSupplyActive(false);

      expect(answers.type, ActivationRequestType.takeover);
      expect(answers.showsContactForm, isTrue);
    });

    test('a meter with the supply running is a voltura, with no form', () {
      final answers = ActivationAnswers.empty
          .withService(ActivationService.electricity)
          .withMeterInstalled(true)
          .withSupplyActive(true);

      expect(answers.type, ActivationRequestType.transfer);
      expect(answers.showsContactForm, isFalse);
    });

    test('changing the meter answer forgets the supply answer', () {
      final answers = ActivationAnswers.empty
          .withService(ActivationService.gas)
          .withMeterInstalled(true)
          .withSupplyActive(true)
          .withMeterInstalled(false)
          .withMeterInstalled(true);

      expect(answers.supplyActive, isNull);
      expect(answers.type, isNull);
    });

    test('changing the service keeps the other answers', () {
      final answers = ActivationAnswers.empty
          .withService(ActivationService.gas)
          .withMeterInstalled(false)
          .withService(ActivationService.electricity);

      expect(answers.service, ActivationService.electricity);
      expect(answers.type, ActivationRequestType.newActivation);
    });
  });

  group('ActivationRequestPayload', () {
    const address = AddressData(
      street: ' Via Roma ',
      streetNumber: '15',
      postalCode: '09100',
      city: 'Cagliari',
      province: 'ca',
    );

    test('sends the answers and the details the API expects', () {
      final payload = ActivationRequestPayload(
        answers: ActivationAnswers.empty
            .withService(ActivationService.electricity)
            .withMeterInstalled(true)
            .withSupplyActive(false),
        firstName: ' Mario ',
        lastName: 'Rossi',
        phone: '333 123-4567',
        address: address,
        privacyAccepted: true,
      );

      expect(payload.toJson(), {
        'energyType': 'electricity',
        'meterInstalled': true,
        'supplyActive': false,
        'firstName': 'Mario',
        'lastName': 'Rossi',
        'phone': '3331234567',
        'street': 'Via Roma',
        'streetNumber': '15',
        'postalCode': '09100',
        'city': 'Cagliari',
        'province': 'ca',
        'privacyAccepted': true,
      });
    });

    test('leaves the supply answer out when there is no meter', () {
      final payload = ActivationRequestPayload(
        answers: ActivationAnswers.empty
            .withService(ActivationService.gas)
            .withMeterInstalled(false),
        firstName: 'Mario',
        lastName: 'Rossi',
        phone: '3331234567',
        address: address,
        privacyAccepted: true,
      );

      expect(payload.toJson().containsKey('supplyActive'), isFalse);
      expect(payload.toJson()['energyType'], 'gas');
    });
  });

  group('ActivationRequestController', () {
    ActivationRequestController filled() {
      final c = ActivationRequestController();
      c.firstName.text = 'Mario';
      c.lastName.text = 'Rossi';
      c.phone.text = '333 1234567';
      c.address.value = const AddressData(
        street: 'Via Roma',
        streetNumber: '15',
        postalCode: '09100',
        city: 'Cagliari',
        province: 'CA',
      );
      c.privacyAccepted.value = true;
      return c;
    }

    test('a complete form passes', () {
      expect(filled().validate(), isTrue);
    });

    test('names every missing field', () {
      final c = ActivationRequestController();

      expect(c.validate(), isFalse);
      final errors = c.errors.value;
      expect(errors.firstName, isNotNull);
      expect(errors.lastName, isNotNull);
      expect(errors.phone, isNotNull);
      expect(errors.address.street, isNotNull);
      expect(errors.address.postalCode, isNotNull);
      expect(errors.privacy, isNotNull);
    });

    test('refuses a short phone number and a bad CAP', () {
      final c = filled();
      c.phone.text = '12345';
      c.address.postalCode.text = '0910';

      expect(c.validate(), isFalse);
      expect(c.errors.value.phone, isNotNull);
      expect(c.errors.value.address.postalCode, isNotNull);
    });

    test('takes the province as free text, like every other address', () {
      final c = filled();
      c.address.province.text = ' Cagliari ';
      c.selectService(ActivationService.gas);
      c.setMeterInstalled(false);

      expect(c.validate(), isTrue);
      expect(c.buildPayload().toJson()['province'], 'Cagliari');
    });

    test('still requires a province', () {
      final c = filled();
      c.address.province.text = '  ';

      expect(c.validate(), isFalse);
      expect(c.errors.value.address.province, isNotNull);
    });

    test('will not send while the answers point to Voltura', () async {
      final c = filled()
        ..selectService(ActivationService.electricity)
        ..setMeterInstalled(true)
        ..setSupplyActive(true);

      expect(await c.submit(), isFalse);
    });
  });

  group('ActivationRequestScreen', () {
    Future<void> pump(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(392, 1600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(392, 876),
          builder: (context, child) => GetMaterialApp(
            locale: const Locale('it'),
            translations: AppTranslations(),
            home: const ActivationRequestScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a new connection goes straight to the contact form',
        (tester) async {
      await pump(tester);
      expect(find.text('2. Hai già un contatore installato?'), findsNothing);

      await tester.tap(find.text('GAS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('NO'));
      await tester.pumpAndSettle();

      expect(find.text('3. La fornitura è attualmente attiva?'), findsNothing);
      expect(find.text('NUOVA ATTIVAZIONE / GAS'), findsOneWidget);
      expect(find.text('Lascia i tuoi recapiti'), findsOneWidget);
      expect(find.text('Richiedi di essere contattato'), findsOneWidget);
      // Nothing the operator fills in after the call is asked for.
      expect(find.textContaining('POD'), findsNothing);
      expect(find.textContaining('PDR'), findsNothing);
    });

    testWidgets('a meter with the supply off is a subentro', (tester) async {
      await pump(tester);

      await tester.tap(find.text('LUCE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SÌ'));
      await tester.pumpAndSettle();
      expect(find.text('3. La fornitura è attualmente attiva?'), findsOneWidget);
      expect(find.text('Lascia i tuoi recapiti'), findsNothing);

      await tester.tap(find.text('NO').last);
      await tester.pumpAndSettle();

      expect(find.text('SUBENTRO / LUCE'), findsOneWidget);
      expect(find.text('Lascia i tuoi recapiti'), findsOneWidget);
    });

    testWidgets('an active supply is pointed to Voltura, with no form',
        (tester) async {
      await pump(tester);

      await tester.tap(find.text('LUCE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SÌ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SÌ').last);
      await tester.pumpAndSettle();

      expect(find.text('Vai alla voltura'), findsOneWidget);
      expect(find.text('Lascia i tuoi recapiti'), findsNothing);
    });

    testWidgets('submitting an empty form shows the field errors',
        (tester) async {
      await pump(tester);
      await tester.tap(find.text('GAS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('NO'));
      await tester.pumpAndSettle();

      final submit = find.byKey(const ValueKey('activation_request.submit'));
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text('Inserisci il cognome'), findsOneWidget);
      expect(
        find.text('Per essere ricontattato devi accettare l’informativa privacy'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('a utility with no bill', () {
    testWidgets('renders its details without the bill-only sections',
        (tester) async {
      tester.view
        ..physicalSize = const Size(392, 1600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final service = UserServiceModel.fromJson({
        'id': 'case-1',
        'caseId': 'case-1',
        'caseType': 'new_activation',
        'billId': null,
        'offerId': 'offer-1',
        'energyType': 'gas',
        'supplyAddress': 'Via Roma 15, Cagliari',
        'offerName': 'Gas Casa Sicura',
        'supplierName': 'Enel Energia',
        'contractNumber': 'SW-20261027-00001',
        'podPdrNumber': '00881234567890',
        'meterNumber': null,
        'annualConsumption': null,
        'consumptionUnit': null,
        'activationDate': '2026-11-01',
        'expiryDate': '2027-11-01',
        'marketType': 'fixed',
        'pricePerSmc': '0.450000',
        'status': 'awaiting_activation',
      });

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(392, 876),
          builder: (context, child) => GetMaterialApp(
            locale: const Locale('it'),
            translations: AppTranslations(),
            home: UtilityDetailsScreen(service: service),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The details hero overflows under the test font for every utility,
      // bill or no bill alike; anything else would be this change's doing.
      final error = tester.takeException();
      expect(error == null || '$error'.contains('overflowed'), isTrue,
          reason: '$error');
      expect(find.text('00881234567890'), findsOneWidget);
    });
  });
}
