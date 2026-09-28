import 'package:flutter/material.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/features/bills/models/bill_model.dart';
import 'package:vyzi/features/request/models/api_offer_model.dart';

class RequestController extends ChangeNotifier {
  final ApiService _api = ApiService();

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  int _selectedTab = 0;

  // Offers state
  bool isLoadingOffers = false;
  String offersError = '';
  List<ApiOfferModel> offers = [];
  int totalOffers = 0;

  /// Payment-method filter for the "Your Offers" tab: 'all', 'direct_debit' or
  /// 'postal_order'. Applied client-side — /offers/my-offers returns the whole
  /// list unpaginated, so there is nothing to round-trip for.
  String paymentFilter = paymentFilterAll;

  static const String paymentFilterAll = 'all';

  /// When set, the list is narrowed to the offers sent for this one request.
  ///
  /// This is how the "new offers recommended for you" notification lands: it
  /// names a bill, and the customer opening it expects the offers they were
  /// just told about — not every offer they have ever been sent across every
  /// supply. It is a deep-link scope, not a saved preference, so the Request
  /// tab drops it as soon as the customer navigates away.
  String? focusBillId;

  /// Whether the list is currently narrowed to one request.
  bool get isBillFocused => focusBillId != null;

  /// The request the list is scoped to, once its bill has been loaded. Null
  /// while the bills are still in flight — the banner names the supply when it
  /// can and stays generic when it cannot, rather than making the offers wait
  /// on a label.
  BillModel? get focusedBill {
    final id = focusBillId;
    if (id == null) return null;
    for (final bill in bills) {
      if (bill.id == id) return bill;
    }
    return null;
  }

  /// The offers sent for this request, before the payment-method chips narrow
  /// them further. Every sent offer carries the bill it was proposed for, so
  /// no extra round trip is needed to scope the list.
  List<ApiOfferModel> get scopedOffers {
    final id = focusBillId;
    if (id == null) return offers;
    return offers.where((o) => o.billId == id).toList();
  }

  /// Offers matching the active filter. An offer accepting both methods shows
  /// under either single-method chip, so it is never hidden from the user.
  List<ApiOfferModel> get filteredOffers {
    final scoped = scopedOffers;
    if (paymentFilter == paymentFilterAll) return scoped;
    if (paymentFilter == OfferPaymentMethod.directDebit) {
      return scoped.where((o) => o.supportsDirectDebit).toList();
    }
    return scoped.where((o) => o.supportsPostalOrder).toList();
  }

  void selectPaymentFilter(String filter) {
    if (paymentFilter == filter) return;
    paymentFilter = filter;
    notifyListeners();
  }

  /// Narrow the list to one request, as a notification asks for.
  ///
  /// The payment filter is reset with it: a chip left over from an earlier
  /// visit could empty the very list the customer was just sent here to see.
  void focusBill(String billId) {
    if (billId.isEmpty) return;
    focusBillId = billId;
    paymentFilter = paymentFilterAll;
    notifyListeners();
    // The banner names the supply the offers are for, which only the bill
    // knows. Fetched in the background — the offers are already on screen and
    // must not wait on a label.
    if (bills.isEmpty && !isLoadingBills) fetchBills();
  }

  /// Widen the list back to every sent offer.
  void clearBillFocus() {
    if (focusBillId == null) return;
    focusBillId = null;
    notifyListeners();
  }

  // Bills (My Requests) state
  bool isLoadingBills = false;
  String billsError = '';
  List<BillModel> bills = [];
  int totalBills = 0;

  int get selectedTab => _selectedTab;

  bool get isYourOffersTab => _selectedTab == 0;
  bool get isMyRequestsTab => _selectedTab == 1;

  void selectTab(int index) {
    if (_selectedTab != index) {
      _selectedTab = index;
      if (index == 0 && !isLoadingOffers) {
        fetchOffers();
      } else if (index == 1 && !isLoadingBills) {
        fetchBills();
      }
      notifyListeners();
    }
  }

