import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppStyles {
  AppStyles._();

  static double get standardHeight => 56.h;

  // ─── Headlines ──────────────────────────────────────────────────────────────
  static TextStyle get h1 => GoogleFonts.openSans(
        fontSize: 24.sp,
        fontWeight: FontWeight.w900,
        color: AppColors.textTitle,
        height: 1.2,
      );

  static TextStyle get headLine2 => h2;

  static TextStyle get h2 => GoogleFonts.openSans(
        fontSize: 22.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.textTitle,
        height: 1.2,
      );

  static TextStyle get h3 => GoogleFonts.openSans(
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textTitle,
        height: 1.2,
      );

  static TextStyle get h4 => GoogleFonts.openSans(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textTitle,
        height: 1.2,
      );

  // ─── Body Text ─────────────────────────────────────────────────────────────
  static TextStyle get body1 => GoogleFonts.openSans(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get body2 => GoogleFonts.openSans(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get body3 => GoogleFonts.openSans(
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get body4 => GoogleFonts.openSans(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // ─── Captions & Labels ─────────────────────────────────────────────────────
  static TextStyle get caption => GoogleFonts.openSans(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get label => GoogleFonts.openSans(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  // ─── Specialized ───────────────────────────────────────────────────────────
  static TextStyle get buttonText => GoogleFonts.openSans(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle get hintStyle => GoogleFonts.openSans(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.hintColor,
      );

  // ─── Compatibility Methods (from old AppStyle) ─────────────────────────────
  static TextStyle title1({Color? color, FontWeight? fontWeight}) => GoogleFonts.openSans(
        fontSize: 72.sp,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color,
      );

  static TextStyle custom({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.openSans(
      fontSize: fontSize?.sp,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
}
