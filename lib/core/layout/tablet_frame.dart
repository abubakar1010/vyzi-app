import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Runs the phone layout on tablets as a centred, phone-width column.
///
/// Every screen is designed for a 392x876 phone and sized through
/// flutter_screenutil, which scales by the screen width. On an iPad that
/// width is 2.6 times a phone's, so every icon, gap and line of text would
/// grow by the same factor. Instead, a screen whose shortest side is a
/// tablet's gets a column no wider than [maxWidth], and both the widgets
/// (through [MediaQuery]) and flutter_screenutil are told that column is the
/// screen. Phones, and iPad Split View panes narrower than a tablet, are left
/// untouched.
class TabletFrame extends StatelessWidget {
  const TabletFrame({super.key, required this.child});

  /// Shortest side, in logical pixels, from which a screen counts as a tablet.
  static const double tabletShortestSide = 600;

  /// Widest the app gets on a tablet: a large phone, so the design still fits.
  static const double maxWidth = 480;

  final Widget child;

  /// The size the app lays itself out for on a screen of [screen] size.
  static Size appSizeFor(Size screen) {
    if (screen.shortestSide < tabletShortestSide) return screen;
    return Size(math.min(screen.width, maxWidth), screen.height);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final appSize = appSizeFor(media.size);
    if (appSize == media.size) return child;

    final data = media.copyWith(size: appSize);
    // ScreenUtilInit measures the device itself and has just configured
    // ScreenUtil for the full width; the column is what the design must fill.
    ScreenUtil.configure(data: data);

    return ColoredBox(
      color: const Color(0xFFE8ECF2),
      child: Center(
        child: SizedBox(
          width: appSize.width,
          child: MediaQuery(
            data: data,
            child: ClipRect(child: child),
          ),
        ),
      ),
    );
  }
}
