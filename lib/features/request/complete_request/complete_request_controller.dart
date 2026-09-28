import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/exceptions/app_exceptions.dart';
import 'package:vyzi/core/models/address_data.dart';
import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/core/utils/tax_id_validator.dart';
import 'package:vyzi/features/bills/models/bill_model.dart';
import 'package:vyzi/features/request/models/api_offer_model.dart';
import 'package:vyzi/features/request/models/case_model.dart';
import 'package:vyzi/features/request/request_success_screen.dart';

enum PaymentMethod { directDebit, postalOrder }

enum InvoiceMethod { digital, paper }

enum AddressMatch { same, different }

enum InvoiceAddressMatch { yes, no }

class UploadedDocumentInfo {
  final String localPath;
  String? remoteUrl;
  final String fileName;
  final String documentType;

  UploadedDocumentInfo({
    required this.localPath,
    this.remoteUrl,
    required this.fileName,
    required this.documentType,
  });
}

class CompleteRequestController extends ChangeNotifier {
  final ApiService _api = ApiService();

  // ── Passed-in data ──
  final ApiOfferModel offer;

  /// The bill the offer was proposed for. The request is opened against this
  /// supply point and no other, so it is handed in rather than looked up.
  final String billId;

  /// The bill itself, loaded from [billId] for the form's pre-fill.
  BillModel? bill;

  // ── Profile data ──
  String firstName = '';
  String lastName = '';
  String email = '';

  /// Which of the two account kinds is filing this request. The form asks a
  /// company for its registered office where it asks a person for their
  /// residence — same fields, and the only honest word for them differs.
  String role = 'personal';
  bool get isBusiness => role == 'business';

  /// The company's certified email, where there is one. A business account
  /// invoices to its PEC, not to the mailbox it happened to sign up with.
  ///
  /// Its own address, distinct from [email]: a company signs in with whatever
  /// mailbox registered it — very often somebody's personal one — and is
  /// reached legally at this.
  String pecEmail = '';

  /// The ragione sociale. A company contracts as itself, so this is the name
  /// the offer is activated in and the name the IBAN has to be registered to.
  String companyName = '';
  String phone = '';

  /// The two account identifiers, of which an account holds exactly one: a
  /// private customer their Codice Fiscale, a company its Partita IVA. Read
  /// separately and resolved by [accountTaxId], so nothing downstream has to
  /// know which row of the profile the value came off.
  String codiceFiscale = '';
  String partitaIva = '';

  /// The identifier this account is known by. Empty when the account has never
  /// recorded one — the request form is one of the places that asks.
  String get accountTaxId => isBusiness ? partitaIva : codiceFiscale;

  // ── Bill-derived data ──
  String podNumber = '';

  // ── Payment ──
  String fullName = '';

  /// Who the contract — and so the direct debit's IBAN — is in the name of.
  ///
  /// A company contracts as itself: the ragione sociale, not the name of the
  /// person who happens to sign. Falls back to the personal name only when the
  /// account carries no company row at all, which a social sign-up can leave
  /// empty; there the bill's printed holder is the best name available.
  String get contractHolderName => isBusiness && companyName.trim().isNotEmpty
      ? companyName.trim()
      : fullName;

  /// The contract holder's tax ID: their Codice Fiscale on a personal account,
  /// the company's Partita IVA on a business one. One account carries one
  /// identifier, and this field holds whichever it is — the mandate is filed
  /// against the holder, and the holder here is the account.
  ///
  /// Pre-filled from the account when it has one, but it belongs to this
  /// request alone: a code given here travels with the case and is never
  /// written back to the profile.
  String taxCode = '';
  PaymentMethod? selectedPayment;
  String iban = '';
  bool ibanSameAsContract = true;
  String holderFirstName = '';
  String holderLastName = '';
  String holderTaxCode = '';

  // ── Addresses ──
  // All three blocks carry the same five fields (street, civic number, city,
  // CAP, province) so the case reaches the backend in one predictable shape.

