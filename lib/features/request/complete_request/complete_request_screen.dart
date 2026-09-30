import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/models/address_data.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/utils/number_format.dart';
import 'package:vyzi/core/utils/phone_utils.dart';
import 'package:vyzi/core/utils/tax_id_validator.dart';
import 'package:vyzi/core/widgets/address_form_fields.dart';
import 'package:vyzi/core/widgets/phone_filled.dart';

import 'package:vyzi/features/request/models/api_offer_model.dart';
import 'package:vyzi/features/utility/multi_capture_screen.dart';
import 'complete_request_controller.dart';

class CompleteRequestScreen extends StatefulWidget {
  final ApiOfferModel offer;

  /// The bill the offer was proposed for — the supply point this request
  /// switches. Required: a request opened against any other bill would settle
  /// the wrong supply and leave these offers on the customer's list.
  final String billId;
  final double? estimatedSavings;

  const CompleteRequestScreen({
    super.key,
    required this.offer,
    required this.billId,
    this.estimatedSavings,
  });

  @override
  State<CompleteRequestScreen> createState() => _CompleteRequestScreenState();
}

class _CompleteRequestScreenState extends State<CompleteRequestScreen> {
  late final CompleteRequestController _c;
  final ScrollController _scrollCtrl = ScrollController();

  // ── Section keys for scroll-to-error ──
  final _personalInfoKey = GlobalKey();
  final _firstNameKey = GlobalKey();
  final _lastNameKey = GlobalKey();
  final _podKey = GlobalKey();
  final _phoneKey = GlobalKey();
  // Business-only rows of the same card.
  final _companyNameKey = GlobalKey();
  final _vatKey = GlobalKey();
  final _ownerTaxCodeKey = GlobalKey();
  final _pecKey = GlobalKey();
  final _identityKey = GlobalKey();
  final _deliveryAddressKey = GlobalKey();
  final _paymentKey = GlobalKey();
  final _invoiceKey = GlobalKey();

  // ── Personal Info edit ──
  bool _editingPersonalInfo = false;
  String _phoneDialCode = '+39';
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _podCtrl;
  // The company's own details, which only a business account is asked for. A
  // personal account leaves these empty and renders nothing that reads them.
  late TextEditingController _companyNameCtrl;
  late TextEditingController _vatCtrl;
  late TextEditingController _ownerTaxCodeCtrl;
  late TextEditingController _pecCtrl;

  // ── Addresses ──
  // Each block owns an AddressFieldGroup, so supply, residential and shipping
  // collect exactly the same five fields through the same widget.

  bool _editingAddress = false;
  final AddressFieldGroup _supply = AddressFieldGroup();
  AddressErrors _supplyErrors = AddressErrors.none;

  bool _residentialAddressConfirmed = false;
  final AddressFieldGroup _residential = AddressFieldGroup();
  AddressErrors _residentialErrors = AddressErrors.none;

  bool _shippingAddressConfirmed = false;
  final AddressFieldGroup _shipping = AddressFieldGroup();
  AddressErrors _shippingErrors = AddressErrors.none;

  // ── Payment Method extras ──
  bool _ibanSameAsContract = true;
  final TextEditingController _ibanCtrl = TextEditingController();
  String? _ibanError;

  final TextEditingController _holderFirstCtrl = TextEditingController();
  final TextEditingController _holderLastCtrl = TextEditingController();
  final TextEditingController _holderTaxCtrl = TextEditingController();
  String? _holderFirstError;
  String? _holderLastError;
  String? _holderTaxError;

  /// Whether the third-party holder block has been checked over and locked, the
  /// way the residence and shipping addresses are. Like those, it is not what
  /// makes the values count — every keystroke already reaches the controller —
  /// it is the answer to "did my Save do anything?".
  bool _holderInfoSaved = false;

  /// Whether a holder field has been typed in since the block was last filled
  /// or saved — what lights the Save button up, so an edit left unconfirmed
  /// does not look finished.
  bool _holderInfoDirty = false;

  // ── Invoice Delivery extras ──
  late TextEditingController _invoiceEmailCtrl;

  bool _profileSynced = false;
  bool _billAddressSynced = false;

  // ── Personal Info validation errors ──
  String? _firstNameError;
  String? _lastNameError;
  String? _podError;
  String? _phoneError;
  String? _companyNameError;
  String? _vatError;
  String? _ownerTaxCodeError;
  String? _pecError;
  String? _addressMatchError;
  String? _invoiceAddressMatchError;
  String? _invoiceEmailError;

  @override
  void initState() {
    super.initState();
    _c = CompleteRequestController(
      offer: widget.offer,
      billId: widget.billId,
    );
    _c.addListener(_onControllerUpdate);

    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _podCtrl = TextEditingController();
    _invoiceEmailCtrl = TextEditingController();
    _companyNameCtrl = TextEditingController();
    _vatCtrl = TextEditingController();
    _ownerTaxCodeCtrl = TextEditingController();
    _pecCtrl = TextEditingController();
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    // Sync text controllers once profile data arrives. Keyed on the fetch being
    // over rather than on a name being in it: an account with no first name is
    // exactly the one that needs this form, and gating on it left the email,
    // phone and holder fields empty for the customers least able to spare them.
    if (!_profileSynced && !_c.isLoadingProfile) {
      _profileSynced = true;
      _firstNameCtrl.text = _c.firstName;
      _lastNameCtrl.text = _c.lastName;
      _emailCtrl.text = _c.email;
      if (_c.phone.isNotEmpty && _c.phone.startsWith('+')) {
        final (dialCode, nationalNumber) = fromE164(_c.phone);
        _phoneDialCode = dialCode;
        _phoneCtrl.text = nationalNumber;
      } else {
        _phoneCtrl.text = _c.phone;
      }
      _podCtrl.text = _c.podNumber;
      // The company's own details. Empty strings on a personal account, whose
      // card renders nothing that reads them.
      _companyNameCtrl.text = _c.companyName;
      _vatCtrl.text = _c.partitaIva;
      _ownerTaxCodeCtrl.text = _c.codiceFiscale;
      _pecCtrl.text = _c.pecEmail;
      // The account's own invoicing address, which for a company is its PEC —
      // the same value the API fills in when the field is left out entirely.
      _invoiceEmailCtrl.text = _c.defaultInvoiceEmail;
      _prefillHolderFromAccount();
    }
    // The bill can supply a Codice Fiscale a private account was missing, and
    // it arrives after the profile does — seed the personal card's field then,
    // so saving the card files it on the profile, but never overwrite what the
    // customer has already typed. A company's field is its owner's code, which
    // the bill does not carry.
    if (!_c.isBusiness &&
        _ownerTaxCodeCtrl.text.isEmpty &&
        _c.taxCode.isNotEmpty) {
      _ownerTaxCodeCtrl.text = _c.taxCode;
    }
    // The holder block is pre-filled from the same account data, so it takes
    // the late arrival too — an empty field there is one the customer would
    // otherwise fill in by hand with a value we already hold. Only while the
    // box is ticked and the block is hidden: once it is open it belongs to the
    // customer, and a notify mid-correction must not type over them.
    if (_ibanSameAsContract) {
      if (_holderFirstCtrl.text.isEmpty && _c.firstName.isNotEmpty) {
        _holderFirstCtrl.text = _c.firstName;
        _c.holderFirstName = _c.firstName;
      }
      if (_holderLastCtrl.text.isEmpty && _c.lastName.isNotEmpty) {
        _holderLastCtrl.text = _c.lastName;
        _c.holderLastName = _c.lastName;
      }
      if (_holderTaxCtrl.text.isEmpty && _c.taxCode.isNotEmpty) {
        _holderTaxCtrl.text = _c.taxCode;
        _c.holderTaxCode = _c.taxCode;
      }
    }
    // Sync POD number when bill data arrives (may arrive after profile sync)
    if (_podCtrl.text.isEmpty && _c.podNumber.isNotEmpty) {
      _podCtrl.text = _c.podNumber;
    }
    // Sync the supply address once the bill's OCR line has been parsed. When
    // the parse could not fill every field, open the edit form immediately so
    // the user completes it here rather than being blocked at the bottom.
    if (!_billAddressSynced && _c.supplyAddress.isNotEmpty && _supply.isUntouched) {
      _billAddressSynced = true;
      _supply.value = _c.supplyAddress;
      if (!_c.supplyAddress.isComplete) _editingAddress = true;
    }
    setState(() {});
  }

