import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/utils/app_styles.dart';
import 'package:vyzi/core/widgets/primary_button.dart';
import 'package:vyzi/features/bills/models/bill_model.dart';
import 'package:vyzi/features/bills/screen/bill_detail_screen.dart';
import 'package:vyzi/features/my_utility/service_details_screen.dart';
import 'package:vyzi/features/request/request_controller.dart';
import 'package:vyzi/features/utility/select_utility_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class MyRequestsProfile extends StatefulWidget {
  const MyRequestsProfile({super.key});

  @override
  State<MyRequestsProfile> createState() => _MyRequestsProfileState();
}

class _MyRequestsProfileState extends State<MyRequestsProfile> {
  late final RequestController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RequestController();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.fetchBills();
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: AppColors.textDark, size: 22.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'request.title'.tr,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: _buildMyRequestsTab(),
    );
  }

  // ── My Requests ──
  Widget _buildMyRequestsTab() {
    if (_controller.isLoadingBills) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.billsError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('request.bills.load_failed'.tr, style: AppStyles.h4),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: () => _controller.fetchBills(),
              child: Text('common.retry'.tr,
                  style: AppStyles.body2
                      .copyWith(color: AppColors.primaryColor)),
            ),
          ],
        ),
      );
    }

    if (_controller.bills.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      itemCount: _controller.bills.length,
      itemBuilder: (_, i) => _buildBillCard(_controller.bills[i]),
    );
  }

  /// Where a request opens.
  ///
  /// An activated request goes straight to its service details: the switch is
  /// finished, so there is nothing left to follow on the request detail and
  /// nothing left to sign. Every other status keeps the normal request flow.
  Future<void> _openRequest(BillModel bill) async {
    await NavHelper.push(
      bill.isActivated
          ? ServiceDetailsScreen(billId: bill.id)
          : BillDetailScreen(billId: bill.id),
    );
    if (mounted) _controller.fetchBills();
  }

  // ── Bill card ──
  Widget _buildBillCard(BillModel bill) {
    return GestureDetector(
      onTap: () => _openRequest(bill),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFF5A1ABE), width: 1.22),
        ),
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0F8),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(bill.billTypeIcon,
                      size: 24.sp, color: AppColors.primaryColor),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bill.supplierName,
                          style: AppStyles.h4.copyWith(fontSize: 15.sp)),
                      SizedBox(height: 2.h),
                      Text(bill.billTypeDisplay,
                          style: AppStyles.body4
                              .copyWith(fontWeight: FontWeight.w700)),
                      if (bill.totalAmount != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          '${'bills.list.amount'.tr}: ${bill.totalAmountDisplay}',
                          style: AppStyles.body4.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  bill.status == 'analyzed'
                      ? Icons.check_circle_outline
                      : bill.status == 'error'
                          ? Icons.error_outline
                          : bill.status == 'pending_email'
                              ? Icons.email_outlined
                              : Icons.hourglass_top_rounded,
                  size: 20.sp,
                  color: bill.statusColor,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: bill.statusBgColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(bill.statusDisplay,
                          style: AppStyles.body4.copyWith(
                              color: bill.statusColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 11.sp)),
                    ),
                    if (bill.isEmailSource) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.email_outlined,
                                size: 12.sp,
                                color: const Color(0xFF6A1B9A)),
                            SizedBox(width: 3.w),
                            Text('Via Email',
                                style: TextStyle(
                                    fontSize: 10.sp,
                                    color: const Color(0xFF6A1B9A),
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Text(bill.formattedDate,
                    style: AppStyles.body4.copyWith(
                        color: const Color(0xFF9810FA),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800)),
              ],
            ),
            if (bill.status == 'analyzed') ...[
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                height: 38.h,
                child: OutlinedButton(
                  onPressed: () => _openRequest(bill),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF5A1ABE)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r)),
                  ),
                  child: Text('request.go_to_details'.tr,
                      style: AppStyles.body2.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF9810FA))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Empty state ──
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 40.h),
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 180.w,
                  height: 180.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF3F0F8),
                  ),
                  child: Center(
                    child: Icon(Icons.receipt_long_rounded,
                        size: 80.sp, color: const Color(0xFFD1C4E9)),
                  ),
                ),
                Positioned(
                  bottom: 10.h,
                  right: 20.w,
                  child: Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.search,
                        size: 20.sp, color: AppColors.primaryColor),
                  ),
                ),
              ],
            ),
            SizedBox(height: 28.h),
            Text('common.no_data'.tr,
                style: AppStyles.h4.copyWith(fontWeight: FontWeight.w800)),
            SizedBox(height: 32.h),
            PrimaryButton(
              title: 'my_utility.upload_button'.tr,
              prefixWidget: Icon(Icons.upload_file_rounded,
                  color: Colors.white, size: 20.sp),
              onPress: () => NavHelper.push(const SelectUtilityScreen()),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
