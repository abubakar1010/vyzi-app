import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/utils/app_assets.dart';
import 'package:vyzi/core/utils/app_styles.dart';
import 'package:vyzi/core/widgets/primary_button.dart';
import 'package:vyzi/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WarmupController extends GetxController {
  var currentIndex = 0.obs;

  void next() {
    if (currentIndex.value < 2) {
      currentIndex.value++;
    }
  }
}

class WarmupOnboarding extends StatelessWidget {
  WarmupOnboarding({super.key});

  final controller = Get.put(WarmupController());

  /// Full-screen slide artwork. Headline, description and the page-dot
  /// indicator are part of the artwork itself, so this screen renders only
  /// the image plus the navigation controls.
  final List<String> slides = [
    AppAssets.onboarding1,
    AppAssets.onboarding2,
    AppAssets.onboarding3,
  ];

  /// Matches the flat background baked into the slide artwork, so the
  /// letterboxing produced by BoxFit.contain is invisible on any screen ratio.
  static const Color _artworkBackground = Color(0xFFFEFEFE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _artworkBackground,
      body: SafeArea(
        top: false,
        child: Obx(() {
          final isLastSlide = controller.currentIndex.value == slides.length - 1;

          return Column(
            children: [
              Expanded(
                child: Image.asset(
                  slides[controller.currentIndex.value],
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: isLastSlide
                    ? PrimaryButton(
                        title: 'onboarding.next'.tr,
                        onPress: () {
                          Get.offNamed(AppRoutes.onboardScreen);
                        },
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Get.offNamed(AppRoutes.onboardScreen);
                            },
                            child: Text(
                              'onboarding.skip'.tr,
                              style: AppStyles.body1.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: controller.next,
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
