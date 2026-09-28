import 'package:get/get.dart';
import 'package:vyzi/core/utils/number_format.dart';

class CaseModel {
  final String id;
  final String status;
  final String? caseNumber;
  final String? caseType;
  final String? billId;
  final String? selectedOfferId;
  final String? notes;
  final String createdAt;
  final String? updatedAt;
  final CaseOfferModel? selectedOffer;

  // ── Activation ──
  // The contract is signed with the supplier, outside the app, so these are
  // whatever the admin entered when they put the case into activation.

  /// When the admin handed the contract over for signing.
  final String? contractSentAt;

  /// When the new supply goes live. Planned while the switch is running.
  final String? activationDate;

  /// When the new supply contract expires.
  final String? expiryDate;

  /// Yearly saving quoted on the offer the customer accepted.
  final double? estimatedSavings;

  const CaseModel({
    required this.id,
    required this.status,
    this.caseNumber,
    this.caseType,
    this.billId,
    this.selectedOfferId,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.selectedOffer,
    this.contractSentAt,
    this.activationDate,
    this.expiryDate,
    this.estimatedSavings,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      caseNumber: json['caseNumber'] as String?,
      caseType: json['caseType'] as String?,
      billId: json['billId'] as String?,
      selectedOfferId: json['selectedOfferId'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String?,
      selectedOffer: json['selectedOffer'] != null
          ? CaseOfferModel.fromJson(json['selectedOffer'] as Map<String, dynamic>)
          : null,
      contractSentAt: json['contractSentAt'] as String?,
      activationDate: json['activationDate'] as String?,
      expiryDate: json['expiryDate'] as String?,
      estimatedSavings: _parseDouble(json['estimatedSavings']),
    );
  }

  /// The switch is under way but the supplier has not confirmed it yet.
  bool get isAwaitingActivation => status == 'awaiting_activation';

  /// The supplier confirmed the switch — the utility is live.
  bool get isActivated => status == 'activated';

  /// The utility belongs to the customer: it is either being switched over or
  /// already live. Mirrors the backend's `LIVE_UTILITY_CASE_STATUSES`.
  bool get isLiveUtility => isAwaitingActivation || isActivated;

  String get statusLabel {
    switch (status) {
      case 'new':
        return 'case.status.new'.tr;
      case 'in_progress':
        return 'case.status.in_progress'.tr;
      case 'documents_pending':
        return 'case.status.documents_pending'.tr;
      case 'contract_sent':
        return 'case.status.contract_sent'.tr;
      case 'awaiting_activation':
        return 'case.status.awaiting_activation'.tr;
      case 'activated':
        return 'case.status.activated'.tr;
      case 'rejected':
        return 'case.status.rejected'.tr;
      case 'cancelled':
        return 'case.status.cancelled'.tr;
      default:
        return status;
    }
  }

  /// Yearly saving, formatted for display. Null when there is no usable figure.
  String? get estimatedSavingsDisplay {
    final value = estimatedSavings;
    if (value == null || value <= 0) return null;
    return formatMoney(value);
  }
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

class CaseOfferModel {
  final String id;
  final String? name;
  final String? energyType;
  final CaseSupplierModel? supplier;

  const CaseOfferModel({
    required this.id,
    this.name,
    this.energyType,
    this.supplier,
  });

  factory CaseOfferModel.fromJson(Map<String, dynamic> json) {
    return CaseOfferModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      energyType: json['energyType'] as String?,
      supplier: json['supplier'] != null
          ? CaseSupplierModel.fromJson(json['supplier'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CaseSupplierModel {
  final String id;
  final String? name;
  final String? logoUrl;
  final String? contractSigningInstructions;
  final String? contractSigningDocumentUrl;
  final String? contractSigningDocumentName;

  const CaseSupplierModel({
    required this.id,
    this.name,
    this.logoUrl,
    this.contractSigningInstructions,
    this.contractSigningDocumentUrl,
    this.contractSigningDocumentName,
  });

  factory CaseSupplierModel.fromJson(Map<String, dynamic> json) {
    return CaseSupplierModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      logoUrl: json['logoUrl'] as String?,
      contractSigningInstructions:
          json['contractSigningInstructions'] as String?,
      contractSigningDocumentUrl: json['contractSigningDocumentUrl'] as String?,
      contractSigningDocumentName:
          json['contractSigningDocumentName'] as String?,
    );
  }

  String? get signingInstructions =>
      contractSigningInstructions?.trim().isEmpty ?? true
      ? null
      : contractSigningInstructions!.trim();

  String? get signingDocumentUrl =>
      contractSigningDocumentUrl?.trim().isEmpty ?? true
      ? null
      : contractSigningDocumentUrl!.trim();

  String get signingDocumentDisplayName {
    final name = contractSigningDocumentName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final url = signingDocumentUrl;
    if (url == null) return '';
    return url.split('/').last;
  }

  bool get signingDocumentIsPdf =>
      signingDocumentUrl?.toLowerCase().endsWith('.pdf') ?? false;

  /// True when the admin configured any signing guideline for this supplier.
  bool get hasSigningGuideline =>
      signingInstructions != null || signingDocumentUrl != null;
}
