import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/appbar/custom_appbar.dart';
import 'package:vyzi/core/utils/app_assets.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/utils/app_styles.dart';
import 'package:vyzi/features/auth/controller/auth_controller.dart';
import 'package:vyzi/core/controllers/language_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vyzi/features/support/support_screen.dart';
import 'about_us.dart';
import 'faq_question.dart';
import 'privacy_policy.dart';
import 'terms_condition.dart';

class MoreScreen extends StatelessWidget {
  MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(title: 'profile.settings.title'.tr, showBackButton: true),
            const SizedBox(height: 32),

            // Settings List wrapped in a single card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0x1A333333),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SettingTile(
                      iconWidget: Image.asset(
                        AppAssets.privacy,
                        width: 24,
                        height: 24,
                      ),
                      title: 'profile.settings.privacy'.tr,
                      trailingIcon: const _TrailingArrow(),
                      onTap: () {
                        NavHelper.push(const PrivacyPolicyScreen());
                      },
                    ),
                    const SizedBox(height: 12),
                    SettingTile(
                      iconWidget: Image.asset(
                        AppAssets.terms,
                        width: 24,
                        height: 24,
                      ),
                      title: 'profile.settings.terms'.tr,
                      trailingIcon: const _TrailingArrow(),
                      onTap: () {
                        NavHelper.push(const TermsCondition());
                      },
                    ),
                    const SizedBox(height: 12),
                    SettingTile(
                      iconWidget: Image.asset(
                        AppAssets.about,
                        width: 24,
                        height: 24,
                      ),
                      title: 'profile.settings.about'.tr,
                      trailingIcon: const _TrailingArrow(),
                      onTap: () {
                        NavHelper.push(AboutUs());
                      },
                    ),
                    const SizedBox(height: 12),
                    SettingTile(
                      iconWidget: Image.asset(
                        AppAssets.menuSupport,
                        width: 24,
                        height: 24,
                      ),
                      title: 'profile.settings.faq'.tr,
                      trailingIcon: const _TrailingArrow(),
                      onTap: () {
                        NavHelper.push(SupportoScreen());
                      },
                    ),
                    const SizedBox(height: 12),
                    // Language Selector
                    Obx(() {
                      final langController = Get.find<LanguageController>();
                      final isItalian = langController.currentLanguageCode == 'it';
                      return SettingTile(
                        iconWidget: const Icon(Icons.language, size: 24, color: Colors.black54),
                        title: 'profile.settings.language'.tr,
                        trailingIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isItalian ? 'IT' : 'EN',
                              style: AppStyles.body2.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const _TrailingArrow(),
                          ],
                        ),
                        onTap: () {
                          _showLanguageSelector(context);
                        },
                      );
                    }),
                    const SizedBox(height: 12),
                    SettingTile(
                      iconWidget: Image.asset(
                        AppAssets.close,
                        width: 24,
                        height: 24,
                      ),
                      title: 'profile.settings.delete_account'.tr,
                      trailingIcon: const _TrailingArrow(),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('profile.settings.delete_confirm_title'.tr),
                            content: Text(
                              'profile.settings.delete_confirm_msg'.tr,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: Text('profile.settings.delete_confirm_cancel'.tr),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  final auth = Get.put(AuthController());
                                  auth.logout();
                                },
                                child: Text(
                                  'profile.settings.delete_confirm_delete'.tr,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final langController = Get.find<LanguageController>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'profile.settings.language'.tr,
                style: AppStyles.body2.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Obx(() {
                final currentLang = langController.currentLanguageCode;
                return Column(
                  children: [
                    _LanguageOption(
                      label: 'profile.settings.language_italian'.tr,
                      code: 'it',
                      isSelected: currentLang == 'it',
                      onTap: () {
                        langController.changeLanguage('it');
                        Navigator.of(ctx).pop();
                      },
                    ),
                    const SizedBox(height: 12),
                    _LanguageOption(
                      label: 'profile.settings.language_english'.tr,
                      code: 'en',
                      isSelected: currentLang == 'en',
                      onTap: () {
                        langController.changeLanguage('en');
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String code;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.code,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: AppColors.primaryColor, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Text(
              code.toUpperCase(),
              style: AppStyles.body2.copyWith(
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.primaryColor : Colors.black54,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primaryColor : Colors.black,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primaryColor, size: 22),
          ],
        ),
      ),
    );
  }
}

/// The trailing chevron on a [SettingTile].
///
/// `arrows_right.webp` is a near-white glyph on transparency, so untinted it
/// all but disappears against the light tile fill. The tint is what makes it
/// legible: Flutter srcIn-blends it over the glyph, keeping the antialiased
/// edges the asset already has.
class _TrailingArrow extends StatelessWidget {
  const _TrailingArrow();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.arrowRight,
      width: 24,
      height: 24,
      color: AppColors.primaryColor,
    );
  }
}

class SettingTile extends StatelessWidget {
  final Widget? iconWidget;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailingIcon;

  const SettingTile({
    super.key,
    this.iconWidget,
    required this.title,
    this.onTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            iconWidget ?? const SizedBox.shrink(),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppStyles.body2.copyWith(fontWeight: FontWeight.w900, color: Colors.black),
              ),
            ),
            trailingIcon ?? const _TrailingArrow(),
          ],
        ),
      ),
    );
  }
}
