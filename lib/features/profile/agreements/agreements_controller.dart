import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/models/address_data.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/core/services/storage_service.dart';

class AgreementModel {
  final String id;
  final String name; // partnerName
  final String city; // derived from address
  final String discount; // discountHeadline (falls back to discountDescription)
  final String imageUrl; // partnerLogoUrl
  final String fullName; // title
  final String description;
  final String offerDate; // validFrom – validUntil
  final String
  discountCode; // discountCode (falls back to scanning the description)
  final String address; // address
  final List<String> howToUse; // howToUse (falls back to the generic steps)

  const AgreementModel({
    required this.id,
    required this.name,
    required this.city,
    required this.discount,
    required this.imageUrl,
    required this.fullName,
    required this.description,
    required this.offerDate,
    required this.discountCode,
    required this.address,
    required this.howToUse,
  });

  factory AgreementModel.fromJson(Map<String, dynamic> json) {
    final partnerName = json['partnerName'] as String? ?? '';
    final title = json['title'] as String? ?? '';
    final description = json['description'] as String? ?? '';
    final discountDesc = json['discountDescription'] as String? ?? '';
    final logoUrl = json['partnerLogoUrl'] as String? ?? '';
    final validFrom = json['validFrom'] as String? ?? '';
    final validUntil = json['validUntil'] as String?;
    final termsUrl = json['termsUrl'] as String? ?? '';
    final address = json['address'] as String? ?? '';
    final id = json['id'] as String? ?? '';

    // Build offerDate string
    final offerDate = validUntil != null
        ? '$validFrom – $validUntil'
        : 'agreements.valid_from'.trParams({'date': validFrom});

    // The admin sets the code explicitly. Rows created before the field existed
    // carry it only inside the free-text description, so fall back to scanning
    // for one there — that scan misses codes not ending in digits, which is
    // exactly why the dedicated field was added.
    final explicitCode = (json['discountCode'] as String? ?? '').trim();
    final discountCode = explicitCode.isNotEmpty
        ? explicitCode
        : RegExp(r'\b([A-Z]{2,}[0-9]+)\b').firstMatch(discountDesc)?.group(0) ??
              '';

    // Large figure on the discount card. Without an admin-set headline, fall
    // back to the first sentence of the description as before.
    final headline = (json['discountHeadline'] as String? ?? '').trim();
    final discountShort = headline.isNotEmpty
        ? headline
        : discountDesc.split('.').first.trim();

    // Admin-authored steps, else the generic ones from the translations.
    final rawSteps = json['howToUse'];
    final adminSteps = rawSteps is List
        ? rawSteps
              .map((e) => e?.toString().trim() ?? '')
              .where((e) => e.isNotEmpty)
              .toList()
        : <String>[];
    final howToUse = adminSteps.isNotEmpty
        ? adminSteps
        : <String>[
            if (discountCode.isNotEmpty) 'agreements.how_to_1'.tr,
            if (termsUrl.isNotEmpty) '${'agreements.how_to_2'.tr}$termsUrl',
            if (discountCode.isNotEmpty) 'agreements.how_to_3'.tr,
            'agreements.how_to_4'.tr,
          ];

    return AgreementModel(
      id: id,
      name: partnerName,
      city: _cityFromAddress(address),
      discount: discountShort,
      imageUrl: logoUrl,
      fullName: title,
      description: description,
      offerDate: offerDate,
      discountCode: discountCode,
      address: address,
      howToUse: howToUse,
    );
  }

  /// Town shown as the list-card subtitle, taken from the partner address:
  /// "Viale Bligny 39, 20136 Milano MI, Italia" -> "Milano".
  ///
  /// Agreement addresses are written to be searchable in Google Maps and so
  /// usually end with the country, which [AddressData.parse] does not expect —
  /// it parses bill lines, which carry none — so drop that first. Anything it
  /// cannot read yields an empty string and the card hides the subtitle rather
  /// than leaving a blank line.
  static String _cityFromAddress(String address) {
    if (address.trim().isEmpty) return '';

    final withoutCountry = address.replaceFirst(
      RegExp(r'[\s,]+(italia|italy)\s*$', caseSensitive: false),
      '',
    );

    return AddressData.parse(withoutCountry).city;
  }
}

class AgreementsController extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool isCopied = false;
  String? copiedCode;
  bool isLoading = false;
  String? errorMessage;

  List<AgreementModel> agreements = [];

  AgreementsController() {
    fetchAgreements();
  }

  Future<void> fetchAgreements() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final storage = Get.find<StorageService>();
      final token = storage.getString(StorageKeys.authToken) ?? '';

      final response = await _api.get(
        ApiConstants.getListMyAgreements,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final body = response.data as Map<String, dynamic>;

      if (body['success'] == true) {
        final rawList = body['data'] as List<dynamic>;
        agreements = rawList
            .map((e) => AgreementModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      errorMessage = 'agreements.error_loading'.tr;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<AgreementModel?> fetchAgreementDetails(String agreementId) async {
    try {
      final storage = Get.find<StorageService>();
      final token = storage.getString(StorageKeys.authToken) ?? '';

      final url = ApiConstants.getMyAgreementDetails.replaceAll(
        '{{agreementId}}',
        agreementId,
      );

      final response = await _api.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final body = response.data as Map<String, dynamic>;

      if (body['success'] == true) {
        return AgreementModel.fromJson(body['data'] as Map<String, dynamic>);
      }
    } catch (_) {
      // Return null on error
    }
    return null;
  }

  Future<void> copyCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    copiedCode = code;
    isCopied = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    isCopied = false;
    copiedCode = null;
    notifyListeners();
  }
}
