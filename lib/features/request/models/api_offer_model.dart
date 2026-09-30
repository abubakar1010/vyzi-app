import 'package:get/get.dart';
import 'package:vyzi/core/utils/number_format.dart';
import 'package:vyzi/core/utils/duration_format.dart';

/// Payment methods a supplier accepts for an offer — mirrors the backend
/// `OfferPaymentMethod` enum. Unlike the case-level payment method the customer
/// picks, an offer may accept both.
class OfferPaymentMethod {
  static const String directDebit = 'direct_debit';
  static const String postalOrder = 'postal_order';
  static const String both = 'both';
}

class ApiOfferModel {
  final String id;

  /// The bill this offer was proposed for, carried over from the sent-offer
  /// record. An offer only means something against one supply point: it is
  /// what the switch request is opened for, and what decides which offers
  /// disappear from the list once one of them is accepted. Empty when the
  /// offer was loaded on its own (e.g. from the offer catalogue).
  final String billId;
  final String name;
  final String? description;
  final String energyType;
  final String marketType;
  final double? pricePerKwh;
  final double? pricePerSmc;
  final double? spread;
  final double fixedMonthlyFee;
  final double activationCost;
  final int contractDurationDays;
  final bool isGreenEnergy;
  final String? validFrom;
  final String? validUntil;
  final String? termsUrl;
  final String? economicConditionsUrl;
  final String target;
  final String paymentMethod;
  final List<String> highlights;
  final String? offerCode;
  final OfferSupplierModel? supplier;
  final double? estimatedSavings;

