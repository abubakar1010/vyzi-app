import 'package:flutter_test/flutter_test.dart';
import 'package:vyzi/features/profile/invite_friends/models/referral_model.dart';

void main() {
  test('reads the configured rewards, welcome reward and funnel stats', () {
    final res = ReferralCodeResponse.fromJson({
      'referralCode': 'AB3KX7WN',
      'shareLink': 'https://api.vyzi.it/r/AB3KX7WN',
      'rewards': {'referrerAmount': 15, 'friendAmount': 5},
      'welcomeReward': {'amount': 5, 'status': 'credited'},
      'stats': {
        'totalInvites': 8,
        'pending': 1,
        'registered': 6,
        'qualified': 4,
        'rewarded': 3,
        'expired': 1,
        'totalEarnings': 45,
      },
    });

    expect(res.rewards.referrerAmount, 15);
    expect(res.rewards.friendAmount, 5);
    expect(res.welcomeReward!.isCredited, isTrue);
    expect(res.stats.registered, 6);
    expect(res.stats.qualified, 4);
    expect(res.stats.totalEarnings, 45);
  });

  test('a user nobody referred has no welcome reward', () {
    final res = ReferralCodeResponse.fromJson({'welcomeReward': null});
    expect(res.welcomeReward, isNull);
  });

  test('parses a Postgres decimal sent as a string', () {
    // TypeORM returns decimal columns as strings; a plain `as num` cast threw.
    final item = ReferralItem.fromJson({
      'id': 'r1',
      'status': 'rewarded',
      'rewardAmount': '10.00',
      'createdAt': '2026-10-01T10:00:00.000Z',
      'referredUser': {'id': 'u1', 'firstName': 'Giulia', 'lastName': 'Bianchi', 'email': 'g@b.it'},
    });

    expect(item.rewardAmount, 10.0);
    expect(item.displayName, 'Giulia Bianchi');
  });

  test('falls back to the invited address before the friend signs up', () {
    final item = ReferralItem.fromJson({
      'id': 'r2',
      'status': 'pending',
      'referredEmail': 'friend@email.com',
      'createdAt': '2026-10-01T10:00:00.000Z',
    });

    expect(item.displayName, 'friend@email.com');
  });
}
