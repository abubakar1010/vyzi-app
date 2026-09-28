
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/utils/app_styles.dart';
import 'package:vyzi/core/utils/phone_utils.dart';

import '../utils/app_colors.dart';

class PhoneTextField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<CountryCode>? onCountryChanged;
  final String? initialSelection;
  final String? labelText;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final bool readOnly;

  /// Container fill color. Defaults to AppColors.fillColor (white, label-inside style).
  final Color? fillColor;

  /// Border radius. Defaults to 8.r.
  final double? borderRadius;

  /// Whether to show the container border. Defaults to true.
  final bool showBorder;

  /// When true, the label is rendered ABOVE the container (matching flat-field screens).
  /// When false, the label is rendered INSIDE the container (matching registration screen).
  final bool externalLabel;

  /// Text style for external label. Defaults to a sensible style if null.
  final TextStyle? labelStyle;

  /// Font size for the phone input text. Defaults to 14.sp.
  final double? fontSize;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Error text to show below the field (for external error handling).
  final String? errorText;

  const PhoneTextField({
    super.key,
    required this.controller,
    this.onCountryChanged,
    this.initialSelection = 'IT',
    this.labelText,
    this.hintText,
    this.validator,
    this.readOnly = false,
    this.fillColor,
    this.borderRadius,
    this.showBorder = true,
    this.externalLabel = false,
    this.labelStyle,
    this.fontSize,
    this.onChanged,
    this.errorText,
  });

  @override
  State<PhoneTextField> createState() => _PhoneTextFieldState();
}

class _PhoneTextFieldState extends State<PhoneTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  late String _currentCountryCode;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _currentCountryCode = widget.initialSelection ?? 'IT';
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? 8.r;
    final bgColor = widget.fillColor ?? AppColors.fillColor;
    final textSize = widget.fontSize ?? 14.sp;
    final effectiveError = widget.errorText ?? _validationError;
    final bool hasError = effectiveError != null;

    final container = Container(
      padding: EdgeInsets.symmetric(
        vertical: widget.externalLabel ? 0 : 4.h,
        horizontal: 8.w,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
        border: widget.showBorder
            ? Border.all(
                color: hasError
                    ? AppColors.error
                    : _isFocused
                        ? AppColors.primaryColor
                        : AppColors.neutral200,
                width: hasError ? 1.5 : 1.2,
              )
            : Border.all(
                color: hasError
                    ? AppColors.error
                    : bgColor,
                width: hasError ? 1.5 : 1,
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Internal label (registration-style)
          if (!widget.externalLabel && widget.labelText != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              child: Text(
                widget.labelText!,
                style: AppStyles.caption.copyWith(
                  color: hasError
                      ? AppColors.error
                      : _isFocused
                          ? AppColors.primaryColor
                          : AppColors.textSecondary,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Country Picker ─────────────────
              SizedBox(
                height: 40.h,
                child: CountryCodePicker(
                  onChanged: (code) {
                    final newIso = code.code ?? 'IT';
                    setState(() => _currentCountryCode = newIso);
                    // Truncate if text exceeds new country's max digits
                    final max = maxPhoneDigits(newIso);
                    final digits = widget.controller.text
                        .replaceAll(RegExp(r'[^\d]'), '');
                    if (digits.length > max) {
                      widget.controller.text = digits.substring(0, max);
                      widget.controller.selection =
                          TextSelection.fromPosition(
                        TextPosition(
                            offset: widget.controller.text.length),
                      );
                    }
                    widget.onCountryChanged?.call(code);
                  },
                  initialSelection: widget.initialSelection,
                  favorite: const ['+39', 'IT'],
                  searchDecoration: InputDecoration(
                    hintText: 'common.search'.tr,
                  ),
                  showCountryOnly: false,
                  showOnlyCountryWhenClosed: false,
                  alignLeft: false,
                  padding: EdgeInsets.zero,
                  textStyle: TextStyle(
                    fontSize: textSize,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: 4.w),

              // ── Phone Number Field ─────────────
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.phone,
                  readOnly: widget.readOnly,
                  textAlignVertical: TextAlignVertical.center,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  validator: widget.validator != null
                      ? (value) {
                          final error = widget.validator!(value);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && _validationError != error) {
                              setState(() => _validationError = error);
                            }
                          });
                          return error;
                        }
                      : null,
                  onChanged: (value) {
                    if (_validationError != null) {
                      setState(() => _validationError = null);
                    }
                    widget.onChanged?.call(value);
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                        maxPhoneDigits(_currentCountryCode)),
                  ],
                  cursorColor: AppColors.primaryColor,
                  style: TextStyle(
                    color: widget.readOnly
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontSize: textSize,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText:
                        widget.hintText ?? 'personal_data.phone_hint'.tr,
                    hintStyle: TextStyle(
                      color: AppColors.hintColor,
                      fontSize: textSize,
                    ),
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 8.w, vertical: 8.h),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // If external label mode, render label above the container
    if (widget.externalLabel && widget.labelText != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.labelText!,
            style: widget.labelStyle ??
                TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.22,
                ),
          ),
          SizedBox(height: 6.h),
          container,
          if (hasError)
            Padding(
              padding: EdgeInsets.only(top: 4.h, left: 4.w),
              child: Text(
                effectiveError,
                style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.error,
                    height: 1.22),
              ),
            ),
        ],
      );
    }

    // Internal label mode — also show error text below container
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        container,
        if (hasError)
          Padding(
            padding: EdgeInsets.only(top: 4.h, left: 14.w),
            child: Text(
              effectiveError,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 11.sp,
              ),
            ),
          ),
      ],
    );
  }
}
