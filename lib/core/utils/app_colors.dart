import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFFFFFFFF);
  static const Color primaryColor = Color(0xFF5A1ABE);
  static const Color secondaryColor = Color(0xFF06B6D4);
  
  static const Color primaryButton = primaryColor;
  static const Color fillColor = Color(0xFFFFFFFF);
  static const Color hintColor = Color(0xFF000000);
  static const Color borderColor = primaryColor;
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF000000);
  static const Color textTitle = Color(0xFF000000);
  static const Color borderGlobal = Color(0xFF7B48CB);
  static const Color shortcardbg = Color(0xFFEFEFEF);



  static const Color purple = primaryColor;
  static const Color lightPurple = Color(0xFFF4E6FB);
  static const Color borderPurple = Color(0xFFDEB0F1);
  static const Color darkPurple = Color(0xFF3E0059);
  
  static const Color blue = Color(0xFF06B6D4);
  static const Color darkBlue = primaryColor;
  static const Color accentBlue = Color(0xFF2B7FFF);
  static const Color linkBlue = Color(0xFF2980B9);
  static const Color linkGreen = Color(0xFF27AE60);

  static const List<Color> primaryGradient = [primaryColor, secondaryColor];

  /// Header gradient matching Figma SVG export (diagonal top-left → bottom-right)
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF9400D3), Color(0xFF06B6D4)],
    begin: Alignment(-1.0, -0.86),
    end: Alignment(1.0, 1.02),
  );

  /// Decorative disc in the top-right of the header banner.
  static const Color headerCircle = Color(0xCC06B6D4);

  /// Fill of the header banner's notification tile. A shade lighter than
  /// [headerCircle] — the tile sits entirely inside that disc, so anything
  /// darker or equal makes the button disappear into it.
  static const Color headerIconTile = Color(0xFF28C8E7);

  static const Color green = Color(0xFF00C896);
  static const Color greenText = Color(0xFF00A876);
  static const Color bg = Color(0xFFF7F8FC);
  static const Color cardBg = Colors.white;
  
  static const Color textDark = Color(0xFF000000);
  static const Color textDarkest = Color(0xFF000000);
  static const Color textMid = Color(0xFF000000);
  static const Color textLight = Color(0xFF000000);
  static const Color divider = Color(0xFFE8E8E8);

  /// Muted text — placeholders, hints and helper copy.
  ///
  /// The `text*` tokens above were all collapsed to pure black, which leaves a
  /// placeholder indistinguishable from a typed value on a filled field.
  static const Color textMuted = Color(0xFF8A8A99);
  static const Color primaryPurple = Color(0xFFEFE8F9);

  // ─── Primary ───────────────────────────────────────────────────────────────
  static const Color primary50 = Color(0xFFF5F7FF);
  static const Color primary100 = Color(0xFFEEF0FF);
  static const Color primary200 = Color(0xFFE1E4FE);
  static const Color primary300 = Color(0xFFC8CCFD);
  static const Color primary400 = Color(0xFFA7ABFA);
  static const Color primary500 = Color(0xFF8884F5);
  static const Color primary600 = Color(0xFF7061ED);
  static const Color primary700 = primaryColor;
  static const Color primary800 = primaryColor;
  static const Color primary900 = Color(0xFF4833A0);
  static const Color primary1000 = Color(0xFF3D307F);

  /// Primary Alpha
  static const Color primaryAlpha10 = Color(0x1A5A1ABE);

  // ─── Neutral ───────────────────────────────────────────────────────────────
  static const Color neutral50 = Color(0xFFFFFFFF);
  static const Color neutral100 = Color(0xFF000000);
  static const Color neutral200 = Color(0xFF000000);
  static const Color neutral300 = Color(0xFF000000);
  static const Color neutral400 = Color(0xFF000000);
  static const Color neutral500 = Color(0xFF000000);
  static const Color neutral600 = Color(0xFF000000);
  static const Color neutral700 = Color(0xFF000000);
  static const Color neutral800 = Color(0xFF000000);
  static const Color neutral900 = Color(0xFF000000);
  static const Color neutral1000 = Color(0xFF000000);

  /// Neutral Alpha
  static const Color neutralAlpha10 = Color(0x1A000000);

  // ─── Red ───────────────────────────────────────────────────────────────────
  static const Color red100 = Color(0xFFFB3748);
  static const Color red200 = Color(0xFFD00416);
  static const Color error = Color(0xFFE53935);

  /// Red Alpha
  static const Color redAlpha10 = Color(0x1AFB3748);

  // ─── Yellow ────────────────────────────────────────────────────────────────
  static const Color yellow100 = Color(0xFFFFDB43);
  static const Color yellow200 = Color(0xFFDFB400);

  /// Yellow Alpha
  static const Color yellowAlpha10 = Color(0x1AFFDB43);

  // ─── Green ─────────────────────────────────────────────────────────────────
  static const Color green100 = Color(0xFF84EBB4);
  static const Color green200 = Color(0xFF1FC16B);






  static const Color invitebg = Color(0xFFEFE8F9);

  /// Green Alpha
  static const Color greenAlpha10 = Color(0x1A1FC16B);






}
