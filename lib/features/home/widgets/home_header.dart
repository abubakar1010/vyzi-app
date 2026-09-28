import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/utils/app_assets.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/utils/app_styles.dart';
import 'package:vyzi/core/widgets/notification_icon_button.dart';
import 'package:vyzi/features/notifications/screen/notification_screen.dart';

/// Collapsing variant of the home banner, for the returning-user layout.
///
/// Must be used inside a [CustomScrollView] — it is a sliver.
///
/// Both extents are *derived* from the content instead of being hard-coded:
///   collapsed (pinned) = vertical padding + logo row
///   expanded           = collapsed + the measured greeting block
///
/// That is what keeps it overflow-free. A fixed expanded/collapsed pair only
/// fits at one screen size and one text scale; everywhere else the flexible
/// space is asked to lay out content taller than the extent it was given.
class HomeSliverHeader extends StatelessWidget {
  const HomeSliverHeader({super.key});

  static double get _padH => 16.w;
  static double get _padV => 16.h;
  static double get _logoBox => 48.w;
  static double get _greetingGap => 8.h;
  static double get _subtitleGap => 4.h;
  static double get _bottomGap => 16.h;

  static TextStyle get _greetingStyle => AppStyles.h1.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w900,
      );

  static TextStyle get _subtitleStyle => AppStyles.body2.copyWith(
        fontSize: 15.sp,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: Colors.white.withValues(alpha: 0.75),
      );

  /// Laid-out height of [text] under the same style, width and text scale the
  /// widget tree will use, so the space reserved matches what gets painted.
  /// The style is merged with the ambient [DefaultTextStyle] exactly like
  /// [Text] does it — otherwise inherited metrics (letter spacing, font
  /// family) would make the measurement disagree with the render.
  static double _measureTextHeight(
    BuildContext context,
    String text,
    TextStyle style,
    double maxWidth,
    int maxLines,
  ) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.inherit ? defaultStyle.merge(style) : style,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: maxLines,
    )..layout(maxWidth: maxWidth);
    return painter.height;
  }

  @override
  Widget build(BuildContext context) {
    final textWidth = MediaQuery.sizeOf(context).width - _padH * 2;
    final greetingHeight = _measureTextHeight(
      context,
      'home.header.greeting'.tr,
      _greetingStyle,
      textWidth,
      1,
    );
    final subtitleHeight = _measureTextHeight(
      context,
      'home.header.subtitle'.tr,
      _subtitleStyle,
      textWidth,
      2,
    );

    final collapsedHeight = _logoBox + _padV * 2;
    final greetingBlockHeight = _greetingGap +
        greetingHeight +
        _subtitleGap +
        subtitleHeight +
        _bottomGap;
    final expandedHeight = collapsedHeight + greetingBlockHeight;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      toolbarHeight: collapsedHeight,
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final topPadding = MediaQuery.paddingOf(context).top;
          final maxHeight = expandedHeight + topPadding;
          final minHeight = collapsedHeight + topPadding;
          final range = maxHeight - minHeight;
          // 1.0 = fully expanded, 0.0 = fully collapsed.
          final t = range <= 0
              ? 0.0
              : ((constraints.maxHeight - minHeight) / range).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Gradient background
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.headerGradient,
                ),
              ),
              _HeaderCircle(topPadding: topPadding),
              // Content
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(_padH, _padV, _padH, _padV),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo + Notification row - always visible, fixed height
                      SizedBox(
                        height: _logoBox,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Logo container
                            Container(
                              width: _logoBox,
                              height: _logoBox,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14.r),
                                child: Image.asset(
                                  AppAssets.homeLogo,
                                  width: _logoBox,
                                  height: _logoBox,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            // Notification in frosted container
                            Container(
                              width: _logoBox,
                              height: _logoBox,
                              decoration: BoxDecoration(
                                color: AppColors.headerIconTile,
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: NotificationIconButton(
                                iconSize: 26,
                                onTap: () =>
                                    NavHelper.push(const NotificationScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Greeting block - shrinks and fades with the scroll.
                      //
                      // Flexible hands it exactly the space that is left, so
                      // the outer column can never be over-filled. OverflowBox
                      // then lets the text lay out at its natural height
                      // instead of being squeezed into that shrinking box —
                      // squeezing it is what produced the bottom overflow —
                      // and ClipRect trims the part that no longer fits.
                      Flexible(
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.topLeft,
                            minHeight: 0,
                            maxHeight: double.infinity,
                            child: Opacity(
                              opacity: t,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: _greetingGap),
                                  Text(
                                    'home.header.greeting'.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _greetingStyle,
                                  ),
                                  SizedBox(height: _subtitleGap),
                                  Text(
                                    'home.header.subtitle'.tr,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: _subtitleStyle,
                                  ),
                                  SizedBox(height: _bottomGap),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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
}

/// The decorative cyan disc in the banner's top-right corner.
///
/// Anchored to the top of the *content* area (below the status bar) rather
/// than centred in the banner, because that is what the design specifies: the
/// arc is cut off by the top edge and stops short of the banner's bottom. A
/// centred disc drifts with the banner height instead — status bar size, text
/// scale and the collapsed/expanded sliver states all change it.
///
/// Geometry is taken from the design at the 392pt base width: a 156pt disc
/// whose centre sits 42pt in from the right edge and 39pt below the status bar.
class _HeaderCircle extends StatelessWidget {
  const _HeaderCircle({required this.topPadding});

  /// Height of the status bar the banner paints behind.
  final double topPadding;

  static double get _size => 156.w;
  static double get _centreFromRight => 42.w;
  static double get _centreFromTop => 39.h;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: _centreFromRight - _size / 2,
      top: topPadding + _centreFromTop - _size / 2,
      child: Container(
        width: _size,
        height: _size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.headerCircle,
        ),
      ),
    );
  }
}

class HomeHeader extends StatelessWidget {
  final bool isOnboarding;

  const HomeHeader({super.key, this.isOnboarding = false});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return isOnboarding
        ? _buildOnboardingHeader(topPadding)
        : _buildRegularHeader(topPadding);
  }

  Widget _buildRegularHeader(double topPadding) {
    return Container(
      // A minimum, not a fixed height: the banner keeps its 162.h look but is
      // still allowed to grow if the text needs more room (large system font
      // scale, longer translations) instead of overflowing.
      constraints: BoxConstraints(minHeight: 162.h + topPadding),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
      ),
      child: Stack(
        children: [
          _HeaderCircle(topPadding: topPadding),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo + Notification row - horizontally aligned
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo container
                      Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14.r),
                          child: Image.asset(
                            AppAssets.homeLogo,
                            width: 48.w,
                            height: 48.w,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      // Notification in frosted container
                      Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: BoxDecoration(
                          color: AppColors.headerIconTile,
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: NotificationIconButton(
                          iconSize: 26,
                          onTap: () => NavHelper.push(const NotificationScreen()),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  // Greeting
                  Text(
                    'home.header.greeting'.tr,
                    style: AppStyles.h1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  // Subtitle
                  Text(
                    'home.header.subtitle'.tr,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingHeader(double topPadding) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
      ),
      child: Stack(
          children: [
            _HeaderCircle(topPadding: topPadding),
            // Content
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo + Notification row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo container
                        Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14.r),
                            child: Image.asset(
                              AppAssets.homeLogo,
                              width: 48.w,
                              height: 48.w,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        // Notification with badge
                        Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            color: AppColors.headerIconTile,
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: NotificationIconButton(
                            iconSize: 26,
                            onTap: () => NavHelper.push(const NotificationScreen()),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    // Greeting
                    Text(
                      'home.header.onboarding_greeting'.tr,
                      style: AppStyles.h1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 26.sp,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    // Subtitle
                    Text(
                      'home.header.onboarding_subtitle'.tr,
                      style: AppStyles.body2.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 15.sp,
                      ),
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
