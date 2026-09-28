import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/utils/number_format.dart';
import 'package:vyzi/features/support/models/faq_model.dart';

class UserServiceModel {
  final String id;
  final String? caseId;
  /// The bill this switch started from. It is how a request the customer taps
  /// in their requests list is matched to the service it became — that list
  /// only ever holds bills. Null on a case opened without one.
  final String? billId;
  final String? offerId;
  final String? energyType;
  final String? supplyAddress;
  final String? offerName;
  final String? supplierName;
  /// The supplier's logo as the API stores it: a relative upload path or an
  /// absolute URL. Resolve it with [supplierLogoUrl] before loading it.
  final String? supplierLogo;
  /// The supplier's own customer-support address, null when they have none on
  /// file — the contact list leaves the email option out rather than open a
  /// mail draft addressed to nobody.
  final String? supplierEmail;
  /// The supplier's site as the admin entered it: usually a bare domain
  /// ("eniplenitude.it"), sometimes a full URL. Open it with [supplierWebsiteUrl].
  final String? supplierWebsite;
  /// Free text the admin wrote about the supplier, shown as the "About
  /// `<supplier>`" section. Null when they wrote none, and the section is left
  /// out rather than shown with an empty body.
  final String? supplierDescription;
  /// The FAQs the admin wrote for this supplier, in display order, shown as
  /// the FAQ section of the utility details. Empty when there are none, and
  /// the section is left out.
  final List<FaqModel> supplierFaqs;
  final String? contractNumber;
  final String? podPdrNumber;
  /// The meter serving this supply, as printed on the bill. Null on a bill the
  /// number could not be read off — the row is left out rather than shown empty.
  final String? meterNumber;
  /// What this supply uses in a year, already annualised by the API from the
  /// bill's own period. Quoted in [consumptionUnit]. Null when the bill carries
  /// no consumption figure.
  final num? annualConsumption;
  /// The unit [annualConsumption] is quoted in — 'kWh' for electricity, 'Smc'
  /// for gas. The API sends it so the client need not map supply type to unit.
  final String? consumptionUnit;
  final String? activationDate;
  final String? expiryDate;
  final String? monthlyEstimate;

  /// How the offer prices energy — 'fixed', 'variable' or 'indexed'. A fixed
  /// offer quotes a per-unit price; the other two quote a spread over the
  /// market index instead, and carry no per-unit price at all. Null on a
  /// service whose offer the API could not resolve.
  final String? marketType;
  final String? pricePerKwh;
  final String? pricePerSmc;

  /// What the customer pays over the market index on a variable or indexed
  /// offer, in EUR per kWh or Smc. Null on a fixed offer, which has a per-unit
  /// price instead.
  final String? spread;
  final String? fixedMonthlyFee;
  final int? contractDurationDays;
  final bool isGreenEnergy;
  final String? status;

  const UserServiceModel({
    required this.id,
    this.caseId,
    this.billId,
    this.offerId,
    this.energyType,
    this.supplyAddress,
    this.offerName,
    this.supplierName,
    this.supplierLogo,
    this.supplierEmail,
    this.supplierWebsite,
    this.supplierDescription,
    this.supplierFaqs = const [],
    this.contractNumber,
    this.podPdrNumber,
    this.meterNumber,
    this.annualConsumption,
    this.consumptionUnit,
    this.activationDate,
    this.expiryDate,
    this.monthlyEstimate,
    this.marketType,
    this.pricePerKwh,
    this.pricePerSmc,
    this.spread,
    this.fixedMonthlyFee,
    this.contractDurationDays,
    this.isGreenEnergy = false,
    this.status,
  });

  /// The supplier logo ready for [Image.network] - the API returns the path it
  /// was uploaded to, which only resolves against the API origin. Null when the
  /// supplier has no logo on file, so callers show their own fallback mark.
  String? get supplierLogoUrl {
    final logo = supplierLogo?.trim();
    if (logo == null || logo.isEmpty) return null;
    return logo.startsWith('http') ? logo : '${ApiConstants.baseUrl}$logo';
  }

  /// The supplier's site ready to launch — the stored value is normally a bare
  /// domain, which [Uri.parse] would treat as a relative path and fail to open,
  /// so it gets an https scheme. Null when the supplier has no site on file.
  String? get supplierWebsiteUrl {
    final site = supplierWebsite?.trim();
    if (site == null || site.isEmpty) return null;
    if (site.startsWith('http://') || site.startsWith('https://')) return site;
    return 'https://$site';
  }

