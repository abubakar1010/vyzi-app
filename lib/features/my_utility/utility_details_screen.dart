import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/utils/app_assets.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/utils/number_format.dart';
import 'package:vyzi/features/home/model/user_service_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vyzi/features/support/support_screen.dart';
import 'package:url_launcher/url_launcher.dart';


class UtilityDetailsScreen extends StatelessWidget {
  final UserServiceModel service;

  const UtilityDetailsScreen({super.key, required this.service});

  bool get _isGas => service.energyType == 'gas';

  /// The heading over the hero figure. An indexed supply has no material
  /// price to name — what the customer pays over the market index is a
  /// spread, and calling that the material price would read as the whole
  /// cost of their energy.
  String get _priceLabel => service.isIndexedPrice
      ? 'utility.spread_over_index'
          .trParams({'index': service.priceIndexLabel})
      : 'utility.material_price'.tr;

  /// The figure itself, or the app's missing-value dash when the offer
  /// carries none. The dash is still deliberately the answer for an offer
  /// with no price on file at all: it is the placeholder every other figure
  /// in the app uses, and inventing a zero would read as free energy.
  String get _priceValue => service.unitPriceValueDisplay ?? kMissingValue;

  String get _priceUnit => ' ${service.unitPriceUnitDisplay}';

  String get _energyTypeLabel {
    if (service.energyType == null) return '';
    if (_isGas) return 'Gas';
    return 'bills.type.electricity'.tr;
  }

  /// The supplier's support address, or null when they have none on file.
  String? get _supplierEmail {
    final email = service.supplierEmail?.trim();
    if (email == null || email.isEmpty) return null;
    return email;
  }

  /// The supplier blurb the admin wrote, or null when they wrote none or the
  /// service carries no supplier name. The section's heading names the
  /// supplier, so without a name there is no heading to write and the whole
  /// section is left out.
  String? get _supplierDescription {
    final name = service.supplierName?.trim();
    if (name == null || name.isEmpty) return null;
    return service.supplierDescriptionDisplay;
  }

