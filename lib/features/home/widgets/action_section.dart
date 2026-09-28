import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/navbar/navbar_controller.dart';
import 'package:vyzi/core/utils/app_assets.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/utils/app_styles.dart';
import 'package:vyzi/features/utility/select_utility_screen.dart';

import 'action_card.dart';

class ActionSection extends StatelessWidget {
  ActionSection({super.key});

  List<Map<String, dynamic>> get actions => [
    {
      "title": 'home.actions.change_supplier'.tr,
      "subtitle": 'home.actions.change_supplier_desc'.tr,
      "image": AppAssets.actionChange,
      "showBadge": false,
    },
    {
      "title": 'home.actions.transfer'.tr,
      "subtitle": 'home.actions.transfer_desc'.tr,
      "image": AppAssets.actionTransfer,
      "showBadge": false,
    },
    {
      "title": 'home.actions.activate'.tr,
      "subtitle": 'home.actions.activate_desc'.tr,
      "image": AppAssets.actionActivate,
      "showBadge": true,
      "badgeText": 'home.actions.activate_badge'.tr,
    },
    {
      "title": 'home.actions.check_invoice'.tr,
      "subtitle": 'home.actions.check_invoice_desc'.tr,
      "image": AppAssets.actionControl,
      "showBadge": false,
    },
  ];

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'home.actions.title'.tr,
            style: AppStyles.h3.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),

          SizedBox(height: 1.h),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            separatorBuilder: (_, __) => SizedBox(height: 14.h),
            itemBuilder: (_, index) {
              final item = actions[index];
              return ActionCard(
                title: item['title'],
                subtitle: item['subtitle'],
                image: item['image'],
                showBadge: item['showBadge'] ?? false,
                badgeText: item['badgeText'],
                onTap: () {
                  if (index == 2) {
                    // Activate Service → switch to My Request tab
                    Get.find<NavbarController>().changeIndex(1);
                  } else {
                    // Change Supplier, Transfer of Ownership, Check Invoice → Select Utility
                    NavHelper.push(const SelectUtilityScreen());
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
