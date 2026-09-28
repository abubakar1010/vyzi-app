class ReferralCodeResponse {
  final String referralCode;
  final String shareLink;
  final ReferralStats stats;

  const ReferralCodeResponse({
    required this.referralCode,
    required this.shareLink,
    required this.stats,
  });

  factory ReferralCodeResponse.fromJson(Map<String, dynamic> json) {
    return ReferralCodeResponse(
      referralCode: json['referralCode'] as String? ?? '',
      shareLink: json['shareLink'] as String? ?? '',
      stats: ReferralStats.fromJson(
        json['stats'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class ReferralStats {
  final int totalInvites;
  final int registered;
  final int qualified;
  final int rewarded;
  final double totalEarnings;

  const ReferralStats({
    required this.totalInvites,
    required this.registered,
    required this.qualified,
    required this.rewarded,
    required this.totalEarnings,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      totalInvites: json['totalInvites'] as int? ?? 0,
      registered: json['registered'] as int? ?? 0,
      qualified: json['qualified'] as int? ?? 0,
      rewarded: json['rewarded'] as int? ?? 0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
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

  factory ReferralItem.fromJson(Map<String, dynamic> json) {
    return ReferralItem(
      id: json['id'] as String? ?? '',
      referralCode: json['referralCode'] as String? ?? '',
      referredEmail: json['referredEmail'] as String?,
      status: json['status'] as String? ?? 'pending',
      rewardAmount: (json['rewardAmount'] as num?)?.toDouble(),
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
