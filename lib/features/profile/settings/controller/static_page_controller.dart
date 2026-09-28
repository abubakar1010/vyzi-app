import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/core/services/storage_service.dart';
import 'package:vyzi/features/profile/settings/models/static_page_model.dart';
import 'package:vyzi/core/localization/system_messages.dart';

class StaticPageController extends GetxController {
  final ApiService _api = ApiService();
  final String slug;

  StaticPageController({required this.slug});

  RxBool isLoading = false.obs;
  RxBool notFound = false.obs;
  RxString error = ''.obs;
  Rx<StaticPageModel?> page = Rx<StaticPageModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchPage();
  }

  Future<void> fetchPage() async {
    isLoading.value = true;
    error.value = '';
    notFound.value = false;

    try {
      final storage = Get.find<StorageService>();
      final lang = storage.getString(StorageKeys.selectedLanguage) ?? 'it';

      final response = await _api.get(
        ApiConstants.staticPage(slug),
        queryParameters: {'locale': lang},
      );
      final body = response.data as Map<String, dynamic>;

      if (body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        page.value = StaticPageModel.fromJson(data);
      } else {
        error.value =
            SystemMessages.resolve(body['message']);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        notFound.value = true;
      } else {
        error.value = 'static_page.error'.tr;
      }
    } catch (e) {
      error.value = 'static_page.error'.tr;
    } finally {
      isLoading.value = false;
    }
  }
}
