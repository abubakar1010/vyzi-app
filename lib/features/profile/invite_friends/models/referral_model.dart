/// Money from the API. Postgres decimals arrive as strings (`"10.00"`), while
/// computed totals arrive as numbers; both are accepted.
double? parseApiMoney(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class ReferralCodeResponse {
  final String referralCode;
  final String shareLink;
  final ReferralRewards rewards;

  /// The user's own reward for joining through someone's invite; null when
  /// nobody referred them.
  final WelcomeReward? welcomeReward;
  final ReferralStats stats;

  const ReferralCodeResponse({
    required this.referralCode,
    required this.shareLink,
    required this.rewards,
    this.welcomeReward,
    required this.stats,
  });

  factory ReferralCodeResponse.fromJson(Map<String, dynamic> json) {
    final welcome = json['welcomeReward'];
    return ReferralCodeResponse(
      referralCode: json['referralCode'] as String? ?? '',
      shareLink: json['shareLink'] as String? ?? '',
      rewards: ReferralRewards.fromJson(
        json['rewards'] as Map<String, dynamic>? ?? {},
      ),
      welcomeReward: welcome is Map<String, dynamic>
          ? WelcomeReward.fromJson(welcome)
          : null,
      stats: ReferralStats.fromJson(
        json['stats'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

/// The amounts the programme pays, configured on the server.
class ReferralRewards {
  final double referrerAmount;
  final double friendAmount;

  const ReferralRewards({
    required this.referrerAmount,
    required this.friendAmount,
  });

  factory ReferralRewards.fromJson(Map<String, dynamic> json) {
    return ReferralRewards(
      referrerAmount: parseApiMoney(json['referrerAmount']) ?? 0,
      friendAmount: parseApiMoney(json['friendAmount']) ?? 0,
    );
  }
}

class WelcomeReward {
  final double amount;

  /// `pending` until the user's first switch goes live and is paid, then
  /// `credited`.
  final String status;

  const WelcomeReward({required this.amount, required this.status});

  bool get isCredited => status == 'credited';

  factory WelcomeReward.fromJson(Map<String, dynamic> json) {
    return WelcomeReward(
      amount: parseApiMoney(json['amount']) ?? 0,
      status: json['status'] as String? ?? 'pending',
    );
  }
}

/// A funnel: each stage counts every referral that reached it, so
/// [registered] includes the friends who went on to qualify or be rewarded.
class ReferralStats {
  final int totalInvites;
  final int pending;
  final int registered;
  final int qualified;
  final int rewarded;
  final int expired;
  final double totalEarnings;

  const ReferralStats({
    required this.totalInvites,
    this.pending = 0,
    required this.registered,
    required this.qualified,
    required this.rewarded,
    this.expired = 0,
    required this.totalEarnings,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      totalInvites: json['totalInvites'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      registered: json['registered'] as int? ?? 0,
      qualified: json['qualified'] as int? ?? 0,
      rewarded: json['rewarded'] as int? ?? 0,
      expired: json['expired'] as int? ?? 0,
      totalEarnings: parseApiMoney(json['totalEarnings']) ?? 0.0,
    );
  }
}

class ReferralItem {
  final String id;
  final String referralCode;
  final String? referredEmail;
  final String status;
  final double? rewardAmount;
  final String? expiresAt;
  final String createdAt;
  final ReferredUser? referredUser;

  const ReferralItem({
    required this.id,
    required this.referralCode,
    this.referredEmail,
    required this.status,
    this.rewardAmount,
    this.expiresAt,
    required this.createdAt,
    this.referredUser,
  });

  /// The friend's name when they signed up, otherwise the invited address.
  String get displayName {
    final user = referredUser;
    if (user != null) {
      final name = '${user.firstName} ${user.lastName}'.trim();
      if (name.isNotEmpty) return name;
      if (user.email.isNotEmpty) return user.email;
    }
    return referredEmail ?? '';
  }

  factory ReferralItem.fromJson(Map<String, dynamic> json) {
    return ReferralItem(
      id: json['id'] as String? ?? '',
      referralCode: json['referralCode'] as String? ?? '',
      referredEmail: json['referredEmail'] as String?,
      status: json['status'] as String? ?? 'pending',
      rewardAmount: parseApiMoney(json['rewardAmount']),
      expiresAt: json['expiresAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      referredUser: json['referredUser'] != null
          ? ReferredUser.fromJson(
              json['referredUser'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class ReferredUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  const ReferredUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory ReferredUser.fromJson(Map<String, dynamic> json) {
    return ReferredUser(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}
