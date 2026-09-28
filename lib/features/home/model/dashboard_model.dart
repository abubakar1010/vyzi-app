class UserDashboardModel {
  final int totalCases;
  final int activeContracts;
  final PotentialSavingsModel potentialSavings;

  const UserDashboardModel({
    required this.totalCases,
    required this.activeContracts,
    required this.potentialSavings,
  });

  factory UserDashboardModel.fromJson(Map<String, dynamic> json) {
    return UserDashboardModel(
      totalCases: json['totalCases'] as int? ?? 0,
      activeContracts: json['activeContracts'] as int? ?? 0,
      potentialSavings: PotentialSavingsModel.fromJson(
        json['potentialSavings'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class PotentialSavingsModel {
  final double totalSavings;
  final int activeUtilities;

  const PotentialSavingsModel({
    required this.totalSavings,
    required this.activeUtilities,
  });

  factory PotentialSavingsModel.fromJson(Map<String, dynamic> json) {
    return PotentialSavingsModel(
      totalSavings: (json['totalSavings'] as num?)?.toDouble() ?? 0.0,
      activeUtilities: json['activeUtilities'] as int? ?? 0,
    );
  }
}
