import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/exceptions/app_exceptions.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/core/services/storage_service.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/utils/phone_utils.dart';
import 'package:vyzi/core/utils/tax_id_validator.dart';

class ProfileController extends ChangeNotifier {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  // ── User Info ──
  String name = '';
  String email = '';
  String memberSince = '';
  String avatarAsset = '';
  String avatarUrl = '';
  bool isUploadingAvatar = false;

  /// Raw backend role — 'personal', 'business' or 'admin'. Set when the
  /// account is registered and never changed afterwards. Kept raw rather than
  /// as a display label so the UI can branch on it in any language; the label
  /// people see comes from [accountType].
  String role = 'personal';

  bool get isBusiness => role == 'business';

  /// Localized account-type label for the profile card.
  String get accountType => isBusiness
      ? 'profile.account_type_business'.tr
      : 'profile.account_type_personal'.tr;

  // ── Business profile — present on business accounts, which register as
  // such. Read by the profile card and by the personal-data screen.
  String companyName = '';
  String partitaIva = '';
  String jobRole = '';
  String pecEmail = '';

  // ── Personal Data form fields ──
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codiceFiscaleController = TextEditingController();

  // Company fields, editable from the personal-data screen when the account is
  // a business one. Kept alongside the plain strings above, which the profile
  // card reads; both are written by [_applyBusinessProfile].
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController partitaIvaController = TextEditingController();

  /// Where the company's invoices go. A business switch request with no
  /// explicit invoice address falls back to the PEC rather than to the sign-in
  /// email, which on a company account is very often somebody's personal
  /// mailbox — so this is worth correcting from the app.
  final TextEditingController pecEmailController = TextEditingController();

  /// Job role currently picked in the personal-data screen. Null means "not
  /// set", which the API stores as null rather than an empty string.
  String? selectedJobRole;
  String phoneDialCode = '+39';
  String phoneCountryCode = 'IT';

  /// Last values the server confirmed, so "cancel and discard" can put every
  /// field back — not just the name, which was all it used to restore.
  Map<String, String> _serverSnapshot = const {};

  bool isSaving = false;
  bool isLoading = false;

  ProfileController() {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.getMyProfile);

      final body = response.data as Map<String, dynamic>;

