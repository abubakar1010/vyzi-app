class StaticPageModel {
  final String id;
  final String slug;
  final String title;
  final String content;
  final String locale;

  const StaticPageModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.content,
    required this.locale,
  });

  factory StaticPageModel.fromJson(Map<String, dynamic> json) {
    return StaticPageModel(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      locale: json['locale'] as String? ?? 'it',
    );
  }
}
