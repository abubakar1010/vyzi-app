import 'dart:math' as math;

import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/navbar/navbar_controller.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/utils/number_format.dart';
import 'package:vyzi/features/home/model/user_service_model.dart';
import 'package:vyzi/features/my_utility/utility_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'single_utility_card.dart';

class UtilitiesSection extends StatelessWidget {
  final RxList<UserServiceModel> services;
  final int maxItems;

  const UtilitiesSection({
    super.key,
    required this.services,
    this.maxItems = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.borderGlobal, width: 1.22),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'home.utilities_section.title'.tr,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  final NavbarController navCtrl = Get.find<NavbarController>();
                  navCtrl.changeIndex(2); // Index for MyUtilitiesScreen
                },
                child: Text(
                  'home.utilities_section.view_all'.tr,
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 1.h),

          Obx(
            () => ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: math.min(services.length, maxItems),
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (_, index) {
                final service = services[index];

                final isGas = service.energyType == 'gas';
                final address = service.supplyAddress?.trim() ?? '';

                return UtilityCard(
                  // The supply address identifies the utility, not the
                  // supplier - a customer can hold two contracts with the same
                  // supplier and only the address tells them apart.
                  title: address.isNotEmpty
                      ? address
                      : 'home.utilities_section.address_missing'.tr,
                  subtitle: service.energyType == null
                      ? ''
                      : (isGas
                          ? 'bills.type.gas'.tr
                          : 'bills.type.electricity'.tr),
                  subtitleIcon: service.energyType == null
                      ? null
                      : (isGas ? Icons.local_fire_department : Icons.bolt),
                  // The supplier the contract runs with. Absent only while a
                  // supplier has no logo on file, and the card falls back to
                  // its generic mark.
                  logoUrl: service.supplierLogoUrl,
                  trailingText: service.monthlyEstimate != null
                      ? formatMoney(service.monthlyEstimate)
                      : null,
                  onTap: () {
                    NavHelper.push(UtilityDetailsScreen(service: service));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
