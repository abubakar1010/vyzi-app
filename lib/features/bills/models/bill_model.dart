import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/utils/number_format.dart';

class BillSupplierModel {
  final String id;
  final String name;
  final String? logoUrl;

  const BillSupplierModel({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  factory BillSupplierModel.fromJson(Map<String, dynamic> json) {
    return BillSupplierModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
    );
  }
}

class BillModel {
  final String id;
  final String fileUrl;
  final String billType;
  final String status;
  final String source;
  final String? podNumber;
  final String? pdrNumber;
  final String? billingPeriodStart;
  final String? billingPeriodEnd;
  final double? totalAmount;
  final double? consumptionKwh;
  final double? consumptionSmc;
  final double? costPerUnit;
  final double? fixedCharges;
  final double? taxes;
  /// The five fields below rendered as one line, as the server composed it.
  final String? supplyAddress;
  final String? supplyStreet;
  final String? supplyStreetNumber;
  final String? supplyCity;
  final String? supplyPostalCode;
  final String? supplyProvince;
  final String? codiceFiscale;
  final String? partitaIva;
  final String? contractNumber;
  final String? meterNumber;
  final String? customerName;
  final Map<String, dynamic>? rawAnalysisData;
  final String userId;
  final String? supplierId;
  final String? meterId;
  final String createdAt;
  final String updatedAt;
  final BillSupplierModel? supplier;

  const BillModel({
    required this.id,
    required this.fileUrl,
    required this.billType,
    required this.status,
    this.source = 'upload',
    this.podNumber,
    this.pdrNumber,
    this.billingPeriodStart,
    this.billingPeriodEnd,
    this.totalAmount,
    this.consumptionKwh,
    this.consumptionSmc,
    this.costPerUnit,
    this.fixedCharges,
    this.taxes,
    this.supplyAddress,
    this.supplyStreet,
    this.supplyStreetNumber,
    this.supplyCity,
    this.supplyPostalCode,
    this.supplyProvince,
    this.codiceFiscale,
    this.partitaIva,
    this.contractNumber,
    this.meterNumber,
    this.customerName,
    this.rawAnalysisData,
    required this.userId,
    this.supplierId,
    this.meterId,
    required this.createdAt,
    required this.updatedAt,
    this.supplier,
  });

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory BillModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String? ?? '';