  /// Where the energy is delivered. Pre-filled from the bill, user-correctable.
  AddressData supplyAddress = AddressData.empty;

  /// Where the customer resides. Equals [supplyAddress] when [addressMatch] is
  /// [AddressMatch.same].
  AddressMatch? addressMatch;
  AddressData residentialAddress = AddressData.empty;

  // ── Invoice ──
  InvoiceMethod? selectedInvoice;

  /// Where digital invoices are sent. Pre-filled with the account email, but the
  /// customer can route them elsewhere.
  String invoiceEmail = '';

  /// Where paper invoices are posted. Only meaningful for [InvoiceMethod.paper];
  /// equals [supplyAddress] when [invoiceAddressMatch] is
  /// [InvoiceAddressMatch.yes].
  InvoiceAddressMatch? invoiceAddressMatch;
  AddressData shippingAddress = AddressData.empty;

  /// The residence address actually recorded on the case.
  AddressData get effectiveResidentialAddress =>
      addressMatch == AddressMatch.different ? residentialAddress : supplyAddress;

  /// The postal address actually recorded on the case, for paper invoices.
  AddressData get effectiveShippingAddress =>
      invoiceAddressMatch == InvoiceAddressMatch.no
          ? shippingAddress
          : supplyAddress;

  // ── Document upload ──
  List<UploadedDocumentInfo> uploadedDocuments = [];
  bool isUploading = false;

  // ── Loading states ──
  bool isLoadingProfile = true;
  bool isLoadingBill = false;
  bool isSavingProfile = false;
  bool isSubmitting = false;
  String? error;

  CompleteRequestController({
    required this.offer,
    required this.billId,
  }) {
    // When the offer accepts only one method there is nothing to choose, so
    // pre-select it — the card renders it as the single option and activation
    // is not blocked on a selection the user cannot make differently.
    if (!offer.supportsPostalOrder) {
      selectedPayment = PaymentMethod.directDebit;
    } else if (!offer.supportsDirectDebit) {
      selectedPayment = PaymentMethod.postalOrder;
    }
    _initialize();
  }

  Future<void> _initialize() async {
    await fetchProfile();
    await fetchBill();
  }

  // ── Profile fetch ──
  Future<void> fetchProfile() async {
    isLoadingProfile = true;
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.getMyProfile);
      final body = response.data as Map<String, dynamic>;