  /// Fetches the user's sent offers from GET /api/v1/offers/my-offers.
  /// These are offers that were sent to the user (auto or manually by admin)
  /// after bill analysis.
  ///
  /// Each record is one offer proposed for one bill, and it is kept that way:
  /// the bill travels with the offer all the way to the switch request, so the
  /// request is opened against the supply point the customer was actually
  /// looking at. Deduplication is therefore per bill *and* offer — the same
  /// offer proposed for two bills is two distinct choices, each with its own
  /// savings figure.
  Future<void> fetchOffers() async {
    isLoadingOffers = true;
    offersError = '';
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.getMyOffers);
      final body = response.data as Map<String, dynamic>;

      if (body['success'] == true) {
        final data = body['data'];
        final rawList = data is List<dynamic> ? data : <dynamic>[];

        final seen = <String>{};
        final allOffers = <ApiOfferModel>[];

        for (final item in rawList) {
          final map = item as Map<String, dynamic>;
          final billId = map['billId'] as String? ?? '';
          final offerData = map['offer'] as Map<String, dynamic>?;
          final snapshot = map['offerSnapshot'] as Map<String, dynamic>?;

          // Prefer live offer data, fall back to snapshot
          if (offerData != null) {
            final enriched = {
              ...offerData,
              'billId': billId,
              'estimatedSavings': map['estimatedSavings'],
            };
            final offer = ApiOfferModel.fromJson(enriched);
            if (offer.id.isNotEmpty && seen.add('$billId|${offer.id}')) {
              allOffers.add(offer);
            }
          } else if (snapshot != null) {
            final id = snapshot['id'] as String? ?? '';
            if (id.isNotEmpty && seen.add('$billId|$id')) {
              allOffers.add(ApiOfferModel(
                id: id,
                billId: billId,
                name: snapshot['name'] as String? ?? '',
                energyType: snapshot['energyType'] as String? ?? '',
                marketType: snapshot['marketType'] as String? ?? '',
                pricePerKwh: _parseDouble(snapshot['pricePerKwh']),
                pricePerSmc: _parseDouble(snapshot['pricePerSmc']),
                spread: _parseDouble(snapshot['spread']),
                target: snapshot['target'] as String? ?? 'both',
                fixedMonthlyFee: _parseDouble(snapshot['fixedMonthlyFee']) ?? 0,
                contractDurationDays:
                    snapshot['contractDurationDays'] as int? ?? 0,
                isGreenEnergy: snapshot['isGreenEnergy'] as bool? ?? false,
                paymentMethod: snapshot['paymentMethod'] as String? ??
                    OfferPaymentMethod.both,
                supplier: snapshot['supplierName'] != null
                    ? OfferSupplierModel(
                        id: snapshot['supplierId'] as String? ?? '',
                        name: snapshot['supplierName'] as String)
                    : null,
                estimatedSavings: _parseDouble(map['estimatedSavings']),
              ));
            }
          }
        }

        offers = allOffers;
        totalOffers = allOffers.length;
      } else {
        offersError = body['message']?.toString() ?? 'Failed to load offers';
      }
    } catch (e) {
      offersError = e.toString();
    } finally {
      isLoadingOffers = false;
      notifyListeners();
    }
  }

  /// Fetches user's bills from GET /api/v1/bills
  Future<void> fetchBills() async {
    isLoadingBills = true;
    billsError = '';
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.getMyBills);
      final body = response.data as Map<String, dynamic>;

      if (body['success'] == true) {
        final data = body['data'];

        List<dynamic> rawList;
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          rawList = data['data'] as List<dynamic>;
          final meta = data['meta'] as Map<String, dynamic>?;
          totalBills = meta?['total'] as int? ?? rawList.length;
        } else if (data is List<dynamic>) {
          rawList = data;
          totalBills = rawList.length;
        } else {
          rawList = [];
          totalBills = 0;
        }

        bills = rawList
            .map((e) => BillModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        billsError = body['message']?.toString() ?? 'Failed to load bills';
      }
    } catch (e) {
      billsError = e.toString();
    } finally {
      isLoadingBills = false;
      notifyListeners();
    }
  }
}
