
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/utils/app_assets.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/routes/app_routes.dart';




class OnboardingScreen extends StatefulWidget {
  @override
  _SelectProfileScreenState createState() => _SelectProfileScreenState();
}


class _SelectProfileScreenState extends State<OnboardingScreen> {
  int selectedIndex = 0; // 0 = Private, 1 = Business
  List<Map<String, dynamic>> get accountTypes => [
    {
      "title": 'onboarding.private'.tr,
      "subtitle": 'onboarding.private_desc'.tr,
      "icon": AppAssets.private,
      "points": [
        'onboarding.private_point1'.tr,
        'onboarding.private_point2'.tr,
        'onboarding.private_point3'.tr,
      ]
    },
    {
      "title": 'onboarding.business'.tr,
      "subtitle": 'onboarding.business_desc'.tr,
      "icon": AppAssets.business,
      "points": [
        'onboarding.business_point1'.tr,
        'onboarding.business_point2'.tr,
        'onboarding.business_point3'.tr,
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Column(
                  children: [
                    SizedBox(height: 18.h),

                    /// LOGO
                    Container(
                      height: 150.h,
                      width: 120.w,
                      // decoration: BoxDecoration(
                      //   color: AppColors.primary100,
                      //   borderRadius: BorderRadius.circular(18.r),
                      // ),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return const LinearGradient(
                              colors: [
                                AppColors.primaryColor,
                                AppColors.secondaryColor,
                              ],
                            ).createShader(bounds);
                          },
                          child: Image.asset(
                            AppAssets.logo,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 10.h),




                    Text(
                      'onboarding.question'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    SizedBox(height: 10.h),

                    Text(
                      'onboarding.subtitle'.tr,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    SizedBox(height: 14.h),

                    /// CARDS
                    ListView.builder(
                      itemCount: accountTypes.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final item = accountTypes[index];
                        final isSelected = selectedIndex == index;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 24.h),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: AppColors.primaryColor,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textPrimary.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),


                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 48.h,
                                      width: 48.w,
                                      decoration: BoxDecoration(
                                        color:
                                        AppColors.primary100,
                                        borderRadius:
                                        BorderRadius.circular(16.r),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(8.w),
                                        child: Image.asset(
                                          item["icon"],
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),

                                    SizedBox(width: 16.w),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item["title"],
                                            style: TextStyle(
                                              fontSize: 18.sp,
                                              fontWeight:
                                              FontWeight.w900,
                                              color:
                                              AppColors.textPrimary,
                                            ),
                                          ),

                                          SizedBox(height: 4.h),

                                          Text(
                                            item["subtitle"],
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              height: 1.4,
                                              fontWeight: FontWeight.w600,
                                              color:
                                              AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Container(
                                      height: 24.h,
                                      width: 24.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.primaryColor,
                                          width: 2,
                                        ),
                                        color: isSelected
                                            ? AppColors.primaryColor
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? Icon(
                                        Icons.check,
                                        color: AppColors.background,
                                        size: 14.sp,
                                      )
                                          : null,
                                    ),
                                  ],
                                ),

                                SizedBox(height: 10.h),

                                Divider(
                                  color: AppColors.divider,
                                  thickness: 1,
                                ),

                                SizedBox(height: 8.h),

                                Column(
                                  children: List.generate(
                                    item["points"].length,
                                        (i) => Padding(
                                      padding:
                                      EdgeInsets.only(bottom: 14.h),
                                      child: Row(
                                        children: [
                                          Container(
                                            height: 16.h,
                                            width: 16.w,
                                            decoration:
                                            const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                              AppColors.linkGreen,
                                            ),
                                            child: Icon(
                                              Icons.check_rounded,
                                              color: AppColors.background,
                                              size: 12.sp,
                                            ),
                                          ),

                                          SizedBox(width: 12.w),

                                          Expanded(
                                            child: Text(
                                              item["points"][i],
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: AppColors.textPrimary,
                                                fontWeight:
                                                FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),


            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 18.h,
              ),
              decoration: BoxDecoration(
                border: const Border(
                  top: BorderSide(color: AppColors.primaryColor, width: 1.22),
                ),
                // gradient: const LinearGradient(
                //   colors: [
                //     Color(0xFF1E40AF),
                //     Color(0xFF06B6D4),
                //   ],
                //   begin: Alignment.topLeft,
                //   end: Alignment.bottomRight,
                // ),
                color: AppColors.primary50,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(34.r),
                  topRight: Radius.circular(34.r),
                ),
              ),
              child: Column(
                children: [
                  /// Sign In Button
                  GestureDetector(
                    onTap: () {
                      Get.toNamed(AppRoutes.signInScreen);
                    },
                    child: Container(
                      height: 52.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Center(
                        child: Text(
                          'onboarding.sign_in'.tr,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.background,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  /// Create Account Button
                  GestureDetector(
                    onTap: () {
                      final role = selectedIndex == 0 ? 'personal' : 'business';
                      // A referral link opens this screen rather than the form,
                      // so the code it carried has to be handed on with the
                      // account type — dropped here it was lost for good.
                      final referralCode =
                          Get.arguments?['referralCode'] as String?;
                      Get.toNamed(AppRoutes.signUpScreen, arguments: {
                        'role': role,
                        if (referralCode != null && referralCode.isNotEmpty)
                          'referralCode': referralCode,
                      });
                    },
                    child: Container(
                      height: 52.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.primaryColor,
                          width: 1.6,
                        ),
                        color: Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          'onboarding.create_account'.tr,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
