/// Where the signed-in user stands on one legal document.
enum LegalDocumentState {
  /// Accepted at the version currently published.
  accepted,

  /// Never accepted — a social sign-in, or an agreement introduced later.
  neverAccepted,

  /// Accepted, but a newer version has since been published.
  updateRequired,
}

LegalDocumentState _stateFromJson(String? raw) {
  switch (raw) {
    case 'accepted':
      return LegalDocumentState.accepted;
    case 'update_required':
      return LegalDocumentState.updateRequired;
    default:
      return LegalDocumentState.neverAccepted;
  }
}

/// A legal document plus this user's consent status for it.
///
/// [version] is the version currently in force, [acceptedVersion] the one the
/// user last agreed to. The two differing is exactly what makes the app ask
/// again — storing a bare "accepted" boolean could not express it.
class LegalDocumentModel {
  final String slug;
  final String title;
  final String version;
  final String locale;
  final String audience;
  final bool requiresAcceptance;
  final DateTime? publishedAt;
  final DateTime? updatedAt;

  /// Plain-language summary of what changed in this version, when the admin
  /// supplied one. Shown above the document in the re-acceptance prompt.
  final String? changeSummary;

  /// Full HTML. Present on `/legal/pending`, omitted by `/legal/documents`.
  final String? content;

  final String? acceptedVersion;
  final DateTime? acceptedAt;
  final LegalDocumentState state;
  final bool needsAcceptance;

  const LegalDocumentModel({
    required this.slug,
    required this.title,
    required this.version,
    required this.locale,
    required this.audience,
    required this.requiresAcceptance,
    required this.state,
    required this.needsAcceptance,
    this.publishedAt,
    this.updatedAt,
    this.changeSummary,
    this.content,
    this.acceptedVersion,
    this.acceptedAt,
  });

  /// True when the user held an older version — the copy shown differs between
  /// "please review our updated terms" and a first-time ask.
  bool get isUpdate => state == LegalDocumentState.updateRequired;

  factory LegalDocumentModel.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic value) =>
        value is String ? DateTime.tryParse(value) : null;

    final summary = json['changeSummary'] as String?;

    return LegalDocumentModel(
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      version: json['version'] as String? ?? '1.0',
      locale: json['locale'] as String? ?? 'it',
      audience: json['audience'] as String? ?? 'all',
      requiresAcceptance: json['requiresAcceptance'] as bool? ?? true,
      publishedAt: parse(json['publishedAt']),
      updatedAt: parse(json['updatedAt']),
      changeSummary:
          (summary == null || summary.trim().isEmpty) ? null : summary.trim(),
      content: json['content'] as String?,
      acceptedVersion: json['acceptedVersion'] as String?,
      acceptedAt: parse(json['acceptedAt']),
      state: _stateFromJson(json['state'] as String?),
      needsAcceptance: json['needsAcceptance'] as bool? ?? false,
    );
  }

  /// The payload `/legal/accept` expects — the version the user was actually
  /// shown, so the server can reject a screen left open across a publish.
  Map<String, dynamic> toAcceptancePayload() => {
        'slug': slug,
        'version': version,
        'locale': locale,
      };
}
