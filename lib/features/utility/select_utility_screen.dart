import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/features/utility/controller/select_utility_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'upload_bill_screen.dart';

class SelectUtilityScreen extends StatefulWidget {
  const SelectUtilityScreen({super.key});

  @override
  State<SelectUtilityScreen> createState() => _SelectUtilityScreenState();
}

class _SelectUtilityScreenState extends State<SelectUtilityScreen> {
  final SelectUtilityController _controller = SelectUtilityController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 28.h),

            // ── Heading ──
             Text(
              'select_utility.heading'.tr,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                height: 1.28,
              ),
            ),
            SizedBox(height: 8.h),

            // ── Subtitle ──
             Text(
              'select_utility.subtitle'.tr,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.22,
              ),
            ),
            SizedBox(height: 24.h),

            // ── Utility selection cards ──
            Row(
              children: [
                Expanded(
                  child: _buildUtilityCard(
                    type: UtilityType.luce,
                    icon: Icons.bolt_rounded,
                    label: 'LUCE',
                    sublabel: 'select_utility.luce_sublabel'.tr,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildUtilityCard(
                    type: UtilityType.gas,
                    icon: Icons.local_fire_department_rounded,
                    label: 'GAS',
                    sublabel: 'select_utility.gas_sublabel'.tr,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // ── Tip banner ──
            _buildTipBanner(),
          ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ──
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded,
            color: AppColors.textDark, size: 22.sp),
        onPressed: () => Navigator.pop(context),
      ),
      title:  Text(
        'select_utility.title'.tr,
        style: TextStyle(
          fontSize: 17.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
          height: 1.22,
        ),
      ),
    );
  }

  // ── Utility card (selected = purple, unselected = white) ──
  Widget _buildUtilityCard({
    required UtilityType type,
    required IconData icon,
    required String label,
    required String sublabel,
  }) {
    final isSelected = _controller.selectedUtility == type;

    return GestureDetector(
      onTap: () {
        _controller.selectUtility(type);
        // Navigate to upload bill screen after a short delay
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UploadBillScreen(utilityType: type),
              ),
            );
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 140.h,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : AppColors.background,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primaryColor.withOpacity(0.22)
                  : AppColors.textPrimary.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Checkmark top-right
            Positioned(
              top: 12.h,
              right: 12.w,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.background : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : AppColors.divider,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: AppColors.primaryColor,
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            // Center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon container
                  Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.background.withOpacity(0.2)
                          : AppColors.primary100,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      icon,
                      size: 26.sp,
                      color: isSelected
                          ? AppColors.background
                          : AppColors.primaryColor,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color:
                          isSelected ? AppColors.background : AppColors.textDark,
                      height: 1.22,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    sublabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: isSelected
                          ? AppColors.background.withOpacity(0.9)
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.22,
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

  // ── Tip banner ──
  Widget _buildTipBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.primary100,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡', style: TextStyle(fontSize: 14.sp)),
          SizedBox(width: 8.w),
          Expanded(
            child: RichText(
              text:  TextSpan(
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.primaryColor,
                  height: 1.22,
                ),
                children: [
                  TextSpan(
                    text: 'select_utility.tip_label'.tr,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  TextSpan(
                    text:
                    'select_utility.tip_text'.tr,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
