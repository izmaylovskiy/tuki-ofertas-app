class Store {
  final int id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? websiteUrl;
  final bool isActive;
  final int productCount;  // Добавлено!

  Store({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.websiteUrl,
    this.isActive = true,
    this.productCount = 0,  // Добавлено!
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      logoUrl: json['logo_url'],
      websiteUrl: json['website_url'],
      isActive: json['is_active'] ?? true,
      productCount: json['product_count'] ?? 0,  // Добавлено!
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'logo_url': logoUrl,
      'website_url': websiteUrl,
      'is_active': isActive,
      'product_count': productCount,  // Добавлено!
    };
  }
}