  /// The site as it reads on screen — the domain alone, without the scheme or a
  /// trailing slash the admin may have pasted in.
  String? get supplierWebsiteDisplay {
    final site = supplierWebsite?.trim();
    if (site == null || site.isEmpty) return null;
    return site
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'/+$'), '');
  }

  /// The supplier blurb as it reads on screen. Null when the admin wrote
  /// none, or wrote only whitespace, so the section can be left out.
  String? get supplierDescriptionDisplay {
    final text = supplierDescription?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  bool get isActivated => status == 'activated';
  bool get isAwaitingActivation => status == 'awaiting_activation';

  bool get _isGas => energyType == 'gas';

  /// Whether this supply is priced off a market index rather than at a flat
  /// per-unit rate. Variable and indexed offers both are: neither carries a
  /// `pricePerKwh`, so asking for one and printing a dash when it is missing
  /// tells the customer their contract has no price, which is wrong — it has a
  /// spread over [priceIndexLabel].
  bool get isIndexedPrice =>
      marketType == 'variable' || marketType == 'indexed';

  /// The market index this supply is priced against — PUN for electricity,
  /// PSV for gas. These are the names printed on the customer's own contract,
  /// so they are not translated.
  String get priceIndexLabel => _isGas ? 'PSV' : 'PUN';

  /// The per-unit figure this supply's price is built from, at unit-price
  /// precision — the flat rate on a fixed offer, the spread on an indexed one.
  /// Null when the offer carries neither, so the caller can show its own
  /// placeholder rather than a formatted zero.
  ///
  /// What that figure *means* differs between the two, which is why
  /// [isIndexedPrice] has to travel with it: `0,012` is a whole price on one
  /// offer and an adder on the other.
  String? get unitPriceValueDisplay {
    final raw = isIndexedPrice ? spread : (_isGas ? pricePerSmc : pricePerKwh);
    final formatted = formatUnitPriceValue(raw, fallback: '');
    return formatted.isEmpty ? null : formatted;
  }

  /// The unit that figure is quoted in — '€/Smc' for gas, '€/kWh' otherwise.
  String get unitPriceUnitDisplay => _isGas ? '€/Smc' : '€/kWh';

  /// The contract duration the way an Italian energy contract quotes it — in
  /// months ("12 mesi", "24 mesi"), never as a raw day count. Days are only
  /// used for a contract shorter than a month, which has no month figure to
  /// quote. Null when the dates it comes from are missing, so the row can be
  /// left out rather than show a placeholder.
  ///
  /// The average month length is what turns days into that figure. A contract
  /// running 1 Jul 2026 → 30 Jun 2027 is 364 days and is a twelve-month
  /// contract; so is one running to 1 Jul 2027 at 365 days. Counting only whole
  /// elapsed months would quote the first one as eleven.
  String? get contractDurationDisplay {
    final days = contractDurationDays;
    if (days == null || days <= 0) return null;

    const daysPerMonth = 30.4375;
    final months = (days / daysPerMonth).round();
    if (months == 0) return days == 1 ? '1 giorno' : '$days giorni';
    return months == 1 ? '1 mese' : '$months mesi';
  }

  /// The yearly consumption the way a bill quotes it — grouped thousands and
  /// the unit, "2.800,00 kWh" in Italian, "2,800.00 kWh" in English. Null when
  /// there is no figure, so the block can be left out rather than show a zero
  /// the customer would read as a real reading.
  String? get annualConsumptionDisplay {
    final value = annualConsumption;
    if (value == null || value <= 0) return null;
    return formatQuantity(value, unit: consumptionUnit?.trim());
  }

  factory UserServiceModel.fromJson(Map<String, dynamic> json) {
    return UserServiceModel(
      id: json['id'] as String? ?? '',
      caseId: json['caseId'] as String?,
      billId: json['billId'] as String?,
      offerId: json['offerId'] as String?,
      energyType: json['energyType'] as String?,
      supplyAddress: json['supplyAddress'] as String?,
      offerName: json['offerName'] as String?,
      supplierName: json['supplierName'] as String?,
      supplierLogo: json['supplierLogo'] as String?,
      supplierEmail: json['supplierEmail'] as String?,
      supplierWebsite: json['supplierWebsite'] as String?,
      supplierDescription: json['supplierDescription'] as String?,
      supplierFaqs: (json['supplierFaqs'] as List<dynamic>? ?? [])
          .map((e) => FaqModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      contractNumber: json['contractNumber'] as String?,
      podPdrNumber: json['podPdrNumber'] as String?,
      meterNumber: json['meterNumber'] as String?,
      annualConsumption: json['annualConsumption'] as num?,
      consumptionUnit: json['consumptionUnit'] as String?,
      activationDate: json['activationDate'] as String?,
      expiryDate: json['expiryDate'] as String?,
      monthlyEstimate: json['monthlyEstimate']?.toString(),
      marketType: json['marketType'] as String?,
      pricePerKwh: json['pricePerKwh']?.toString(),
      pricePerSmc: json['pricePerSmc']?.toString(),
      spread: json['spread']?.toString(),
      fixedMonthlyFee: json['fixedMonthlyFee']?.toString(),
      contractDurationDays: json['contractDurationDays'] as int?,
      isGreenEnergy: json['isGreenEnergy'] as bool? ?? false,
      status: json['status'] as String?,
    );
  }
}
