import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vyzi/core/services/deep_link_service.dart';
import 'package:vyzi/core/services/referral_service.dart';
import 'package:vyzi/core/services/storage_service.dart';

const _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

/// Answers the claim without a network, counting how often it was asked.
class _FakeReferralService extends ReferralService {
  _FakeReferralService(this._answer);
  final Future<String?> Function() _answer;
  int calls = 0;

  @override
  Future<String?> claimDeferredReferral() {
    calls++;
    return _answer();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel,
            (call) async => call.method == 'readAll' ? <String, String>{} : null);
    storage = StorageService();
    await storage.init();
    Get.put<StorageService>(storage, permanent: true);
  });

  tearDown(Get.reset);

  test('a code claimed on first launch becomes the pending referral', () async {
    final links = DeepLinkService();
    final service = _FakeReferralService(() async => 'ab3kx7wn');

    await links.claimDeferredReferral(service: service);

    expect(links.pendingReferralCode, 'AB3KX7WN');
    expect(storage.getString(StorageKeys.pendingReferralCode), 'AB3KX7WN');
  });

  test('asks only once per install, whatever the answer', () async {
    final links = DeepLinkService();
    final service = _FakeReferralService(() async => null);

    await links.claimDeferredReferral(service: service);
    await links.claimDeferredReferral(service: service);

    expect(service.calls, 1);
    expect(links.pendingReferralCode, isNull);
  });

  test('tries again next launch when the network failed', () async {
    final links = DeepLinkService();
    final failing = _FakeReferralService(() async => throw Exception('offline'));

    await links.claimDeferredReferral(service: failing);

    expect(storage.getBool(StorageKeys.deferredReferralChecked), isNot(true));
  });
}
