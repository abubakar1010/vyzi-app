// HOME CONTROLLER

import 'package:get/get.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/core/services/storage_service.dart';
import 'package:vyzi/core/utils/number_format.dart';
import 'package:vyzi/features/home/model/dashboard_model.dart';
import 'package:vyzi/features/home/model/user_service_model.dart';

class HomeController extends GetxController {
  final ApiService _api = ApiService();

  RxBool isLoadingServices = false.obs;
  RxBool isLoadingDashboard = false.obs;
  RxString servicesError = ''.obs;
  RxString dashboardError = ''.obs;

  /// True only for a genuinely new user who has no bills.
  RxBool isFirstVisit = false.obs;

  /// summary data — updated from /api/v1/dashboard/user
  RxString savingAmount = formatMoney(0).obs;
  RxInt activeUtilities = 0.obs;

  /// Full dashboard model from API
  Rx<UserDashboardModel?> dashboard = Rx<UserDashboardModel?>(null);

  /// User's activated services from /api/v1/meters/my-services
  RxList<UserServiceModel> serviceList = <UserServiceModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _resolveFirstVisit();
    fetchDashboard();
    fetchServices();
  }

  /// If the local flag is set, skip immediately. Otherwise check the
  /// server for existing bills — if the user has uploaded any bill,
  /// they are not new.
  Future<void> _resolveFirstVisit() async {
    final storage = Get.find<StorageService>();
    final userId = storage.getString(StorageKeys.userId) ?? '';
    final key = '${StorageKeys.hasSeenHome}_$userId';

    if (storage.getBool(key) ?? false) {
      isFirstVisit.value = false;
      return;
    }

    try {
      final response = await _api.get(ApiConstants.getMyBills);
      final body = response.data as Map<String, dynamic>;
      final bills = body['data'] as List<dynamic>? ?? [];
      isFirstVisit.value = bills.isEmpty;
    } catch (_) {
      // On error default to regular layout
      isFirstVisit.value = false;
    }

    storage.setBool(key, true);
  }

  /// Fetches user dashboard data (potential savings + active requests)
  Future<void> fetchDashboard() async {
    isLoadingDashboard.value = true;
    dashboardError.value = '';

    try {
      final response = await _api.get(ApiConstants.userDashboard);
      final body = response.data as Map<String, dynamic>;

      if (body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        final model = UserDashboardModel.fromJson(data);
        dashboard.value = model;

        final savings = model.potentialSavings.totalSavings;
        savingAmount.value = formatMoney(savings);
        activeUtilities.value = model.activeContracts;
      } else {
        dashboardError.value =
            body['message']?.toString() ?? 'Failed to load dashboard';
      }
    } catch (e) {
      dashboardError.value = e.toString();
    } finally {
      isLoadingDashboard.value = false;
    }
  }

  /// Fetches user's activated services (utilities)
  Future<void> fetchServices() async {
    isLoadingServices.value = true;
    servicesError.value = '';

    try {
      final response = await _api.get(ApiConstants.myServices);
      final body = response.data as Map<String, dynamic>;

      if (body['success'] == true) {
        final rawList = body['data'] as List<dynamic>;
        final services = rawList
            .map((e) => UserServiceModel.fromJson(e as Map<String, dynamic>))
            .toList();
        serviceList.assignAll(services);
      } else {
        servicesError.value =
            body['message']?.toString() ?? 'Failed to load services';
      }
    } catch (e) {
      servicesError.value = e.toString();
    } finally {
      isLoadingServices.value = false;
    }
  }
}
