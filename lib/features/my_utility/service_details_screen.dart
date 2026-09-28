import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/features/home/model/user_service_model.dart';
import 'package:vyzi/features/my_utility/utility_details_screen.dart';

/// [UtilityDetailsScreen] reached from a bill instead of from the utilities
/// list.
///
/// Once a request is activated it is no longer something the customer acts on —
/// it is a live supply, and everything about it belongs on the service details.
/// So an activated request opens straight here, skipping both the request
/// detail and the signing screen. The requests list only ever holds bills, so
/// the service that switch became is looked up on the way in, matched on the
/// bill it started from.
class ServiceDetailsScreen extends StatefulWidget {
  final String billId;

  const ServiceDetailsScreen({super.key, required this.billId});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _error;

  /// The details screen, built once the service resolves.
  Widget? _details;

  @override
  void initState() {
    super.initState();
    _fetchService();
  }

  Future<void> _fetchService() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _api.get(ApiConstants.myServices);
      final body = response.data as Map<String, dynamic>;

      if (body['success'] == true) {
        final service = _matchBill(body['data'] as List<dynamic>);
        // A live supply the list does not carry means the case behind the bill
        // was closed or reassigned since the request was drawn — retrying is
        // the only useful thing to offer.
        if (service == null) {
          _error = 'utility.error_load'.tr;
        } else {
          _details = UtilityDetailsScreen(service: service);
        }
      } else {
        _error = 'utility.error_load'.tr;
      }
    } catch (_) {
      _error = 'utility.error_load'.tr;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// The service this screen's bill became, or null when the list holds none.
  UserServiceModel? _matchBill(List<dynamic> data) {
    for (final entry in data) {
      final service = UserServiceModel.fromJson(entry as Map<String, dynamic>);
      if (service.billId == widget.billId) return service;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final details = _details;
    if (details != null) return details;

    // Same chrome as the details screen itself, so resolving the service does
    // not read as a different page opening.
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor))
            : _buildError(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error ?? 'utility.error_load'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: _fetchService,
              child: Text('utility.retry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
