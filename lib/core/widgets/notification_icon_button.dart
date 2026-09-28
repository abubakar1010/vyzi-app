import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/utils/app_assets.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/features/notifications/controller/notification_controller.dart';

/// Bell + unread badge, sized to fill the tile it is dropped into.
///
/// The badge is placed against the *tile's* corner, not the bell's bounding
/// box, so it lands where the design puts it regardless of [iconSize].
class NotificationIconButton extends StatefulWidget {
  final double iconSize;
  final VoidCallback onTap;

  const NotificationIconButton({
    super.key,
    required this.iconSize,
    required this.onTap,
  });

  @override
  State<NotificationIconButton> createState() => _NotificationIconButtonState();
}

class _NotificationIconButtonState extends State<NotificationIconButton> {
  /// Resolved once, in initState — not in build. `NotificationController.to`
  /// registers the singleton on first use, and doing that during build is a
  /// side effect in the wrong phase.
  late final NotificationController _controller = NotificationController.to;

  /// Badge geometry, in design units, measured from the tile's top-right.
  static double get _badgeSize => 14.w;
  static double get _badgeTop => 10.w;
  static double get _badgeRight => 8.w;

  @override
  void initState() {
    super.initState();
    // The bell is rebuilt whenever the navbar is (i.e. after every sign-in),
    // so this is the point where a fresh session gets its first real count.
    _controller.refreshUnreadCount(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Obx(() {
        final count = _controller.unreadCount.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Image.asset(
                AppAssets.notification,
                width: widget.iconSize.w,
                height: widget.iconSize.h,
                fit: BoxFit.contain,
              ),
            ),
            if (count > 0)
              Positioned(
                top: _badgeTop,
                right: _badgeRight,
                child: Container(
                  height: _badgeSize,
                  // A circle for a single digit; grows into a pill for
                  // wider labels instead of overflowing them.
                  constraints: BoxConstraints(minWidth: _badgeSize),
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  decoration: BoxDecoration(
                    color: AppColors.red100,
                    borderRadius: BorderRadius.circular(_badgeSize / 2),
                  ),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      // The pill is a fixed height, so a large system font
                      // scale would clip the digits rather than enlarge them.
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
