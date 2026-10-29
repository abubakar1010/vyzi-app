import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/exceptions/app_exceptions.dart';
import 'package:vyzi/core/localization/system_messages.dart';
import 'package:vyzi/core/models/address_data.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/core/widgets/address_form_fields.dart';
import 'package:vyzi/features/activation_request/models/activation_request_model.dart';

/// Validation messages for the contact fields, one per field. All null means
/// the form may be sent.
class ActivationContactErrors {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final AddressErrors address;
  final String? privacy;

  const ActivationContactErrors({
    this.firstName,
    this.lastName,
    this.phone,
    this.address = AddressErrors.none,
    this.privacy,
  });

  static const ActivationContactErrors none = ActivationContactErrors();

  bool get hasErrors =>
      firstName != null ||
      lastName != null ||
      phone != null ||
      address.hasErrors ||
      privacy != null;
}

/// "Attiva una nuova utenza": the questions, the contact form and sending it.
///
/// The answers decide what is shown ([ActivationAnswers]); the server decides
/// the case type from the same answers, so nothing here sends one.
class ActivationRequestController extends GetxController {
  ActivationRequestController({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  static final RegExp _phonePattern = RegExp(r'^(\+39)?\d{9,13}$');

  final Rx<ActivationAnswers> answers = ActivationAnswers.empty.obs;
  final Rx<ActivationContactErrors> errors = ActivationContactErrors.none.obs;
  final RxBool privacyAccepted = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxString submitError = ''.obs;

  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final AddressFieldGroup address = AddressFieldGroup();

  @override
  void onInit() {
    super.onInit();
    _prefillFromProfile();
  }

  @override
  void onClose() {
    firstName.dispose();
    lastName.dispose();
    phone.dispose();
    address.dispose();
    super.onClose();
  }

  void selectService(ActivationService value) =>
      answers.value = answers.value.withService(value);

  void setMeterInstalled(bool value) =>
      answers.value = answers.value.withMeterInstalled(value);

  void setSupplyActive(bool value) =>
      answers.value = answers.value.withSupplyActive(value);

  void togglePrivacy(bool value) {
    privacyAccepted.value = value;
    if (value && errors.value.privacy != null) validate();
  }

  /// Re-checks only once a submit has shown errors, so a field does not turn
  /// red while it is still being typed for the first time.
  void onFieldChanged() {
    if (errors.value.hasErrors) validate();
  }

  /// The name and phone the account already holds. Editable — the person to
  /// call need not be the account holder — and never overwrites typing.
  Future<void> _prefillFromProfile() async {
    try {
      final response = await _api.get(ApiConstants.getMyProfile);
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) return;
      final data = body['data'] as Map<String, dynamic>;
      void fill(TextEditingController c, Object? value) {
        if (c.text.isEmpty && value is String) c.text = value;
      }

      fill(firstName, data['firstName']);
      fill(lastName, data['lastName']);
      fill(phone, data['phone']);
    } catch (_) {
      // A prefill that fails leaves the fields empty for the customer to fill.
    }
  }

  /// Checks every field; returns true when the form may be sent.
  bool validate() {
    final cleanPhone = phone.text.replaceAll(RegExp(r'[\s.\-()/]'), '');
    final addressErrors = address.value.validate();

    errors.value = ActivationContactErrors(
      firstName: firstName.text.trim().isEmpty
          ? 'activation_request.first_name_required'.tr
          : null,
      lastName: lastName.text.trim().isEmpty
          ? 'activation_request.last_name_required'.tr
          : null,
      phone: cleanPhone.isEmpty
          ? 'activation_request.phone_required'.tr
          : (!_phonePattern.hasMatch(cleanPhone)
              ? 'activation_request.phone_invalid'.tr
              : null),
      address: addressErrors,
      privacy: privacyAccepted.value
          ? null
          : 'activation_request.privacy_required'.tr,
    );
    return !errors.value.hasErrors;
  }

  ActivationRequestPayload buildPayload() {
    return ActivationRequestPayload(
      answers: answers.value,
      firstName: firstName.text,
      lastName: lastName.text,
      phone: phone.text,
      address: address.value,
      privacyAccepted: privacyAccepted.value,
    );
  }

  /// Sends the request. True once the server has it; otherwise
  /// [submitError] holds the message to show (empty when the form itself
  /// stopped it, since the fields then show their own errors).
  Future<bool> submit() async {
    submitError.value = '';
    if (!answers.value.showsContactForm || isSubmitting.value) return false;
    if (!validate()) return false;

    isSubmitting.value = true;
    try {
      final response = await _api.post(
        ApiConstants.activationRequests,
        data: buildPayload().toJson(),
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == true) return true;
      submitError.value = SystemMessages.resolve(body['message']);
    } on AppException catch (e) {
      submitError.value = e.message;
    } catch (_) {
      submitError.value = 'activation_request.submit_failed'.tr;
    } finally {
      isSubmitting.value = false;
    }
    return false;
  }
}
