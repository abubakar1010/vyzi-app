import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/localization/app_translations.dart';
import 'package:vyzi/features/activation_request/models/activation_request_model.dart';
import 'package:vyzi/features/request/models/case_model.dart';

ActivationRequestModel _request(String status) => ActivationRequestModel.fromJson({
      'id': 'case-1',
      'caseType': 'takeover',
      'energyType': 'gas',
      'status': status,
    });

void main() {
  group('the steps a customer sees', () {
    test('everything before the contract is the first step', () {
      for (final status in ['new', 'in_progress', 'documents_pending']) {
        expect(_request(status).stepsReached(contractSent: false), 0, reason: status);
      }
    });

    test('each later status sits on its own step', () {
      expect(_request('contract_sent').stepsReached(contractSent: true), 1);
      expect(_request('awaiting_activation').stepsReached(contractSent: true), 2);
      expect(_request('activated').stepsReached(contractSent: true), 4);
    });

    test('a closed request keeps the steps it reached', () {
      expect(_request('rejected').stepsReached(contractSent: false), 1);
      expect(_request('cancelled').stepsReached(contractSent: true), 2);
      expect(_request('terminated').stepsReached(contractSent: true), 4);
    });

    test('only the ended statuses count as closed', () {
      for (final status in ['rejected', 'cancelled', 'terminated']) {
        expect(_request(status).isClosed, isTrue, reason: status);
      }
      expect(_request('contract_sent').isClosed, isFalse);
    });

    test('the contract shows once it has been sent, and not after a close', () {
      expect(_request('in_progress').showsContract, isFalse);
      expect(_request('contract_sent').showsContract, isTrue);
      expect(_request('awaiting_activation').showsContract, isTrue);
      expect(_request('rejected').showsContract, isFalse);
    });
  });

  test('every status reads in Italian, never as a raw key', () {
    final italian = AppTranslations().keys['it_IT']!;
    for (final status in [
      'new',
      'in_progress',
      'documents_pending',
      'contract_sent',
      'awaiting_activation',
      'activated',
      'rejected',
      'cancelled',
      'terminated',
    ]) {
      expect(italian['activation_request.status.$status'], isNotNull, reason: status);
    }
    expect(italian['case.status.terminated'], isNotNull);
  });

  test('the contract files are picked out of the case documents', () {
    Get.locale = const Locale('it', 'IT');
    final switchCase = CaseModel.fromJson({
      'id': 'case-1',
      'status': 'contract_sent',
      'createdAt': '2026-11-01T10:00:00Z',
      'documents': [
        {'id': 'd1', 'fileName': 'id.pdf', 'documentType': 'identity_document'},
        {'id': 'd2', 'fileName': 'contratto.pdf', 'documentType': 'contract', 'fileUrl': '/uploads/c.pdf'},
      ],
    });

    expect(switchCase.contractDocuments.map((d) => d.id), ['d2']);
    expect(switchCase.contractDocuments.single.fileUrl, '/uploads/c.pdf');
  });
}