  void _scrollToKey(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.2,
        );
      }
    });
  }

  void _scrollToFirstIncomplete() {
    // Personal info missing → open edit mode and scroll to the card
    if (_c.firstName.trim().isEmpty ||
        _c.lastName.trim().isEmpty ||
        _c.phone.trim().isEmpty ||
        _c.podNumber.trim().isEmpty) {
      if (!_editingPersonalInfo) {
        setState(() => _editingPersonalInfo = true);
      }
      // Set errors so the user sees which fields need attention
      setState(() {
        _firstNameError = _c.firstName.trim().isEmpty
            ? 'request.form.first_name_required'.tr
            : null;
        _lastNameError = _c.lastName.trim().isEmpty
            ? 'request.form.last_name_required'.tr
            : null;
        _podError = _c.podNumber.trim().isEmpty
            ? 'request.form.pod_number_required'.tr
            : null;
        _phoneError = _c.phone.trim().isEmpty
            ? 'request.form.phone_required'.tr
            : null;
      });
      _scrollToKey(_personalInfoKey);
      return;
    }
    // Supply address incomplete — open the edit form on the offending fields
    if (!_c.supplyAddress.isComplete) {
      setState(() {
        _editingAddress = true;
        _supplyErrors = _supply.value.validate();
      });
      _scrollToKey(_deliveryAddressKey);
      return;
    }
    // Delivery address match not selected
    if (_c.addressMatch == null) {
      setState(() {
        _addressMatchError = (_c.isBusiness
                ? 'request.form.address_match_required_business'
                : 'request.form.address_match_required')
            .tr;
      });
      _scrollToKey(_deliveryAddressKey);
      return;
    }
    // Residence address declared different but not filled in / confirmed
    if (_c.addressMatch == AddressMatch.different &&
        !_c.residentialAddress.isComplete) {
      setState(() {
        _residentialAddressConfirmed = false;
        _residentialErrors = _residential.value.validate();
      });
      _scrollToKey(_deliveryAddressKey);
      return;
    }
    // No identity document uploaded at all
    if (_c.uploadedDocuments.isEmpty) {
      _scrollToKey(_identityKey);
      return;
    }
    // Payment / IBAN missing
    if (_c.selectedPayment == null) {
      _scrollToKey(_paymentKey);
      return;
    }
    // Direct debit with the holder block incomplete. Which fields are at fault
    // depends on whose account it is — only one of the two tax-ID fields is on
    // screen at a time — so they are marked together and the card is shown once.
    if (_c.selectedPayment == PaymentMethod.directDebit &&
        (!_c.isHolderTaxCodeValid ||
            (!_c.ibanSameAsContract &&
                (_c.holderFirstName.trim().isEmpty ||
                    _c.holderLastName.trim().isEmpty)))) {
      // The holder is the account, so the code belongs to the account: it is
      // given in the personal card, not typed into the mandate.
      if (_c.ibanSameAsContract) {
        _openAccountTaxIdField();
        return;
      }
      setState(() {
        // The same message the field itself would have shown, so a code that
        // fails only on its check character is named as such at submit time too.
        final taxError = _c.isHolderTaxCodeValid
            ? null
            : (_holderTaxIdError(_c.effectiveHolderTaxCode) ??
                'request.form.holder_tax_id_error'.tr);
        // Sending the customer to fields they cannot type in helps nobody —
        // if the holder block is at fault it is reopened, whatever Save said
        // earlier.
        _holderInfoSaved = false;
        _holderInfoDirty = true;
        _holderTaxError = taxError;
        _holderFirstError = _c.holderFirstName.trim().isEmpty
            ? 'request.form.holder_first_name_required'.tr
            : null;
        _holderLastError = _c.holderLastName.trim().isEmpty
            ? 'request.form.holder_last_name_required'.tr
            : null;
      });
      _scrollToKey(_paymentKey);
      return;
    }
    // Digital invoice: the address the invoices go to is not an email
    if (_c.selectedInvoice == InvoiceMethod.digital &&
        !CompleteRequestController.isValidEmail(_c.effectiveInvoiceEmail)) {
      setState(() {
        _invoiceEmailError = 'request.form.invoice_email_error'.tr;
      });
      _scrollToKey(_invoiceKey);
      return;
    }
    // Paper invoice: shipping destination unanswered or incomplete
    if (_c.selectedInvoice == InvoiceMethod.paper) {
      if (_c.invoiceAddressMatch == null) {
        setState(() {
          _invoiceAddressMatchError = 'request.form.shipping_match_required'.tr;
        });
        _scrollToKey(_invoiceKey);
        return;
      }
      if (_c.invoiceAddressMatch == InvoiceAddressMatch.no &&
          !_c.shippingAddress.isComplete) {
        setState(() {
          _shippingAddressConfirmed = false;
          _shippingErrors = _shipping.value.validate();
        });
        _scrollToKey(_invoiceKey);
        return;
      }
    }
    // Fallback — scroll to top
    _scrollToKey(_personalInfoKey);
  }

  @override
  void dispose() {
    _c.dispose();
    _scrollCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _podCtrl.dispose();
    _companyNameCtrl.dispose();
    _vatCtrl.dispose();
    _ownerTaxCodeCtrl.dispose();
    _pecCtrl.dispose();
    _ibanCtrl.dispose();
    _holderFirstCtrl.dispose();
    _holderLastCtrl.dispose();
    _holderTaxCtrl.dispose();
    _invoiceEmailCtrl.dispose();
    _supply.dispose();
    _residential.dispose();
    _shipping.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: _c.isLoadingProfile
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
              controller: _scrollCtrl,
              // Dragging the form is the user putting the keyboard away, not
              // asking to keep typing — every other scrolling form in the app
              // behaves this way.
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOfferCard(),
                  _gap(),
                  Container(key: _personalInfoKey, child: _buildPersonalInfoCard()),
                  _gap(),
                  Container(key: _deliveryAddressKey, child: _buildSupplyAddressCard()),
                  _gap(),
                  Container(key: _identityKey, child: _buildIdentityVerificationCard()),
                  _gap(),
                  Container(key: _paymentKey, child: _buildPaymentMethodCard()),
                  _gap(),
                  Container(key: _invoiceKey, child: _buildInvoiceDeliveryCard()),
                  _gap(),
                  _buildAlmostThereCard(),
                  if (_c.bill == null && !_c.isLoadingBill) ...[
                    SizedBox(height: 12.h),
                    _buildNoBillWarning(),
                  ],
                  SizedBox(height: 16.h),
                  _buildActivateButton(),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
      ),
    );
  }

  SizedBox _gap() => SizedBox(height: 16.h);

  // ─────────────────────────────────────────────
  //  APPBAR
  // ─────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded,
            color: AppColors.textDark, size: 22.sp),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'request.form.complete_request_title'.tr,
        style: TextStyle(
          fontSize: 17.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
          height: 1.22,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  OFFER CARD
  // ─────────────────────────────────────────────

  Widget _buildOfferCard() {
    final offer = widget.offer;
    final supplierLogo = offer.supplier?.logoUrl;
    final baseUrl = ApiConstants.baseUrl;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: supplierLogo != null && supplierLogo.isNotEmpty
                    ? Image.network(
                        supplierLogo.startsWith('http')
                            ? supplierLogo
                            : '$baseUrl$supplierLogo',
                        width: 50.w,
                        height: 50.w,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _offerIconFallback(),
                      )
                    : _offerIconFallback(),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.name,
                        style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                            height: 1.22)),
                    Text(offer.supplier?.name ?? offer.marketTypeDisplay,
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textPrimary,
                            height: 1.22)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.primary100,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(offer.energyPriceDisplay,
                style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w400,
                    height: 1.22)),
          ),
          SizedBox(height: 10.h),
          _buildInfoRow(Icons.credit_card_outlined, AppColors.accentBlue,
              '${'request.form.payment_method_info'.tr}${offer.paymentMethodDisplay}'),
          SizedBox(height: 7.h),
          _buildInfoRow(Icons.check_circle_outline, AppColors.primary400,
              '${offer.contractDurationDisplay} · ${offer.target == 'business' ? 'request.form.target_business'.tr : 'request.form.target_residential'.tr}'),
          SizedBox(height: 12.h),
          _dividerLine(),
          SizedBox(height: 12.h),
          _buildOfferPriceSection(offer),
        ],
      ),
    );
  }

  Widget _buildOfferPriceSection(ApiOfferModel offer) {
    final savings = widget.estimatedSavings ?? offer.estimatedSavings;
    if (savings != null && savings > 0) {
      final savingsDisplay = formatMoney(savings);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('request.offers.estimated_savings'.tr,
              style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.22)),
          SizedBox(height: 4.h),
          Text(savingsDisplay,
              style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green200,
                  height: 1.22)),
        ],
      );
    }
    return Row(
      children: [
        Text(formatMoney(offer.fixedMonthlyFee),
            style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.green200,
                height: 1.22)),
        SizedBox(width: 8.w),
        Text('/mese',
            style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
                height: 1.22)),
      ],
    );
  }

  Widget _offerIconFallback() {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: AppColors.primary300,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(Icons.bolt, color: AppColors.background, size: 24.sp),
    );
  }

  Widget _buildInfoRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 15.sp, color: color),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textPrimary,
                  height: 1.22)),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  PERSONAL INFORMATION
  // ─────────────────────────────────────────────

  Widget _buildPersonalInfoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('request.form.personal_info_title'.tr),
              GestureDetector(
                onTap: _c.isSavingProfile ? null : _onPersonalInfoAction,
                child: Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: _editingPersonalInfo
                        ? AppColors.linkGreen
                        : AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    children: [
                      if (_c.isSavingProfile)
                        SizedBox(
                          width: 12.sp,
                          height: 12.sp,
                          child: const CircularProgressIndicator(
                            strokeWidth: 1.6,
                            color: AppColors.background,
                          ),
                        )
                      else
                        Icon(
                          _editingPersonalInfo
                              ? Icons.check_rounded
                              : Icons.edit_rounded,
                          color: AppColors.background,
                          size: 12.sp,
                        ),
                      SizedBox(width: 4.w),
                      Text(
                        _editingPersonalInfo ? 'common.save'.tr : 'request.form.edit'.tr,
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.background,
                            fontWeight: FontWeight.w600,
                            height: 1.22),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          // The two kinds of account are asked for different things here. A
          // private customer gives their own details; a company is a company
          // plus the person who signs for it, so its card carries the ragione
          // sociale and the VAT number alongside the owner's name and code.
          if (_editingPersonalInfo)
            ...(_c.isBusiness ? _businessEditFields() : _personalEditFields())
          else
            ...(_c.isBusiness ? _businessReadRows() : _personalReadRows()),
        ],
      ),
    );
  }

  List<Widget> _personalEditFields() => [
        Container(
          key: _firstNameKey,
          child: _buildEditField('request.form.first_name_field'.tr, _firstNameCtrl,
              errorText: _firstNameError,
              onChanged: (_) => setState(() => _firstNameError = null)),
        ),
        SizedBox(height: 10.h),
        Container(
          key: _lastNameKey,
          child: _buildEditField('request.form.last_name_field'.tr, _lastNameCtrl,
              errorText: _lastNameError,
              onChanged: (_) => setState(() => _lastNameError = null)),
        ),
        SizedBox(height: 10.h),
        // The customer's own code, kept on the profile: it is what a direct
        // debit on their own IBAN is filed against, and the payment section
        // reads it from here instead of asking for it a second time.
        Container(
          key: _ownerTaxCodeKey,
          child: _buildEditField(
              'request.form.tax_code_label'.tr, _ownerTaxCodeCtrl,
              errorText: _ownerTaxCodeError,
              maxLength: 16,
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) => setState(
                  () => _ownerTaxCodeError = _codiceFiscaleError(value))),
        ),
        SizedBox(height: 10.h),
        _buildEditField('request.form.email_field'.tr, _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            readOnly: true),
        SizedBox(height: 10.h),
        Container(
          key: _podKey,
          child: _buildEditField('request.form.pod_number_field'.tr, _podCtrl,
              errorText: _podError,
              onChanged: (_) => setState(() => _podError = null)),
        ),
        SizedBox(height: 10.h),
        _phoneEditField(),
      ];

  List<Widget> _personalReadRows() => [
        _personalRow('request.form.first_name_field'.tr, _c.firstName),
        _personalRow('request.form.last_name_field'.tr, _c.lastName),
        _personalRow('request.form.tax_code_label'.tr, _c.taxCode),
        _personalRow('request.form.email_field'.tr, _c.email),
        _personalRow('request.form.phone_field'.tr, _c.phone),
        _personalRow('request.form.pod_number_field'.tr, _c.podNumber),
      ];

  /// What a company is asked to confirm before its request is filed.
  ///
  /// Seven rows that identify the two parties to the contract — the company by
  /// its ragione sociale and Partita IVA, the owner who signs by their name and
  /// Codice Fiscale, and the two addresses it is reached at — then the phone
  /// number and the delivery point, which belong to this supply rather than to
  /// either party.
  ///
  /// Email and PEC are both here and are not the same address: a company signs
  /// in with whatever mailbox registered it, and is reached legally at its PEC.
  List<Widget> _businessReadRows() => [
        _personalRow('request.form.company_name_field'.tr, _c.companyName),
        _personalRow('request.form.vat_label'.tr, _c.partitaIva),
        _personalRow('request.form.owner_first_name_field'.tr, _c.firstName),
        _personalRow('request.form.owner_last_name_field'.tr, _c.lastName),
        _personalRow('request.form.owner_tax_code_field'.tr, _c.codiceFiscale),
        _personalRow('request.form.email_field'.tr, _c.email),
        _personalRow('request.form.pec_field'.tr, _c.pecEmail),
        _personalRow('request.form.phone_field'.tr, _c.phone),
        _personalRow('request.form.pod_number_field'.tr, _c.podNumber),
      ];

  List<Widget> _businessEditFields() => [
        Container(
          key: _companyNameKey,
          child: _buildEditField(
              'request.form.company_name_field'.tr, _companyNameCtrl,
              errorText: _companyNameError,
              maxLength: 255,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() => _companyNameError = null)),
        ),
        SizedBox(height: 10.h),
        Container(
          key: _vatKey,
          child: _buildEditField('request.form.vat_label'.tr, _vatCtrl,
              errorText: _vatError,
              keyboardType: TextInputType.number,
              maxLength: 11,
              onChanged: (value) =>
                  setState(() => _vatError = _partitaIvaError(value))),
        ),
        SizedBox(height: 10.h),
        Container(
          key: _firstNameKey,
          child: _buildEditField(
              'request.form.owner_first_name_field'.tr, _firstNameCtrl,
              errorText: _firstNameError,
              onChanged: (_) => setState(() => _firstNameError = null)),
        ),
        SizedBox(height: 10.h),
        Container(
          key: _lastNameKey,
          child: _buildEditField(
              'request.form.owner_last_name_field'.tr, _lastNameCtrl,
              errorText: _lastNameError,
              onChanged: (_) => setState(() => _lastNameError = null)),
        ),
        SizedBox(height: 10.h),
        Container(
          key: _ownerTaxCodeKey,
          child: _buildEditField(
              'request.form.owner_tax_code_field'.tr, _ownerTaxCodeCtrl,
              errorText: _ownerTaxCodeError,
              maxLength: 16,
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) => setState(
                  () => _ownerTaxCodeError = _codiceFiscaleError(value))),
        ),
        SizedBox(height: 10.h),
        // The address the account signs in with, and the only row here it
        // cannot change: it is the account's identity, not a contact detail.
        _buildEditField('request.form.email_field'.tr, _emailCtrl,
            keyboardType: TextInputType.emailAddress, readOnly: true),
        SizedBox(height: 10.h),
        Container(
          key: _pecKey,
          child: _buildEditField('request.form.pec_field'.tr, _pecCtrl,
              errorText: _pecError,
              maxLength: 255,
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) =>
                  setState(() => _pecError = _pecAddressError(value))),
        ),
        SizedBox(height: 10.h),
        _phoneEditField(),
        SizedBox(height: 10.h),
        Container(
          key: _podKey,
          child: _buildEditField('request.form.pod_number_field'.tr, _podCtrl,
              errorText: _podError,
              onChanged: (_) => setState(() => _podError = null)),
        ),
      ];

  /// The phone row, identical on both cards — same widget, same validator, same
  /// dial-code handling.
  Widget _phoneEditField() => Container(
        key: _phoneKey,
        child: PhoneTextField(
          labelText: 'request.form.phone_field'.tr,
          controller: _phoneCtrl,
          validator: validatePhone,
          externalLabel: true,
          fillColor: AppColors.shortcardbg,
          borderRadius: 10.r,
          showBorder: false,
          fontSize: 13.sp,
          errorText: _phoneError,
          onChanged: (_) => setState(() => _phoneError = null),
          onCountryChanged: (CountryCode code) {
            _phoneDialCode = code.dialCode ?? '+39';
            setState(() => _phoneError = null);
          },
        ),
      );

  /// Edit ⇄ Save for the personal information card. Saving writes the values to
  /// the user's profile, so what the customer corrects here is what Profile →
  /// Personal Data shows afterwards; the card stays open if the save fails.
  Future<void> _onPersonalInfoAction() async {
    FocusScope.of(context).unfocus();
    if (!_editingPersonalInfo) {
      setState(() {
        _firstNameError = null;
        _lastNameError = null;
        _podError = null;
        _phoneError = null;
        _companyNameError = null;
        _vatError = null;
        _ownerTaxCodeError = null;
        _pecError = null;
        _editingPersonalInfo = true;
      });
      return;
    }

    final isBusiness = _c.isBusiness;
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final pod = _podCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final company = _companyNameCtrl.text.trim();
    final vat = normalizeTaxId(_vatCtrl.text);
    final ownerTaxCode = normalizeTaxId(_ownerTaxCodeCtrl.text);
    final pec = _pecCtrl.text.trim();

    setState(() {
      // The company's card names the two people apart, so the message does too.
      _firstNameError = firstName.isEmpty
          ? (isBusiness
                  ? 'request.form.owner_first_name_required'
                  : 'request.form.first_name_required')
              .tr
          : null;
      _lastNameError = lastName.isEmpty
          ? (isBusiness
                  ? 'request.form.owner_last_name_required'
                  : 'request.form.last_name_required')
              .tr
          : null;
      _podError = pod.isEmpty ? 'request.form.pod_number_required'.tr : null;
      _phoneError = phone.isEmpty ? 'request.form.phone_required'.tr : null;
      if (!isBusiness) {
        // Optional in general, but a direct debit on the customer's own IBAN
        // is filed against it — with that chosen, a blank code is an error.
        _ownerTaxCodeError = ownerTaxCode.isEmpty && _needsAccountTaxId
            ? 'request.form.tax_code_required_hint'.tr
            : _codiceFiscaleError(ownerTaxCode);
      }
      if (isBusiness) {
        // Required: the company row cannot be written without it, and it is
        // the name the contract and the IBAN are registered to.
        _companyNameError =
            company.isEmpty ? 'request.form.company_name_required'.tr : null;
        // Required for the same reason it is at sign-up — it is what
        // identifies the company, and the direct debit is filed against it.
        _vatError = vat.isEmpty
            ? 'request.form.vat_required'.tr
            : _partitaIvaError(vat);
        // Optional, like a personal account's own code: only a value that was
        // typed and is wrong is flagged.
        _ownerTaxCodeError = _codiceFiscaleError(ownerTaxCode);
        _pecError = _pecAddressError(pec);
      }
    });

    // In the order the fields appear, so the customer is taken to the first
    // problem rather than to whichever branch of a nested ternary ran first.
    final errored = <(String?, GlobalKey)>[
      if (isBusiness) (_companyNameError, _companyNameKey),
      if (isBusiness) (_vatError, _vatKey),
      (_firstNameError, _firstNameKey),
      (_lastNameError, _lastNameKey),
      (_ownerTaxCodeError, _ownerTaxCodeKey),
      if (isBusiness) (_pecError, _pecKey),
      if (isBusiness) (_phoneError, _phoneKey),
      (_podError, _podKey),
      if (!isBusiness) (_phoneError, _phoneKey),
    ].where((e) => e.$1 != null);

    if (errored.isNotEmpty) {
      _scrollToKey(errored.first.$2);
      return;
    }

    final saved = await _c.savePersonalInfo(
      firstName: firstName,
      lastName: lastName,
      phone: toE164(_phoneDialCode, phone),
      podNumber: pod,
      companyName: isBusiness ? company : null,
      partitaIva: isBusiness ? vat : null,
      codiceFiscale: ownerTaxCode,
      pecEmail: isBusiness ? pec : null,
    );

    if (!mounted || !saved) return;

    // The server may have normalised the phone number — show what it stored.
    if (_c.phone.startsWith('+')) {
      final (dialCode, nationalNumber) = fromE164(_c.phone);
      _phoneDialCode = dialCode;
      _phoneCtrl.text = nationalNumber;
    }
    if (_c.ibanSameAsContract) {
      _holderFirstCtrl.text = _c.holderFirstName;
      _holderLastCtrl.text = _c.holderLastName;
      _holderTaxCtrl.text = _c.taxCode;
    }
    _ownerTaxCodeCtrl.text = _c.codiceFiscale;
    if (isBusiness) {
      // Show what the server stored, here and everywhere else the same values
      // appear. The Partita IVA is on this screen twice — here, and again in
      // Metodo di Pagamento as the code the mandate is filed against — so a
      // correction made in this card has to reach the other one, or the two
      // disagree and nothing tells the customer which was used.
      _companyNameCtrl.text = _c.companyName;
      _vatCtrl.text = _c.partitaIva;
      _pecCtrl.text = _c.pecEmail;
      // The invoice field defaults to the PEC, which may have just been given
      // for the first time — but never type over an address the customer has
      // already put there themselves.
      if (_c.invoiceEmail.trim().isEmpty) {
        _invoiceEmailCtrl.text = _c.defaultInvoiceEmail;
      }
    }
    setState(() => _editingPersonalInfo = false);
  }

  Widget _buildEditField(
      String label,
      TextEditingController ctrl, {
        TextInputType keyboardType = TextInputType.text,
        String? errorText,
        bool readOnly = false,
        int? maxLength,
        TextCapitalization textCapitalization = TextCapitalization.none,
        ValueChanged<String>? onChanged,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                height: 1.22)),
        SizedBox(height: 6.h),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? AppColors.primary50 : AppColors.shortcardbg,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: errorText != null ? AppColors.error : AppColors.shortcardbg,
              width: errorText != null ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            readOnly: readOnly,
            maxLength: maxLength,
            textCapitalization: textCapitalization,
            onChanged: onChanged,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(
                fontSize: 13.sp,
                color: readOnly ? AppColors.textSecondary : AppColors.textDark,
                fontWeight: FontWeight.w500,
                height: 1.22),
            decoration: InputDecoration(
              contentPadding:
              EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              border: InputBorder.none,
              isDense: true,
              counterText: '',
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 4.h, left: 4.w),
            child: Text(errorText,
                style: TextStyle(fontSize: 11.sp, color: AppColors.error, height: 1.22)),
          ),
      ],
    );
  }

  Widget _personalRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 9.h),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textPrimary,
                    height: 1.22)),
          ),
          Expanded(
            flex: 6,
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                    height: 1.22)),
          ),
        ],
      ),
    );
  }

  Widget _dividerLine() =>
      Divider(height: 1, thickness: 1, color: AppColors.divider);

  // ─────────────────────────────────────────────
  //  SUPPLY ADDRESS
  // ─────────────────────────────────────────────

  Widget _buildSupplyAddressCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('request.form.delivery_address'.tr),
          SizedBox(height: 12.h),

          // ── Address box ──
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined,
                    color: AppColors.primaryColor, size: 20.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          _c.supplyAddress.streetLine.isNotEmpty
                              ? _c.supplyAddress.streetLine
                              : 'request.form.address_missing'.tr,
                          style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: _c.supplyAddress.streetLine.isNotEmpty
                                  ? AppColors.textDark
                                  : AppColors.textSecondary,
                              height: 1.22)),
                      if (_c.supplyAddress.cityLine.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(_c.supplyAddress.cityLine,
                            style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textPrimary,
                                height: 1.22)),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    setState(() => _editingAddress = !_editingAddress);
                  },
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Icon(Icons.edit_outlined,
                        color: _editingAddress
                            ? AppColors.primaryColor
                            : AppColors.textDark,
                        size: 18.sp),
                  ),
                ),
              ],
            ),
          ),

          // The supply address is submitted with the case, so an incomplete one
          // blocks activation — say so here rather than at the bottom.
          if (!_c.supplyAddress.isComplete && !_editingAddress) ...[
            SizedBox(height: 8.h),
            _inlineWarning('request.form.complete_supply_address'.tr),
          ],

          // ── Inline address edit form ──
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _editingAddress
                ? Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: _buildAddressEditForm(),
            )
                : const SizedBox.shrink(),
          ),

          SizedBox(height: 14.h),

          Text(
              (_c.isBusiness
                      ? 'request.form.registered_office_matches_delivery'
                      : 'request.form.residential_matches_delivery')
                  .tr,
              style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  height: 1.4)),
          SizedBox(height: 10.h),

          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: _addressMatchError != null
                  ? Border.all(color: Colors.red, width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                    child: _addressOption('request.form.address_yes_same'.tr, AddressMatch.same)),
                SizedBox(width: 10.w),
                Expanded(
                    child: _addressOption(
                        'request.form.address_no_different'.tr, AddressMatch.different)),
              ],
            ),
          ),

          if (_addressMatchError != null) ...[
            SizedBox(height: 6.h),
            Text(
              _addressMatchError!,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.red,
                height: 1.22,
              ),
            ),
          ],

          // ── New residential form when "No" ──
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _c.addressMatch == AddressMatch.different
                ? Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: _buildNewResidentialForm(),
            )
                : const SizedBox.shrink(),
          ),

          if (_c.addressMatch == AddressMatch.different) ...[
            SizedBox(height: 12.h),
            _confirmAddressButton(
              confirmed: _residentialAddressConfirmed,
              onEdit: () => setState(() => _residentialAddressConfirmed = false),
              onConfirm: () {
                final address = _residential.value;
                final errors = address.validate();
                setState(() => _residentialErrors = errors);
                if (errors.hasErrors) return;
                _c.residentialAddress = address;
                setState(() => _residentialAddressConfirmed = true);
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Confirm / Edit toggle shared by the residence and shipping address forms,
  /// so both commit their values to the controller the same way.
  Widget _confirmAddressButton({
    required bool confirmed,
    required VoidCallback onConfirm,
    required VoidCallback onEdit,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46.h,
      child: ElevatedButton(
        onPressed: () {
          FocusScope.of(context).unfocus();
          if (confirmed) {
            onEdit();
          } else {
            onConfirm();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              confirmed ? AppColors.primary300 : AppColors.primaryColor,
          foregroundColor: AppColors.background,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        child: Text(
          confirmed ? 'request.form.edit'.tr : 'common.confirm'.tr,
          style: TextStyle(
              fontSize: 14.sp, fontWeight: FontWeight.w600, height: 1.22),
        ),
      ),
    );
  }

  Widget _inlineWarning(String message) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.yellowAlpha10,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.yellow100, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.yellow200, size: 14.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    fontSize: 11.sp, color: AppColors.textDark, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressEditForm() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('request.form.delivery_address'.tr,
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      height: 1.22)),
              _cardAction(
                onTap: _saveSupplyAddress,
                icon: Icons.check_rounded,
                label: 'common.save'.tr,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          AddressFormFields(
            group: _supply,
            errors: _supplyErrors,
            onChanged: () {
              // Keep the summary above the form in step with what is typed.
              _c.supplyAddress = _supply.value;
              setState(() => _supplyErrors = AddressErrors.none);
            },
          ),
        ],
      ),
    );
  }

  void _saveSupplyAddress() {
    FocusScope.of(context).unfocus();
    final address = _supply.value;
    final errors = address.validate();
    setState(() => _supplyErrors = errors);
    if (errors.hasErrors) return;
    _c.supplyAddress = address;
    setState(() => _editingAddress = false);
  }

  Widget _buildNewResidentialForm() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inlineWarning((_c.isBusiness
                  ? 'request.form.no_selection_info_business'
                  : 'request.form.no_selection_info')
              .tr),
          SizedBox(height: 14.h),
          Text(
              (_c.isBusiness
                      ? 'request.form.new_registered_office'
                      : 'request.form.new_residential_address')
                  .tr,
              style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  height: 1.22)),
          SizedBox(height: 12.h),
          AddressFormFields(
            group: _residential,
            errors: _residentialErrors,
            readOnly: _residentialAddressConfirmed,
            onChanged: () => setState(() {
              // Kept live, like the supply address: Confirm validates and locks
              // the fields, it is not what makes the value count.
              _c.residentialAddress = _residential.value;
              _residentialErrors = AddressErrors.none;
            }),
          ),
        ],
      ),
    );
  }

  Widget _addressTextField(
      TextEditingController ctrl, {
        String hint = '',
        TextInputType keyboardType = TextInputType.text,
        bool readOnly = false,
        ValueChanged<String>? onChanged,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.shortcardbg,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.shortcardbg, width: 1),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onChanged: onChanged,
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
            fontSize: 13.sp,
            color: readOnly ? AppColors.textSecondary : AppColors.textDark,
            fontWeight: FontWeight.w500,
            height: 1.22),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          TextStyle(fontSize: 13.sp, color: AppColors.textSecondary, height: 1.22),
          contentPadding:
          EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _addressOption(String label, AddressMatch match) {
    final isSelected = _c.addressMatch == match;
    return GestureDetector(
      onTap: () {
        _c.selectAddressMatch(match);
        setState(() {
          _residentialAddressConfirmed = false;
          _addressMatchError = null;
          _residentialErrors = AddressErrors.none;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary100
              : AppColors.background,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : AppColors.divider,
            width: 1.22,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18.w,
              height: 18.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primaryColor
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.textDark,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.circle, color: AppColors.background, size: 8.sp)
                  : null,
            ),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.textPrimary,
                      height: 1.22)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  IDENTITY VERIFICATION
  // ─────────────────────────────────────────────

  Widget _buildIdentityVerificationCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('request.form.identity_verification_title'.tr),
              if (_c.uploadedDocuments.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.linkGreen, size: 14.sp),
                    SizedBox(width: 3.w),
                    Text('${_c.uploadedDocuments.length} ${'request.form.files_selected'.tr}',
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.linkGreen,
                            fontWeight: FontWeight.w600,
                            height: 1.22)),
                  ],
                )
              else
                Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: Colors.red.shade400, size: 14.sp),
                    SizedBox(width: 3.w),
                    Text('request.form.required'.tr,
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.red.shade400,
                            fontWeight: FontWeight.w600,
                            height: 1.22)),
                  ],
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
              'request.form.id_document_instruction'.tr,
              style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textPrimary,
                  height: 1.5)),
          SizedBox(height: 14.h),
          if (_c.uploadedDocuments.isNotEmpty) ...[
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: _c.uploadedDocuments.asMap().entries.map((e) {
                final doc = e.value;
                final name = doc.fileName;
                return Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: AppColors.greenAlpha10,
                    borderRadius: BorderRadius.circular(20.r),
                    border:
                    Border.all(color: AppColors.linkGreen, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.insert_drive_file_outlined,
                          size: 12.sp, color: AppColors.linkGreen),
                      SizedBox(width: 4.w),
                      Text(
                        name.length > 16 ? '${name.substring(0, 16)}...' : name,
                        style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.linkGreen,
                            height: 1.22),
                      ),
                      SizedBox(width: 4.w),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _c.removeDocument(e.key),
                        child: Padding(
                          padding: EdgeInsets.all(4.w),
                          child: Icon(Icons.close_rounded,
                              size: 12.sp, color: AppColors.linkGreen),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 10.h),
          ],
          Row(
            children: [
              Expanded(
                child: _buildIdButton(
                  icon: Icons.photo_camera_rounded,
                  label: 'request.form.take_photo_button'.tr,
                  sublabel: 'request.form.take_photo_hint'.tr,
                  canUpload: _canAddDocument,
                  onTap: _takePhoto,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildIdButton(
                  icon: Icons.upload_rounded,
                  label: 'request.form.upload_file_button'.tr,
                  sublabel: 'request.form.upload_formats'.tr,
                  canUpload: _canAddDocument,
                  onTap: _pickFile,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdButton({
    required IconData icon,
    required String label,
    required String sublabel,
    required bool canUpload,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: canUpload ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: canUpload ? AppColors.background : AppColors.primary50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: canUpload
                ? AppColors.primaryColor.withOpacity(0.3)
                : AppColors.divider,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 26.sp,
                color: canUpload
                    ? AppColors.primaryColor
                    : AppColors.textSecondary),
            SizedBox(height: 6.h),
            Text(label,
                style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: canUpload
                        ? AppColors.textDark
                        : AppColors.textSecondary,
                    height: 1.22)),
            SizedBox(height: 2.h),
            Text(sublabel,
                style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.textSecondary,
                    height: 1.22)),
          ],
        ),
      ),
    );
  }

  bool get _canAddDocument =>
      _c.uploadedDocuments.length < CompleteRequestController.maxDocuments;

  Future<void> _pickFile() async {
    await _c.pickDocuments();
  }

  /// Opens the same multi-shot camera used for bill scanning, so the front
  /// and back can be taken one after the other in a single session.
  Future<void> _takePhoto() async {
    final paths =
        await Navigator.of(context, rootNavigator: true).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => MultiCaptureScreen(
          existingCount: _c.uploadedDocuments.length,
          maxCount: CompleteRequestController.maxDocuments,
          title: 'request.form.id_camera_title'.tr,
        ),
      ),
    );
    if (paths != null && paths.isNotEmpty) {
      _c.addCapturedDocuments(paths);
    }
  }


  // ─────────────────────────────────────────────
  //  PAYMENT METHOD
  // ─────────────────────────────────────────────

  Widget _buildPaymentMethodCard() {
    final isDirectDebit = _c.selectedPayment == PaymentMethod.directDebit;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('request.form.payment_method_title'.tr),
          SizedBox(height: 2.h),
          Text('request.form.payment_preference'.tr,
              style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textPrimary,
                  height: 1.22)),
          // Whose name and tax code the mandate carries is only asked once the
          // customer has said whose account the IBAN is — see the holder block
          // under the IBAN. A postal order needs neither.
          SizedBox(height: 14.h),

          // ── Payment options ──
          // Only what the chosen offer actually accepts is shown; an offer
          // limited to one method renders that single, pre-selected option.
          Text('request.form.choose_payment_method'.tr,
              style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  height: 1.22)),
          SizedBox(height: 10.h),
          if (widget.offer.supportsDirectDebit)
            _paymentOption(
              method: PaymentMethod.directDebit,
              title: 'request.payment.sdd_title'.tr,
              subtitle: 'request.payment.sdd_subtitle_full'.tr,
            ),
          if (widget.offer.supportsDirectDebit &&
              widget.offer.supportsPostalOrder)
            SizedBox(height: 8.h),
          if (widget.offer.supportsPostalOrder)
            _paymentOption(
              method: PaymentMethod.postalOrder,
              title: 'request.payment.postal_bill_title'.tr,
              subtitle: 'request.payment.postal_bill_subtitle_full'.tr,
            ),

          // ── Direct Debit extras (only when directDebit selected) ──
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: isDirectDebit
                ? Padding(
              padding: EdgeInsets.only(top: 14.h),
              child: _buildDirectDebitExtras(),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// SS-1: IBAN checkbox + Holder Information card
  Widget _buildDirectDebitExtras() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── IBAN Input Field ──
        Row(
          children: [
            Text(
              'request.form.iban_label'.tr,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                height: 1.22,
              ),
            ),
            Text(' *',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.error,
                height: 1.22,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.shortcardbg,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: _ibanError != null ? AppColors.error : AppColors.shortcardbg,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _ibanCtrl,
            textCapitalization: TextCapitalization.characters,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            textAlignVertical: TextAlignVertical.center,
            maxLength: 27,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
              height: 1.22,
            ),
            decoration: InputDecoration(
              hintText: 'request.form.iban_hint'.tr,
              hintStyle: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
                height: 1.22,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              border: InputBorder.none,
              isDense: true,
              counterText: '',
            ),
            onChanged: (value) {
              final cleaned = value.replaceAll(RegExp(r'\s'), '').toUpperCase();
              _c.iban = cleaned;
              setState(() {
                if (cleaned.isEmpty) {
                  _ibanError = null;
                } else if (!CompleteRequestController.isValidItalianIban(cleaned)) {
                  _ibanError = 'request.form.iban_error'.tr;
                } else {
                  _ibanError = null;
                }
              });
            },
          ),
        ),
        if (_ibanError != null)
          Padding(
            padding: EdgeInsets.only(top: 4.h, left: 4.w),
            child: Text(
              _ibanError!,
              style: TextStyle(fontSize: 11.sp, color: AppColors.error, height: 1.22),
            ),
          ),
        SizedBox(height: 14.h),

        // ── Yes, IBAN checkbox ──
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusScope.of(context).unfocus();
            setState(() {
              _ibanSameAsContract = !_ibanSameAsContract;
              _c.ibanSameAsContract = _ibanSameAsContract;
              // Same holder: the mandate carries the account's own name and
              // tax code, filled in from what the account already holds.
              // Different holder: a new person or company, so the fields open
              // empty rather than on the account's data.
              if (_ibanSameAsContract) {
                _prefillHolderFromAccount();
              } else {
                _clearHolderFields();
              }
              // The holder card is hidden while the box is ticked, and unticking
              // it reveals fields the customer has not touched yet — either way
              // there is no error left worth showing against them, and nothing
              // has been checked over yet.
              _holderInfoSaved = false;
              _holderInfoDirty = false;
              _holderFirstError = null;
              _holderLastError = null;
              _holderTaxError = null;
            });
          },
          child: Container(
            width: double.infinity,
            padding:
            EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: Row(
              children: [
                // checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: _ibanSameAsContract
                        ? AppColors.greenAlpha10
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(
                      color: _ibanSameAsContract
                          ? AppColors.linkGreen
                          : AppColors.primaryColor,
                      width: 1,
                    ),
                  ),
                  child: _ibanSameAsContract
                      ? Icon(Icons.check_rounded,
                      size: 13.sp, color: AppColors.linkGreen)
                      : null,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'request.form.iban_same_as_contract'.tr,
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                        height: 1.22),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Holder details: the account's own when ticked, new fields when not ──
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          child: Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: _ibanSameAsContract
                ? _buildContractHolderSummary()
                : _buildHolderInfoCard(),
          ),
        ),
      ],
    );
  }

  /// The account's own holder details, filled in automatically, for a mandate
  /// on the contract holder's own IBAN: name and Codice Fiscale for a private
  /// customer, ragione sociale and Partita IVA for a company.
  ///
  /// Read-only, always. The holder here is the account, so its details come
  /// from the profile; manual holder data is asked for only when the IBAN
  /// belongs to someone else. An account with no usable tax ID is sent to the
  /// personal information card to give it, rather than handed an empty field
  /// here to type something the profile should already hold.
  Widget _buildContractHolderSummary() {
    final taxLabel = _c.isBusiness
        ? 'request.form.vat_label'.tr
        : 'request.form.tax_code_label'.tr;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A company contracts as itself: the IBAN has to be registered to
          // the ragione sociale, not to the person signing.
          if (_c.isBusiness) ...[
            _personalRow(
                'request.form.company_name_field'.tr, _c.contractHolderName),
          ] else ...[
            _personalRow('request.form.first_name'.tr, _c.firstName),
            _dividerLine(),
            _personalRow('request.form.last_name'.tr, _c.lastName),
          ],
          _dividerLine(),
          if (_isAccountTaxValid)
            _personalRow(taxLabel, _c.taxCode)
          else
            _missingAccountTaxIdRow(taxLabel),
        ],
      ),
    );
  }

  bool get _isAccountTaxValid => isValidItalianTaxId(_c.taxCode);

  /// Whether the account's own tax ID is needed for this request: a direct
  /// debit on the contract holder's own IBAN is filed against it.
  bool get _needsAccountTaxId =>
      _c.selectedPayment == PaymentMethod.directDebit && _c.ibanSameAsContract;

  /// The tax-ID line of the holder summary when the account has no usable one:
  /// says so, and takes the customer to the one field that fills it.
  Widget _missingAccountTaxIdRow(String label) {
    final missing = _c.taxCode.trim().isEmpty;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 9.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textPrimary,
                        height: 1.22)),
              ),
              Icon(Icons.error_outline_rounded,
                  size: 16.sp, color: AppColors.error),
              SizedBox(width: 4.w),
              Text(
                (missing
                        ? 'request.form.holder_tax_id_missing'
                        : 'request.form.holder_tax_id_invalid')
                    .tr,
                style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                    height: 1.22),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openAccountTaxIdField,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (missing
                          ? 'request.form.holder_tax_id_add'
                          : 'request.form.holder_tax_id_fix')
                      .tr,
                  style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                      height: 1.22),
                ),
                SizedBox(width: 2.w),
                Icon(Icons.arrow_upward_rounded,
                    size: 14.sp, color: AppColors.primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the personal information card on the account's tax ID — the
  /// Partita IVA for a company, the Codice Fiscale for a private customer —
  /// with the reason it is needed, and scrolls to it.
  void _openAccountTaxIdField() {
    FocusScope.of(context).unfocus();
    setState(() {
      _editingPersonalInfo = true;
      if (_c.isBusiness) {
        _vatError = _vatCtrl.text.trim().isEmpty
            ? 'request.form.vat_required'.tr
            : _partitaIvaError(_vatCtrl.text);
      } else {
        _ownerTaxCodeError = _ownerTaxCodeCtrl.text.trim().isEmpty
            ? 'request.form.tax_code_required_hint'.tr
            : _codiceFiscaleError(_ownerTaxCodeCtrl.text);
      }
    });
    _scrollToKey(_c.isBusiness ? _vatKey : _ownerTaxCodeKey);
  }

  void _clearHolderFields() {
    _holderFirstCtrl.clear();
    _holderLastCtrl.clear();
    _holderTaxCtrl.clear();
    _c.holderFirstName = '';
    _c.holderLastName = '';
    _c.holderTaxCode = '';
  }

  /// Fills the holder block with whatever the account already holds: the
  /// customer's name and the account's tax ID. Fields the account has nothing
  /// for are left blank.
  void _prefillHolderFromAccount() {
    _holderFirstCtrl.text = _c.firstName;
    _holderLastCtrl.text = _c.lastName;
    _holderTaxCtrl.text = _c.taxCode;
    _c.holderFirstName = _c.firstName;
    _c.holderLastName = _c.lastName;
    _c.holderTaxCode = _c.taxCode;
  }

  /// SS-1 bottom half: Holder Information editable card
  Widget _buildHolderInfoCard() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('request.form.holder_info'.tr,
              style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  height: 1.22)),
          SizedBox(height: 12.h),
          _buildEditField('request.form.first_name'.tr, _holderFirstCtrl,
              errorText: _holderFirstError,
              readOnly: _holderInfoSaved,
              onChanged: (v) {
                _c.holderFirstName = v.trim();
                setState(() {
                  _holderInfoDirty = true;
                  _holderFirstError = v.trim().isEmpty
                      ? 'request.form.holder_first_name_required'.tr
                      : null;
                });
              }),
          SizedBox(height: 10.h),
          _buildEditField('request.form.last_name'.tr, _holderLastCtrl,
              errorText: _holderLastError,
              readOnly: _holderInfoSaved,
              onChanged: (v) {
                _c.holderLastName = v.trim();
                setState(() {
                  _holderInfoDirty = true;
                  _holderLastError = v.trim().isEmpty
                      ? 'request.form.holder_last_name_required'.tr
                      : null;
                });
              }),
          SizedBox(height: 10.h),
          _buildEditField(
              'request.form.holder_tax_id_label'.tr,
              _holderTaxCtrl,
              errorText: _holderTaxError,
              // A third-party holder may be a person or a company, so the
              // longer of the two forms is what the field has to allow.
              maxLength: 16,
              readOnly: _holderInfoSaved,
              textCapitalization: TextCapitalization.characters,
              onChanged: (v) {
                _c.holderTaxCode = v.trim();
                setState(() {
                  _holderInfoDirty = true;
                  _holderTaxError = _holderTaxIdError(v);
                });
              }),
          SizedBox(height: 14.h),
          if (_holderInfoSaved) ...[
            _holderSavedBanner(),
            SizedBox(height: 10.h),
          ],
          _HolderSaveButton(
            onTap: _onHolderInfoAction,
            saved: _holderInfoSaved,
            highlighted: !_holderInfoSaved && _holderInfoDirty,
          ),
        ],
      ),
    );
  }

  /// The "Details saved" line shown above the button once Save has gone
  /// through, so the customer sees the tap landed without scrolling for it.
  Widget _holderSavedBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.greenAlpha10,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.linkGreen, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: AppColors.linkGreen, size: 18.sp),
          SizedBox(width: 8.w),
          Text('request.form.holder_details_saved'.tr,
              style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.linkGreen,
                  fontWeight: FontWeight.w600,
                  height: 1.22)),
        ],
      ),
    );
  }

  /// Save ⇄ Edit for the third-party holder block.
  ///
  /// Saving does not send anything: these three values belong to the case and
  /// travel with it at activation. What it does is check them here, where the
  /// customer can still fix them, instead of letting a mistyped Codice Fiscale
  /// surface as a blocked Activate button four sections further down.
  void _onHolderInfoAction() {
    FocusScope.of(context).unfocus();

    if (_holderInfoSaved) {
      setState(() => _holderInfoSaved = false);
      return;
    }

    final firstName = _holderFirstCtrl.text.trim();
    final lastName = _holderLastCtrl.text.trim();
    final taxCode = _holderTaxCtrl.text.trim();

    _c.holderFirstName = firstName;
    _c.holderLastName = lastName;
    _c.holderTaxCode = taxCode;

    final firstError = firstName.isEmpty
        ? 'request.form.holder_first_name_required'.tr
        : null;
    final lastError =
        lastName.isEmpty ? 'request.form.holder_last_name_required'.tr : null;
    // Empty is an error here, unlike while typing: the customer has said they
    // are done, and a direct debit cannot be filed without the holder's code.
    final taxError = _c.isHolderTaxCodeValid
        ? null
        : (_holderTaxIdError(taxCode) ??
            'request.form.holder_tax_id_error'.tr);

    setState(() {
      _holderFirstError = firstError;
      _holderLastError = lastError;
      _holderTaxError = taxError;
      _holderInfoSaved =
          firstError == null && lastError == null && taxError == null;
      if (_holderInfoSaved) _holderInfoDirty = false;
    });
  }

  /// The green check-and-label control a card puts next to its title.
  ///
  /// Opaque and padded on purpose: the bare icon-plus-text row it replaces was
  /// only a few pixels tall and had a dead gap in the middle, so a tap that
  /// looked like a hit often was not one.
  Widget _cardAction({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.linkGreen, size: 14.sp),
            SizedBox(width: 3.w),
            Text(label,
                style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.linkGreen,
                    fontWeight: FontWeight.w600,
                    height: 1.22)),
          ],
        ),
      ),
    );
  }

  /// What to say about a Partita IVA a supplier would refuse, or null when
  /// there is nothing to say yet.
  ///
  /// Separate from [_holderTaxIdError], which takes either code. Here both codes are on screen at once — the company's VAT number and its
  /// owner's Codice Fiscale, one row apart — so each field is held to its own
  /// rule and names the other code as the other code rather than as invalid.
  String? _partitaIvaError(String value) {
    switch (partitaIvaProblem(value)) {
      case null:
        return null;
      case PartitaIvaProblem.codiceFiscale:
        return 'request.form.vat_tax_code_not_accepted'.tr;
      case PartitaIvaProblem.checkDigit:
      case PartitaIvaProblem.shape:
        return 'request.form.vat_error'.tr;
    }
  }

  /// The same, for the owner's Codice Fiscale on a business card.
  String? _codiceFiscaleError(String value) {
    switch (codiceFiscaleProblem(value)) {
      case null:
        return null;
      case CodiceFiscaleProblem.vatNumber:
        return 'request.form.tax_code_vat_not_accepted'.tr;
      case CodiceFiscaleProblem.checkCharacter:
        final expected = codiceFiscaleCheckCharacter(value);
        return 'request.form.tax_code_error_check'
            .trParams({'char': expected ?? ''});
      case CodiceFiscaleProblem.shape:
        return 'request.form.tax_code_error'.tr;
    }
  }

  /// The PEC is optional — a company that has not got one yet still switches,
  /// and its invoices fall back to the sign-in address — so only an address
  /// that was typed and is not one is flagged.
  String? _pecAddressError(String value) =>
      value.trim().isEmpty || CompleteRequestController.isValidEmail(value)
          ? null
          : 'request.form.pec_invalid'.tr;

  /// What to say about the direct debit holder's tax ID, or null when there is
  /// nothing to say yet.
  ///
  /// An untouched field is left alone — the customer has not finished with it,
  /// and the summary above the Activate button already says it is needed. This
  /// is the same restraint the IBAN field shows.
  ///
  /// Either form on either kind of account, whether or not the account is the
  /// holder: a Codice Fiscale or a Partita IVA, checked only for formal
  /// validity.
  String? _holderTaxIdError(String value) {
    switch (taxIdProblem(value)) {
      case null:
        return null;
      case TaxIdProblem.checkCharacter:
        // Fifteen of the sixteen characters are already right. Saying only
        // "invalid" sends the customer back to retype a code that was very
        // nearly correct; naming the last character points at the typo.
        final expected = codiceFiscaleCheckCharacter(value);
        return 'request.form.tax_code_error_check'.trParams({'char': expected ?? ''});
      case TaxIdProblem.checkDigit:
        return 'request.form.vat_error'.tr;
      case TaxIdProblem.shape:
        return 'request.form.holder_tax_id_error'.tr;
    }
  }

  Widget _paymentOption({
    required PaymentMethod method,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _c.selectedPayment == method;
    return GestureDetector(
      onTap: () => _c.selectPayment(method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary100
              : AppColors.background,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : AppColors.divider,
            width: 1.22,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primaryColor
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.textDark,
                  width: 1.22,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check_rounded, color: AppColors.background, size: 12.sp)
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                          height: 1.22)),
                  SizedBox(height: 2.h),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textPrimary,
                          height: 1.22)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  INVOICE DELIVERY METHOD
  // ─────────────────────────────────────────────

  Widget _buildInvoiceDeliveryCard() {
    final isDigital = _c.selectedInvoice == InvoiceMethod.digital;
    final isPaper = _c.selectedInvoice == InvoiceMethod.paper;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('request.form.invoice_delivery_title'.tr),
          SizedBox(height: 2.h),
          Text(
              'request.form.invoice_delivery_tip'.tr,
              style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textPrimary,
                  height: 1.5)),
          SizedBox(height: 12.h),

          _invoiceOption(
            method: InvoiceMethod.digital,
            title: 'request.invoice.digital_title'.tr,
            subtitle: 'request.invoice.digital_subtitle'.tr,
          ),
          SizedBox(height: 8.h),
          _invoiceOption(
            method: InvoiceMethod.paper,
            title: 'request.invoice.paper_title'.tr,
            subtitle: 'request.payment.postal_bill_subtitle_full'.tr,
          ),

          // ── Digital extras: pre-filled note + email field ──
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: isDigital
                ? Padding(
              padding: EdgeInsets.only(top: 14.h),
              child: _buildDigitalInvoiceExtras(),
            )
                : const SizedBox.shrink(),
          ),

          // ── Paper extras: delivery address Yes/No + sub-forms ──
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: isPaper
                ? Padding(
              padding: EdgeInsets.only(top: 14.h),
              child: _buildPaperInvoiceExtras(),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// SS-2: purple pre-filled note + email input
  Widget _buildDigitalInvoiceExtras() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Purple info chip
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
          decoration: BoxDecoration(
            color: AppColors.primary100,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            'request.form.prefilled_email'.tr,
            style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
                height: 1.22),
          ),
        ),
        SizedBox(height: 12.h),

        // Email label + field
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${(_c.isBusiness ? 'request.form.pec_for_invoice' : 'request.form.email_for_invoice').tr} ',
                style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    height: 1.22),
              ),
               TextSpan(
                text: '*',
                style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.error,
                    height: 1.22),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        _addressTextField(_invoiceEmailCtrl,
            hint: (_c.isBusiness
                    ? 'request.form.pec_invoice_hint'
                    : 'request.form.email_invoice_hint')
                .tr,
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              _c.invoiceEmail = value;
              setState(() {
                // An empty field falls back to the account email, so only flag
                // an address that was typed and is not one.
                _invoiceEmailError = value.trim().isEmpty ||
                        CompleteRequestController.isValidEmail(value)
                    ? null
                    : 'request.form.invoice_email_error'.tr;
              });
            }),
        if (_invoiceEmailError != null)
          Padding(
            padding: EdgeInsets.only(top: 4.h, left: 4.w),
            child: Text(_invoiceEmailError!,
                style: TextStyle(
                    fontSize: 11.sp, color: AppColors.error, height: 1.22)),
          ),
      ],
    );
  }

  /// SS-3/4/5: delivery address match question + sub-forms
  Widget _buildPaperInvoiceExtras() {
    final isYes = _c.invoiceAddressMatch == InvoiceAddressMatch.yes;
    final isNo = _c.invoiceAddressMatch == InvoiceAddressMatch.no;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('request.form.shipping_match_question'.tr,
            style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                height: 1.4)),
        SizedBox(height: 10.h),

        // Yes / No toggle
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: _invoiceAddressMatchError != null
                ? Border.all(color: AppColors.error, width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                  child: _invoiceAddressOption(
                      'request.form.yes'.tr, InvoiceAddressMatch.yes)),
              SizedBox(width: 10.w),
              Expanded(
                  child: _invoiceAddressOption(
                      'request.form.no'.tr, InvoiceAddressMatch.no)),
            ],
          ),
        ),

        if (_invoiceAddressMatchError != null) ...[
          SizedBox(height: 6.h),
          Text(_invoiceAddressMatchError!,
              style: TextStyle(
                  fontSize: 12.sp, color: AppColors.error, height: 1.22)),
        ],

        // ── Yes: pink address banner (SS-4) ──
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          child: isYes
              ? Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: _buildInvoiceYesBanner(),
          )
              : const SizedBox.shrink(),
        ),

        // ── No: full address form (SS-5) ──
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          child: isNo
              ? Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: _buildInvoiceNoForm(),
          )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// SS-4: pink address confirmation banner
  Widget _buildInvoiceYesBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: AppColors.redAlpha10,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.red100.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined,
              color: AppColors.red200, size: 16.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '${'request.invoice.destination_preview'.tr} ${_c.supplyAddress.formatted}',
              style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.red200,
                  fontWeight: FontWeight.w500,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  /// SS-5: full new shipping address form + Confirm Address button
  Widget _buildInvoiceNoForm() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // info banner
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.textDark, size: 14.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'request.form.enter_shipping_address'.tr,
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textPrimary,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          AddressFormFields(
            group: _shipping,
            errors: _shippingErrors,
            readOnly: _shippingAddressConfirmed,
            onChanged: () => setState(() {
              _c.shippingAddress = _shipping.value;
              _shippingErrors = AddressErrors.none;
            }),
          ),
          SizedBox(height: 16.h),

          _confirmAddressButton(
            confirmed: _shippingAddressConfirmed,
            onEdit: () => setState(() => _shippingAddressConfirmed = false),
            onConfirm: () {
              final address = _shipping.value;
              final errors = address.validate();
              setState(() => _shippingErrors = errors);
              if (errors.hasErrors) return;
              _c.shippingAddress = address;
              setState(() => _shippingAddressConfirmed = true);
            },
          ),
        ],
      ),
    );
  }

  Widget _invoiceOption({
    required InvoiceMethod method,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _c.selectedInvoice == method;
    return GestureDetector(
      onTap: () {
        // Switching to digital drops the shipping address in the controller, so
        // clear the matching screen state too — otherwise coming back to paper
        // shows locked fields whose value no longer counts.
        _c.selectInvoice(method);
        if (method == InvoiceMethod.digital) {
          setState(() {
            _shippingAddressConfirmed = false;
            _shippingErrors = AddressErrors.none;
            _invoiceAddressMatchError = null;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary100
              : AppColors.background,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : AppColors.divider,
            width: 1.22,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primaryColor
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.textDark,
                  width: 1.22,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check_rounded, color: AppColors.background, size: 12.sp)
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                          height: 1.22)),
                  SizedBox(height: 2.h),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textPrimary,
                          height: 1.22)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _invoiceAddressOption(String label, InvoiceAddressMatch match) {
    final isSelected = _c.invoiceAddressMatch == match;
    return GestureDetector(
      onTap: () {
        _c.selectInvoiceAddressMatch(match);
        setState(() {
          _shippingAddressConfirmed = false;
          _invoiceAddressMatchError = null;
          _shippingErrors = AddressErrors.none;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary100
              : AppColors.background,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : AppColors.divider,
            width: 1.22,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18.w,
              height: 18.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primaryColor
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.textDark,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.circle, color: AppColors.background, size: 8.sp)
                  : null,
            ),
            SizedBox(width: 6.w),
            Text(label,
                style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primaryColor
                        : AppColors.textPrimary,
                    height: 1.22)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  ALMOST THERE BANNER
  // ─────────────────────────────────────────────

  Widget _buildAlmostThereCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.greenAlpha10,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded,
              color: AppColors.linkGreen, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('request.form.almost_done'.tr,
                    style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        height: 1.22)),
                SizedBox(height: 4.h),
                Text(
                    'request.form.contract_send_info'.tr,
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textPrimary,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  ACTIVATE BUTTON
  // ─────────────────────────────────────────────

  Widget _buildNoBillWarning() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.yellowAlpha10,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.yellow100, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: AppColors.yellow200, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'request.form.no_bill_warning'.tr,
              style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textDark,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivateButton() {
    final missingPersonalFields = <String>[];
    if (_c.firstName.trim().isEmpty) missingPersonalFields.add('request.form.first_name_field'.tr);
    if (_c.lastName.trim().isEmpty) missingPersonalFields.add('request.form.last_name_field'.tr);
    if (_c.phone.trim().isEmpty) missingPersonalFields.add('request.form.phone_field'.tr);
    if (_c.podNumber.trim().isEmpty) missingPersonalFields.add('request.form.pod_number_field'.tr);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (missingPersonalFields.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14.sp, color: Colors.red.shade400),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    '${missingPersonalFields.join(', ')} ${missingPersonalFields.length == 1 ? 'is' : 'are'} required.',
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.red.shade400,
                        height: 1.22),
                  ),
                ),
              ],
            ),
          ),
        if (!_c.isAddressValid)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14.sp, color: Colors.red.shade400),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    'request.form.address_required_hint'.tr,
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.red.shade400,
                        height: 1.22),
                  ),
                ),
              ],
            ),
          ),
        if (_c.uploadedDocuments.isEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14.sp, color: Colors.red.shade400),
                SizedBox(width: 4.w),
                Text(
                  'request.form.identity_required_hint'.tr,
                  style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.red.shade400,
                      height: 1.22),
                ),
              ],
            ),
          ),
        if (_c.selectedPayment == PaymentMethod.directDebit &&
            !CompleteRequestController.isValidItalianIban(_c.iban))
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14.sp, color: Colors.red.shade400),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    'request.form.iban_required_hint'.tr,
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.red.shade400,
                        height: 1.22),
                  ),
                ),
              ],
            ),
          ),
        if (_c.selectedPayment == PaymentMethod.directDebit &&
            !_c.isHolderTaxCodeValid)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14.sp, color: Colors.red.shade400),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    _c.isBusiness
                        ? 'request.form.vat_required_hint'.tr
                        : 'request.form.tax_code_required_hint'.tr,
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.red.shade400,
                        height: 1.22),
                  ),
                ),
              ],
            ),
          ),
        if (_c.selectedInvoice == InvoiceMethod.digital &&
            !CompleteRequestController.isValidEmail(_c.effectiveInvoiceEmail))
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14.sp, color: Colors.red.shade400),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    'request.form.invoice_email_required_hint'.tr,
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.red.shade400,
                        height: 1.22),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 54.h,
          child: ElevatedButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              // `canActivate` is false while the request is in flight, so
              // without this a second tap sends the form scrolling off to a
              // "missing" field instead of doing nothing.
              if (_c.isSubmitting) return;
              if (_c.canActivate) {
                _c.activateOffer();
              } else {
                _scrollToFirstIncomplete();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _c.canActivate
                  ? AppColors.primaryColor
                  : AppColors.primary300,
              foregroundColor: AppColors.background,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r)),
            ),
            child: _c.isSubmitting
                ? SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text('request.form.activate_offer'.tr,
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.22)),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primaryColor, width: 1.22),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
            height: 1.22));
  }
}


