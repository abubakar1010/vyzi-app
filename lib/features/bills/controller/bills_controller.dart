import 'package:get/get.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/features/bills/models/bill_model.dart';

class BillsController extends GetxController {
  final ApiService _api = ApiService();

  // ── List state ──
  RxBool isLoadingBills = false.obs;
  RxString billsError = ''.obs;
  RxList<BillModel> bills = <BillModel>[].obs;
  RxInt totalBills = 0.obs;
  RxInt currentPage = 1.obs;
  RxInt totalPages = 1.obs;
  final int limit = 20;

  // ── Filters ──
  Rx<String?> filterBillType = Rx<String?>(null);
  Rx<String?> filterStatus = Rx<String?>(null);

  // ── Detail state ──
  RxBool isLoadingDetail = false.obs;
  RxString detailError = ''.obs;
  Rx<BillModel?> selectedBill = Rx<BillModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchBills();
  }

  /// Fetches paginated list of user's bills with optional filters
  Future<void> fetchBills({int page = 1}) async {
    isLoadingBills.value = true;
    billsError.value = '';

    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };
      if (filterBillType.value != null) {
        queryParams['billType'] = filterBillType.value;
      }
      if (filterStatus.value != null) {
        queryParams['status'] = filterStatus.value;
      }

      final response = await _api.get(
        ApiConstants.billsBase,
        queryParameters: queryParams,
      );
      final body = response.data as Map<String, dynamic>;

      if (body['success'] == true) {
        final data = body['data'];

        List<dynamic> rawList;
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          rawList = data['data'] as List<dynamic>;
          final meta = data['meta'] as Map<String, dynamic>?;
          totalBills.value = meta?['total'] as int? ?? rawList.length;
          currentPage.value = meta?['page'] as int? ?? page;
          totalPages.value = meta?['totalPages'] as int? ?? 1;
        } else if (data is List<dynamic>) {
          rawList = data;
          totalBills.value = rawList.length;
          currentPage.value = 1;
          totalPages.value = 1;
        } else {
          rawList = [];
          totalBills.value = 0;
        }

        bills.assignAll(
          rawList
              .map((e) => BillModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      } else {
        billsError.value =
            body['message']?.toString() ?? 'Impossibile caricare le bollette';
      }
    } catch (e) {
      billsError.value = e.toString();
    } finally {
      isLoadingBills.value = false;
    }
  }

  /// Fetches a single bill by ID with supplier relations
  Future<void> fetchBillDetails(String billId) async {
    isLoadingDetail.value = true;
    detailError.value = '';
    selectedBill.value = null;

    try {
      final url =
          ApiConstants.getMyBillDetails.replaceAll('{{billId}}', billId);
      final response = await _api.get(url);
      final body = response.data as Map<String, dynamic>;

      if (body['success'] == true) {
        selectedBill.value =
            BillModel.fromJson(body['data'] as Map<String, dynamic>);
      } else {
        detailError.value =
            body['message']?.toString() ?? 'Impossibile caricare la bolletta';
      }
    } catch (e) {
      detailError.value = e.toString();
    } finally {
      isLoadingDetail.value = false;
    }
  }

  /// Applies filters and reloads the bill list
  void applyFilter({String? billType, String? status}) {
    filterBillType.value = billType;
    filterStatus.value = status;
    fetchBills();
  }

  /// Clears all filters and reloads
  void clearFilters() {
    filterBillType.value = null;
    filterStatus.value = null;
    fetchBills();
  }

  void loadNextPage() {
    if (currentPage.value < totalPages.value) {
      fetchBills(page: currentPage.value + 1);
    }
  }

  void loadPreviousPage() {
    if (currentPage.value > 1) {
      fetchBills(page: currentPage.value - 1);
    }
  }
}
