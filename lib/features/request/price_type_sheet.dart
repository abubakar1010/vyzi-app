import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/features/request/models/api_offer_model.dart';

/// Explains the offer's price type — the popup behind the "What does this
/// mean?" link on the Offer Details price-type row.
///
/// The copy is chosen from the offer's own market type, never shared across
/// every offer. An indexed or variable offer is explained through the
/// wholesale index it tracks; a fixed offer must not mention the index,
/// indexation or the spread at all, because none of it applies and reading it
/// next to a locked rate is what makes customers doubt the price they were
/// quoted.
class PriceTypeSheet extends StatelessWidget {
  final ApiOfferModel offer;

  const PriceTypeSheet({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final isIndexed = offer.isIndexedPrice;

    // The indexed popup keeps the market-green accent it shipped with; the
    // fixed one takes the brand purple, so the two read as different answers
    // before a word of them is read.
    final accent = isIndexed ? _kIndexAccent : AppColors.purple;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Hero banner ──
              isIndexed ? const _IndexedBanner() : const _FixedBanner(),

              // ── Content ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      isIndexed
                          ? 'offer.price_type_indexed_title'.tr
                          : 'offer.price_type_fixed_title'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Info card
                    _InfoCard(
                      // The index is named rather than hardcoded to PUN: a gas
                      // offer follows the PSV, and the price row right above
                      // this popup already says so.
                      text: isIndexed
                          ? 'offer.price_type_indexed_text'
                              .trParams({'index': offer.priceIndexLabel})
                          : 'offer.price_type_fixed_text'.tr,
                      note: isIndexed
                          ? 'offer.price_type_indexed_note'.tr
                          : 'offer.price_type_fixed_note'.tr,
                      accent: accent,
                    ),
                    const SizedBox(height: 24),

                    // Got It button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
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

/// Accent of the indexed popup — the market-trend green the artwork uses.
const Color _kIndexAccent = Color(0xFF2ED8B4);

const double _kBannerHeight = 160;

/// Banner for an indexed offer: the market-trend artwork.
class _IndexedBanner extends StatelessWidget {
  const _IndexedBanner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kBannerHeight,
      width: double.infinity,
      child: Image.asset(
        'assets/images/priceType.webp',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _BannerFallback(
          gradient: [Color(0xFF0D4A3A), Color(0xFF1A6B50), Color(0xFF0A3528)],
          icon: Icons.trending_up_rounded,
          iconColor: _kIndexAccent,
        ),
      ),
    );
  }
}

/// Banner for a fixed offer. Drawn rather than an asset, and deliberately not
/// the market-trend artwork — a rising chart is the one image a locked price
/// should not open with.
class _FixedBanner extends StatelessWidget {
  const _FixedBanner();

  @override
  Widget build(BuildContext context) {
    return const _BannerFallback(
      gradient: [Color(0xFF3E0059), Color(0xFF5A1ABE), Color(0xFF2A0B57)],
      icon: Icons.lock_outline_rounded,
      iconColor: Colors.white,
    );
  }
}

class _BannerFallback extends StatelessWidget {
  final List<Color> gradient;
  final IconData icon;
  final Color iconColor;

  const _BannerFallback({
    required this.gradient,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kBannerHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.5,
            ),
          ),
          child: Icon(icon, color: iconColor, size: 30),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String text;
  final String note;
  final Color accent;

  const _InfoCard({
    required this.text,
    required this.note,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main description
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Note row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: accent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  note,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
