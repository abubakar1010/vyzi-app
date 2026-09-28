import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PriceCalculationDialog extends StatelessWidget {
  const PriceCalculationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Hero Banner ──
              _HeroBanner(),

              // ── Body Content ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      'offer.price_calc_title'.tr,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D0D1A),
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'offer.price_calc_subtitle'.tr,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Formula card
                    _FormulaCard(),
                    const SizedBox(height: 18),

                    // Footer note
                    Text(
                      'offer.price_calc_footer'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade500,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Got It button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A2B6B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        child: Text('common.got_it'.tr),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top hero banner — shows your asset image.
/// Falls back to a clean white background with the navy icon if asset is missing.
class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // ── Asset image (replace path with yours) ──
        Container(
          height: 130,
          width: double.infinity,
          padding: const EdgeInsets.only(top: 20),
          child: Image.asset(
            // 🔑 Replace with your actual asset, e.g.:
            // 'assets/images/price_banner.png'
            'assets/images/price_calculate.webp',
            height: 64,
            errorBuilder: (_, __, ___) {
              // Fallback: light grey background matching the screenshot
              return Container(
                color: const Color(0xFFF2F4F8),
              );
            },
          ),
        ),

        // ── Icon badge — sits on the bottom edge of the banner ──
        Positioned(
          bottom: -28,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2B6B),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A2B6B).withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }
}

class _FormulaCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // PUN GME
          const Text(
            'PUN GME',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D0D1A),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),

          // Plus sign
          Text(
            '+',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),

          // Value
          const Text(
            '0,01 €/KWh',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D0D1A),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
