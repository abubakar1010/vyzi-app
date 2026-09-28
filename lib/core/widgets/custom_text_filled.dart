
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vyzi/core/utils/app_styles.dart';

import '../utils/app_colors.dart';




// ─────────────────────────────────────────────
//  Custom Text Field
// ─────────────────────────────────────────────
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool isPassword;
  final bool? readOnly;
  final Color? fillColor;
  final int? maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? labelText;
  final String? hintText;
  final double? contentPaddingH;
  final double? contentPaddingV;
  final FormFieldValidator? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double? height;
  final TextCapitalization textCapitalization;
  final int? maxLength;

  /// Restricts what can be typed *or pasted*. `keyboardType` only picks the
  /// on-screen keyboard, so a numeric field without this still accepts letters
  /// from a paste or a hardware keyboard.
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.readOnly = false,
    this.fillColor,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.labelText,
    this.hintText,
    this.contentPaddingH,
    this.contentPaddingV,
    this.validator,
    this.onChanged,
    this.onTap,
    this.borderColor,
    this.height,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscure = true;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
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
    final bool hasError = _errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: widget.fillColor ?? AppColors.fillColor,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: hasError
                  ? AppColors.error
                  : _isFocused
                      ? AppColors.primaryColor
                      : (widget.borderColor ?? AppColors.neutral200),
              width: hasError ? 1.5 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.labelText != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
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
              TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType: widget.keyboardType,
                textCapitalization: widget.textCapitalization,
                maxLength: widget.maxLength,
                inputFormatters: widget.inputFormatters,
                obscureText: widget.isPassword ? _obscure : false,
                obscuringCharacter: '•',
                maxLines: widget.maxLines,
                readOnly: widget.readOnly ?? false,
                textAlignVertical: TextAlignVertical.center,
                onTap: widget.onTap,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                onChanged: (value) {
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                  widget.onChanged?.call(value);
                },
                validator: widget.validator != null
                    ? (value) {
                        final error = widget.validator!(value);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _errorText != error) {
                            setState(() => _errorText = error);
                          }
                        });
                        return error;
                      }
                    : null,
                cursorColor: AppColors.primaryColor,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.sp,
                  height: 1.2,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: widget.contentPaddingH ?? 14.w,
                    vertical: widget.contentPaddingV ?? 8.h,
                  ),
                  filled: false,
                  prefixIcon: widget.prefixIcon,
                  prefixIconConstraints: widget.prefixIcon != null
                      ? const BoxConstraints(minWidth: 0, minHeight: 0)
                      : null,
                  suffixIcon: widget.isPassword
                      ? GestureDetector(
                          onTap: () => setState(() => _obscure = !_obscure),
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: widget.contentPaddingH ?? 14.w),
                            child: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.primaryColor,
                              size: 20.sp,
                            ),
                          ),
                        )
                      : widget.suffixIcon,
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: AppColors.hintColor,
                    fontSize: 14.sp,
                  ),
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: EdgeInsets.only(top: 4.h, left: 14.w),
            child: Text(
              _errorText!,
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
