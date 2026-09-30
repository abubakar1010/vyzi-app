import 'package:country_code_picker/country_code_picker.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/utils/tax_id_validator.dart';
import 'package:vyzi/core/utils/phone_utils.dart';
import 'package:vyzi/core/widgets/custom_text_filled.dart';
import 'package:vyzi/core/widgets/phone_filled.dart';
import 'package:vyzi/core/widgets/primary_button.dart';
import 'package:vyzi/core/widgets/social_button.dart';
import 'package:vyzi/core/exceptions/app_exceptions.dart';
import 'package:vyzi/core/services/social_auth_service.dart';
import 'package:vyzi/core/services/deep_link_service.dart';
import 'package:vyzi/routes/app_routes.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:vyzi/features/auth/controller/auth_controller.dart';
import 'package:vyzi/features/profile/personal_data_screen.dart';
import 'package:vyzi/features/profile/settings/privacy_policy.dart';
import 'package:vyzi/features/profile/settings/terms_condition.dart';



// ─────────────────────────────────────────────
//  Register Screen
// ─────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();

  // Only sent when signing up as a business; the API requires both in that
  // case and rejects the whole registration without them.
  final _companyNameController = TextEditingController();
  final _partitaIvaController = TextEditingController();

  bool _agreeToTerms = false;
  late String selectedRole;
  String _selectedDialCode = '+39';

  /// One recognizer per document named in the consent line. They have to be
  /// fields rather than built inline: a TextSpan recognizer created during
  /// build is never disposed, and this widget rebuilds on every keystroke.
  final _termsRecognizer = TapGestureRecognizer();
  final _privacyRecognizer = TapGestureRecognizer();

  bool get _isBusinessSignUp => selectedRole == 'business';

  @override
  void initState() {
    super.initState();
    // Chosen on the onboarding screen, which is the only way onto this form and
    // the only place the account type is ever picked — it is fixed for the life
    // of the account, so this screen shows no control for it. The fallback is a
    // safety net for a route opened without arguments, not a supported path.
    selectedRole = Get.arguments?['role'] ?? 'personal';

    _termsRecognizer.onTap = () => _openDocument(const TermsCondition());
    _privacyRecognizer.onTap = () => _openDocument(const PrivacyPolicyScreen());
    final refCode = Get.arguments?['referralCode'] as String?;
    if (refCode != null && refCode.isNotEmpty) {
      _referralCodeController.text = refCode;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    _companyNameController.dispose();
    _partitaIvaController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  /// Opens a document over the form. Pushed rather than replaced so everything
  /// already typed survives being read.
  void _openDocument(Widget screen) {
    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(builder: (_) => screen));
  }

  /// The consent line, with every document named as a tappable link.
  ///
  /// The backend records consent to each of these at the version in force, so
  /// each one has to be named and readable here — accepting a document you
  /// were never shown is not consent. The same two documents bind a personal
  /// and a business sign-up alike.
  List<TextSpan> _consentSpans() {
    final linkStyle = TextStyle(
      color: AppColors.primaryColor,
      fontWeight: FontWeight.w600,
      fontSize: 12.sp,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primaryColor,
    );

    final documents = <TextSpan>[
      TextSpan(
        text: 'auth.signup.terms_link'.tr,
        style: linkStyle,
        recognizer: _termsRecognizer,
      ),
      TextSpan(
        text: 'auth.signup.privacy_link'.tr,
        style: linkStyle,
        recognizer: _privacyRecognizer,
      ),
    ];

    final spans = <TextSpan>[TextSpan(text: 'auth.signup.accept_prefix'.tr)];

    for (var i = 0; i < documents.length; i++) {
      if (i > 0) {
        spans.add(TextSpan(
          text: i == documents.length - 1
              ? 'auth.signup.list_conjunction'.tr
              : 'auth.signup.list_separator'.tr,
        ));
      }
      spans.add(documents[i]);
    }

    spans.add(const TextSpan(text: ' *'));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12.h),

                // ── Title ──────────────────────────
                Text(
                  'auth.signup.title'.tr,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 20.h),

                // ── First Name + Last Name (inline) ─
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        labelText: 'auth.signup.first_name_label'.tr,
                        controller: _firstNameController,
                        hintText: 'auth.signup.first_name_hint'.tr,
                        validator: (v) => v == null || v.isEmpty ? 'request.form.required'.tr : null,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: CustomTextField(
                        labelText: 'auth.signup.last_name_label'.tr,
                        controller: _lastNameController,
                        hintText: 'auth.signup.last_name_hint'.tr,
                        validator: (v) => v == null || v.isEmpty ? 'request.form.required'.tr : null,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // ── Email ──────────────────────────────────────────
                //
                // The address the account signs in with, whichever kind it is.
                // A company's PEC is a different address and is asked for
                // later, on the profile screen and in the switch request — it
                // is where the company is reached legally, not how it logs in,
                // and calling the sign-in mailbox a PEC left the two
                // impossible to tell apart.
                CustomTextField(
                  labelText: 'auth.signup.email_label'.tr,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  hintText: 'auth.signup.email_hint'.tr,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 14.w, right: 8.w),
                    child: Icon(
                      Icons.mail_outline,
                      color: AppColors.primaryColor,
                      size: 20.sp,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'auth.login.email_error'.tr;
                    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
                    if (!emailRegex.hasMatch(v)) return 'auth.login.email_error'.tr;
                    return null;
                  },
                ),

                SizedBox(height: 12.h),

                // ── Phone with flag (inline) ───────
                PhoneTextField(
                  labelText: 'auth.signup.phone_label'.tr,
                  controller: _phoneController,
                  validator: validatePhone,
                  onCountryChanged: (CountryCode code) {
                    _selectedDialCode = code.dialCode ?? '+39';
                  },
                ),

                // ── Company details (business sign-up only) ─
                if (_isBusinessSignUp) ...[
                  SizedBox(height: 12.h),
                  CustomTextField(
                    labelText: 'auth.signup.company_name_label'.tr,
                    controller: _companyNameController,
                    hintText: 'auth.signup.company_name_hint'.tr,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 255,
                    validator: (v) {
                      final value = (v as String?)?.trim() ?? '';
                      if (value.isEmpty) {
                        return 'auth.signup.company_name_error'.tr;
                      }
                      if (value.length < 2) {
                        return 'auth.signup.company_name_short'.tr;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12.h),
                  CustomTextField(
                    labelText: 'auth.signup.vat_label'.tr,
                    controller: _partitaIvaController,
                    hintText: 'auth.signup.vat_hint'.tr,
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final value = (v as String?)?.trim() ?? '';
                      if (value.isEmpty) return 'auth.signup.vat_required'.tr;
                      // The check digit too, not just eleven digits. The
                      // API is held to the same rule, so a number that only
                      // looks right is refused at signup rather than at the
                      // first direct debit.
                      if (!isValidPartitaIva(value)) {
                        return 'auth.signup.vat_invalid'.tr;
                      }
                      return null;
                    },
                  ),
                ],

                SizedBox(height: 12.h),

                // ── Password ───────────────────────
                CustomTextField(
                  labelText: 'auth.signup.password_label'.tr,
                  controller: _passwordController,
                  isPassword: true,
                  hintText: 'auth.signup.password_hint'.tr,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'auth.login.password_error'.tr;
                    if (v.length < 8) return 'auth.login.password_error'.tr;
                    if (!RegExp(r'[a-z]').hasMatch(v)) return 'auth.signup.password_lowercase'.tr;
                    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'auth.signup.password_uppercase'.tr;
                    if (!RegExp(r'\d').hasMatch(v)) return 'auth.signup.password_number'.tr;
                    if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"|,.<>/?\\]').hasMatch(v)) return 'auth.signup.password_special'.tr;
                    return null;
                  },
                ),

                SizedBox(height: 12.h),

                // ── Confirm Password ───────────────
                CustomTextField(
                  labelText: 'auth.signup.confirm_password_label'.tr,
                  controller: _confirmPasswordController,
                  isPassword: true,
                  hintText: 'auth.signup.confirm_password_hint'.tr,
                  validator: (v) =>
                      v != _passwordController.text ? 'auth.signup.password_mismatch'.tr : null,
                ),

                SizedBox(height: 16.h),

                // ── Terms Checkbox ─────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          setState(() => _agreeToTerms = !_agreeToTerms),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 20.w,
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: _agreeToTerms
                              ? AppColors.primaryColor
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(4.r),
                          border: Border.all(
                            color: AppColors.primaryColor,
                            width: 1.5,
                          ),
                        ),
                        child: _agreeToTerms
                            ? Icon(Icons.check,
                            size: 14.sp, color: AppColors.background)
                            : null,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          children: _consentSpans(),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                // ── Register Button ────────────────
                PrimaryButton(
                  title: 'auth.signup.button'.tr,
                  onPress: () async {
                    if (!_agreeToTerms) {
                      Get.snackbar(
                        'auth.validation.warning'.tr,
                        'auth.signup.terms_required'.tr,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }
                    if (_formKey.currentState!.validate()) {
                      final auth = Get.put(AuthController());
                      try {
                        final phoneTrimmed = _phoneController.text.trim();
                        await auth.register(
                          email: _emailController.text.trim(),
                          password: _passwordController.text,
                          confirmPassword: _confirmPasswordController.text,
                          firstName: _firstNameController.text.trim(),
                          lastName: _lastNameController.text.trim(),
                          phone: phoneTrimmed.isEmpty
                              ? null
                              : toE164(_selectedDialCode, phoneTrimmed),
                          role: selectedRole,
                          companyName: _isBusinessSignUp
                              ? _companyNameController.text.trim()
                              : null,
                          partitaIva: _isBusinessSignUp
                              ? _partitaIvaController.text.trim()
                              : null,
                          referralCode: _referralCodeController.text.trim().isEmpty
                              ? null
                              : _referralCodeController.text.trim(),
                          acceptedTerms: _agreeToTerms,
                        );

                        // Clear pending referral code from deep link storage
                        try {
                          final deepLinkService = Get.find<DeepLinkService>();
                          await deepLinkService.clearPendingReferralCode();
                        } catch (_) {}

                        // Navigate to OTP verification screen and pass email
                        Get.toNamed(AppRoutes.createAccountOtpScreen, arguments: {
                          'email': _emailController.text.trim(),
                          'type': 'email_verification'
                        });
                      } catch (e) {
                        // The sign-up form's own wording for the three
                        // refusals it knows best; otherwise the server's
                        // reason, translated, rather than a bare "failed".
                        String errorMessage = e is AppException
                            ? e.message
                            : 'auth.signup.registration_failed_default'.tr;
                        final rawError = e is AppException ? e.rawMessage : auth.error.value;
                        if (rawError.contains('Email already registered')) {
                          errorMessage = 'auth.signup.error.email_exists'.tr;
                        } else if (rawError.contains('Partita IVA is already registered')) {
                          errorMessage = 'auth.signup.error.vat_exists'.tr;
                        } else if (rawError.contains('Password must contain')) {
                          errorMessage = 'auth.signup.password_requirements_unmet'.tr;
                        }
                        Get.snackbar('auth.validation.error'.tr, errorMessage);
                      }
                    }
                  },
                ),

                SizedBox(height: 20.h),

                // ── Divider ────────────────────────
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.divider)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Text(
                        'auth.login.divider'.tr,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.divider)),
                  ],
                ),

                SizedBox(height: 16.h),

                // ── Facebook ───────────────────────
                SocialButton(
                  label: 'auth.login.facebook'.tr,
                  logo: _facebookLogo(),
                  onPress: () => _handleSocialLogin(SocialProvider.facebook),
                ),

                SizedBox(height: 10.h),

                // ── Apple ──────────────────────────
                SocialButton(
                  label: 'auth.login.apple'.tr,
                  logo: _appleLogo(),
                  onPress: () => _handleSocialLogin(SocialProvider.apple),
                ),

                SizedBox(height: 10.h),

                // ── Google ─────────────────────────
                SocialButton(
                  label: 'auth.login.google'.tr,
                  logo: _googleLogo(),
                  onPress: () => _handleSocialLogin(SocialProvider.google),
                ),

                SizedBox(height: 20.h),

                // ── Login Link ─────────────────────
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: 'auth.signup.have_account'.tr,
                        ),
                        TextSpan(
                          text: 'auth.signup.login'.tr,
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 13.sp,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Get.offNamed(AppRoutes.signInScreen);
                            },
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSocialLogin(SocialProvider provider) async {
    final auth = Get.put(AuthController());
    try {
      // The account type chosen on the onboarding screen applies to social
      // sign-up too: without it every "Continue with Google" produced a
      // personal account, whatever the user had picked there.
      await auth.socialLogin(provider, role: selectedRole);
      Get.offAllNamed(AppRoutes.navbarScreen);
      // A business account created this way has no company row yet — the
      // provider hands back a name, an email and a picture, and nothing a
      // company is identified by. Land on the form that collects the company
      // name and Partita IVA rather than on the home tab, where nothing would
      // ask until a switch request stalled on the missing VAT number. The
      // account is already a business; this only fills in its details.
      if (_isBusinessSignUp) {
        Get.to(() => const PersonalDataScreen());
      }
    } on SocialAuthCancelledException {
      // The user dismissed the provider sheet — nothing to report.
    } catch (_) {
      final rawError = auth.error.value;
      final errorMessage = rawError.contains('suspended')
          ? 'auth.login.error.suspended'.tr
          : rawError.isNotEmpty
              ? rawError
              : 'auth.login.error.social_failed'.tr;
      Get.snackbar('auth.validation.error'.tr, errorMessage);
    }
  }

  // ── Custom AppBar ──────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(56.h),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    size: 20.sp, color: AppColors.textPrimary),
                onPressed: () => Get.back(),
              ),
              IconButton(
                icon: Icon(Icons.close,
                    size: 22.sp, color: AppColors.textPrimary),
                onPressed: () => Navigator.maybePop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Labeled field wrapper ──────────────────
  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        child,
      ],
    );
  }

  // ── Brand Logos ────────────────────────────
  Widget _facebookLogo() {
    return Image.asset(
      'assets/icons/facebook.webp',
      width: 24.w,
      height: 24.h,
    );
  }

  Widget _appleLogo() {
    return Image.asset(
      'assets/icons/apple.webp',
      width: 24.w,
      height: 24.h,
    );
  }

  Widget _googleLogo() {
    return Image.asset(
      'assets/icons/gogle.webp',
      width: 24.w,
      height: 24.h,
    );
  }
}

