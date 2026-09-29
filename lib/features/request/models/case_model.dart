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

  /// The identity documents on the case, newest first, including any an admin
  /// rejected and the files uploaded to replace them.
  final List<CaseDocumentModel> documents;

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
    this.documents = const [],
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
      documents: (json['documents'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CaseDocumentModel.fromJson)
          .toList(),
    );
  }

  /// Documents an admin turned down that the customer has not replaced yet —
  /// each one is waiting on a new upload before the case can move on.
  List<CaseDocumentModel> get documentsAwaitingReplacement {
    final replaced = documents
        .map((d) => d.replacesDocumentId)
        .whereType<String>()
        .toSet();
    return documents
        .where((d) => d.isRejected && !replaced.contains(d.id))
        .toList();
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

/// A file attached to the case — for now, always part of the identity check.
class CaseDocumentModel {
  final String id;
  final String fileName;
  final String documentType;
  final bool verified;
  final String? rejectedAt;

  /// `expired`, `unreadable`, `incomplete`, `wrong_document` or `other`.
  final String? rejectionReason;

  /// The admin's own words, shown beside the reason.
  final String? rejectionNote;

  /// The rejected document this file was uploaded to replace.
  final String? replacesDocumentId;

  const CaseDocumentModel({
    required this.id,
    required this.fileName,
    required this.documentType,
    this.verified = false,
    this.rejectedAt,
    this.rejectionReason,
    this.rejectionNote,
    this.replacesDocumentId,
  });

  factory CaseDocumentModel.fromJson(Map<String, dynamic> json) {
    return CaseDocumentModel(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      documentType: json['documentType'] as String? ?? '',
      verified: json['verified'] as bool? ?? false,
      rejectedAt: json['rejectedAt'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      rejectionNote: json['rejectionNote'] as String?,
      replacesDocumentId: json['replacesDocumentId'] as String?,
    );
  }

  bool get isRejected => rejectedAt != null;

  /// Why it was turned down, in the customer's language.
  String get rejectionReasonLabel {
    switch (rejectionReason) {
      case 'expired':
      case 'unreadable':
      case 'incomplete':
      case 'wrong_document':
        return 'case.document.rejection.$rejectionReason'.tr;
      default:
        return 'case.document.rejection.other'.tr;
    }
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
