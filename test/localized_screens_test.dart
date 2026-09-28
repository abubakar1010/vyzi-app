import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/constants/contact_constants.dart';
import 'package:vyzi/core/localization/app_translations.dart';
import 'package:vyzi/features/home/email/email_bill_controller.dart';
import 'package:vyzi/features/home/email/email_bill_screen.dart';
import 'package:vyzi/features/home/widgets/summary_card.dart';

void main() {
  tearDown(Get.reset);

  for (final language in ['it', 'en']) {
    testWidgets(
      'email instructions and clipboard use the same inbox ($language)',
      (tester) async {
        tester.view
          ..physicalSize = const Size(320, 640)
          ..devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.4;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData')
              copied = (call.arguments as Map)['text'] as String;
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );

        await tester.pumpWidget(
          GetMaterialApp(
            locale: Locale(language),
            translations: AppTranslations(),
            home: EmailBillScreen(billType: 'electricity'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(ContactConstants.billInbox), findsOneWidget);
        expect(
          find.text(language == 'it' ? 'Invia via email' : 'Send by email'),
          findsOneWidget,
        );
        expect(
          find.text(
            language == 'it' ? 'Ho inviato la bolletta' : 'I have sent my bill',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await Get.find<EmailBillController>().copyEmail();
        await tester.pumpAndSettle();
        expect(copied, ContactConstants.billInbox);
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('home summary labels wrap at narrow widths ($language)', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(392, 876),
          builder: (_, __) => GetMaterialApp(
            locale: Locale(language),
            translations: AppTranslations(),
            home: Scaffold(
              body: Builder(
                builder: (_) => Row(
                  children: [
                    for (final key in [
                      'home.summary.savings_title',
                      'home.summary.utilities_title',
                    ])
                      Expanded(
                        child: SummaryCard(
                          icon: const Icon(Icons.bolt),
                          iconColor: Colors.purple,
                          iconBgColor: Colors.white,
                          title: key.tr,
                          value: '0',
                          valueColor: Colors.purple,
                          subtitle: '',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
