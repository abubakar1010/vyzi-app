import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// How the app adapts to wide windows: an iPad, full screen or in a Split
/// View pane wide enough to count.
///
/// Every screen is designed for a 392x876 phone and sized through
/// flutter_screenutil, which scales by the window width. On an iPad that would
/// grow every icon, gap and line of text 2.6 times, so wide windows get one
/// fixed scale instead ([AdaptiveScale]) and the layouts use the room they get:
/// a navigation rail, content kept to a readable width ([ReadableWidth],
/// [SliverReadableWidth]) and more columns ([Adaptive.columns]).
///
/// Decisions go by window width, not device: a narrow Split View or Slide Over
/// pane on an iPad is laid out exactly like a phone.
class Adaptive {
  Adaptive._();

  /// Window width, in logical pixels, from which the tablet layout is used.
  static const double wideBreakpoint = 600;

  /// What one design pixel is worth on a wide window. iPadOS sizes text and
  /// controls much as iOS does, so the phone design is kept close to 1:1.
  static const double wideScale = 1.1;

  /// Widest a column of text, a form or a detail page grows to.
  static const double readableWidth = 720;

  /// Widest a dashboard of cards side by side grows to.
  static const double dashboardWidth = 1100;

  /// Widest a sign-in or sign-up form grows to.
  static const double formWidth = 520;

  static bool isWideWidth(double width) => width >= wideBreakpoint;

  /// Whether the window gets the tablet layout.
  static bool isWide(BuildContext context) =>
      isWideWidth(MediaQuery.sizeOf(context).width);

  /// How many columns a grid of cards at least [minTileWidth] wide gets in
  /// [width]: one on a phone, more as the window widens.
  static int columns(double width, {double minTileWidth = 340, int max = 3}) {
    if (!isWideWidth(width)) return 1;
    return (width / minTileWidth).floor().clamp(1, max);
  }

  /// Side padding for a page: [phone] on a phone, and on a wide window
  /// whatever centres the content at [maxWidth], but never less than [phone].
  ///
  /// Hand it to the page's scroll view, so the whole window scrolls and the
  /// scroll bar stays at its edge.
  static EdgeInsets gutters(
    BuildContext context,
    double phone, {
    double maxWidth = readableWidth,
  }) {
    return page(
      context,
      EdgeInsets.symmetric(horizontal: phone),
      maxWidth: maxWidth,
    );
  }

  /// A page's [phone] padding, with the sides widened on a wide window so the
  /// content between them is centred at [maxWidth]. See [gutters].
  static EdgeInsets page(
    BuildContext context,
    EdgeInsets phone, {
    double maxWidth = readableWidth,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (!isWideWidth(width)) return phone;
    final inset = (width - maxWidth) / 2;
    return phone.copyWith(
      left: math.max(phone.left, inset),
      right: math.max(phone.right, inset),
    );
  }

  /// The side padding that centres content no wider than [maxWidth] in
  /// [available], and never less than [minimum].
  static double centringInset(
    double available, {
    double maxWidth = readableWidth,
    required double minimum,
  }) {
    return math.max(minimum, (available - maxWidth) / 2);
  }
}

/// Configures flutter_screenutil for the window: the phone design scaled by
/// width on phones, and one fixed scale on wide windows.
///
/// Sits directly inside [ScreenUtilInit]'s builder, which runs again whenever
/// the window changes size, so a rotation or a Split View resize lands here.
class AdaptiveScale extends StatelessWidget {
  const AdaptiveScale({super.key, required this.child});

  final Widget child;

  /// The design size that makes flutter_screenutil scale a window of [window]
  /// size by [Adaptive.wideScale], or null when the phone design size stands.
  static Size? designSizeFor(Size window) {
    if (!Adaptive.isWideWidth(window.width)) return null;
    return window / Adaptive.wideScale;
  }

  @override
  Widget build(BuildContext context) {
    final designSize = designSizeFor(MediaQuery.sizeOf(context));
    if (designSize != null) {
      ScreenUtil.configure(
        data: MediaQuery.of(context),
        designSize: designSize,
      );
    }
    return child;
  }
}

/// Keeps [child] to [maxWidth], centred, on a wide window; a phone gets it
/// as it is.
///
/// Wrap what sits *inside* a scroll view, so the whole window still scrolls
/// and the scroll bar stays at its edge.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({
    super.key,
    required this.child,
    this.maxWidth = Adaptive.readableWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!Adaptive.isWide(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// The sliver form of [ReadableWidth].
class SliverReadableWidth extends StatelessWidget {
  const SliverReadableWidth({
    super.key,
    required this.sliver,
    this.maxWidth = Adaptive.readableWidth,
  });

  final Widget sliver;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!Adaptive.isWide(context)) return sliver;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final inset = Adaptive.centringInset(
          constraints.crossAxisExtent,
          maxWidth: maxWidth,
          minimum: 0,
        );
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          sliver: sliver,
        );
      },
    );
  }
}

/// A scrolling list of cards: one column on a phone, and on a wide window as
/// many columns as fit cards at least [minTileWidth] wide.
///
/// The cards keep their own heights and are dealt across the columns in order
/// (a masonry), so a short card never leaves a hole beside a tall one. They are
/// expected to space themselves vertically (a bottom margin), as they already
/// do in the phone list; [spacing] is the gap between columns. Wide lists are
/// built in one go, which suits the dozen-odd cards these screens show.
class AdaptiveListView extends StatelessWidget {
  const AdaptiveListView.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.minTileWidth = 340,
    this.maxColumns = 3,
    this.spacing = 14,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
    this.maxWidth,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry? padding;
  final double minTileWidth;
  final int maxColumns;
  final double spacing;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  /// When set, [padding] is the phone padding, and a wide window widens its
  /// sides to centre the cards at this width, as [Adaptive.page] does.
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!Adaptive.isWide(context)) {
      return ListView.builder(
        controller: controller,
        physics: physics,
        shrinkWrap: shrinkWrap,
        padding: padding,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        var resolved =
            padding?.resolve(Directionality.of(context)) ?? EdgeInsets.zero;
        if (maxWidth != null) {
          resolved = Adaptive.page(context, resolved, maxWidth: maxWidth!);
        }
        final columns = Adaptive.columns(
          constraints.maxWidth - resolved.horizontal,
          minTileWidth: minTileWidth,
          max: maxColumns,
        );
        return ListView(
          controller: controller,
          physics: physics,
          shrinkWrap: shrinkWrap,
          padding: resolved,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var column = 0; column < columns; column++) ...[
                  if (column > 0) SizedBox(width: spacing),
                  Expanded(
                    child: Column(
                      children: [
                        for (var i = column; i < itemCount; i += columns)
                          itemBuilder(context, i),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}
