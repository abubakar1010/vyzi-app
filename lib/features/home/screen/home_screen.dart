import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/navbar/navbar_controller.dart';
import 'package:vyzi/core/utils/app_assets.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/features/home/controller/home_controller.dart';
import 'package:vyzi/features/notifications/controller/notification_controller.dart';
import 'package:vyzi/features/home/widgets/action_section.dart';
import 'package:vyzi/features/home/widgets/home_header.dart';
import 'package:vyzi/features/home/widgets/how_it_works.dart';
import 'package:vyzi/features/home/widgets/summary_card.dart';
import 'package:vyzi/features/home/widgets/upload_section.dart';
import 'package:vyzi/features/home/widgets/utilities_section.dart';
import 'package:vyzi/features/utility/select_utility_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final HomeController controller;
  Worker? _tabWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = Get.put(HomeController());

    // Re-fetch dashboard + services whenever user switches to the Home tab.
    // IndexedStack keeps all tabs alive, so initState only runs once —
    // this listener ensures fresh data on every tab activation.
    final navCtrl = Get.find<NavbarController>();
    _tabWorker = ever<int>(navCtrl.selectedTabRx, (index) {
      if (index == 0) {
        controller.fetchDashboard();
        controller.fetchServices();
        // The bell lives in this header, and work done on another tab
        // (uploading a bill, opening a ticket) can create notifications.
        NotificationController.notifyMayHaveChanged();
      }
    });
  }

  @override
  void dispose() {
    _tabWorker?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final navCtrl = Get.find<NavbarController>();
      if (navCtrl.selectedIndex == 0) {
        controller.fetchDashboard();
        controller.fetchServices();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(
        () {
          final showOnboarding = controller.isFirstVisit.value;
          final hasUtilities = controller.serviceList.isNotEmpty;

          return CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────
              if (showOnboarding)
                SliverToBoxAdapter(
                  child: HomeHeader(isOnboarding: true),
                )
              else
                const HomeSliverHeader(),

              // ── Content ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 100.h),
                  child: Column(
                    children: [
                      if (showOnboarding) ...[
                        UploadSection(
                          onTap: () {
                            NavHelper.push(const SelectUtilityScreen());
                          },
                        ),
                        SizedBox(height: 16.h),
                        _buildSummaryRow(),
                        SizedBox(height: 20.h),
                        HowItWorksCard(),
                      ],
                      if (!showOnboarding) ...[
                        _buildSummaryRow(),
                        SizedBox(height: 18.h),
                        if (hasUtilities) ...[
                          UtilitiesSection(
                            services: controller.serviceList,
                          ),
                          SizedBox(height: 18.h),
                        ],
                        ActionSection(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Summary cards row (shared by both layouts) ──────────────────────────
  Widget _buildSummaryRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SummaryCard(
              icon: Image.asset(AppAssets.down),
              iconColor: AppColors.green200,
              iconBgColor: AppColors.greenAlpha10,
              title: 'home.summary.savings_title'.tr,
              value: controller.savingAmount.value,
              valueColor: AppColors.green200,
              subtitle: 'home.summary.savings_subtitle'.tr,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: SummaryCard(
              icon: Image.asset(AppAssets.cir),
              iconColor: AppColors.primaryColor,
              iconBgColor: AppColors.primaryAlpha10,
              title: 'home.summary.utilities_title'.tr,
              value: controller.activeUtilities.value.toString(),
              valueColor: AppColors.primaryColor,
              subtitle: 'home.summary.utilities_subtitle'.tr,
            ),
          ),
        ],
      ),
    );
  }
}
