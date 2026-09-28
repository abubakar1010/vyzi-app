import 'package:vyzi/features/splash/spalsh_screen.dart';
import 'package:vyzi/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/utils/app_colors.dart';
import 'core/localization/app_translations.dart';
import 'core/controllers/language_controller.dart';



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(392, 876),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'VYZI',
          debugShowCheckedModeBanner: false,
          translations: AppTranslations(),
          locale: Get.find<LanguageController>().currentLocale.value,
          fallbackLocale: const Locale('it', 'IT'),
          // Without these, Flutter's own widgets and the country picker speak
          // English whatever the app language is.
          supportedLocales: const [Locale('it', 'IT'), Locale('en', 'US')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            CountryLocalizations.delegate,
          ],
          theme: ThemeData(
            primaryColor: AppColors.primaryColor,
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
            scaffoldBackgroundColor: AppColors.background,
            fontFamily: GoogleFonts.openSans().fontFamily,
            textTheme: GoogleFonts.openSansTextTheme(Theme.of(context).textTheme),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black87),
              titleTextStyle: GoogleFonts.openSans(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          initialRoute: AppRoutes.splashScreen,
          getPages: AppRoutes.page,
          // Bindings are handled by DependencyInjection.init() in main.dart
          initialBinding: BindingsBuilder(() {
            // Controllers are already lazy loaded via DI
          }),
        );
      },
      child:  SplashScreen(),
    );
  }
}

