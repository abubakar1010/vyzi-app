import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/appbar/custom_appbar.dart';
import 'package:vyzi/core/layout/adaptive.dart';
import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/widgets/address_form_fields.dart';
import 'package:vyzi/features/activation_request/activation_request_controller.dart';
import 'package:vyzi/features/activation_request/activation_request_success_screen.dart';
import 'package:vyzi/features/activation_request/models/activation_request_model.dart';
import 'package:vyzi/features/utility/select_utility_screen.dart';

/// "Attiva una nuova utenza" — the Home card's callback request.
///
/// Two or three questions decide the request type, then one contact form —
/// the same for a new connection and a subentro, for luce and gas. No offers,
/// no documents and no POD/PDR: a consultant fills those in on the phone.
class ActivationRequestScreen extends StatefulWidget {
  const ActivationRequestScreen({super.key});

  @override
  State<ActivationRequestScreen> createState() =>
      _ActivationRequestScreenState();
}

class _ActivationRequestScreenState extends State<ActivationRequestScreen> {
  static const _tag = 'activation_request';

  static const _purple = AppColors.primaryColor;
  static const _selectedBg = Color(0xFFF3EEFD);
  static const _border = Color(0xFFE3E1EE);
  static const _textMuted = Color(0xFF6B6F80);
  static const _infoBg = Color(0xFFE6F7FB);
  static const _badgeBg = Color(0xFFE8F7F0);
  static const _badgeBorder = Color(0xFFB9E6D2);
  static const _badgeText = Color(0xFF0B7A55);
  static const _noteBg = Color(0xFFF5F6FA);