    return BillModel(
      id: json['id'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      billType: json['billType'] as String? ?? '',
      status: rawStatus,
      source: json['source'] as String? ?? 'upload',
      podNumber: json['podNumber'] as String?,
      pdrNumber: json['pdrNumber'] as String?,
      billingPeriodStart: json['billingPeriodStart'] as String?,
      billingPeriodEnd: json['billingPeriodEnd'] as String?,
      totalAmount: _parseDouble(json['totalAmount']),
      consumptionKwh: _parseDouble(json['consumptionKwh']),
      consumptionSmc: _parseDouble(json['consumptionSmc']),
      costPerUnit: _parseDouble(json['costPerUnit']),
      fixedCharges: _parseDouble(json['fixedCharges']),
      taxes: _parseDouble(json['taxes']),
      supplyAddress: json['supplyAddress'] as String?,
      supplyStreet: json['supplyStreet'] as String?,
      supplyStreetNumber: json['supplyStreetNumber'] as String?,
      supplyCity: json['supplyCity'] as String?,
      supplyPostalCode: json['supplyPostalCode'] as String?,
      supplyProvince: json['supplyProvince'] as String?,
      codiceFiscale: json['codiceFiscale'] as String?,
      partitaIva: json['partitaIva'] as String?,
      contractNumber: json['contractNumber'] as String?,
      meterNumber: json['meterNumber'] as String?,
      customerName: json['customerName'] as String?,
      rawAnalysisData: json['rawAnalysisData'] as Map<String, dynamic>?,
      userId: json['userId'] as String? ?? '',
      supplierId: json['supplierId'] as String?,
      meterId: json['meterId'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      supplier: json['supplier'] != null
          ? BillSupplierModel.fromJson(
              json['supplier'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isEmailSource => source == 'email';

  /// The switch is done and the new supply is live. An activated request has
  /// nothing left for the customer to act on, so it stops behaving like a
  /// request: it opens on its service details rather than on the request
  /// detail or the signing screen.
  bool get isActivated => status == 'activated';

  // ── Display Getters ──

  String get billTypeDisplay {
    switch (billType) {
      case 'electricity':
        return 'bills.type.electricity'.tr;
      case 'gas':
        return 'bills.type.gas'.tr;
      default:
        return billType;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'pending_email':
        return 'bills.status.pending_email'.tr;
      case 'uploaded':
        return 'bills.status.uploaded'.tr;
      case 'analyzing':
        return 'bills.status.analyzing'.tr;
      case 'analyzed':
        return 'bills.status.analyzed'.tr;
      case 'error':
        return 'bills.status.error'.tr;
      case 'verification_required':
        return 'bills.status.verification_required'.tr;
      case 'verification_review':
        return 'bills.status.verification_review'.tr;
      case 'verified':
        return 'bills.status.verified'.tr;
      case 'offer_sent':
        return 'bills.status.offer_sent'.tr;
      case 'offer_accepted':
        return 'bills.status.offer_accepted'.tr;
      case 'contract_sent':
        return 'bills.status.contract_sent'.tr;
      case 'awaiting_activation':
        return 'bills.status.awaiting_activation'.tr;
      case 'activated':
        return 'bills.status.activated'.tr;
      case 'cancelled':
        return 'bills.status.cancelled'.tr;
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending_email':
        return const Color(0xFF6A1B9A);
      case 'uploaded':
        return const Color(0xFFDFB400);
      case 'analyzing':
        return const Color(0xFFDFB400);
      case 'analyzed':
        return const Color(0xFF1FC16B);
      case 'error':
        return const Color(0xFFE53935);
      case 'verification_required':
        return const Color(0xFFE65100);
      case 'verification_review':
        return const Color(0xFFF57F17);
      case 'verified':
        return const Color(0xFF1FC16B);
      case 'offer_sent':
        return const Color(0xFF0097A7);
      case 'offer_accepted':
        return const Color(0xFF7B1FA2);
      case 'contract_sent':
        return const Color(0xFFF57F17);
      case 'awaiting_activation':
        return const Color(0xFF0288D1);
      case 'activated':
        return const Color(0xFF1FC16B);
      case 'cancelled':
        return const Color(0xFF757575);
      default:
        return const Color(0xFFDFB400);
    }
  }

  Color get statusBgColor {
    switch (status) {
      case 'pending_email':
        return const Color(0xFFF3E5F5);
      case 'uploaded':
        return const Color(0xFFFFF3E0);
      case 'analyzing':
        return const Color(0xFFFFF3E0);
      case 'analyzed':
        return const Color(0xFFDCFCE7);
      case 'error':
        return const Color(0xFFFFEBEE);
      case 'verification_required':
        return const Color(0xFFFFF3E0);
      case 'verification_review':
        return const Color(0xFFFFF8E1);
      case 'verified':
        return const Color(0xFFDCFCE7);
      case 'offer_sent':
        return const Color(0xFFE0F7FA);
      case 'offer_accepted':
        return const Color(0xFFF3E5F5);
      case 'contract_sent':
        return const Color(0xFFFFF8E1);
      case 'awaiting_activation':
        return const Color(0xFFE1F5FE);
      case 'activated':
        return const Color(0xFFDCFCE7);
      case 'cancelled':
        return const Color(0xFFF5F5F5);
      default:
        return const Color(0xFFFFF3E0);
    }
  }

  IconData get billTypeIcon {
    return billType == 'gas' ? Icons.local_fire_department : Icons.bolt;
  }

  String get formattedDate {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return createdAt;
    }
  }

  String get totalAmountDisplay => formatMoney(totalAmount);

  String get consumptionDisplay {
    if (billType == 'gas' && consumptionSmc != null) {
      return formatQuantity(consumptionSmc, unit: 'Smc');
    }
    if (consumptionKwh != null) {
      return formatQuantity(consumptionKwh, unit: 'kWh');
    }
    return kMissingValue;
  }

  String get billingPeriodDisplay {
    if (billingPeriodStart == null && billingPeriodEnd == null) return '-';
    final start = _formatDateStr(billingPeriodStart);
    final end = _formatDateStr(billingPeriodEnd);
    if (start.isNotEmpty && end.isNotEmpty) return '$start - $end';
    if (start.isNotEmpty) return '${'bills.period.from'.tr} $start';
    return end;
  }

  String get costPerUnitDisplay =>
      formatUnitPrice(costPerUnit, unit: billType == 'gas' ? 'Smc' : 'kWh');

  String get fixedChargesDisplay => formatMoney(fixedCharges);

  String get taxesDisplay => formatMoney(taxes);

  String get supplierName => knownSupplierName ?? 'bills.supplier.unknown'.tr;

  /// The supplier read off the bill, or null when neither the match nor the
  /// OCR produced one — for screens that hide the field rather than show
  /// "unknown".
  String? get knownSupplierName {
    for (final name in [
      supplier?.name,
      rawAnalysisData?['ocrSupplierName'] as String?,
    ]) {
      if (name != null && name.trim().isNotEmpty) return name.trim();
    }
    return null;
  }

  String _formatDateStr(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