  /// A mail draft to the supplier, with the customer's own contract reference
  /// already in the subject so they don't have to quote it themselves.
  Future<void> _openEmail() async {
    final email = _supplierEmail;
    if (email == null) return;

    final contract = service.contractNumber;
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: contract == null || contract.isEmpty
          ? null
          : 'subject=${Uri.encodeComponent(contract)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWebsite() async {
    final url = service.supplierWebsiteUrl;
    if (url == null) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
        'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          // Not Get.back(): this screen is pushed onto the tab's own navigator,
          // which GetX does not know about, so Get.back() looks at the root
          // navigator, finds nothing to pop and leaves the arrow dead.
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20.sp,
          ),
        ),
        title: Text(
          'utility.details_title'.tr,
          style: TextStyle(
            color: Colors.black,
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),

            /// TOP CARD
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22.r),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFB300FF),
                    Color(0xFF0AA9FF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    top: -10,
                    child: Icon(
                      _isGas ? Icons.local_fire_department : Icons.flash_on,
                      size: 90.sp,
                      color: Colors.white.withOpacity(0.10),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statusChip(),

                      SizedBox(height: 18.h),

                      Text(
                        service.supplierName ?? service.offerName ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),

                      SizedBox(height: 8.h),

                      Text(
                        _energyTypeLabel,
                        style: TextStyle(
                          color: const Color(0xFF1FC16B),
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      SizedBox(height: 26.h),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _priceLabel,
                                  style: TextStyle(
                                    color:
                                    Colors.white.withOpacity(0.85),
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                                SizedBox(height: 5.h),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: _priceValue,
                                        style: TextStyle(
                                          color:
                                          const Color(0xFF00FF84),
                                          fontSize: 32.sp,
                                          fontWeight:
                                          FontWeight.w900,
                                        ),
                                      ),
                                      TextSpan(
                                        text: _priceUnit,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  // While the switch is still running this is
                                  // the date the supplier gave us, not a fact —
                                  // say so rather than let it read as live.
                                  service.isAwaitingActivation
                                      ? 'utility.activation_planned'.tr
                                      : 'utility.activation'.tr,
                                  style: TextStyle(
                                    color:
                                    Colors.white.withOpacity(0.85),
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  _formatDate(service.activationDate),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25.sp,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 18.h),

            /// ACTIVE OFFER
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: const Color(0xFFEFE8F9),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: const Color(0xFFEFE8F9), width: 1.22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('utility.active_offer'.tr),
                  SizedBox(height: 16.h),
                  _infoRow('utility.offer_name'.tr, service.offerName ?? '-'),
                  SizedBox(height: 16.h),
                  _infoRow('utility.service_type'.tr, _energyTypeLabel),
                  if (service.fixedMonthlyFee != null) ...[
                    SizedBox(height: 16.h),
                    _infoRow('utility.fixed_fee'.tr, '${formatMoney(service.fixedMonthlyFee)}/mese'),
                  ],
                  if (service.monthlyEstimate != null) ...[
                    SizedBox(height: 16.h),
                    _infoRow('utility.monthly_estimate'.tr, formatMoney(service.monthlyEstimate)),
                  ],
                  if (service.contractDurationDisplay != null) ...[
                    SizedBox(height: 16.h),
                    _infoRow(
                      'utility.contract_duration'.tr,
                      service.contractDurationDisplay!,
                    ),
                  ],
                  if (service.expiryDate != null) ...[
                    SizedBox(height: 16.h),
                    _infoRow('utility.expiry'.tr, _formatDate(service.expiryDate)),
                  ],
                  if (service.isGreenEnergy) ...[
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Icon(Icons.eco, color: const Color(0xFF1FC16B), size: 18.sp),
                        SizedBox(width: 6.w),
                        Text(
                          'utility.green_energy'.tr,
                          style: TextStyle(
                            color: const Color(0xFF1FC16B),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 22.h),

            /// SUPPLY INFO
            Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(color: const Color(0xFF5A1ABE), width: 1.22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        AppAssets.location,
                        color: AppColors.primaryColor,
                        width: 20.sp,
                        height: 20.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'utility.supply_info'.tr,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFE8F9),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(color: const Color(0xFFD2D2D2), width: 1),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'utility.pod_code'.tr,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                service.podPdrNumber ?? '-',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (service.podPdrNumber != null) {
                              Clipboard.setData(
                                  ClipboardData(text: service.podPdrNumber!));
                              Get.showSnackbar(GetSnackBar(
                                message: 'utility.copied'.tr,
                                duration: const Duration(seconds: 2),
                              ));
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.circular(12.r),
                              border: Border.all(color: const Color(0xFFC4C5D5), width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.copy_outlined,
                                  size: 14.sp,
                                  color: Colors.black,
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  'utility.copy'.tr,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  ..._supplyFacts(),

                  if (service.annualConsumptionDisplay != null) ...[
                    SizedBox(height: 22.h),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'utility.annual_consumption'.tr,
                                style: TextStyle(
                                  color: const Color(0xFF8A8A9E),
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                service.annualConsumptionDisplay!,
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Image.asset(
                          AppAssets.chart,
                          color: AppColors.primaryColor,
                          width: 32.sp,
                          height: 32.sp,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 24.h),

            _sectionTitle('utility.contact_support'.tr),

            SizedBox(height: 14.h),

            // The supplier's own channels only show when they have one on
            // file; the in-app ticket always does, since it reaches us rather
            // than the supplier.
            if (_supplierEmail != null) ...[
              _supportTile(
                icon: AppAssets.sendEmail,
                title: 'utility.send_email'.tr,
                subtitle: _supplierEmail!,
                onTap: _openEmail,
              ),
              SizedBox(height: 12.h),
            ],

            _supportTile(
              icon: AppAssets.openTicket,
              title: 'utility.open_ticket'.tr,
              subtitle: 'utility.open_ticket_desc'.tr,
              onTap: () => NavHelper.push(const SupportFormScreen()),
            ),

            if (service.supplierWebsiteUrl != null) ...[
              SizedBox(height: 12.h),
              _supportTile(
                icon: AppAssets.website,
                title: 'utility.website'.tr,
                subtitle: service.supplierWebsiteDisplay!,
                isWebsite: true,
                onTap: _openWebsite,
              ),
            ],

            // The supplier blurb the admin wrote, when there is one. Sits
            // between the contact options and the FAQs, so the customer reads
            // who supplies them before the questions about it.
            if (_supplierDescription != null) ...[
              SizedBox(height: 26.h),

              _sectionTitle(
                'utility.about_supplier'.trParams({
                  'name': service.supplierName!.trim(),
                }),
              ),

              SizedBox(height: 14.h),

              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFFD2D2D2),
                    width: 1.22,
                  ),
                ),
                child: Text(
                  _supplierDescription!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],

            // The FAQs the admin wrote for this supplier, when there are any.
            // A supplier with none has no section at all rather than an
            // empty heading.
            if (service.supplierFaqs.isNotEmpty) ...[
              SizedBox(height: 26.h),

              _sectionTitle('utility.faq'.tr),

              SizedBox(height: 14.h),

              ...service.supplierFaqs.map(
                (item) => Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFD2D2D2), width: 1.22),
                  ),
                  child: ExpansionTile(
                    shape: const Border(),
                    tilePadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                    ),
                    title: Text(
                      item.question,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                        child: Text(
                          item.answer,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(height: 30.h),
          ],
        ),
      ),
      ),
    );
  }

  Widget _statusChip() {
    final bool activated = service.isActivated;
    final Color dotColor = activated
        ? const Color(0xFF00FF84)
        : const Color(0xFFFFB800);
    final String label = activated
        ? 'utility.active_offer_badge'.tr
        : 'utility.awaiting_activation_badge'.tr;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 5.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 7.h,
            width: 7.w,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }

  /// Label on the left, value flush right, both columns starting at the same
  /// baseline so a wrapped value stays lined up with its label.
  ///
  /// The two columns are flexed rather than spaced apart: a [Spacer] would eat
  /// half the free width and leave every value right-aligned inside a box whose
  /// edge moved with the length of its label.
  Widget _infoRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            title,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          flex: 5,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  /// The supply's identifying facts — where it is delivered, which meter serves
  /// it, and the reference the customer quotes us — two to a row.
  ///
  /// Only the ones the case actually carries are built. A bill the OCR could
  /// not read a meter number off leaves that column out entirely rather than
  /// printing a dash the customer would take for a real value.
  List<Widget> _supplyFacts() {
    final facts = <MapEntry<String, String>>[
      if ((service.supplyAddress ?? '').trim().isNotEmpty)
        MapEntry('utility.address'.tr, service.supplyAddress!.trim()),
      if ((service.meterNumber ?? '').trim().isNotEmpty)
        MapEntry('utility.meter_number'.tr, service.meterNumber!.trim()),
      if ((service.contractNumber ?? '').trim().isNotEmpty)
        MapEntry('utility.contract_number'.tr, service.contractNumber!.trim()),
    ];

    final rows = <Widget>[];
    for (var i = 0; i < facts.length; i += 2) {
      final left = facts[i];
      final right = i + 1 < facts.length ? facts[i + 1] : null;

      rows.add(SizedBox(height: 18.h));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _miniInfo(title: left.key, value: left.value),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: right == null
                  ? const SizedBox.shrink()
                  : _miniInfo(title: right.key, value: right.value),
            ),
          ],
        ),
      );
    }

    return rows;
  }

  Widget _miniInfo({
    required String title,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11.sp,
            color: const Color(0xFF8A8A9E),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _supportTile({
    required String icon,
    required String title,
    required String subtitle,
    bool isWebsite = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFD2D2D2), width: 1.22),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Image.asset(
              icon,
              height: 42.h,
              width: 42.w,
            ),
          ),

          SizedBox(width: 14.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Icon(
            isWebsite
                ? Icons.open_in_new
                : Icons.arrow_forward_ios,
            size: 16.sp,
            color: Colors.black,
          ),
        ],
      ),
      ),
    );
  }
}
