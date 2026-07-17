import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/shopping_list.dart';

class ShoppingListProvider with ChangeNotifier {
  List<ShoppingListItem> _items = [];
  
  List<ShoppingListItem> get items => _items;
  
  int get itemCount => _items.length;
  
  int get checkedCount => _items.where((i) => i.isChecked).length;

  bool hasProduct(int productId) {
    return _items.any((item) => item.productId == productId);
  }

  void addProduct(Product product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((i) => i.productId == product.id);
    
    if (existingIndex != -1) {
      // Увеличиваем количество
      final existing = _items[existingIndex];
      _items[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      // Добавляем новый
      _items.add(ShoppingListItem(
        productId: product.id,
        product: product,
        quantity: quantity,
        isChecked: false,
      ));
    }
    notifyListeners();
  }

  void removeProduct(int productId) {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  void toggleChecked(int productId) {
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isChecked: !_items[index].isChecked);
      notifyListeners();
    }
  }

  void clearChecked() {
    _items.removeWhere((item) => item.isChecked);
    notifyListeners();
  }

  void clearAll() {
    _items.clear();
    notifyListeners();
  }

  double getTotalCost() {
    return _items.fold(0.0, (sum, item) {
      final price = item.product?.bestPrice?.effectivePrice ?? 0;
      return sum + (price * item.quantity);
    });
  }

  // Оптимизация: группировка по магазинам
  Map<String, List<ShoppingListItem>> getItemsByStore() {
    final Map<String, List<ShoppingListItem>> result = {};
    
    for (final item in _items) {
      if (item.product == null) continue;
      
      final bestPrice = item.product!.bestPrice;
      if (bestPrice == null) continue;
      
      final storeSlug = bestPrice.storeSlug;
      result.putIfAbsent(storeSlug, () => []);
      result[storeSlug]!.add(item);
    }
    
    return result;
  }

  // Подсчёт экономии если покупать с акциями
  double getTotalSavings() {
    return _items.fold(0.0, (sum, item) {
      if (item.product == null) return sum;
      
      final bestPrice = item.product!.bestPrice;
      if (bestPrice == null || !bestPrice.hasPromo) return sum;
      
      final regularPrice = bestPrice.regularPrice ?? 0;
      final promoPrice = bestPrice.promoPrice ?? regularPrice;
      final savings = (regularPrice - promoPrice) * item.quantity;
      
      return sum + savings;
    });
  }
}
