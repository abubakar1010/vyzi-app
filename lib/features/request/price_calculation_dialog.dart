import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vyzi/features/request/models/api_offer_model.dart';

/// Breaks the energy price down into the formula it comes from — the popup
/// behind the "How is it calculated?" link on the Offer Details energy-price
/// row.
///
/// Only an indexed or variable offer has a formula, so Offer Details opens
/// this for those alone; a fixed offer has a single locked rate and gets the
/// fixed branch of [PriceTypeSheet] instead. The index and the spread come
/// from the offer, never from house defaults: a hardcoded "PUN GME + 0,01"
/// contradicts the rate printed one row above it on every other offer.
class PriceCalculationDialog extends StatelessWidget {
  final ApiOfferModel offer;

  const PriceCalculationDialog({super.key, required this.offer});

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
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'offer.price_calc_subtitle'.tr,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Formula card
                    _FormulaCard(
                      index: offer.priceIndexLabel,
                      spread: offer.spreadDisplay,
                    ),
                    const SizedBox(height: 18),

                    // Footer note
                    Text(
                      'offer.price_calc_footer'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
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
                          backgroundColor: const Color(0xFF5A1ABE),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
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
class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {


    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // ── Asset image ──
        Container(
          height: 130,
          width: double.infinity,
          padding: const EdgeInsets.only(top: 20),

          child: Image.asset(
            'assets/images/price_calculate.webp',
            height: 64,
            errorBuilder: (_, __, ___) {
              return Container(
                color: const Color(0xFFF2F4F8),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The offer's own formula, stacked: index over `+` over spread.
class _FormulaCard extends StatelessWidget {
  /// Wholesale index the offer tracks, e.g. `PUN GME` or `PSV`.
  final String index;

  /// Supplier markup over the index, already formatted, e.g. `€0,010/kWh`.
  final String spread;

  const _FormulaCard({required this.index, required this.spread});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w900,
      color: Colors.black,
      letterSpacing: 0.5,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2F4F7), width: 1),
      ),
      child: Column(
        children: [
          // Index
          Text(index, textAlign: TextAlign.center, style: style),
          const SizedBox(height: 6),

          // Plus sign
          const Text(
            '+',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),

          // Spread
          Text(spread, textAlign: TextAlign.center, style: style),
        ],
      ),
    );
  }
}
