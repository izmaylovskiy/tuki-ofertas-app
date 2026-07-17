import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/api_service.dart';

enum SortBy { discount, priceLow, priceHigh, name }

class ProductsProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _searchQuery = '';
  int? _selectedCategoryId;
  String? _selectedCategorySlug;
  SortBy _sortBy = SortBy.discount;
  int _currentPage = 1;
  int _totalProducts = 0;
  bool _hasMore = true;

  // Getters
  List<Product> get products => _products;
  List<Product> get allProducts => _products; // Для совместимости
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  String? get selectedCategorySlug => _selectedCategorySlug;
  SortBy get sortBy => _sortBy;
  int get totalProducts => _totalProducts;
  bool get hasMore => _hasMore;

  ProductsProvider() {
    loadInitialData();
  }

  /// Загрузить начальные данные (категории и продукты)
  Future<void> loadInitialData() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      // Загружаем категории
      _categories = await _api.getCategories();
      
      // Загружаем продукты
      await _loadProducts(reset: true);
      
      _hasError = false;
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
      print('Error loading initial data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Загрузить продукты с текущими фильтрами
  Future<void> _loadProducts({bool reset = false}) async {
    if (reset) {
      _currentPage = 1;
      _products = [];
    }

    try {
      final sortByStr = _getSortByString();
      
      final response = await _api.getProducts(
        categoryId: _selectedCategoryId,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        sortBy: sortByStr,
        page: _currentPage,
        perPage: 30,
      );

      if (reset) {
        _products = response.products;
      } else {
        _products.addAll(response.products);
      }
      
      _totalProducts = response.total;
      _hasMore = response.hasMore;
      _hasError = false;
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
      print('Error loading products: $e');
    }
  }

  String _getSortByString() {
    switch (_sortBy) {
      case SortBy.discount:
        return 'discount';
      case SortBy.priceLow:
        return 'price_low';
      case SortBy.priceHigh:
        return 'price_high';
      case SortBy.name:
        return 'name';
    }
  }

  /// Загрузить следующую страницу
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    _currentPage++;
    await _loadProducts();

    _isLoading = false;
    notifyListeners();
  }

  /// Обновить данные
  Future<void> refresh() async {
    await _loadProducts(reset: true);
    notifyListeners();
  }

  /// Получить отфильтрованные продукты (локальная фильтрация по магазинам)
  List<Product> getFilteredProducts({Set<String>? storeFilter}) {
    var result = _products;

    // Фильтр по магазинам (локально, т.к. API уже отфильтровал по категории)
    if (storeFilter != null && storeFilter.isNotEmpty) {
      result = result
          .where((p) => p.prices.any((price) => storeFilter.contains(price.storeSlug)))
          .toList();
    }

    return result;
  }

  /// Получить топ скидки
  List<Product> getTopDiscounts({int limit = 10, Set<String>? storeFilter}) {
    var result = _products
        .where((p) => p.maxDiscount != null && p.maxDiscount! > 0)
        .toList();

    if (storeFilter != null && storeFilter.isNotEmpty) {
      result = result
          .where((p) => p.prices.any((price) =>
              storeFilter.contains(price.storeSlug) && price.hasPromo))
          .toList();
    }

    result.sort((a, b) => (b.maxDiscount ?? 0).compareTo(a.maxDiscount ?? 0));
    return result.take(limit).toList();
  }

  /// Получить продукт по ID
  Product? getProductById(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Установить поисковый запрос
  void setSearchQuery(String query) {
    _searchQuery = query;
    _loadProducts(reset: true).then((_) => notifyListeners());
  }

  /// Установить категорию
  void setCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    
    // Найти slug категории
    if (categoryId != null) {
      final category = _categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => Category(id: 0, name: '', slug: ''),
      );
      _selectedCategorySlug = category.slug;
    } else {
      _selectedCategorySlug = null;
    }
    
    _loadProducts(reset: true).then((_) => notifyListeners());
  }

  /// Установить сортировку
  void setSortBy(SortBy sort) {
    _sortBy = sort;
    _loadProducts(reset: true).then((_) => notifyListeners());
  }

  /// Сбросить все фильтры
  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _selectedCategorySlug = null;
    _sortBy = SortBy.discount;
    _loadProducts(reset: true).then((_) => notifyListeners());
  }

  /// Получить название текущей категории
  String? get currentCategoryName {
    if (_selectedCategoryId == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == _selectedCategoryId).name;
    } catch (e) {
      return null;
    }
  }
}