  const ApiOfferModel({
    required this.id,
    this.billId = '',
    required this.name,
    this.description,
    required this.energyType,
    required this.marketType,
    this.pricePerKwh,
    this.pricePerSmc,
    this.spread,
    this.fixedMonthlyFee = 0,
    this.activationCost = 0,
    this.contractDurationDays = 0,
    this.isGreenEnergy = false,
    this.validFrom,
    this.validUntil,
    this.termsUrl,
    this.economicConditionsUrl,
    this.target = 'both',
    this.paymentMethod = OfferPaymentMethod.both,
    this.highlights = const [],
    this.offerCode,
    this.supplier,
    this.estimatedSavings,
  });

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int _parseInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  factory ApiOfferModel.fromJson(Map<String, dynamic> json) {
    return ApiOfferModel(
      id: json['id'] as String? ?? '',
      billId: json['billId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      energyType: json['energyType'] as String? ?? '',
      marketType: json['marketType'] as String? ?? '',
      pricePerKwh: _parseDouble(json['pricePerKwh']),
      pricePerSmc: _parseDouble(json['pricePerSmc']),
      spread: _parseDouble(json['spread']),
      fixedMonthlyFee: _parseDouble(json['fixedMonthlyFee']) ?? 0,
      activationCost: _parseDouble(json['activationCost']) ?? 0,
      contractDurationDays: _parseInt(json['contractDurationDays']),
      isGreenEnergy: json['isGreenEnergy'] as bool? ?? false,
      validFrom: json['validFrom'] as String?,
      validUntil: json['validUntil'] as String?,
      termsUrl: json['termsUrl'] as String?,
      economicConditionsUrl: json['economicConditionsUrl'] as String?,
      target: json['target'] as String? ?? 'both',
      // Older offers predate the field — treating them as "both" keeps them
      // visible under every filter chip rather than silently disappearing.
      paymentMethod:
          json['paymentMethod'] as String? ?? OfferPaymentMethod.both,
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      offerCode: json['offerCode'] as String?,
      supplier: json['supplier'] != null
          ? OfferSupplierModel.fromJson(
              json['supplier'] as Map<String, dynamic>)
          : null,
      estimatedSavings: _parseDouble(json['estimatedSavings']),
    );
  }

  /// Formatted estimated savings for display
  String get estimatedSavingsDisplay => formatMoney(estimatedSavings);

  /// The offer's fixed supply cost, e.g. `€12,00/mese`. The suffix is
  /// translated rather than hardcoded, so the English locale does not read
  /// `€12.00/mese`. An offer with no standing charge shows `€0,00`, not a
  /// dash: zero is a real, and persuasive, fixed cost.
  String get fixedMonthlyFeeDisplay =>
      '${formatMoney(fixedMonthlyFee)}${'common.per_month'.tr}';

  /// Whether the energy price tracks a wholesale index instead of being locked
  /// for the contract period.
  ///
  /// To the customer `variable` and `indexed` are the same deal — a market
  /// index plus the supplier's spread — so every screen that has to choose
  /// between "fixed" and "follows the market" asks this rather than re-listing
  /// the two market types and eventually forgetting one of them.
  bool get isIndexedPrice => marketType == 'variable' || marketType == 'indexed';

  /// The wholesale index an indexed offer follows: PUN GME for electricity,
  /// PSV for gas. Means nothing on a fixed offer, which follows no index.
  String get priceIndexLabel => energyType == 'gas' ? 'PSV' : 'PUN GME';

  /// The unit an indexed price is quoted in — Sm³ for gas, kWh otherwise.
  String get energyUnitLabel => energyType == 'gas' ? 'Sm³' : 'kWh';

  /// The supplier's markup over the index, e.g. `€0,010/kWh`. A missing spread
  /// reads as zero rather than a dash — it is one half of a formula, and
  /// "PUN GME + -" is not a price.
  String get spreadDisplay =>
      formatUnitPrice(spread ?? 0, unit: energyUnitLabel);

  /// Formatted energy price string for display. Variable and indexed offers
  /// read as index + spread (e.g. "PUN GME + €0,010/kWh"); fixed offers read
  /// as a flat rate (e.g. "€0,134/kWh").
  ///
  /// Every price here sits at the same three decimals. The old version trimmed
  /// trailing zeros, which made a 0,010 spread and a 0,100 spread differ in
  /// width as well as value and left the column ragged.
  String get energyPriceDisplay {
    if (isIndexedPrice) return '$priceIndexLabel + $spreadDisplay';

    final price = pricePerKwh ?? pricePerSmc;
    if (price == null) return '';
    final unit = pricePerKwh != null ? 'kWh' : 'Sm³';
    return formatUnitPrice(price, unit: unit);
  }

  /// The energy price row on the offer list card, worded by offer type:
  ///
  ///   fixed              `Prezzo Energia (Fisso): €0,14/kWh`
  ///   variable/indexed   `Prezzo Energia: PUN + 0,025 €/kWh`
  ///                      `Prezzo Energia: PUN + Spread` (no spread on record)
  ///
  /// Prices drop their trailing zeros here, unlike [energyPriceDisplay] — the
  /// spec for this row asks for it. A missing spread names the term instead of
  /// printing a zero: the list is not the place to claim a spread of nothing.
  String get energyPriceRow {
    if (isIndexedPrice) {
      return 'request.offers.energy_price_indexed'.trParams({
        'index': energyType == 'gas' ? 'PSV' : 'PUN',
        'spread': spread == null
            ? 'request.offers.energy_price_spread'.tr
            : '${formatUnitPriceCompactValue(spread)} €/$energyUnitLabel',
      });
    }

    final price = pricePerKwh ?? pricePerSmc;
    final unit = pricePerKwh != null ? 'kWh' : 'Sm³';
    return 'request.offers.energy_price_fixed'.trParams({
      'price': price == null
          ? kMissingValue
          : '€${formatUnitPriceCompactValue(price)}/$unit',
    });
  }

  /// Whether the supplier accepts direct debit (SDD) for this offer.
  bool get supportsDirectDebit =>
      paymentMethod == OfferPaymentMethod.directDebit ||
      paymentMethod == OfferPaymentMethod.both;

  /// Whether the supplier accepts a postal order for this offer.
  bool get supportsPostalOrder =>
      paymentMethod == OfferPaymentMethod.postalOrder ||
      paymentMethod == OfferPaymentMethod.both;

  /// Translated payment-method label. "Both" reads as the two options joined,
  /// so the card never shows a bare "Both" the customer has to decode.
  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case OfferPaymentMethod.directDebit:
        return 'request.filter.direct_debit'.tr;
      case OfferPaymentMethod.postalOrder:
        return 'request.filter.postal_slip'.tr;
      default:
        return '${'request.filter.direct_debit'.tr} / ${'request.filter.postal_slip'.tr}';
    }
  }

  /// Market type display label
  String get marketTypeDisplay {
    switch (marketType) {
      case 'fixed':
        return 'offer.market_fixed'.tr;
      case 'variable':
        return 'offer.market_variable'.tr;
      case 'indexed':
        return 'offer.market_indexed'.tr;
      default:
        return marketType;
    }
  }

  /// Contract duration display — months by default, days if < 30
  String get contractDurationDisplay {
    if (contractDurationDays <= 0) return 'offer.duration_indefinite'.tr;
    if (contractDurationDays < 30) return formatDays(contractDurationDays);
    return formatMonths(contractDurationDays ~/ 30);
  }

  /// Contractual binding display — months by default, days if < 30
  String get bindingDisplay {
    if (contractDurationDays <= 0) return 'offer.no_binding'.tr;
    if (contractDurationDays < 30) return formatDays(contractDurationDays);
    return formatMonths(contractDurationDays ~/ 30);
  }
}

class OfferSupplierModel {
  final String id;
  final String name;
  final String? logoUrl;
  final String? description;
  final double? rating;

  const OfferSupplierModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.description,
    this.rating,
  });

  factory OfferSupplierModel.fromJson(Map<String, dynamic> json) {
    return OfferSupplierModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      description: json['description'] as String?,
      rating: ApiOfferModel._parseDouble(json['rating']),
    );
  }
}
