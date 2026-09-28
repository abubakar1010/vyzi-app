class FaqModel {
  final String id;
  final String category;
  final String question;
  final String answer;
  final int sortOrder;
  final bool isActive;
  final String locale;
  final String targetAudience;
  final String createdAt;
  final String updatedAt;

  const FaqModel({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.sortOrder,
    required this.isActive,
    required this.locale,
    required this.targetAudience,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      locale: json['locale'] as String? ?? 'it',
      targetAudience: json['targetAudience'] as String? ?? 'both',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}
