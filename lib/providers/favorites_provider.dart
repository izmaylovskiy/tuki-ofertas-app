import 'package:flutter/material.dart';
import '../models/product.dart';

class FavoritesProvider with ChangeNotifier {
  final Set<int> _favoriteIds = {};
  final Map<int, bool> _notifyOnPromo = {};

  Set<int> get favoriteIds => _favoriteIds;

  bool isFavorite(int productId) => _favoriteIds.contains(productId);
  
  bool shouldNotify(int productId) => _notifyOnPromo[productId] ?? true;

  void toggleFavorite(int productId) {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
      _notifyOnPromo.remove(productId);
    } else {
      _favoriteIds.add(productId);
      _notifyOnPromo[productId] = true;
    }
    notifyListeners();
  }

  void setNotifyOnPromo(int productId, bool notify) {
    _notifyOnPromo[productId] = notify;
    notifyListeners();
  }

  List<Product> getFavoriteProducts(List<Product> allProducts) {
    return allProducts.where((p) => _favoriteIds.contains(p.id)).toList();
  }

  void clearAll() {
    _favoriteIds.clear();
    _notifyOnPromo.clear();
    notifyListeners();
  }
}
