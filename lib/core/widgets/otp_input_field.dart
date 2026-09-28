import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_colors.dart';

/// A 6-box OTP input backed by a **single** [TextEditingController].
///
/// Using one real text field (rendered invisibly on top of the decorative
/// boxes) instead of one [TextField] per digit gives us, for free:
/// * programmatic clearing — `controller.clear()` actually empties the boxes
/// * backspace that walks back through the digits
/// * paste / copy of a full code (non-digits are stripped automatically)
/// * SMS + keychain autofill via [AutofillHints.oneTimeCode]
class OtpInputField extends StatefulWidget {
  const OtpInputField({
    super.key,
    required this.controller,
    this.focusNode,
    this.length = 6,
    this.boxHeight = 52,
    this.minBoxWidth = 36,
    this.maxBoxWidth = 48,
    this.spacing = 8,
    this.fontSize = 20,
    this.autoFocus = true,
    this.enabled = true,
    this.onChanged,
    this.onCompleted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final int length;
  final double boxHeight;
  final double minBoxWidth;
  final double maxBoxWidth;
  final double spacing;
  final double fontSize;
  final bool autoFocus;
  final bool enabled;

  /// Called on every edit with the full code typed so far.
  final ValueChanged<String>? onChanged;

  /// Called once the code reaches [length] (typing, pasting or autofill).
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  FocusNode? _internalFocusNode;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleExternalChange);
    _focusNode.addListener(_handleExternalChange);

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.enabled) _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant OtpInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleExternalChange);
      widget.controller.addListener(_handleExternalChange);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleExternalChange);
      widget.focusNode?.addListener(_handleExternalChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleExternalChange);
    _focusNode.removeListener(_handleExternalChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  /// Repaint the boxes whenever the text or the focus changes — including
  /// changes made from outside (e.g. `clearOtp()` after a resend).
  void _handleExternalChange() {
    if (mounted) setState(() {});
  }

  void _caretToEnd() {
    final length = widget.controller.text.length;
    if (widget.controller.selection.baseOffset != length ||
        widget.controller.selection.extentOffset != length) {
      widget.controller.selection = TextSelection.collapsed(offset: length);
    }
  }

  void _handleChanged(String value) {
    widget.onChanged?.call(value);
    if (value.length >= widget.length) {
      _focusNode.unfocus();
      widget.onCompleted?.call(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSpacing = widget.spacing * (widget.length - 1);
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final available =
            (maxWidth - totalSpacing).clamp(0.0, double.infinity);
        final boxWidth = (available / widget.length)
            .clamp(widget.minBoxWidth, widget.maxBoxWidth);
        final rowWidth = boxWidth * widget.length + totalSpacing;

        return SizedBox(
          width: rowWidth,
          height: widget.boxHeight,
          child: Stack(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == widget.length - 1 ? 0 : widget.spacing,
                    ),
                    child: _buildBox(index, boxWidth),
                  );
                }),
              ),

              /// The real (invisible) field sits on top so a tap anywhere on
              /// the row opens the keyboard and a long-press offers "Paste".
              Positioned.fill(child: _buildHiddenField()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBox(int index, double width) {
    final code = widget.controller.text;
    final digit = index < code.length ? code[index] : '';
    final isFilled = digit.isNotEmpty;
    final isActive = _focusNode.hasFocus &&
        (index == code.length ||
            (code.length >= widget.length && index == widget.length - 1));

    final Color borderColor = isActive || isFilled
        ? AppColors.primaryColor
        : AppColors.divider;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      width: width,
      height: widget.boxHeight,
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.18),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 120),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Text(
          digit,
          key: ValueKey('otp-$index-$digit'),
          style: TextStyle(
            fontSize: widget.fontSize,
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildHiddenField() {
    return TextSelectionTheme(
      data: const TextSelectionThemeData(
        cursorColor: Colors.transparent,
        selectionColor: Colors.transparent,
        selectionHandleColor: Colors.transparent,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        autofocus: false,
        expands: true,
        maxLines: null,
        minLines: null,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.oneTimeCode],
        enableInteractiveSelection: true,
        enableSuggestions: false,
        showCursor: false,
        cursorColor: Colors.transparent,
        textAlign: TextAlign.center,
        // Invisible: the digits are painted by the boxes underneath.
        style: const TextStyle(color: Colors.transparent, fontSize: 1),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(widget.length),
        ],
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          filled: false,
        ),
        onTap: _caretToEnd,
        onChanged: _handleChanged,
        onSubmitted: (value) {
          if (value.length >= widget.length) widget.onCompleted?.call(value);
        },
        onTapOutside: (_) => _focusNode.unfocus(),
      ),
    );
  }
}
