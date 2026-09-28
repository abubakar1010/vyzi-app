import 'dart:async';

import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/utils/app_styles.dart';
import 'package:vyzi/core/widgets/primary_button.dart';
import 'package:vyzi/features/request/models/api_offer_model.dart';
import 'package:vyzi/features/request/offer_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:vyzi/features/bills/models/bill_model.dart';
import 'package:vyzi/features/utility/select_utility_screen.dart';

import 'package:vyzi/features/bills/screen/bill_detail_screen.dart';
import 'package:vyzi/features/my_utility/service_details_screen.dart';
import '../../core/appbar/custom_appbar.dart';
import '../../core/navbar/navbar_controller.dart';
import 'request_controller.dart';
import 'request_offers_focus.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final RequestController _controller;
  late final TabController _tabController;
  Worker? _tabWorker;
  StreamSubscription<String>? _focusSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = RequestController();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _controller.selectTab(_tabController.index);
      }
    });

    _controller.addListener(() {
      if (mounted) setState(() {});
    });

    _controller.fetchOffers();

    // Re-fetch offers whenever user switches to this tab via bottom nav.
    // IndexedStack keeps all tabs alive, so initState only runs once —
    // this listener ensures fresh data on every tab activation.
    final navCtrl = Get.find<NavbarController>();
    _tabWorker = ever<int>(navCtrl.selectedTabRx, (index) {
      if (index == NavTabs.request) {
        _controller.fetchOffers();
      } else {
        // A bill scope belongs to the notification that opened this tab, not
        // to the tab. Leaving drops it, so coming back tomorrow shows every
        // offer rather than a filter the customer never set.
        _controller.clearBillFocus();
      }
    });

    // "New offers recommended for you" asks for one request's offers. The tap
    // may have happened just now, or — on a cold start out of a tapped push —
    // before this screen existed, in which case the intent was parked and is
    // read here at mount. Deferred a frame either way: applying it calls
    // setState, which initState is too early for.
    _focusSub = RequestOffersFocus.stream.listen((_) => _applyOffersFocus());
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyOffersFocus());
  }

  /// Take the "show me this request's offers" intent a notification tap left,
  /// and put the tab where it asks: Your Offers, narrowed to that request.
  void _applyOffersFocus() {
    if (!mounted) return;
    final billId = RequestOffersFocus.take();
    if (billId == null) return;

    // Selecting the bottom-nav tab here as well as in NotificationRouter is
    // what makes a cold start land: the intent is parked before the navbar
    // exists, so the switch that accompanied it had nothing to switch.
    NavHelper.switchTab(NavTabs.request);
    _tabController.animateTo(0);
    _controller.selectTab(0);
    _controller.focusBill(billId);
  }

  @override
  void dispose() {
    _focusSub?.cancel();
    _tabWorker?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final navCtrl = Get.find<NavbarController>();
      if (navCtrl.selectedIndex == NavTabs.request) {
        _controller.fetchOffers();
      }
    }
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'request.title'.tr,
        showBackButton: false,
      ),
      body: Column(
        children: [
          SizedBox(height: 10.h),
          _buildTabBar(),
          Expanded(
            child: _controller.isYourOffersTab
                ? _buildOffersTab()
                : _buildMyRequestsTab(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TAB BAR
  // ─────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _tabItem('request.tab.your_offers'.tr, 0),
          _tabItem('request.tab.my_requests'.tr, 1),
        ],
      ),
    );
  }

  Widget _tabItem(String title, int index) {
    final isSelected = _controller.selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          _controller.selectTab(index);
        },
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Text(
                  title,
                  style: isSelected ? AppStyles.h4 : AppStyles.body2.copyWith(color: Colors.black),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 2.h,
                color: isSelected
                    ? AppColors.primaryColor
                    : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  YOUR OFFERS TAB
  // ─────────────────────────────────────────────

  Widget _buildOffersTab() {
    if (_controller.isLoadingOffers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.offersError.isNotEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('request.offers.load_failed'.tr, style: AppStyles.h4),
              SizedBox(height: 8.h),
              TextButton(
                onPressed: () => _controller.fetchOffers(),
                child: Text('common.retry'.tr,
                    style: AppStyles.body2
                        .copyWith(color: AppColors.primaryColor)),
              ),
            ],
          ),
        ),
      );
    }

    // The scope banner sits above everything, including the empty states — a
    // list narrowed by a notification rather than by the customer has to say
    // so wherever it lands them.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_controller.isBillFocused) _buildFocusBanner(),
        Expanded(child: _buildOffersList()),
      ],
    );
  }

  Widget _buildOffersList() {
    // Nothing has ever been sent: the illustrated "upload a bill" state.
    if (_controller.offers.isEmpty) {
      return _buildEmptyState();
    }

    // Scoped to a request that carries no offers. Different news from the
    // state above, and from a payment chip that happens to match nothing.
    if (_controller.scopedOffers.isEmpty) {
      return _buildNoOffersForRequest();
    }

    // The filter row stays mounted even when it empties the list, so the user
    // can always get back to "All" without leaving the tab.
    final offers = _controller.filteredOffers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterSection(),
        _buildOffersHeader(offers.length),
        Expanded(
          child: offers.isEmpty
              ? _buildNoFilterMatches()
              : ListView.builder(
                  padding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  itemCount: offers.length,
                  itemBuilder: (context, index) =>
                      _buildOfferCard(offers[index]),
                ),
        ),
      ],
    );
  }

  // ── Notification scope banner ──
  // Names the request the list was narrowed to and offers one tap out of it.
  // A filter the customer did not set themselves has to explain itself.
  Widget _buildFocusBanner() {
    final bill = _controller.focusedBill;
    final label = bill == null
        ? 'request.offers.for_this_request'.tr
        : 'request.offers.for_request'.trParams({
            'supply': '${bill.supplierName} · ${bill.billTypeDisplay}',
          });

    return Container(
      width: double.infinity,
      color: const Color(0xFFF0EEFF),
      padding: EdgeInsets.fromLTRB(14.w, 6.h, 6.w, 6.h),
      child: Row(
        children: [
          Icon(Icons.local_offer_outlined,
              size: 18.w, color: AppColors.primaryColor),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              label,
              style: AppStyles.body4.copyWith(
                  color: AppColors.primaryColor, fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => _controller.clearBillFocus(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            ),
            child: Text(
              'request.offers.show_all'.tr,
              style: AppStyles.body4.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoOffersForRequest() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_offer_outlined,
                size: 48.sp, color: const Color(0xFFD1C4E9)),
            SizedBox(height: 14.h),
            Text(
              'request.offers.none_for_request'.tr,
              textAlign: TextAlign.center,
              style: AppStyles.body3.copyWith(color: Colors.grey[600]),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: () => _controller.clearBillFocus(),
              child: Text(
                'request.offers.show_all'.tr,
                style: AppStyles.body2.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Payment Method filter row ──
  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Line 1: Filter icon + label ──
          Row(
            children: [
              Image.asset(
                'assets/images/filter.webp',
                width: 20.w,
                height: 20.h,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 4.w),
              Text(
                'request.filter.payment_method'.tr,
                style: AppStyles.h4
                    .copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // ── Line 2: Filter chips ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _paymentFilters
                  .map(
                    (f) => Padding(
                      padding: EdgeInsets.only(right: 6.w),
                      child: _filterChip(f.$2, f.$1),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// (filter value, label) pairs — order matches the design.
  List<(String, String)> get _paymentFilters => [
        (RequestController.paymentFilterAll, 'request.filter.all'.tr),
        (OfferPaymentMethod.directDebit, 'request.filter.direct_debit'.tr),
        (OfferPaymentMethod.postalOrder, 'request.filter.postal_slip'.tr),
      ];

  Widget _filterChip(String label, String value) {
    final isSelected = _controller.paymentFilter == value;
    return GestureDetector(
      onTap: () => _controller.selectPaymentFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: const Color(0xFF5A1ABE),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: isSelected
              ? AppStyles.body4.copyWith(color: Colors.white, fontWeight: FontWeight.w800)
              : AppStyles.body4.copyWith(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildNoFilterMatches() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Text(
          'request.offers.none_for_payment_method'.tr,
          textAlign: TextAlign.center,
          style: AppStyles.body3.copyWith(color: Colors.grey[600]),
        ),
      ),
    );
  }

  // ── Offers count header ──
  Widget _buildOffersHeader(int count) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'request.offers.best_for_you'.tr,
            style: AppStyles.h4.copyWith(fontSize: 15.sp),
          ),
          Text(
            '$count ${'request.offers.found'.tr}',
            style: AppStyles.body4.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // ── Offer card ──
  Widget _buildOfferCard(ApiOfferModel offer) {
    final supplierName = offer.supplier?.name ?? offer.name;
    final subtitle = offer.supplier != null ? offer.name : (offer.description ?? '');

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF5A1ABE),
          width: 1.22,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top: logo + title + badge ──
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 10.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: _buildSupplierLogo(offer.supplier?.logoUrl),
                ),
                SizedBox(width: 12.w),
                // Title & subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplierName,
                        style: AppStyles.h4.copyWith(fontSize: 15.sp),
                      ),
                      SizedBox(height: 2.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: const Color(0xFF5A1ABE),
                            width: 1.22,
                          ),
                        ),
                        child: Text(
                          subtitle,
                          style: AppStyles.body4.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Energy price info row ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                  horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EEFF),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '${'request.offers.energy_price_label'.tr} : ${offer.energyPriceDisplay}',
                style: AppStyles.body4.copyWith(color: AppColors.primaryColor, fontWeight: FontWeight.w800),
              ),
            ),
          ),

          SizedBox(height: 10.h),

          // ── Payment method row ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: _buildInfoRow(
              icon: Icon(Icons.credit_card_outlined,
                  size: 20.w, color: const Color(0xFF5B7FD8)),
              iconColor: const Color(0xFF5B7FD8),
              text:
                  '${'request.offers.payment_method_label'.tr}: ${offer.paymentMethodDisplay}',
            ),
          ),

          SizedBox(height: 8.h),

          // ── Fixed supply cost row ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icon(Icons.euro_symbol,
                      size: 20.w, color: const Color(0xFF9B59B6)),
                  iconColor: const Color(0xFF9B59B6),
                  text:
                      '${'offer.fixed_costs'.tr}: ${offer.fixedMonthlyFeeDisplay}',
                ),
                SizedBox(height: 12.h),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey,
                ),
              ],
            ),
          ),

          SizedBox(height: 4.h),

          // ── Annual savings (headline) ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  offer.estimatedSavingsDisplay,
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    'request.offer.annual_savings'.tr,
                    style: AppStyles.body3.copyWith(
                        color: const Color(0xFF1A1A2E),
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 14.h),

          // ── CTA Button ──
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: PrimaryButton(
              title: 'request.go_to_details'.tr,
              height: 46.h,
              onPress: () async {
                await NavHelper.push(OfferDetailsScreen(
                  offerId: offer.id,
                  billId: offer.billId,
                  estimatedSavings: offer.estimatedSavings,
                ));
                // The customer may have accepted an offer while they were in
                // there, which retires every offer sent for that bill — reload
                // so the list does not keep showing choices already spent.
                if (mounted) _controller.fetchOffers();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierLogo(String? logoUrl) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      final url = logoUrl.startsWith('http')
          ? logoUrl
          : '${ApiConstants.baseUrl}$logoUrl';
      return Image.network(
        url,
        width: 52.w,
        height: 52.w,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultLogo(),
      );
    }
    return _defaultLogo();
  }

  Widget _defaultLogo() {
    return Container(
      width: 52.w,
      height: 52.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A4C), Color(0xFF3A1F8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.bolt, color: Colors.white, size: 26.sp),
    );
  }

  Widget _buildBillSupplierLogo(String? logoUrl, IconData fallbackIcon) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      final url = logoUrl.startsWith('http')
          ? logoUrl
          : '${ApiConstants.baseUrl}$logoUrl';
      return Image.network(
        url,
        width: 48.w,
        height: 48.w,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F0F8),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(fallbackIcon, size: 24.sp, color: AppColors.primaryColor),
        ),
      );
    }
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0F8),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(fallbackIcon, size: 24.sp, color: AppColors.primaryColor),
    );
  }

  Widget _buildInfoRow({
    required Widget icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      children: [
        icon,
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            style: AppStyles.body4.copyWith(color: Colors.black, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  EMPTY STATE
  // ─────────────────────────────────────────────

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 40.h),
            // Circular illustration with bill icon and magnifier
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 180.w,
                  height: 180.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF3F0F8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.receipt_long_rounded,
                      size: 80.sp,
                      color: const Color(0xFFD1C4E9),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10.h,
                  right: 20.w,
                  child: Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.search,
                      size: 20.sp,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 28.h),
            Text(
              'request.offers.empty_title'.tr,
              style: AppStyles.h4.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'request.offers.empty_desc'.tr,
              textAlign: TextAlign.center,
              style: AppStyles.body2.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),
            PrimaryButton(
              title: 'my_utility.upload_button'.tr,
              prefixWidget: Icon(
                Icons.upload_file_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
              onPress: () {
                NavHelper.push(const SelectUtilityScreen());
              },
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  MY REQUESTS TAB (Bills)
  // ─────────────────────────────────────────────

  Widget _buildMyRequestsTab() {
    if (_controller.isLoadingBills) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.billsError.isNotEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('request.bills.load_failed'.tr, style: AppStyles.h4),
              SizedBox(height: 8.h),
              TextButton(
                onPressed: () => _controller.fetchBills(),
                child: Text('common.retry'.tr,
                    style: AppStyles.body2
                        .copyWith(color: AppColors.primaryColor)),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller.bills.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      itemCount: _controller.bills.length,
      itemBuilder: (context, index) =>
          _buildBillCard(_controller.bills[index]),
    );
  }

  /// Where a request opens.
  ///
  /// An activated request goes straight to its service details: the switch is
  /// finished, so there is nothing left to follow on the request detail and
  /// nothing left to sign. Every other status keeps the normal request flow.
  Future<void> _openRequest(BillModel bill) async {
    await NavHelper.push(
      bill.isActivated
          ? ServiceDetailsScreen(billId: bill.id)
          : BillDetailScreen(billId: bill.id),
    );
    if (mounted) _controller.fetchBills();
  }

  Widget _buildBillCard(BillModel bill) {
    return GestureDetector(
      onTap: () => _openRequest(bill),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: const Color(0xFF5A1ABE),
            width: 1.22,
          ),
        ),
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: icon + title + status icon ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: _buildBillSupplierLogo(
                    bill.supplier?.logoUrl,
                    bill.billTypeIcon,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.supplierName,
                        style: AppStyles.h4.copyWith(fontSize: 15.sp),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        bill.billTypeDisplay,
                        style: AppStyles.body4
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (bill.totalAmount != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          '${'request.offers.amount_label'.tr}: ${bill.totalAmountDisplay}',
                          style: AppStyles.body4.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  bill.status == 'analyzed'
                      ? Icons.check_circle_outline
                      : bill.status == 'error'
                          ? Icons.error_outline
                          : Icons.hourglass_top_rounded,
                  size: 20.sp,
                  color: bill.statusColor,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: bill.statusBgColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    bill.statusDisplay,
                    style: AppStyles.body4.copyWith(
                        color: bill.statusColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 11.sp),
                  ),
                ),
                Text(
                  bill.formattedDate,
                  style: AppStyles.body4.copyWith(
                      color: const Color(0xFF9810FA),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
            if (bill.status == 'analyzed') ...[
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                height: 38.h,
                child: OutlinedButton(
                  onPressed: () => _openRequest(bill),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF5A1ABE)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    'request.offers.view_details'.tr,
                    style: AppStyles.body2.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF9810FA)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
