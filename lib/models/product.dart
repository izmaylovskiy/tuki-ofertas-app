class Product {
  final int id;
  final String name;
  final String? barcode;
  final int? categoryId;
  final String? categoryName;
  final String? imageUrl;
  final String? unit;
  final List<ProductPrice> prices;

  Product({
    required this.id,
    required this.name,
    this.barcode,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.unit,
    this.prices = const [],
  });

  /// Проверка что у товара есть валидные цены
  bool get hasValidPrices {
    if (prices.isEmpty) return false;
    return prices.any((p) => p.isValid);
  }

  /// Минимальная цена среди всех магазинов (только валидные)
  double? get minPrice {
    final validPrices = prices.where((p) => p.isValid).toList();
    if (validPrices.isEmpty) return null;
    return validPrices.map((p) => p.effectivePrice).reduce((a, b) => a < b ? a : b);
  }

  // Лучшая цена среди всех магазинов
  ProductPrice? get bestPrice {
    final validPrices = prices.where((p) => p.isValid).toList();
    if (validPrices.isEmpty) return null;
    return validPrices.reduce((a, b) => 
      a.effectivePrice < b.effectivePrice ? a : b
    );
  }

  // Максимальная скидка
  int? get maxDiscount {
    final validPrices = prices.where((p) => p.isValid).toList();
    if (validPrices.isEmpty) return null;
    final discounts = validPrices
        .where((p) => p.discountPercent != null && p.discountPercent! > 0)
        .map((p) => p.discountPercent!);
    if (discounts.isEmpty) return null;
    return discounts.reduce((a, b) => a > b ? a : b);
  }

  // Есть ли скидка
  bool get hasDiscount => maxDiscount != null && maxDiscount! > 0;

  // Список магазинов где есть акция
  List<String> get storesWithPromo {
    return prices
        .where((p) => p.hasPromo && p.isValid)
        .map((p) => p.storeSlug)
        .toList();
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      barcode: json['barcode'],
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      imageUrl: json['image_url'],
      unit: json['unit'],
      prices: json['prices'] != null
          ? (json['prices'] as List)
              .map((e) => ProductPrice.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'category_id': categoryId,
      'category_name': categoryName,
      'image_url': imageUrl,
      'unit': unit,
      'prices': prices.map((e) => e.toJson()).toList(),
    };
  }
}

class ProductPrice {
  final int id;
  final String storeSlug;
  final String storeName;
  final double? regularPrice;
  final double? promoPrice;
  final int? discountPercent;
  final String? promoDescription;
  final DateTime? validFrom;
  final DateTime? validUntil;

  ProductPrice({
    required this.id,
    required this.storeSlug,
    required this.storeName,
    this.regularPrice,
    this.promoPrice,
    this.discountPercent,
    this.promoDescription,
    this.validFrom,
    this.validUntil,
  });

  /// Проверка что цена валидна (не null и > 0)
  bool get isValid {
    final price = effectivePrice;
    return price > 0;
  }

  /// Эффективная цена (промо или обычная)
  double get effectivePrice => promoPrice ?? regularPrice ?? 0;

  /// Есть ли промо-цена
  bool get hasPromo => 
      promoPrice != null && 
      promoPrice! > 0 &&
      regularPrice != null &&
      promoPrice! < regularPrice!;

  factory ProductPrice.fromJson(Map<String, dynamic> json) {
    return ProductPrice(
      id: json['id'],
      storeSlug: json['store_slug'],
      storeName: json['store_name'],
      regularPrice: json['regular_price']?.toDouble(),
      promoPrice: json['promo_price']?.toDouble(),
      discountPercent: json['discount_percent'],
      promoDescription: json['promo_description'],
      validFrom: json['valid_from'] != null 
          ? DateTime.parse(json['valid_from']) 
          : null,
      validUntil: json['valid_until'] != null 
          ? DateTime.parse(json['valid_until']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_slug': storeSlug,
      'store_name': storeName,
      'regular_price': regularPrice,
      'promo_price': promoPrice,
      'discount_percent': discountPercent,
      'promo_description': promoDescription,
      'valid_from': validFrom?.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
    };
  }
}
