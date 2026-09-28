import 'package:country_code_picker/country_code_picker.dart';
import 'package:vyzi/core/appbar/custom_appbar.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/utils/app_styles.dart';
import 'package:vyzi/core/utils/phone_utils.dart';
import 'package:vyzi/core/widgets/phone_filled.dart';
import 'package:vyzi/features/profile/controller/profile_controller.dart';
import 'package:vyzi/features/profile/widgets/business_role_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class PersonalDataScreen extends StatefulWidget {
  /// The profile tab's own controller, so opening this screen from there
  /// shares its loaded state. Left null by the sign-up paths that push this
  /// screen with no profile tab behind them, which get one of their own.
  final ProfileController? controller;

  const PersonalDataScreen({super.key, this.controller});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  late final ProfileController _c;

  /// Whether this screen created the controller and so has to dispose it.
  /// The profile tab disposes the one it passes in.
  late final bool _ownsController;

  /// Whether the job-role picker is expanded.
  bool _roleOpen = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _c = widget.controller ?? ProfileController();

    _c.addListener(_onControllerChanged);

    // Re-read the profile every time the page opens. A business account that
    // has just been created through a social sign-up has no company row yet,
    // and the section that collects one has to be on screen — filled in with
    // whatever the server holds — the moment the user arrives here.
    WidgetsBinding.instance.addPostFrameCallback((_) => _c.fetchProfile());
  }

  @override
  void dispose() {
    _c.removeListener(_onControllerChanged);
    if (_ownsController) _c.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: 'personal_data.title'.tr, showBackButton: true),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Subtitle ──
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
              child: Text(
                'personal_data.subtitle'.tr,
                style: AppStyles.body3.copyWith(height: 1.5, color: AppColors.textPrimary),
              ),
            ),

            // ── Avatar + name card ──
            _buildAvatarCard(),

            SizedBox(height: 20.h),

            // ── Form fields card ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _buildFormCard(),
            ),

            // ── Business data card ──
            if (_c.isBusiness) ...[
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _buildBusinessCard(),
              ),
            ],

            SizedBox(height: 16.h),

            // ── Privacy notice card ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _buildPrivacyCard(),
            ),

            SizedBox(height: 32.h),

            // ── Action buttons ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _buildActionButtons(),
            ),

            SizedBox(height: 30.h),
          ],
        ),
      ),
      ),
    );
  }

  // ── Avatar card ──
  Widget _buildAvatarCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 10.h),
      child: Column(
        children: [
          // Avatar with edit button
          GestureDetector(
            onTap: _c.isUploadingAvatar ? null : () => _c.pickAndUploadAvatar(context),
            child: Stack(
              children: [
                Container(
                  width: 90.w,
                  height: 90.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.divider, width: 2),
                    color: AppColors.primary50,
                  ),
                  child: ClipOval(
                    child: _c.isUploadingAvatar
                        ? Center(
                            child: SizedBox(
                              width: 28.w,
                              height: 28.w,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _c.avatarUrl.isNotEmpty
                            ? Image.network(
                                _c.avatarUrl,
                                fit: BoxFit.cover,
                                width: 90.w,
                                height: 90.w,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person_rounded,
                                  size: 48.sp,
                                  color: AppColors.textSecondary,
                                ),
                              )
                            : Icon(
                                Icons.person_rounded,
                                size: 48.sp,
                                color: AppColors.textSecondary,
                              ),
                  ),
                ),
                // Edit icon badge
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 26.w,
                    height: 26.w,
                    decoration: BoxDecoration(
                      color: AppColors.darkBlue,
                      shape: BoxShape.circle,
                      border:
                      Border.all(color: AppColors.background, width: 2),
                    ),
                    child: Icon(Icons.edit_rounded,
                        color: AppColors.background, size: 12.sp),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 14.h),

          Text(
            _c.name,
            style: AppStyles.h2.copyWith(fontSize: 17.sp),
          ),
          SizedBox(height: 3.h),
          Text(
            _c.memberSince,
            style: AppStyles.body4,
          ),
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: _c.isUploadingAvatar ? null : () => _c.pickAndUploadAvatar(context),
            child: Text(
              'personal_data.change_photo'.tr,
              style: AppStyles.body3.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form card ──
  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField(
            label: 'personal_data.first_name'.tr,
            controller: _c.firstNameController,
            hint: 'personal_data.first_name_hint'.tr,
          ),
          SizedBox(height: 16.h),
          _buildField(
            label: 'personal_data.last_name'.tr,
            controller: _c.lastNameController,
            hint: 'personal_data.last_name_hint'.tr,
          ),
          SizedBox(height: 16.h),
          // The address the account signs in with, on either kind of account.
          // A company's certified address is a different thing and lives in the
          // business card below: the mailbox that registered a company account
          // is very often somebody's personal one, and calling it the PEC made
          // the two impossible to tell apart.
          _buildField(
            label: 'personal_data.email'.tr,
            controller: _c.emailController,
            hint: 'personal_data.email_hint'.tr,
            keyboardType: TextInputType.emailAddress,
            readOnly: true,
          ),
          SizedBox(height: 16.h),
          PhoneTextField(
            labelText: 'personal_data.phone'.tr,
            controller: _c.phoneController,
            initialSelection: _c.phoneCountryCode,
            validator: validatePhone,
            externalLabel: true,
            fillColor: const Color(0xFFF3F3F5),
            borderRadius: 10.r,
            showBorder: true,
            labelStyle: AppStyles.label.copyWith(fontSize: 14.sp, color: AppColors.textPrimary),
            onCountryChanged: (CountryCode code) {
              _c.phoneDialCode = code.dialCode ?? '+39';
              _c.phoneCountryCode = code.code ?? 'IT';
            },
          ),
          // The Codice Fiscale of the person this account belongs to — the
          // customer themselves, or on a business account the owner who signs
          // for the company. Distinct from the Partita IVA on the business card
          // below: that identifies the company, this identifies the signatory,
          // and the supplier asks a business customer for both.
          SizedBox(height: 16.h),
          _buildField(
            label: (_c.isBusiness
                    ? 'personal_data.owner_tax_code'
                    : 'personal_data.tax_code')
                .tr,
            controller: _c.codiceFiscaleController,
            hint: (_c.isBusiness
                    ? 'personal_data.owner_tax_code_hint'
                    : 'personal_data.tax_code_hint')
                .tr,
            textCapitalization: TextCapitalization.characters,
            maxLength: 16,
          ),
        ],
      ),
    );
  }

  // ── Business data card ──
  //
  // A business account carries a company name, a Partita IVA and the role its
  // holder occupies there. The first two are given at registration and were
  // then only visible to an admin in the dashboard — this is where the account
  // holder sees and corrects them, and the only place the role is set.
  Widget _buildBusinessCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business_rounded,
                  size: 18.sp, color: AppColors.primaryColor),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'personal_data.business_section'.tr,
                  style: AppStyles.h4.copyWith(fontSize: 15.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'personal_data.business_section_desc'.tr,
            style: AppStyles.body4.copyWith(height: 1.4),
          ),
          SizedBox(height: 16.h),
          _buildField(
            label: 'personal_data.company_name'.tr,
            controller: _c.companyNameController,
            hint: 'personal_data.company_name_hint'.tr,
            textCapitalization: TextCapitalization.words,
            maxLength: 255,
          ),
          SizedBox(height: 16.h),
          _buildField(
            label: 'personal_data.vat'.tr,
            controller: _c.partitaIvaController,
            hint: 'personal_data.vat_hint'.tr,
            keyboardType: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
          ),
          SizedBox(height: 16.h),
          // Where the company is reached legally, and where its invoices go.
          // Its own address rather than the one at the top of this screen: a
          // company signs in with whatever mailbox registered it, and a
          // statutory invoice does not belong in somebody's personal inbox.
          // Optional — a company without a PEC yet still switches, and its
          // invoices fall back to the sign-in address until it has one.
          _buildField(
            label: 'personal_data.pec'.tr,
            controller: _c.pecEmailController,
            hint: 'personal_data.pec_hint'.tr,
            keyboardType: TextInputType.emailAddress,
            maxLength: 255,
          ),
          SizedBox(height: 16.h),
          _buildRolePicker(),
        ],
      ),
    );
  }

  // ── Job role picker ──
  //
  // A picker rather than a text field, over one shared list, so a role stored
  // by any path always maps back onto a row here.
  Widget _buildRolePicker() {
    final selected = _c.selectedJobRole;
    final selectedLabel = selected == null
        ? null
        : kBusinessRoleOptions
            .firstWhere(
              (r) => r.value == selected,
              orElse: () => kBusinessRoleOptions.last,
            )
            .labelKey
            .tr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'personal_data.job_role'.tr,
          style: AppStyles.label
              .copyWith(fontSize: 14.sp, color: AppColors.textPrimary),
        ),
        SizedBox(height: 6.h),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusScope.of(context).unfocus();
            setState(() => _roleOpen = !_roleOpen);
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F5),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: _roleOpen ? AppColors.primaryColor : AppColors.divider,
                width: _roleOpen ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedLabel ?? 'personal_data.job_role_hint'.tr,
                    style: selectedLabel != null
                        ? AppStyles.body2
                        : AppStyles.hintStyle,
                  ),
                ),
                AnimatedRotation(
                  turns: _roleOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22.sp,
                    color: _roleOpen
                        ? AppColors.primaryColor
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _roleOpen
              ? Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: _buildRoleMenu(),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }

  Widget _buildRoleMenu() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < kBusinessRoleOptions.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.divider),
            _buildRoleMenuItem(kBusinessRoleOptions[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleMenuItem(BusinessRoleOption option) {
    final isSelected = option.value == _c.selectedJobRole;
    return InkWell(
      onTap: () {
        setState(() {
          // Tapping the selected row clears it — the field is optional.
          _c.selectedJobRole = isSelected ? null : option.value;
          _roleOpen = false;
        });
      },
      child: Container(
        width: double.infinity,
        color: isSelected ? AppColors.primary100 : AppColors.background,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.labelKey.tr,
                style: AppStyles.body2.copyWith(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded,
                  size: 18.sp, color: AppColors.primaryColor),
          ],
        ),
      ),
    );
  }

  // ── Single field ──
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.label.copyWith(fontSize: 14.sp, color: AppColors.textPrimary),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          textCapitalization: textCapitalization,
          inputFormatters: [
            if (formatters != null) ...formatters,
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
          ],
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          style: AppStyles.body2.copyWith(
            color: readOnly ? AppColors.textSecondary : null,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppStyles.hintStyle,
            counterText: '',
            filled: true,
            fillColor: readOnly ? const Color(0xFFE8E8EA) : const Color(0xFFF3F3F5),
            contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w, vertical: 12.h),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(
                  color: AppColors.divider, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(
                  color: Color(0xFFF3F3F5), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Privacy card ──
  Widget _buildPrivacyCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary100,
        borderRadius: BorderRadius.circular(12.r),
      ),
      padding: EdgeInsets.all(14.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined,
              color: AppColors.primaryColor, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'personal_data.privacy_title'.tr,
                  style: AppStyles.h4.copyWith(fontSize: 13.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  'personal_data.privacy_desc'.tr,
                  style: AppStyles.body4.copyWith(color: AppColors.primaryColor, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Action buttons ──
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Save Changes — dark filled
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: _c.isSaving
                ? null
                : () async {
              final success = await _c.saveChanges();
              if (success && mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              foregroundColor: AppColors.background,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: _c.isSaving
                ? SizedBox(
              width: 20.w,
              height: 20.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.background,
              ),
            )
                : Text(
              'personal_data.save_changes'.tr,
              style: AppStyles.buttonText.copyWith(fontSize: 15.sp),
            ),
          ),
        ),

        SizedBox(height: 12.h),

        // Cancel and discard — text button
        SizedBox(
          width: double.infinity,
          height: 44.h,

          child: TextButton(
            onPressed: () {
              _c.cancelChanges();
              Navigator.pop(context);
            },
            child: Text(
              'personal_data.cancel_discard'.tr,
              style: AppStyles.body2.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
