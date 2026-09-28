import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/services/notification_router.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/app_styles.dart';
import '../controller/notification_controller.dart';
import '../models/notification_model.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  /// The app-wide singleton, shared with the home-header badge, so marking
  /// something read here moves the badge there too.
  final NotificationController controller = NotificationController.to;

  @override
  void initState() {
    super.initState();
    // Always refresh when the screen is opened - the controller is long-lived
    // and its list may be stale.
    controller.refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'notifications.title'.tr,
          style: AppStyles.h3.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Obx(() {
            if (controller.unreadCount.value == 0) return const SizedBox();
            return TextButton(
              onPressed: () => controller.markAllAsRead(),
              child: Text(
                'notifications.mark_all_read'.tr,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 64.w,
                  color: AppColors.dividerColor,
                ),
                SizedBox(height: 16.h),
                Text(
                  'notifications.empty'.tr,
                  style: AppStyles.body1.copyWith(color: AppColors.textLight),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshAll(),
          child: ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            itemCount: controller.notifications.length +
                (controller.currentPage.value < controller.totalPages.value
                    ? 1
                    : 0),
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppColors.dividerColor.withValues(alpha: 0.5),
            ),
            itemBuilder: (context, index) {
              if (index == controller.notifications.length) {
                // Load more button
                return Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Center(
                    child: Obx(() => controller.isLoading.value
                        ? const CircularProgressIndicator()
                        : TextButton(
                            onPressed: () => controller.loadMore(),
                            child: Text(
                              'notifications.load_more'.tr,
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )),
                  ),
                );
              }

              final notification = controller.notifications[index];
              return _NotificationTile(
                notification: notification,
                onTap: () => _onNotificationTap(controller, notification),
              );
            },
          ),
        );
      }),
    );
  }

  void _onNotificationTap(
      NotificationController controller, NotificationModel notification) {
    if (!notification.isRead) {
      controller.markAsRead(notification.id);
    }

    NotificationRouter.openFromList(
      type: notification.type,
      data: notification.data,
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.tryParse(notification.createdAt);
    final timeAgo = createdAt != null
        ? timeago.format(createdAt, locale: Get.locale?.languageCode ?? 'it')
        : '';

    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.isRead
            ? Colors.white
            : AppColors.primaryColor.withValues(alpha: 0.04),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: notification.isRead
                    ? AppColors.dividerColor.withValues(alpha: 0.3)
                    : AppColors.primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForType(notification.type),
                size: 20.w,
                color: notification.isRead
                    ? AppColors.textLight
                    : AppColors.primaryColor,
              ),
            ),
            SizedBox(width: 12.w),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textLight,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      _TypeBadge(type: notification.type),
                      const Spacer(),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textLight.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'bill_analyzed':
        return Icons.receipt_long_rounded;
      case 'bill_verification':
        return Icons.verified_user_rounded;
      case 'offer_available':
        return Icons.local_offer_rounded;
      case 'case_update':
        return Icons.folder_open_rounded;
      case 'contract_status':
        return Icons.description_rounded;
      case 'contract_verification':
        return Icons.gavel_rounded;
      case 'activation_complete':
        return Icons.check_circle_rounded;
      case 'referral_status':
        return Icons.people_rounded;
      case 'support_reply':
        return Icons.support_agent_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: _getColorForType(type).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        'notifications.type.$type'.tr,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: _getColorForType(type),
        ),
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'bill_analyzed':
        return Colors.blue;
      case 'bill_verification':
        return Colors.orange;
      case 'offer_available':
        return Colors.green;
      case 'case_update':
        return Colors.amber.shade700;
      case 'contract_status':
        return Colors.purple;
      case 'contract_verification':
        return Colors.deepOrange;
      case 'activation_complete':
        return Colors.teal;
      case 'referral_status':
        return Colors.cyan;
      case 'support_reply':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}
