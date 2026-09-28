import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/utils/number_format.dart';
import 'package:vyzi/features/request/complete_request/complete_request_screen.dart';
import 'package:vyzi/features/request/document_viewer_screen.dart';
import 'package:vyzi/features/request/models/api_offer_model.dart';
import 'package:vyzi/features/request/price_calculation_dialog.dart';
import 'package:vyzi/features/request/price_type_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OfferDetailRow {
  final String label;
  final String value;

  /// Label of the explanatory link under the value, e.g. "What does this
  /// mean?". Null on rows that explain themselves — and on rows whose popup
  /// does not apply to this particular offer.
  final String? linkText;
  final Color linkColor;

  /// What that link opens. Held per row rather than dispatched by comparing
  /// the tapped label against a translated string: which popup an offer gets
  /// now depends on its market type, and matching on text cannot express that.
  final VoidCallback? onLinkTap;

  const OfferDetailRow({
    required this.label,
    required this.value,
    this.linkText,
    this.linkColor = AppColors.linkBlue,
    this.onLinkTap,
  });
}

class OfferDetailsScreen extends StatefulWidget {
  final String offerId;

  /// The bill this offer was proposed for. The switch request is opened
  /// against it, so it has to travel with the offer rather than be guessed
  /// from the customer's bill list further down the flow.
  final String billId;
  final double? estimatedSavings;

  const OfferDetailsScreen({
    super.key,
    required this.offerId,
    required this.billId,
    this.estimatedSavings,
  });

  @override
  State<OfferDetailsScreen> createState() => _OfferDetailsScreenState();
}

class _OfferDetailsScreenState extends State<OfferDetailsScreen> {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  String _error = '';
  ApiOfferModel? _offer;

  @override
  void initState() {
    super.initState();
    _fetchOfferDetails();
  }

  Future<void> _fetchOfferDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final url = ApiConstants.getOfferDetails
          .replaceAll('{{offerId}}', widget.offerId);
      final response = await _api.get(url);
      final body = response.data as Map<String, dynamic>;

