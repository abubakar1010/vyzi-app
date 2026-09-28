import 'dart:io';

import 'package:dio/dio.dart' hide Response;
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import 'api_service.dart';

// ─── Result Model ───────────────────────────────────────

class BillOcrResult {
  final String? supplierName;
  final String? supplierConfidence;
  final String? podNumber;
  final String? pdrNumber;
  final double? totalAmount;
  final double? consumptionKwh;
  final double? consumptionSmc;
  final double? costPerUnit;
  final double? fixedCharges;
  final double? taxes;
  final String? billingPeriodStart; // YYYY-MM-DD
  final String? billingPeriodEnd; // YYYY-MM-DD
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
  final String overallConfidence; // "high" | "medium" | "low"
  final String? fileUrl; // Server-side file path from extraction (avoids re-upload)

  const BillOcrResult({
    this.supplierName,
    this.supplierConfidence,
    this.podNumber,
    this.pdrNumber,
    this.totalAmount,
    this.consumptionKwh,
    this.consumptionSmc,
    this.costPerUnit,
    this.fixedCharges,
    this.taxes,
    this.billingPeriodStart,
    this.billingPeriodEnd,
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
    this.overallConfidence = 'low',
    this.fileUrl,
  });

  bool get hasAnyData =>
      supplierName != null ||
      podNumber != null ||
      pdrNumber != null ||
      totalAmount != null ||
      consumptionKwh != null ||
      consumptionSmc != null ||
      costPerUnit != null ||
      fixedCharges != null ||
      taxes != null ||
      billingPeriodStart != null ||
      billingPeriodEnd != null;

  /// Returns list of missing required field labels for the given bill type.
  List<String> getMissingFields(String billType) {
    final missing = <String>[];
    final isElectricity = billType == 'electricity';

    if (isElectricity && podNumber == null) missing.add('POD');
    if (!isElectricity && pdrNumber == null) missing.add('PDR');
    if (totalAmount == null) missing.add('upload_bill.field_total');
    if (isElectricity && consumptionKwh == null) missing.add('upload_bill.field_consumption');
    if (!isElectricity && consumptionSmc == null) missing.add('upload_bill.field_consumption');
    if (fixedCharges == null) missing.add('upload_bill.field_fixed_charges');
    if (taxes == null) missing.add('upload_bill.field_taxes');
    if (billingPeriodStart == null || billingPeriodEnd == null) missing.add('upload_bill.field_period');
    // Street and city are what the switch needs; the rest of the address is
    // filled in on the request form. Mirrors the server's own check.
    if (supplyStreet == null || supplyCity == null) {
      missing.add('upload_bill.field_address');
    }
    if (codiceFiscale == null && partitaIva == null) missing.add('upload_bill.field_tax_code');

    return missing;
  }

  bool isComplete(String billType) => getMissingFields(billType).isEmpty;

  /// Parse from server extraction response
  factory BillOcrResult.fromJson(Map<String, dynamic> json) {
    final confidence = json['confidence'] as Map<String, dynamic>? ?? {};
    return BillOcrResult(
      supplierName: json['supplierName'] as String?,
      supplierConfidence: confidence['supplierName'] as String? ?? 'low',
      podNumber: json['podNumber'] as String?,
      pdrNumber: json['pdrNumber'] as String?,
      totalAmount: _toDouble(json['totalAmount']),
      consumptionKwh: _toDouble(json['consumptionKwh']),
      consumptionSmc: _toDouble(json['consumptionSmc']),
      costPerUnit: _toDouble(json['costPerUnit']),
      fixedCharges: _toDouble(json['fixedCharges']),
      taxes: _toDouble(json['taxes']),
      billingPeriodStart: json['billingPeriodStart'] as String?,
      billingPeriodEnd: json['billingPeriodEnd'] as String?,
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
      overallConfidence: json['overallConfidence'] as String? ?? 'low',
      fileUrl: json['fileUrl'] as String?,
    );
  }

  static double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }
}

// ─── Service ────────────────────────────────────────────

class BillOcrService {
  static const List<String> _supportedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];

  /// Check if file is a supported type for extraction
  static bool isSupported(String path) {
    final ext = path.split('.').last.toLowerCase();
    return _supportedExtensions.contains(ext);
  }

  /// Sends the bill file to the backend for extraction via OpenAI Vision API.
  /// Uses extended timeouts since OCR involves PDF-to-image conversion +
  /// AI Vision API call + potential second-pass extraction.
  Future<BillOcrResult> extractFromFile(String filePath, String billType) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('File not found: $filePath');
    }

    final multipartFile = await MultipartFile.fromFile(
      filePath,
      filename: filePath.split('/').last,
    );

    final response = await ApiService().uploadFile(
      ApiConstants.extractBill,
      file: multipartFile,
      data: {'billType': billType},
      options: Options(
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 60),
      ),
    );

    final responseData = response.data;
    final body = responseData is Map<String, dynamic> && responseData.containsKey('data')
        ? responseData['data'] as Map<String, dynamic>
        : responseData as Map<String, dynamic>;

    debugPrint('Server extraction complete: overallConfidence=${body['overallConfidence']}');
    return BillOcrResult.fromJson(body);
  }
}
