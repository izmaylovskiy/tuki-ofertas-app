import 'product.dart';

class ShoppingList {
  final int id;
  final String name;
  final DateTime createdAt;
  final List<ShoppingListItem> items;

  ShoppingList({
    required this.id,
    required this.name,
    required this.createdAt,
    this.items = const [],
  });

  int get itemCount => items.length;
  
  int get checkedCount => items.where((i) => i.isChecked).length;
  
  double get totalEstimatedCost {
    return items.fold(0.0, (sum, item) {
      final price = item.product?.bestPrice?.effectivePrice ?? 0;
      return sum + (price * item.quantity);
    });
  }

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      items: json['items'] != null
          ? (json['items'] as List)
              .map((e) => ShoppingListItem.fromJson(e))
              .toList()
          : [],
    );
  }
}

class ShoppingListItem {
  final int productId;
  final Product? product;
  final int quantity;
  final bool isChecked;

  ShoppingListItem({
    required this.productId,
    this.product,
    this.quantity = 1,
    this.isChecked = false,
  });

  ShoppingListItem copyWith({
    int? productId,
    Product? product,
    int? quantity,
    bool? isChecked,
  }) {
    return ShoppingListItem(
      productId: productId ?? this.productId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      productId: json['product_id'],
      product: json['product'] != null 
          ? Product.fromJson(json['product']) 
          : null,
      quantity: json['quantity'] ?? 1,
      isChecked: json['is_checked'] ?? false,
    );
  }
}
