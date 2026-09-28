import 'package:flutter_test/flutter_test.dart';
import 'package:vyzi/features/legal/models/legal_document_model.dart';

Map<String, dynamic> json({
  String version = '2.1',
  String? acceptedVersion,
  String? acceptedAt,
  String state = 'never_accepted',
  bool needsAcceptance = true,
  String? changeSummary,
}) =>
    {
      'slug': 'terms-conditions',
      'title': 'Termini e Condizioni',
      'version': version,
      'locale': 'it',
      'audience': 'all',
      'requiresAcceptance': true,
      'publishedAt': '2026-08-20T09:00:00.000Z',
      'updatedAt': '2026-08-20T09:00:00.000Z',
      'changeSummary': changeSummary,
      'content': '<p>terms</p>',
      'acceptedVersion': acceptedVersion,
      'acceptedAt': acceptedAt,
      'state': state,
      'needsAcceptance': needsAcceptance,
    };

void main() {
  group('LegalDocumentModel', () {
    test('reads a document the user has never accepted', () {
      final doc = LegalDocumentModel.fromJson(json());

      expect(doc.slug, 'terms-conditions');
      expect(doc.version, '2.1');
      expect(doc.acceptedVersion, isNull);
      expect(doc.state, LegalDocumentState.neverAccepted);
      expect(doc.needsAcceptance, isTrue);
      expect(doc.isUpdate, isFalse);
    });

    test('distinguishes an update from a first-time ask', () {
      // The prompt says "replaces version 2.0" only in this case; a first-time
      // ask has no earlier version to name.
      final doc = LegalDocumentModel.fromJson(json(
        state: 'update_required',
        acceptedVersion: '2.0',
        acceptedAt: '2026-03-02T11:24:00.000Z',
      ));

      expect(doc.isUpdate, isTrue);
      expect(doc.acceptedVersion, '2.0');
      expect(doc.acceptedAt, isNotNull);
      expect(doc.needsAcceptance, isTrue);
    });

    test('reads a document that is fully accepted', () {
      final doc = LegalDocumentModel.fromJson(json(
        state: 'accepted',
        acceptedVersion: '2.1',
        acceptedAt: '2026-08-20T12:00:00.000Z',
        needsAcceptance: false,
      ));

      expect(doc.state, LegalDocumentState.accepted);
      expect(doc.needsAcceptance, isFalse);
      expect(doc.isUpdate, isFalse);
    });

    test('treats a blank change summary as absent', () {
      // An admin who saves the field empty must not produce an empty
      // "What's changed" card above the document.
      expect(
        LegalDocumentModel.fromJson(json(changeSummary: '   ')).changeSummary,
        isNull,
      );
      expect(
        LegalDocumentModel.fromJson(json(changeSummary: 'Shorter notice.'))
            .changeSummary,
        'Shorter notice.',
      );
    });

    test('sends back the version it was shown, so the server can reject a stale screen', () {
      final doc = LegalDocumentModel.fromJson(json(version: '2.1'));

      expect(doc.toAcceptancePayload(), {
        'slug': 'terms-conditions',
        'version': '2.1',
        'locale': 'it',
      });
    });

    test('survives a response missing every optional field', () {
      final doc = LegalDocumentModel.fromJson({'slug': 'privacy-policy'});

      expect(doc.version, '1.0');
      expect(doc.locale, 'it');
      expect(doc.state, LegalDocumentState.neverAccepted);
      expect(doc.needsAcceptance, isFalse);
      expect(doc.content, isNull);
    });
  });
}