      if (body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;

        firstName = data['firstName'] as String? ?? '';
        lastName = data['lastName'] as String? ?? '';
        email = data['email'] as String? ?? '';
        phone = data['phone'] as String? ?? '';
        codiceFiscale = data['codiceFiscale'] as String? ?? '';
        role = data['role'] as String? ?? role;
        final business = data['businessProfile'];
        pecEmail = business is Map<String, dynamic>
            ? (business['pecEmail'] as String? ?? '')
            : '';
        partitaIva = business is Map<String, dynamic>
            ? (business['partitaIva'] as String? ?? '')
            : '';
        companyName = business is Map<String, dynamic>
            ? (business['companyName'] as String? ?? '')
            : '';

        fullName = '$firstName $lastName'.trim();
        // Whichever of the two this account is identified by. A company's VAT
        // number is read off the business profile for exactly the reason a
        // private customer's tax code is read off the user row: it is that
        // account's only tax identifier, and the mandate is filed against it.
        taxCode = accountTaxId;
      }
    } catch (_) {
      // Non-blocking — user can manually enter data
    } finally {
      isLoadingProfile = false;
      notifyListeners();
    }
  }

  // ── Profile save ──

  /// Persists the personal-information edits to the user's account, so the same
  /// values are what Profile → Personal Data shows. The delivery point travels
  /// with the case instead: it belongs to the bill, not to the profile.
  ///
  /// Returns false when the update was rejected — the caller keeps the form
  /// open so nothing the user typed is lost.
  Future<bool> savePersonalInfo({
    required String firstName,
    required String lastName,
    required String phone,
    required String podNumber,
    // Business only — a personal card does not collect these and passes none,
    // so the payload it sends is byte-for-byte what it always sent.
    String? companyName,
    String? partitaIva,
    String? codiceFiscale,
    String? pecEmail,
  }) async {
    isSavingProfile = true;
    notifyListeners();

    try {
      final response = await _api.patch(
        ApiConstants.updateProfile,
        data: <String, dynamic>{
          'firstName': firstName,
          'lastName': lastName,
          if (phone.isNotEmpty) 'phone': phone,
          if (isBusiness) ...<String, dynamic>{
            // Omitted when blank rather than sent empty: the API's optional
            // rules skip a missing field but still check an empty string, so
            // a blank one comes back as a 400 naming a field this card has
            // already accepted.
            if ((companyName ?? '').trim().isNotEmpty)
              'companyName': companyName!.trim(),
            if ((partitaIva ?? '').trim().isNotEmpty)
              'partitaIva': normalizeTaxId(partitaIva!),
            if ((codiceFiscale ?? '').trim().isNotEmpty)
              'codiceFiscale': normalizeTaxId(codiceFiscale!),
            // Sent even when cleared, so emptying the field sticks — an
            // omitted key would leave the old address in place. The server
            // turns the empty string back into null.
            if (pecEmail != null) 'pecEmail': pecEmail.trim(),
          },
        },
      );

      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) return false;

      // Prefer what the server stored — it is the value the profile screen and
      // the case will read back.
      final data = body['data'] as Map<String, dynamic>?;
      this.firstName = data?['firstName'] as String? ?? firstName;
      this.lastName = data?['lastName'] as String? ?? lastName;
      this.phone = data?['phone'] as String? ?? phone;
      this.podNumber = podNumber;
      this.codiceFiscale = data?['codiceFiscale'] as String? ?? this.codiceFiscale;

      final business = data?['businessProfile'];
      if (business is Map<String, dynamic>) {
        this.companyName = business['companyName'] as String? ?? this.companyName;
        this.partitaIva = business['partitaIva'] as String? ?? this.partitaIva;
        this.pecEmail = business['pecEmail'] as String? ?? this.pecEmail;
      }

      // A corrected VAT number has to reach the mandate too. The payment card
      // and the holder block both read `taxCode`, and leaving it on the old
      // value files the direct debit against a number the customer has just
      // told us was wrong — on the same screen, a few sections further down.
      if (isBusiness && this.partitaIva.trim().isNotEmpty) {
        taxCode = this.partitaIva.trim();
        if (ibanSameAsContract) holderTaxCode = taxCode;
      }

      // The payment section shows the contract holder — which is the name on
      // the bill when there is one, and otherwise the profile name.
      final billHolder = bill?.customerName;
      if (billHolder == null || billHolder.isEmpty) {
        fullName = '${this.firstName} ${this.lastName}'.trim();
      }
      if (ibanSameAsContract) {
        holderFirstName = this.firstName;
        holderLastName = this.lastName;
      }
      return true;
    } on ServerException catch (e) {
      _showError(e.message);
      return false;
    } catch (_) {
      _showError('request.form.profile_update_failed'.tr);
      return false;
    } finally {
      isSavingProfile = false;
      notifyListeners();
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'common.error'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  // ── Bill fetch ──

  /// Loads the bill the offer was proposed for. It is what the case is opened
  /// against, so the form stays disabled until it is here — activating against
  /// a guessed bill would switch a supply point the customer never chose.
  Future<void> fetchBill() async {
    isLoadingBill = true;
    notifyListeners();

    try {
      final url =
          ApiConstants.getMyBillDetails.replaceAll('{{billId}}', billId);
      final response = await _api.get(url);
      final body = response.data as Map<String, dynamic>;

      if (body['success'] == true && body['data'] != null) {
        bill = BillModel.fromJson(body['data'] as Map<String, dynamic>);
        _prefillFromBill(bill!);
      }
    } catch (_) {
      // Non-blocking — `canActivate` keeps the request from being sent without
      // a bill, and the user can retry by reopening the offer.
    } finally {
      isLoadingBill = false;
      notifyListeners();
    }
  }

  void _prefillFromBill(BillModel b) {
    podNumber = b.podNumber ?? b.pdrNumber ?? '';
    // The bill carries the supply address already split into the five fields.
    // Bills stored before those fields existed — and any line the split could
    // make nothing of — still only have the printed line, so fall back to
    // parsing it and let the user correct whatever that got wrong.
    if (supplyAddress.isEmpty) {
      final fromBill = AddressData(
        street: b.supplyStreet ?? '',
        streetNumber: b.supplyStreetNumber ?? '',
        city: b.supplyCity ?? '',
        postalCode: b.supplyPostalCode ?? '',
        province: b.supplyProvince ?? '',
      );
      supplyAddress =
          fromBill.isNotEmpty ? fromBill : AddressData.parse(b.supplyAddress);
    }
    if (b.customerName != null && b.customerName!.isNotEmpty) {
      fullName = b.customerName!;
    }
    // Only where the account has nothing. The bill's tax ID was read off the
    // page by OCR, so it is the weaker of the two — letting it overwrite a code
    // the customer confirmed on their profile would replace a good value with a
    // misread one, and now that the field is checked they would have to fix it.
    //
    // A bill prints whichever identifier its holder has, and the account is
    // asked for the one that matches its own kind — so a company takes the
    // Partita IVA off the page and a private customer the Codice Fiscale.
    if (taxCode.isEmpty) {
      final fromBill = isBusiness ? b.partitaIva : b.codiceFiscale;
      if (fromBill != null && fromBill.isNotEmpty) taxCode = fromBill;
    }
    notifyListeners();
  }

  // ── Selections ──
  void selectAddressMatch(AddressMatch match) {
    addressMatch = match;
    notifyListeners();
  }

  void selectPayment(PaymentMethod method) {
    selectedPayment = method;
    notifyListeners();
  }

  void selectInvoice(InvoiceMethod method) {
    selectedInvoice = method;
    // The shipping question only exists for paper invoices; drop any earlier
    // answer so a digital invoice never carries a stale shipping address.
    if (method == InvoiceMethod.digital) {
      invoiceAddressMatch = null;
      shippingAddress = AddressData.empty;
    }
    notifyListeners();
  }

  void selectInvoiceAddressMatch(InvoiceAddressMatch match) {
    invoiceAddressMatch = match;
    notifyListeners();
  }

  // ── Invoice email ──

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool isValidEmail(String value) => _emailPattern.hasMatch(value.trim());

  /// The address digital invoices will actually be sent to — what the customer
  /// typed, falling back to the account's own invoicing address when the field
  /// was left blank.
  ///
  /// For a company that is its PEC rather than its sign-in email, matching what
  /// the API fills in when the field is omitted entirely. The sign-in address
  /// on a business account is very often the personal mailbox of whoever
  /// registered, and statutory invoices do not belong there.
  String get defaultInvoiceEmail =>
      isBusiness && pecEmail.trim().isNotEmpty ? pecEmail.trim() : email.trim();

  String get effectiveInvoiceEmail =>
      invoiceEmail.trim().isNotEmpty ? invoiceEmail.trim() : defaultInvoiceEmail;

  bool get _isInvoiceValid {
    if (selectedInvoice != InvoiceMethod.digital) return true;
    return isValidEmail(effectiveInvoiceEmail);
  }

  // ── IBAN validation ──
  static bool isValidItalianIban(String value) {
    final cleaned = value.replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (cleaned.length != 27) return false;
    if (!cleaned.startsWith('IT')) return false;
    return RegExp(r'^[A-Z0-9]+$').hasMatch(cleaned);
  }

  // ── Holder tax ID ──

  /// The tax ID the mandate will be filed against: the contract holder's own
  /// when the account is theirs, otherwise the one given for the third party.
  String get effectiveHolderTaxCode =>
      ibanSameAsContract ? taxCode.trim() : holderTaxCode.trim();

  /// Whether that tax ID is one the supplier will accept.
  ///
  /// Either a Codice Fiscale or a Partita IVA, on either kind of account and
  /// whoever holds the IBAN — only formal validity is checked, as the API
  /// does. An account that never recorded a code is no more filable than a
  /// third party whose code was mistyped.
  bool get isHolderTaxCodeValid => isValidItalianTaxId(effectiveHolderTaxCode);

  bool get _isPaymentValid {
    if (selectedPayment != PaymentMethod.directDebit) return true;
    if (!isValidItalianIban(iban)) return false;
    if (!isHolderTaxCodeValid) return false;
    if (!ibanSameAsContract) {
      return holderFirstName.trim().isNotEmpty &&
          holderLastName.trim().isNotEmpty;
    }
    return true;
  }

  // ── Document selection (multi-file, deferred upload) ──
  // No minimum count: the ID may arrive as a single PDF with front and back,
  // as two separate files, or as several photos. Only the upper bound applies.
  static const int maxDocuments = 10;

  Future<void> pickDocuments() async {
    final remaining = maxDocuments - uploadedDocuments.length;
    if (remaining <= 0) return;

    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );

      if (result == null || result.files.isEmpty) return;

      final filesToAdd = result.files.take(remaining);
      for (final file in filesToAdd) {
        if (file.path == null) continue;

        // Identity files are not categorized: an ID may arrive as one PDF with
        // front and back, as two files, or as several photos, so every file in
        // this section carries the same flat type.
        uploadedDocuments.add(UploadedDocumentInfo(
          localPath: file.path!,
          fileName: file.name,
          documentType: 'identity_document',
        ));
      }
      notifyListeners();
    } catch (e) {
      Get.snackbar(
        'upload_bill.file_validation_title'.tr,
        (e is AppException ? e.message : 'system.unexpected'.tr),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    }
  }

  /// Adds photos taken with the in-app camera (front, back, or both).
  void addCapturedDocuments(List<String> paths) {
    final remaining = maxDocuments - uploadedDocuments.length;
    if (remaining <= 0) return;

    for (final path in paths.take(remaining)) {
      uploadedDocuments.add(UploadedDocumentInfo(
        localPath: path,
        fileName: path.split(RegExp(r'[/\\]')).last,
        documentType: 'identity_document',
      ));
    }
    notifyListeners();
  }

  /// Uploads all pending local documents to the server.
  /// Returns true if all uploads succeeded.
  Future<bool> _uploadPendingDocuments() async {
    bool allSucceeded = true;
    for (final doc in uploadedDocuments) {
      if (doc.remoteUrl != null) continue; // already uploaded

      try {
        final multipartFile = await MultipartFile.fromFile(
          doc.localPath,
          filename: doc.fileName,
        );

        final response = await _api.uploadFile(
          ApiConstants.fileUpload,
          file: multipartFile,
        );

        final body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          final data = body['data'] as Map<String, dynamic>;
          doc.remoteUrl = data['url'] as String? ?? '';
        } else {
          allSucceeded = false;
        }
      } catch (_) {
        allSucceeded = false;
      }
    }
    return allSucceeded;
  }

  void removeDocument(int index) {
    uploadedDocuments.removeAt(index);
    notifyListeners();
  }

  // ── Address validation ──

  /// Every address that will be submitted must be complete: the supply address
  /// always, the residence address when it differs, and the shipping address
  /// when paper invoices go somewhere else.
  bool get isAddressValid {
    if (!supplyAddress.isComplete) return false;
    if (addressMatch == null) return false;
    if (addressMatch == AddressMatch.different &&
        !residentialAddress.isComplete) {
      return false;
    }
    if (selectedInvoice == InvoiceMethod.paper) {
      if (invoiceAddressMatch == null) return false;
      if (invoiceAddressMatch == InvoiceAddressMatch.no &&
          !shippingAddress.isComplete) {
        return false;
      }
    }
    return true;
  }

  // ── Case creation ──
  bool get canActivate =>
      bill != null &&
      !isSubmitting &&
      firstName.trim().isNotEmpty &&
      lastName.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      podNumber.trim().isNotEmpty &&
      isAddressValid &&
      selectedPayment != null &&
      selectedInvoice != null &&
      uploadedDocuments.isNotEmpty &&
      _isPaymentValid &&
      _isInvoiceValid;

  Future<void> activateOffer() async {
    if (!canActivate) return;

    isSubmitting = true;
    error = null;
    notifyListeners();

    try {
      // Step 1: Upload all pending identity documents
      final uploadSuccess = await _uploadPendingDocuments();
      if (!uploadSuccess) {
        throw Exception('Failed to upload one or more identity documents');
      }

      // Step 2: Create the case. The tax code the customer gave goes with it
      // and nowhere else — it is this request's, not an account detail this
      // form is entitled to change behind them.
      final data = <String, dynamic>{
        'billId': bill!.id,
        'selectedOfferId': offer.id,
        // The user may have corrected the delivery point on this form; the
        // server writes it back to the bill it belongs to.
        'podNumber': podNumber.trim(),
      };

      // Addresses — the supply address always, the residence address resolved
      // against the user's answer, and the shipping address only where paper
      // invoices are actually posted.
      data.addAll(supplyAddress.toJson('supply'));
      data['residentialSameAsSupply'] = addressMatch == AddressMatch.same;
      data.addAll(effectiveResidentialAddress.toJson('residential'));

      // Payment method & IBAN
      data['paymentMethod'] = selectedPayment == PaymentMethod.directDebit
          ? 'rid_bancario'
          : 'postal_order';
      data['invoiceDelivery'] = selectedInvoice == InvoiceMethod.digital
          ? 'digital'
          : 'paper';
      if (selectedInvoice == InvoiceMethod.digital) {
        data['invoiceEmail'] = effectiveInvoiceEmail;
      }
      if (selectedInvoice == InvoiceMethod.paper) {
        data['shippingSameAsSupply'] =
            invoiceAddressMatch == InvoiceAddressMatch.yes;
        data.addAll(effectiveShippingAddress.toJson('shipping'));
      }
      if (selectedPayment == PaymentMethod.directDebit) {
        data['iban'] = iban.replaceAll(RegExp(r'\s'), '').toUpperCase();
        // The holder block always travels with a direct debit, even when it is
        // the contract holder's own account. Sending it only for a third party
        // left the CRM inferring "same holder" from three empty columns, which
        // reads the same as "nobody filled these in" — and whether the mandate
        // needs a second signature turns on exactly that distinction.
        data['ibanSameAsContract'] = ibanSameAsContract;
        data['ibanHolderFirstName'] = holderFirstName;
        data['ibanHolderLastName'] = holderLastName;
        data['ibanHolderTaxCode'] = normalizeTaxId(effectiveHolderTaxCode);
      }

      final caseResponse = await _api.post(
        ApiConstants.casesBase,
        data: data,
      );

      final caseBody = caseResponse.data as Map<String, dynamic>;
      if (caseBody['success'] != true) {
        throw Exception(
            caseBody['message']?.toString() ?? 'Failed to create case');
      }

      final caseData = caseBody['data'] as Map<String, dynamic>;
      final createdCase = CaseModel.fromJson(caseData);

      // Step 3: Attach uploaded documents
      for (final doc in uploadedDocuments) {
        try {
          await _api.post(
            ApiConstants.caseDocuments(createdCase.id),
            data: {
              'documentType': doc.documentType,
              'fileUrl': doc.remoteUrl ?? '',
              'fileName': doc.fileName,
            },
          );
        } catch (_) {
          // Document attachment failure is non-fatal — case already created
        }
      }

      // Step 4: Navigate to success with the bill the case was opened for
      NavHelper.pushReplacement(
          RequestSuccessScreen(billId: createdCase.billId));
    } catch (e) {
      error = (e is AppException ? e.message : 'system.unexpected'.tr);
      Get.snackbar(
        'auth.validation.error'.tr,
        error!,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
