import 'package:vyzi/core/exceptions/app_exceptions.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/core/services/storage_service.dart';
import 'package:vyzi/features/support/models/faq_model.dart';
import 'package:vyzi/core/localization/system_messages.dart';

class FaqController extends GetxController {
  final ApiService _api = ApiService();

  RxBool isLoading = false.obs;
  RxString error = ''.obs;
  RxList<FaqModel> faqs = <FaqModel>[].obs;

  Future<void> fetchFaqs({String? category}) async {
    isLoading.value = true;
    error.value = '';

    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;

      final storage = Get.find<StorageService>();
      final lang =
          storage.getString(StorageKeys.selectedLanguage) ?? 'it';
      queryParams['locale'] = lang;

      // Only show FAQs meant for this account type (the API also returns the
      // ones targeted at `both`). Logged-out users get every audience.
      final role = storage.getString(StorageKeys.userRole);
      if (role == 'personal' || role == 'business') {
        queryParams['targetAudience'] = role;
      }

      final response = await _api.get(
        ApiConstants.faqs,
        queryParameters: queryParams,
      );
      final body = response.data as Map<String, dynamic>;

      if (body['success'] == true) {
        final data = body['data'] as List<dynamic>;
        faqs.assignAll(
          data
              .map((e) => FaqModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      } else {
        error.value = SystemMessages.resolve(body['message']);
      }
    } catch (e) {
      error.value = (e is AppException ? e.message : 'system.unexpected'.tr);
    } finally {
      isLoading.value = false;
    }
  }
}
