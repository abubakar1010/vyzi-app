import 'package:flutter_test/flutter_test.dart';
import 'package:vyzi/features/request/models/case_model.dart';

Map<String, dynamic> _doc(
  String id, {
  String? rejectedAt,
  String? reason,
  String? replaces,
}) =>
    {
      'id': id,
      'fileName': '$id.jpg',
      'documentType': 'identity_document',
      'verified': false,
      'rejectedAt': rejectedAt,
      'rejectionReason': reason,
      'rejectionNote': null,
      'replacesDocumentId': replaces,
    };

CaseModel _case(List<Map<String, dynamic>> documents) => CaseModel.fromJson({
      'id': 'case-1',
      'status': 'offer_accepted',
      'createdAt': '2026-09-28T10:00:00.000Z',
      'documents': documents,
    });

void main() {
  test('a rejected document with no replacement is awaiting one', () {
    final c = _case([
      _doc('a', rejectedAt: '2026-09-29T09:00:00.000Z', reason: 'expired'),
      _doc('b'),
    ]);

    expect(c.documentsAwaitingReplacement.map((d) => d.id), ['a']);
    expect(c.documentsAwaitingReplacement.single.rejectionReason, 'expired');
  });

  test('a replacement upload clears it, however many files it took', () {
    final c = _case([
      _doc('front', replaces: 'a'),
      _doc('back', replaces: 'a'),
      _doc('a', rejectedAt: '2026-09-29T09:00:00.000Z', reason: 'incomplete'),
    ]);

    expect(c.documentsAwaitingReplacement, isEmpty);
  });

  test('a case without documents, or an older payload without the list', () {
    expect(_case([]).documentsAwaitingReplacement, isEmpty);
    expect(
      CaseModel.fromJson({'id': 'x', 'status': 'offer_accepted', 'createdAt': ''})
          .documents,
      isEmpty,
    );
  });
}
