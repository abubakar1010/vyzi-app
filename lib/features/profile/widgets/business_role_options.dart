/// One selectable job role for a business account.
///
/// [value] is what gets stored — the English label, so the admin panel reads
/// the same thing whatever language the app was in — while [labelKey] is what
/// the user sees.
///
/// Offered by the personal-data screen, which is where a business account
/// sets the role and corrects it later. Registration does not ask for it, so a
/// business account starts with none until it is picked there.
class BusinessRoleOption {
  final String value;
  final String labelKey;

  const BusinessRoleOption(this.value, this.labelKey);
}

const List<BusinessRoleOption> kBusinessRoleOptions = [
  BusinessRoleOption('CEO / Founder', 'business_role.ceo'),
  BusinessRoleOption('Manager', 'business_role.manager'),
  BusinessRoleOption('Financial Manager', 'business_role.finance'),
  BusinessRoleOption('IT Administrator', 'business_role.it'),
  BusinessRoleOption('Other', 'business_role.other'),
];
