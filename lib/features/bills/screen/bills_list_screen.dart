import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/appbar/custom_appbar.dart';
import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/utils/app_styles.dart';
import 'package:vyzi/features/bills/controller/bills_controller.dart';
import 'package:vyzi/features/bills/models/bill_model.dart';
import 'package:vyzi/features/bills/screen/bill_detail_screen.dart';

class BillsListScreen extends StatelessWidget {
  BillsListScreen({super.key});

  final BillsController controller = Get.put(BillsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'bills.title'.tr,
        showBackButton: false,
      ),
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          SizedBox(height: 10.h),
          _buildFilterSection(),
          _buildBillsHeader(),
          Expanded(child: _buildBillsList()),
          _buildPagination(),
        ],
      ),
      ),
    );
  }

  // ── Filter Section ──
  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bill type filter
          Row(
            children: [
              Image.asset(
                'assets/images/filter.webp',
                width: 20.w,
                height: 20.h,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 4.w),
              Text(
                'bills.filter.bill_type'.tr,
                style: AppStyles.h4
                    .copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Obx(() {
            final selected = controller.filterBillType.value;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('bills.filter.all_types'.tr, selected == null, () {
                    controller.applyFilter(
                        status: controller.filterStatus.value);
                  }),
                  SizedBox(width: 6.w),
                  _filterChip('bills.filter.electricity'.tr, selected == 'electricity', () {
                    controller.applyFilter(
                      billType: 'electricity',
                      status: controller.filterStatus.value,
                    );
                  }),
                  SizedBox(width: 6.w),
                  _filterChip('bills.filter.gas'.tr, selected == 'gas', () {
                    controller.applyFilter(
                      billType: 'gas',
                      status: controller.filterStatus.value,
                    );
                  }),
                ],
              ),
            );
          }),
          SizedBox(height: 12.h),
          // Status filter
          Row(
            children: [
              Image.asset(
                'assets/images/filter.webp',
                width: 20.w,
                height: 20.h,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 4.w),
              Text(
                'bills.filter.status'.tr,
                style: AppStyles.h4
                    .copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Obx(() {
            final selected = controller.filterStatus.value;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('bills.filter.all_statuses'.tr, selected == null, () {
                    controller.applyFilter(
                        billType: controller.filterBillType.value);
                  }),
                  SizedBox(width: 6.w),
                  _filterChip('bills.filter.uploaded'.tr, selected == 'uploaded', () {
                    controller.applyFilter(
                      billType: controller.filterBillType.value,
                      status: 'uploaded',
                    );
                  }),
                  SizedBox(width: 6.w),
                  _filterChip('bills.filter.analyzing'.tr, selected == 'analyzing', () {
                    controller.applyFilter(
                      billType: controller.filterBillType.value,
                      status: 'analyzing',
                    );
                  }),
                  SizedBox(width: 6.w),
                  _filterChip('bills.filter.analyzed'.tr, selected == 'analyzed', () {
                    controller.applyFilter(
                      billType: controller.filterBillType.value,
                      status: 'analyzed',
                    );
                  }),
                  SizedBox(width: 6.w),
                  _filterChip('bills.filter.error'.tr, selected == 'error', () {
                    controller.applyFilter(
                      billType: controller.filterBillType.value,
                      status: 'error',
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: const Color(0xFF5A1ABE),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: isSelected
              ? AppStyles.body4
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w800)
              : AppStyles.body4
                  .copyWith(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ── Bills Count Header ──
  Widget _buildBillsHeader() {
    return Obx(() => Padding(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'bills.list.your_bills'.tr,
                style: AppStyles.h4.copyWith(fontSize: 15.sp),
              ),
              Text(
                '${controller.totalBills.value} ${'bills.list.found'.tr}',
                style:
                    AppStyles.body4.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ));
  }

  // ── Bills List ──
  Widget _buildBillsList() {
    return Obx(() {
      if (controller.isLoadingBills.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.billsError.value.isNotEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('bills.load_failed'.tr,
                    style: AppStyles.h4),
                SizedBox(height: 8.h),
                TextButton(
                  onPressed: () => controller.fetchBills(),
                  child: Text('common.retry'.tr,
                      style: AppStyles.body2
                          .copyWith(color: AppColors.primaryColor)),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.bills.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 48.sp, color: AppColors.textPrimary),
                SizedBox(height: 12.h),
                Text('bills.no_bills_found'.tr,
                    style: AppStyles.body2
                        .copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        itemCount: controller.bills.length,
        itemBuilder: (context, index) =>
            _buildBillCard(controller.bills[index]),
      );
    });
  }

  // ── Bill Card ──
  Widget _buildBillCard(BillModel bill) {
    return GestureDetector(
      onTap: () => NavHelper.push(BillDetailScreen(billId: bill.id)),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: const Color(0xFF5A1ABE),
            width: 1.22,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: icon + info + status ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bill type icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    width: 52.w,
                    height: 52.w,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      bill.billTypeIcon,
                      color: AppColors.background,
                      size: 26.sp,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Name + type badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.supplierName,
                        style: AppStyles.h4.copyWith(fontSize: 15.sp),
                      ),
                      SizedBox(height: 3.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: const Color(0xFF5A1ABE),
                            width: 1.22,
                          ),
                        ),
                        child: Text(
                          bill.billTypeDisplay,
                          style: AppStyles.body4
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // Status chip
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: bill.statusBgColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    bill.statusDisplay,
                    style: AppStyles.body4.copyWith(
                      color: bill.statusColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            const Divider(color: AppColors.divider, height: 1.22),
            SizedBox(height: 12.h),
            // ── Bottom row: amount + period + date ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('bills.list.amount'.tr,
                        style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 11.sp)),
                    SizedBox(height: 2.h),
                    Text(
                      bill.totalAmountDisplay,
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('bills.list.period'.tr,
                        style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 11.sp)),
                    SizedBox(height: 2.h),
                    Text(
                      bill.billingPeriodDisplay,
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('bills.list.date'.tr,
                        style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 11.sp)),
                    SizedBox(height: 2.h),
                    Text(
                      bill.formattedDate,
                      style: TextStyle(
                        color: const Color(0xFF9810FA),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Pagination Controls ──
  Widget _buildPagination() {
    return Obx(() {
      if (controller.totalPages.value <= 1) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: controller.currentPage.value > 1
                  ? () => controller.loadPreviousPage()
                  : null,
              icon: Icon(Icons.chevron_left, size: 24.sp),
              color: AppColors.primaryColor,
              disabledColor: AppColors.divider,
            ),
            SizedBox(width: 12.w),
            Text(
              'bills.list.page_of'.trParams({'current': '${controller.currentPage.value}', 'total': '${controller.totalPages.value}'}),
              style: AppStyles.body3.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(width: 12.w),
            IconButton(
              onPressed: controller.currentPage.value <
                      controller.totalPages.value
                  ? () => controller.loadNextPage()
                  : null,
              icon: Icon(Icons.chevron_right, size: 24.sp),
              color: AppColors.primaryColor,
              disabledColor: AppColors.divider,
            ),
          ],
        ),
      );
    });
  }
}
