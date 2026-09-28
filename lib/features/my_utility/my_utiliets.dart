import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/features/home/controller/home_controller.dart';
import 'package:vyzi/features/home/model/user_service_model.dart';
import 'package:vyzi/features/utility/select_utility_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vyzi/features/my_utility/utility_details_screen.dart';

import '../../core/navbar/navbar_controller.dart';

class MyUtilitiesScreen extends StatefulWidget {
  const MyUtilitiesScreen({super.key});

  @override
  State<MyUtilitiesScreen> createState() => _MyUtilitiesScreenState();
}

class _MyUtilitiesScreenState extends State<MyUtilitiesScreen> {
  late final HomeController _controller;
  Worker? _tabWorker;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<HomeController>();

    // Re-fetch services whenever user switches to this tab via bottom nav.
    // IndexedStack keeps all tabs alive, so initState only runs once —
    // this listener ensures fresh data on every tab activation.
    final navCtrl = Get.find<NavbarController>();
    _tabWorker = ever<int>(navCtrl.selectedTabRx, (index) {
      if (index == 2) {
        _controller.fetchServices();
      }
    });
  }

  @override
  void dispose() {
    _tabWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            Expanded(
              child: Obx(() {
                if (_controller.isLoadingServices.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_controller.serviceList.isEmpty) {
                  return _emptyState();
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  children: [
                    ..._controller.serviceList
                        .map((s) => _ServiceTile(service: s)),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('my_utility.title'.tr,
              style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4)),
          SizedBox(height: 4),
          Text('my_utility.subtitle'.tr,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.electrical_services_outlined,
                  size: 40, color: AppColors.primaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              'my_utility.no_utilities'.tr,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'my_utility.empty_desc'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => NavHelper.push(SelectUtilityScreen()),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text('my_utility.upload_button'.tr,
                    style: TextStyle(
                        color: AppColors.background,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Service Tile ──
class _ServiceTile extends StatelessWidget {
  final UserServiceModel service;
  const _ServiceTile({required this.service});

  /// The energy type the way a customer reads it on a bill - "Gas",
  /// "Electricity" - never the raw `gas`/`electricity` the API stores.
  String get _energyTypeLabel {
    final type = service.energyType;
    if (type == null || type.isEmpty) return '';
    return type == 'gas' ? 'bills.type.gas'.tr : 'bills.type.electricity'.tr;
  }

  /// The activation date as an Italian date reads it - 26/03/2026. Empty when
  /// there is no date yet, so the card leaves the slot blank rather than
  /// showing a placeholder next to the "Active Since" label.
  String get _activeSinceDisplay {
    final raw = service.activationDate;
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      return '$d/$m/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => NavHelper.push(UtilityDetailsScreen(service: service)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF7B48CB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
                color: AppColors.textPrimary.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _logo(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.supplierName ?? service.offerName ?? '',
                          style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(_energyTypeLabel,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _meta('utility.active_since'.tr, _activeSinceDisplay,
                    align: CrossAxisAlignment.end),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _meta(
                      'utility.offer_type'.tr, service.offerName ?? ''),
                ),
                const SizedBox(width: 12),
                _meta('utility.pod_label'.tr, service.podPdrNumber ?? '',
                    align: CrossAxisAlignment.end),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The supplier's own logo, so a customer recognises who supplies the
  /// contract at a glance.
  ///
  /// Falls back to the branded energy mark when there is no logo to show -
  /// the supplier has none on file, or the one it has failed to load - so a
  /// logo-less supplier still looks deliberate.
  Widget _logo() {
    final url = service.supplierLogoUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 52,
        height: 52,
        child: url == null ? _energyMark() : _supplierLogo(url),
      ),
    );
  }

  Widget _supplierLogo(String url) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      // Supplier logos are drawn for a white ground and most are transparent,
      // so the logo gets one of its own rather than the card's. Built here and
      // not as a wrapper, because a wrapper would also dress the energy mark
      // that errorBuilder puts in the image's place.
      frameBuilder: (_, child, __, ___) => Container(
        color: AppColors.background,
        padding: const EdgeInsets.all(6),
        child: child,
      ),
      errorBuilder: (_, __, ___) => _energyMark(),
    );
  }

  Widget _energyMark() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        service.energyType == 'gas'
            ? Icons.local_fire_department
            : Icons.bolt,
        color: AppColors.background,
        size: 26,
      ),
    );
  }

  Widget _meta(String label, String value,
      {CrossAxisAlignment align = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label,
            textAlign: align == CrossAxisAlignment.end
                ? TextAlign.right
                : TextAlign.left,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            textAlign: align == CrossAxisAlignment.end
                ? TextAlign.right
                : TextAlign.left,
            style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}
