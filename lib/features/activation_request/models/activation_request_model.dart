import 'package:get/get.dart';
import 'package:vyzi/core/models/address_data.dart';

/// The two services a supply can be activated for.
enum ActivationService { electricity, gas }

extension ActivationServiceApi on ActivationService {
  /// The value the API speaks: `electricity` or `gas`.
  String get apiValue => this == ActivationService.gas ? 'gas' : 'electricity';

  /// `LUCE` / `GAS`, as the toggle and the badge print it.
  String get label => this == ActivationService.gas
      ? 'activation_request.service_gas'.tr
      : 'activation_request.service_electricity'.tr;
}

/// What the answers add up to.
enum ActivationRequestType {
  /// No meter installed: a new connection.
  newActivation,

  /// Meter installed, supply off: a subentro.
  takeover,

  /// Meter installed and the supply running. Not an activation — a change of
  /// holder is a voltura, so the form is not shown at all.
  transfer,
}

/// The "Attiva una nuova utenza" questions, and what they resolve to.
///
/// Pure state so the branching is testable on its own: no meter means the
/// supply question is never asked; a meter with the supply off is a subentro;
/// a meter with the supply running is sent to Voltura instead.
class ActivationAnswers {
  final ActivationService? service;
  final bool? meterInstalled;
  final bool? supplyActive;

  const ActivationAnswers({this.service, this.meterInstalled, this.supplyActive});

  static const ActivationAnswers empty = ActivationAnswers();

  ActivationAnswers withService(ActivationService value) => ActivationAnswers(
        service: value,
        meterInstalled: meterInstalled,
        supplyActive: supplyActive,
      );

  /// Changing the meter answer forgets the supply answer: it is only asked
  /// when there is a meter, and a stale one would decide the type silently.
  ActivationAnswers withMeterInstalled(bool value) => ActivationAnswers(
        service: service,
        meterInstalled: value,
        supplyActive: value == meterInstalled ? supplyActive : null,
      );

  ActivationAnswers withSupplyActive(bool value) => ActivationAnswers(
        service: service,
        meterInstalled: meterInstalled,
        supplyActive: value,
      );

  /// Question 2 appears once a service is chosen.
  bool get showsMeterQuestion => service != null;

  /// Question 3 is asked only when a meter is installed.
  bool get showsSupplyQuestion => service != null && meterInstalled == true;

  /// Null until the answers are enough to decide.
  ActivationRequestType? get type {
    if (service == null || meterInstalled == null) return null;
    if (meterInstalled == false) return ActivationRequestType.newActivation;
    if (supplyActive == null) return null;
    return supplyActive!
        ? ActivationRequestType.transfer
        : ActivationRequestType.takeover;
  }

  /// The contact form is shown for a new connection or a subentro.
  bool get showsContactForm =>
      type == ActivationRequestType.newActivation ||
      type == ActivationRequestType.takeover;
}

/// The contact details the form collects, as the API takes them.
class ActivationRequestPayload {
  final ActivationAnswers answers;
  final String firstName;
  final String lastName;
  final String phone;
  final AddressData address;
  final bool privacyAccepted;

  const ActivationRequestPayload({
    required this.answers,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.address,
    required this.privacyAccepted,
  });

  Map<String, dynamic> toJson() => {
        'energyType': answers.service!.apiValue,
        'meterInstalled': answers.meterInstalled,
        if (answers.meterInstalled == true) 'supplyActive': answers.supplyActive,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'phone': phone.replaceAll(RegExp(r'[\s.\-()/]'), ''),
        'street': address.street.trim(),
        'streetNumber': address.streetNumber.trim(),
        'postalCode': address.postalCode.trim(),
        'city': address.city.trim(),
        'province': address.province.trim().toUpperCase(),
        'privacyAccepted': privacyAccepted,
      };
}

/// One of the customer's activation requests, as the requests tab lists it.
class ActivationRequestModel {
  final String id;
  final String? caseNumber;
  final String caseType;
  final String? energyType;
  final String status;
  final AddressData address;
  final DateTime? createdAt;

  const ActivationRequestModel({
    required this.id,
    required this.caseNumber,
    required this.caseType,
    required this.energyType,
    required this.status,
    required this.address,
    required this.createdAt,
  });

  factory ActivationRequestModel.fromJson(Map<String, dynamic> json) {
    return ActivationRequestModel(
      id: json['id'] as String,
      caseNumber: json['caseNumber'] as String?,
      caseType: json['caseType'] as String? ?? '',
      energyType: json['energyType'] as String?,
      status: json['status'] as String? ?? 'new',
      address: AddressData.fromJson(json, 'supply'),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal(),
    );
  }

  bool get isGas => energyType == 'gas';

  /// In activation or activated: the supply is the customer's, and opens as a
  /// utility rather than as a request.
  bool get isLive => status == 'awaiting_activation' || status == 'activated';

  /// `Subentro · Luce`
  String get title {
    final type = caseType == 'takeover'
        ? 'activation_request.type_takeover'.tr
        : 'activation_request.type_new_activation'.tr;
    final service = isGas
        ? 'activation_request.service_gas_title'.tr
        : 'activation_request.service_electricity_title'.tr;
    return '$type · $service';
  }

  String get statusLabel => 'activation_request.status.$status'.tr;
}