      if (body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;

        final firstName = data['firstName'] as String? ?? '';
        final lastName = data['lastName'] as String? ?? '';

        name = '$firstName $lastName'.trim();
        email = data['email'] as String? ?? '';

        _applyRole(data['role'] as String?);
        final business = data['businessProfile'];
        if (business == null) {
          _clearBusinessProfile();
        } else {
          _applyBusinessProfile(business);
        }

        // memberSince from createdAt
        final createdAt = data['createdAt'] as String?;
        if (createdAt != null) {
          final dt = DateTime.tryParse(createdAt);
          if (dt != null) {
            const months = [
              'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
              'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
            ];
            memberSince = 'Membro dal ${months[dt.month - 1]} ${dt.year}';
          }
        }

        // Avatar
        final avatar = data['avatar'] as String?;
        if (avatar != null && avatar.isNotEmpty) {
          avatarUrl = avatar.startsWith('http')
              ? avatar
              : '${ApiConstants.baseUrl}$avatar';
        }

        // Populate form fields
        firstNameController.text = firstName;
        lastNameController.text = lastName;
        emailController.text = email;
        final rawPhone = data['phone'] as String? ?? '';
        if (rawPhone.isNotEmpty) {
          final (dialCode, nationalNumber) = fromE164(rawPhone);
          phoneDialCode = dialCode;
          phoneController.text = nationalNumber;
        } else {
          phoneController.text = '';
        }
        codiceFiscaleController.text = data['codiceFiscale'] as String? ?? '';
        _takeSnapshot();
      }
    } catch (_) {
      // Keep existing values on error
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Role and company details, as the server reports them
  // ─────────────────────────────────────────────────────────────────────────

  /// Stores the role locally and mirrors it into [StorageKeys.userRole], which
  /// other features (FAQ filtering, offer targeting) read without re-fetching
  /// the profile. The two have to stay in step: everything downstream branches
  /// on the stored copy.
  void _applyRole(String? value) {
    if (value == null || value.isEmpty) return;
    role = value;
    Get.find<StorageService>().setString(StorageKeys.userRole, value);
  }

  void _applyBusinessProfile(dynamic raw) {
    if (raw is! Map<String, dynamic>) return;
    companyName = raw['companyName'] as String? ?? companyName;
    partitaIva = raw['partitaIva'] as String? ?? partitaIva;
    jobRole = raw['jobRole'] as String? ?? jobRole;
    pecEmail = raw['pecEmail'] as String? ?? pecEmail;
    companyNameController.text = companyName;
    partitaIvaController.text = partitaIva;
    pecEmailController.text = pecEmail;
    selectedJobRole = jobRole.isEmpty ? null : jobRole;
  }

  /// Wipes the company fields for an account the server reports no company
  /// for, so nothing stale is shown as if it had been saved.
  void _clearBusinessProfile() {
    companyName = '';
    partitaIva = '';
    jobRole = '';
    pecEmail = '';
    companyNameController.text = '';
    partitaIvaController.text = '';
    pecEmailController.text = '';
    selectedJobRole = null;
  }

  void _takeSnapshot() {
    _serverSnapshot = {
      'firstName': firstNameController.text,
      'lastName': lastNameController.text,
      'email': emailController.text,
      'phone': phoneController.text,
      'phoneDialCode': phoneDialCode,
      'codiceFiscale': codiceFiscaleController.text,
      'companyName': companyNameController.text,
      'partitaIva': partitaIvaController.text,
      'pecEmail': pecEmailController.text,
      'jobRole': selectedJobRole ?? '',
    };
  }

  Future<bool> saveChanges() async {
    isSaving = true;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
      };

      // Only include optional fields if they have a value — empty strings
      // fail backend regex validation for codiceFiscale
      final phone = phoneController.text.trim();
      if (phone.isNotEmpty) {
        body['phone'] = toE164(phoneDialCode, phone);
      }

      // The code of the person behind the account, on either kind: the customer
      // themselves, or on a business account the owner who signs. Distinct from
      // the company's Partita IVA below — the two identify different parties,
      // and a business customer is asked for both.
      //
      // Checked here, and normalised, because a code the API refuses would come
      // back as a bare 400 naming a field this screen had already accepted.
      // Sent only when it has a value: an empty string is not skipped by the
      // API's optional rule, so a blank one would be refused as malformed.
      final codiceFiscale = normalizeTaxId(codiceFiscaleController.text);
      if (codiceFiscale.isNotEmpty) {
        if (!isValidCodiceFiscale(codiceFiscale)) {
          _showError('personal_data.tax_code_invalid'.tr);
          return false;
        }
        body['codiceFiscale'] = codiceFiscale;
      }

      // Company details, for accounts that have them. Both are sent together:
      // the API needs the pair to create a company row for an account that
      // somehow has none.
      if (isBusiness) {
        final company = companyNameController.text.trim();
        final vat = partitaIvaController.text.trim();

        if (vat.isNotEmpty && !isValidPartitaIva(vat)) {
          _showError('personal_data.vat_invalid'.tr);
          return false;
        }
        // Where the company's invoices are delivered. Checked here for the
        // same reason the tax code is: a PEC the API refuses would come back
        // as a bare 400 naming a field the screen had already accepted.
        final pec = pecEmailController.text.trim();
        if (pec.isNotEmpty && !GetUtils.isEmail(pec)) {
          _showError('personal_data.pec_invalid'.tr);
          return false;
        }

        if (company.isNotEmpty) body['companyName'] = company;
        if (vat.isNotEmpty) body['partitaIva'] = vat;
        // These two are sent even when cleared, so emptying the field sticks
        // — an omitted key would leave the old value in place. The server
        // turns the empty string back into null.
        body['pecEmail'] = pec;
        body['jobRole'] = selectedJobRole ?? '';
      }

      final response = await _api.patch(
        ApiConstants.updateProfile,
        data: body,
      );

      final resBody = response.data as Map<String, dynamic>;

      if (resBody['success'] == true) {
        final data = resBody['data'] as Map<String, dynamic>?;
        if (data != null) {
          final firstName = data['firstName'] as String? ?? firstNameController.text;
          final lastName = data['lastName'] as String? ?? lastNameController.text;
          name = '$firstName $lastName'.trim();
          email = data['email'] as String? ?? email;
          final returnedPhone = data['phone'] as String? ?? '';
          if (returnedPhone.isNotEmpty) {
            final (dialCode, nationalNumber) = fromE164(returnedPhone);
            phoneDialCode = dialCode;
            phoneController.text = nationalNumber;
          }
          // Whatever the server stored, falling back to what is on screen.
          codiceFiscaleController.text =
              data['codiceFiscale'] as String? ?? codiceFiscaleController.text;
          _applyBusinessProfile(data['businessProfile']);
          firstNameController.text = firstName;
          lastNameController.text = lastName;
          emailController.text = email;
          _takeSnapshot();
        }

        Get.snackbar(
          'personal_data.update_success_title'.tr,
          'personal_data.update_success_message'.tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.primaryColor,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
        );
        return true;
      }

      return false;
    } on ServerException catch (e) {
      Get.snackbar(
        'personal_data.update_error_title'.tr,
        // The only conflict this endpoint returns, and the server phrases it in
        // English — say it in the user's language instead.
        e.statusCode == 409 ? 'personal_data.vat_taken'.tr : e.message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
      );
      return false;
    } catch (_) {
      Get.snackbar(
        'personal_data.update_error_title'.tr,
        'personal_data.update_error_message'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
      );
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> pickAndUploadAvatar(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text('personal_data.camera'.tr),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text('personal_data.gallery'.tr),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 80);
    if (picked == null) return;

    isUploadingAvatar = true;
    notifyListeners();

    try {
      // Upload the file
      final multipartFile = await MultipartFile.fromFile(
        picked.path,
        filename: picked.name,
      );

      final uploadResponse = await _api.uploadFile(
        ApiConstants.fileUpload,
        file: multipartFile,
      );

      final uploadBody = uploadResponse.data as Map<String, dynamic>;
      if (uploadBody['success'] == true) {
        final data = uploadBody['data'] as Map<String, dynamic>;
        final remoteUrl = data['url'] as String? ?? '';

        // Update profile with the new avatar URL
        await _api.patch(
          ApiConstants.updateProfile,
          data: {'avatar': remoteUrl},
        );

        avatarUrl = remoteUrl.startsWith('http')
            ? remoteUrl
            : '${ApiConstants.baseUrl}$remoteUrl';
        avatarAsset = '';
      }
    } catch (_) {
      // Keep existing avatar on error
    } finally {
      isUploadingAvatar = false;
      notifyListeners();
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'personal_data.update_error_title'.tr,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.error,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
    );
  }

  /// Puts every field back to what the server last confirmed. Splitting [name]
  /// on a space, as this used to, dropped edits to the phone, the Codice
  /// Fiscale and the company details on the floor — they stayed on screen and
  /// came back the next time the form was opened.
  void cancelChanges() {
    if (_serverSnapshot.isEmpty) {
      // Nothing loaded yet — fall back to re-reading from the server.
      fetchProfile();
      return;
    }

    firstNameController.text = _serverSnapshot['firstName'] ?? '';
    lastNameController.text = _serverSnapshot['lastName'] ?? '';
    emailController.text = _serverSnapshot['email'] ?? '';
    phoneController.text = _serverSnapshot['phone'] ?? '';
    phoneDialCode = _serverSnapshot['phoneDialCode'] ?? phoneDialCode;
    codiceFiscaleController.text = _serverSnapshot['codiceFiscale'] ?? '';
    companyNameController.text = _serverSnapshot['companyName'] ?? '';
    partitaIvaController.text = _serverSnapshot['partitaIva'] ?? '';
    pecEmailController.text = _serverSnapshot['pecEmail'] ?? '';
    final role = _serverSnapshot['jobRole'] ?? '';
    selectedJobRole = role.isEmpty ? null : role;
    notifyListeners();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    codiceFiscaleController.dispose();
    companyNameController.dispose();
    partitaIvaController.dispose();
    pecEmailController.dispose();
    super.dispose();
  }
}
