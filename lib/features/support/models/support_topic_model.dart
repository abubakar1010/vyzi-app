class SupportTopicModel {
  final String id;
  final String name;
  final String? description;
  final int sortOrder;
  final String? icon;

  const SupportTopicModel({
    required this.id,
    required this.name,
    this.description,
    this.sortOrder = 0,
    this.icon,
  });

  factory SupportTopicModel.fromJson(Map<String, dynamic> json) {
    return SupportTopicModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      icon: json['icon'] as String?,
    );
  }
}