      if (body['success'] == true) {
        _offer = ApiOfferModel.fromJson(body['data'] as Map<String, dynamic>);
      } else {
        _error = body['message']?.toString() ?? 'Failed to load offer';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<OfferDetailRow> _buildDetailRows(ApiOfferModel offer) {
    return [
      OfferDetailRow(
        label: 'offer.contract_term'.tr,
        value: offer.bindingDisplay,
      ),
      // Both explanations below are chosen from the offer's market type. An
      // indexed offer gets the index popup plus the formula popup; a fixed one
      // gets the fixed-price popup alone, and nowhere on this screen may it
      // read about the index, indexation or the spread.
      OfferDetailRow(
        label: 'offer.price_type'.tr,
        value: offer.marketTypeDisplay,
        linkText: 'offer.price_type_link'.tr,
        linkColor: AppColors.linkBlue,
        onLinkTap: () => showDialog(
          context: context,
          builder: (_) => PriceTypeSheet(offer: offer),
        ),
      ),
      OfferDetailRow(
        label: 'offer.energy_price'.tr,
        value: offer.energyPriceDisplay,
        // A fixed price is not worked out from anything: there is no formula
        // to open, and the index + spread popup would contradict the flat rate
        // printed on this very row.
        linkText: offer.isIndexedPrice ? 'offer.energy_price_link'.tr : null,
        linkColor: AppColors.linkGreen,
        onLinkTap: offer.isIndexedPrice
            ? () => showDialog(
                  context: context,
                  builder: (_) => PriceCalculationDialog(offer: offer),
                )
            : null,
      ),
      OfferDetailRow(
        label: 'offer.fixed_costs'.tr,
        value: offer.fixedMonthlyFeeDisplay,
      ),
      OfferDetailRow(
        label: 'offer.contract_duration'.tr,
        value: offer.contractDurationDisplay,
      ),
      OfferDetailRow(
        label: 'offer.payment_method'.tr,
        value: offer.paymentMethodDisplay,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textPrimary)),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _fetchOfferDetails,
                          child: Text('common.retry'.tr),
                        ),
                      ],
                    ),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final offer = _offer!;
    final detailRows = _buildDetailRows(offer);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        _supplierCard(offer),
        const SizedBox(height: 14),
        _savingsCard(offer),
        const SizedBox(height: 6),
        ...detailRows.map((row) => _detailRow(row)),
        const SizedBox(height: 10),
        _economicConditionsCard(offer),
        const SizedBox(height: 20),
        _bottomButton(),
        const SizedBox(height: 24),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 40,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(Icons.chevron_left, color: AppColors.textDark, size: 28),
        ),
      ),
      title: Text(
        'offer.details_title'.tr,
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _supplierCard(ApiOfferModel offer) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildLogo(offer.supplier?.logoUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer.supplier?.name ?? offer.name,
                    style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(offer.name,
                    style: const TextStyle(
                        color: AppColors.textMid,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(String? logoUrl) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      final url = logoUrl.startsWith('http')
          ? logoUrl
          : '${ApiConstants.baseUrl}$logoUrl';
      return Image.network(
        url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultLogo(),
      );
    }
    return _defaultLogo();
  }

  Widget _defaultLogo() {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0A4C), Color(0xFF3A1F8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.bolt, color: Colors.white, size: 24),
    );
  }

  Widget _savingsCard(ApiOfferModel offer) {
    final savings = widget.estimatedSavings ?? offer.estimatedSavings;
    if (savings == null || savings <= 0) return const SizedBox.shrink();
    final savingsDisplay = formatMoney(savings);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4B2FB9), Color(0xFF7B5FE9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            'offer.max_benefit'.tr,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            savingsDisplay,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'request.offer.annual_savings'.tr,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(OfferDetailRow row) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        row.label,
                        style: const TextStyle(
                          color: AppColors.textDarkest,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward,
                        size: 13, color: AppColors.textLight),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      row.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                    if (row.linkText != null) ...[
                      const SizedBox(height: 3),
                      GestureDetector(
                        onTap: row.onLinkTap,
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          row.linkText!,
                          style: TextStyle(
                            color: row.linkColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.divider, height: 1.2),
      ],
    );
  }

  void _viewDocument(String url) {
    NavHelper.push(DocumentViewerScreen(
      url: url,
      title: 'offer.economic_conditions'.tr,
    ));
  }

  Widget _economicConditionsCard(ApiOfferModel offer) {
    final hasDocument = offer.economicConditionsUrl != null &&
        offer.economicConditionsUrl!.isNotEmpty;

    return GestureDetector(
      onTap: hasDocument ? () => _viewDocument(offer.economicConditionsUrl!) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasDocument
                ? const Color(0xFFB396E1)
                : const Color(0xFFE0E0E0),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: hasDocument
                    ? const Color(0xFFF0EEFB)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasDocument
                    ? Icons.description_outlined
                    : Icons.info_outline_rounded,
                color: hasDocument ? AppColors.purple : const Color(0xFF9E9E9E),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'offer.economic_conditions'.tr,
                    style: TextStyle(
                      color: hasDocument
                          ? AppColors.textDark
                          : const Color(0xFF9E9E9E),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!hasDocument) ...[
                    const SizedBox(height: 4),
                    Text(
                      'offer.economic_conditions_unavailable'.tr,
                      style: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasDocument)
              const Icon(Icons.chevron_right,
                  color: AppColors.textLight, size: 22),
          ],
        ),
      ),
    );
  }


  Widget _bottomButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          NavHelper.push(CompleteRequestScreen(
            offer: _offer!,
            billId: widget.billId,
            estimatedSavings: widget.estimatedSavings,
          ));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(
          'offer.select_offer'.tr,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
