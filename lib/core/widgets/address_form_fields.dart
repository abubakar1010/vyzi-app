import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../models/address_data.dart';
import '../utils/app_colors.dart';

/// The five text controllers behind one address block.
///
/// Kept together so supply, residential and shipping addresses cannot drift
/// apart: every block owns one of these and reads its value the same way.
class AddressFieldGroup {
  final TextEditingController street = TextEditingController();
  final TextEditingController streetNumber = TextEditingController();
  final TextEditingController city = TextEditingController();
  final TextEditingController postalCode = TextEditingController();

  /// Free text — whatever the user types is kept as typed.
  final TextEditingController province = TextEditingController();

  AddressData get value => AddressData(
        street: street.text.trim(),
        streetNumber: streetNumber.text.trim(),
        city: city.text.trim(),
        postalCode: postalCode.text.trim(),
        province: province.text.trim(),
      );

  set value(AddressData address) {
    street.text = address.street;
    streetNumber.text = address.streetNumber;
    city.text = address.city;
    postalCode.text = address.postalCode;
    province.text = address.province;
  }

  /// True when nothing has been typed yet — used to decide whether a bill
  /// pre-fill may overwrite the fields.
  bool get isUntouched => value.isEmpty;

  void dispose() {
    street.dispose();
    streetNumber.dispose();
    city.dispose();
    postalCode.dispose();
    province.dispose();
  }
}

/// Renders the five address fields — street, civic number, city, CAP and
/// province — in the one layout used by every address block in the app.
class AddressFormFields extends StatelessWidget {
  final AddressFieldGroup group;
  final AddressErrors errors;
  final bool readOnly;

  /// Fired on every edit so the parent can clear errors and re-evaluate.
  final VoidCallback? onChanged;

  const AddressFormFields({
    super.key,
    required this.group,
    this.errors = AddressErrors.none,
    this.readOnly = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                context,
                label: 'request.form.address'.tr,
                controller: group.street,
                hint: 'request.form.street_hint'.tr,
                error: errors.street,
                maxLength: 255,
              ),
            ),
            SizedBox(width: 10.w),
            SizedBox(
              width: 96.w,
              child: _field(
                context,
                label: 'request.form.street_number'.tr,
                controller: group.streetNumber,
                hint: 'request.form.street_number_hint'.tr,
                error: errors.streetNumber,
                maxLength: 10,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                context,
                label: 'request.form.city'.tr,
                controller: group.city,
                hint: 'request.form.city_hint'.tr,
                error: errors.city,
                maxLength: 100,
              ),
            ),
            SizedBox(width: 10.w),
            SizedBox(
              width: 96.w,
              child: _field(
                context,
                label: 'request.form.postal_code'.tr,
                controller: group.postalCode,
                hint: 'request.form.postal_code_hint'.tr,
                error: errors.postalCode,
                keyboardType: TextInputType.number,
                formatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        _field(
          context,
          label: 'request.form.province'.tr,
          controller: group.province,
          hint: 'request.form.province_hint'.tr,
          error: errors.province,
          maxLength: 100,
        ),
      ],
    );
  }

  // ── Fields ────────────────────────────────────────────────────────────────

  Widget _field(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
    String? error,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        SizedBox(height: 6.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.shortcardbg,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: error != null ? AppColors.error : AppColors.shortcardbg,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            inputFormatters: [
              if (formatters != null) ...formatters,
              if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
            ],
            onChanged: (_) => onChanged?.call(),
            // Tapping anything that is not a text field puts the keyboard away.
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: readOnly ? AppColors.textSecondary : AppColors.textDark,
              fontWeight: FontWeight.w500,
              height: 1.22,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
                height: 1.22,
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              border: InputBorder.none,
              isDense: true,
              counterText: '',
            ),
          ),
        ),
        _error(error),
      ],
    );
  }

  Widget _label(String text) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textPrimary,
              height: 1.22,
            ),
          ),
          TextSpan(
            text: ' *',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.error,
              height: 1.22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _error(String? message) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: 4.h, left: 4.w),
      child: Text(
        message,
        style: TextStyle(fontSize: 11.sp, color: AppColors.error, height: 1.22),
      ),
    );
  }
}
