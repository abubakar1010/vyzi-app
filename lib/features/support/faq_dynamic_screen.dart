import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/appbar/custom_appbar.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/utils/app_styles.dart';
import 'package:vyzi/features/support/controller/faq_controller.dart';

class FaqDynamicScreen extends StatefulWidget {
  final String? category;
  final String title;
  final String heroImage;

  const FaqDynamicScreen({
    super.key,
    this.category,
    required this.title,
    required this.heroImage,
  });

  @override
  State<FaqDynamicScreen> createState() => _FaqDynamicScreenState();
}

class _FaqDynamicScreenState extends State<FaqDynamicScreen> {
  late final FaqController _controller;
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    final tag = widget.category ?? 'all';
    _controller = Get.put(FaqController(), tag: tag);
    _controller.fetchFaqs(category: widget.category);
  }

  @override
  void dispose() {
    final tag = widget.category ?? 'all';
    Get.delete<FaqController>(tag: tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: widget.title),
      body: SafeArea(
        child: Obx(() {
          if (_controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.error.value.isNotEmpty) {
            return _buildErrorState();
          }

          if (_controller.faqs.isEmpty) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Image.asset(
                      widget.heroImage,
                      width: double.infinity,
                      height: 320.h,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imageFallback(),
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // Section title
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    'faq.title'.tr,
                    style: AppStyles.h4.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                SizedBox(height: 14.h),

                // FAQ accordion items
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: List.generate(
                      _controller.faqs.length,
                      (i) => _buildFaqItem(i),
                    ),
                  ),
                ),

                SizedBox(height: 30.h),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFaqItem(int index) {
    final isExpanded = _expandedIndex == index;
    final faq = _controller.faqs[index];

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedIndex = isExpanded ? -1 : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      faq.question,
                      style: AppStyles.body3.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.black,
                      size: 20.sp,
                    ),
                  ),
                ],
              ),
            ),

            // Answer (animated expand)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.divider,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      faq.answer,
                      style: AppStyles.body4.copyWith(
                        height: 1.6,
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48.sp, color: AppColors.primaryColor.withValues(alpha: 0.5)),
            SizedBox(height: 16.h),
            Text(
              'faq.error'.tr,
              style: AppStyles.body2.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () =>
                  _controller.fetchFaqs(category: widget.category),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text('faq.retry'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.question_answer_outlined,
                size: 48.sp, color: AppColors.primaryColor.withValues(alpha: 0.5)),
            SizedBox(height: 16.h),
            Text(
              'faq.empty'.tr,
              style: AppStyles.body2.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      width: double.infinity,
      height: 220.h,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined,
                size: 52.sp,
                color: AppColors.primaryColor.withValues(alpha: 0.5)),
            SizedBox(height: 8.h),
            Text(
              'Utility Services',
              style: AppStyles.body2.copyWith(
                color: AppColors.primaryColor.withValues(alpha: 0.7),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