/// The boxed Save / Edit button at the foot of the holder block.
///
/// It replaces a small green "Salva" link beside the title that read as a
/// status label, so customers typed the holder's details and moved on without
/// confirming them. Outlined while there is nothing new to confirm, filled and
/// gently pulsing once a field has been changed, and an Edit button after a
/// successful save.
class _HolderSaveButton extends StatefulWidget {
  const _HolderSaveButton({
    required this.onTap,
    required this.saved,
    required this.highlighted,
  });

  final VoidCallback onTap;
  final bool saved;
  final bool highlighted;

  @override
  State<_HolderSaveButton> createState() => _HolderSaveButtonState();
}

class _HolderSaveButtonState extends State<_HolderSaveButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _HolderSaveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlighted != widget.highlighted) _syncPulse();
  }

  void _syncPulse() {
    if (widget.highlighted) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filled = widget.highlighted;
    final foreground = filled ? AppColors.background : AppColors.primaryColor;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Transform.scale(
          scale: 1 + 0.02 * t,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            decoration: BoxDecoration(
              color: filled ? AppColors.primaryColor : AppColors.primary50,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.primaryColor, width: 1.2),
              boxShadow: filled
                  ? [
                      BoxShadow(
                        color: AppColors.primaryColor
                            .withValues(alpha: 0.18 + 0.22 * t),
                        blurRadius: 6 + 8 * t,
                        spreadRadius: 1 * t,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10.r),
          onTap: widget.onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 13.h, horizontal: 12.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.saved ? Icons.edit_outlined : Icons.check_rounded,
                  color: foreground,
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    widget.saved
                        ? 'request.form.edit_holder_details'.tr
                        : 'request.form.save_holder_details'.tr,
                    style: TextStyle(
                        fontSize: 14.sp,
                        color: foreground,
                        fontWeight: FontWeight.w700,
                        height: 1.22),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