  late final ActivationRequestController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.put(ActivationRequestController(), tag: _tag);
  }

  @override
  void dispose() {
    Get.delete<ActivationRequestController>(tag: _tag);
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final sent = await _c.submit();
    if (!mounted) return;
    if (sent) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ActivationRequestSuccessScreen()),
      );
    } else if (_c.submitError.value.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_c.submitError.value),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'activation_request.title'.tr),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final answers = _c.answers.value;
          final type = answers.type;
          return SingleChildScrollView(
            padding: Adaptive.page(
              context,
              EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 28.h),
              maxWidth: Adaptive.formWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'activation_request.intro'.tr,
                  style: TextStyle(fontSize: 13.sp, color: _textMuted, height: 1.45),
                ),
                SizedBox(height: 22.h),
                _question('activation_request.q_service'.tr),
                _choiceRow(
                  first: 'activation_request.service_electricity'.tr,
                  second: 'activation_request.service_gas'.tr,
                  firstSelected: answers.service == ActivationService.electricity,
                  secondSelected: answers.service == ActivationService.gas,
                  onFirst: () => _c.selectService(ActivationService.electricity),
                  onSecond: () => _c.selectService(ActivationService.gas),
                ),
                if (answers.showsMeterQuestion) ...[
                  SizedBox(height: 18.h),
                  _question('activation_request.q_meter'.tr),
                  _choiceRow(
                    first: 'activation_request.yes'.tr,
                    second: 'activation_request.no'.tr,
                    firstSelected: answers.meterInstalled == true,
                    secondSelected: answers.meterInstalled == false,
                    onFirst: () => _c.setMeterInstalled(true),
                    onSecond: () => _c.setMeterInstalled(false),
                  ),
                ],
                if (answers.meterInstalled == false) ...[
                  SizedBox(height: 14.h),
                  _infoBanner(),
                ],
                if (answers.showsSupplyQuestion) ...[
                  SizedBox(height: 18.h),
                  _question('activation_request.q_supply'.tr),
                  _choiceRow(
                    first: 'activation_request.yes'.tr,
                    second: 'activation_request.no'.tr,
                    firstSelected: answers.supplyActive == true,
                    secondSelected: answers.supplyActive == false,
                    onFirst: () => _c.setSupplyActive(true),
                    onSecond: () => _c.setSupplyActive(false),
                  ),
                ],
                if (type == ActivationRequestType.transfer) ...[
                  SizedBox(height: 18.h),
                  _transferNotice(),
                ],
                if (answers.showsContactForm) ...[
                  SizedBox(height: 16.h),
                  _typeBadge(type!, answers.service!),
                  SizedBox(height: 20.h),
                  _contactForm(),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Questions ─────────────────────────────────────────────────────────────

  Widget _question(String text) => Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: Text(
          text,
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800),
        ),
      );

  Widget _choiceRow({
    required String first,
    required String second,
    required bool firstSelected,
    required bool secondSelected,
    required VoidCallback onFirst,
    required VoidCallback onSecond,
  }) {
    return Row(
      children: [
        Expanded(child: _choice(first, firstSelected, onFirst)),
        SizedBox(width: 12.w),
        Expanded(child: _choice(second, secondSelected, onSecond)),
      ],
    );
  }

  Widget _choice(String label, bool selected, VoidCallback onTap) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 46.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _selectedBg : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: selected ? _purple : _border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: selected ? _purple : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoBanner() => Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: _infoBg,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          'activation_request.no_meter_info'.tr,
          style: TextStyle(fontSize: 12.sp, height: 1.4),
        ),
      );

  Widget _typeBadge(ActivationRequestType type, ActivationService service) {
    final isTakeover = type == ActivationRequestType.takeover;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: _badgeBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _badgeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${isTakeover ? 'activation_request.badge_takeover'.tr : 'activation_request.badge_new_activation'.tr}'
            ' / ${service.label}',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w900,
              color: _badgeText,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            isTakeover
                ? 'activation_request.badge_takeover_desc'.tr
                : 'activation_request.badge_new_activation_desc'.tr,
            style: TextStyle(fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  /// A running supply is not an activation: changing its holder is a voltura.
  Widget _transferNotice() => Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: _noteBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'activation_request.transfer_title'.tr,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 6.h),
            Text(
              'activation_request.transfer_desc'.tr,
              style: TextStyle(fontSize: 12.sp, height: 1.4, color: _textMuted),
            ),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: OutlinedButton(
                key: const ValueKey('activation_request.go_to_transfer'),
                onPressed: () => NavHelper.push(const SelectUtilityScreen()),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _purple),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(
                  'activation_request.transfer_cta'.tr,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: _purple,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  // ── Contact form ──────────────────────────────────────────────────────────

  Widget _contactForm() {
    final errors = _c.errors.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'activation_request.contact_title'.tr,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 12.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _textField(
                label: 'activation_request.first_name'.tr,
                hint: 'activation_request.first_name_hint'.tr,
                controller: _c.firstName,
                error: errors.firstName,
                maxLength: 100,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _textField(
                label: 'activation_request.last_name'.tr,
                hint: 'activation_request.last_name_hint'.tr,
                controller: _c.lastName,
                error: errors.lastName,
                maxLength: 100,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        _textField(
          label: 'activation_request.phone'.tr,
          hint: 'activation_request.phone_hint'.tr,
          controller: _c.phone,
          error: errors.phone,
          keyboardType: TextInputType.phone,
          formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]'))],
          maxLength: 20,
        ),
        SizedBox(height: 20.h),
        Text(
          'activation_request.supply_address'.tr,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 10.h),
        AddressFormFields(
          group: _c.address,
          errors: errors.address,
          onChanged: _c.onFieldChanged,
          streetLabel: 'activation_request.street'.tr,
          cityLabel: 'activation_request.city'.tr,
        ),
        SizedBox(height: 16.h),
        _privacyCheckbox(errors.privacy),
        SizedBox(height: 18.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: _noteBg,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'activation_request.note_title'.tr,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 2.h),
              Text(
                'activation_request.note_desc'.tr,
                style: TextStyle(fontSize: 12.sp, color: _textMuted),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            key: const ValueKey('activation_request.submit'),
            onPressed: _c.isSubmitting.value ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              disabledBackgroundColor: _purple.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: _c.isSubmitting.value
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'activation_request.submit'.tr,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _privacyCheckbox(String? error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _c.togglePrivacy(!_c.privacyAccepted.value),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24.w,
                height: 24.w,
                child: Checkbox(
                  value: _c.privacyAccepted.value,
                  onChanged: (v) => _c.togglePrivacy(v ?? false),
                  activeColor: _purple,
                  side: BorderSide(
                    color: error != null ? AppColors.error : _purple,
                    width: 1.4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'activation_request.privacy'.tr,
                  style: TextStyle(fontSize: 12.sp, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: EdgeInsets.only(top: 4.h, left: 34.w),
            child: Text(
              error,
              style: TextStyle(fontSize: 11.sp, color: AppColors.error),
            ),
          ),
      ],
    );
  }

  Widget _textField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? error,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp)),
        SizedBox(height: 6.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.shortcardbg,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: error != null ? AppColors.error : AppColors.shortcardbg,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: [
              if (formatters != null) ...formatters,
              if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
            ],
            onChanged: (_) => _c.onFieldChanged(),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 13.sp, color: _textMuted),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              error,
              style: TextStyle(fontSize: 11.sp, color: AppColors.error),
            ),
          ),
      ],
    );
  }
}
