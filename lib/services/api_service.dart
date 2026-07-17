import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/category.dart';
import '../models/store.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String baseUrl = ApiConfig.baseUrl;

  // ============ PRODUCTS ============

  /// Получить список продуктов с фильтрами
  Future<ProductsResponse> getProducts({
    int? categoryId,
    String? categorySlug,
    List<String>? stores,
    bool? hasDiscount,
    int? minDiscount,
    String sortBy = 'discount',
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      'sort_by': sortBy,
    };

    if (categoryId != null) {
      params['category_id'] = categoryId.toString();
    }
    if (categorySlug != null) {
      params['category'] = categorySlug;
    }
    if (stores != null && stores.isNotEmpty) {
      params['store'] = stores.join(',');
    }
    if (hasDiscount != null) {
      params['has_discount'] = hasDiscount.toString();
    }
    if (minDiscount != null) {
      params['min_discount'] = minDiscount.toString();
    }
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: params);
  
    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List? ?? [];
        
        // Парсим и ФИЛЬТРУЕМ товары без валидных цен
        final allProducts = items.map((e) => Product.fromJson(e)).toList();
        final validProducts = allProducts.where((p) => p.hasValidPrices).toList();
        
        // Логируем для отладки
        if (allProducts.length != validProducts.length) {
          print('Filtered out ${allProducts.length - validProducts.length} products without valid prices');
        }
        
        return ProductsResponse(
          products: validProducts,
          total: data['total'] ?? validProducts.length,
          page: data['page'] ?? page,
          perPage: data['per_page'] ?? perPage,
        );
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('API Error: $e');
      rethrow;
    }
  }

  /// Получить продукт по ID
  Future<Product?> getProduct(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/$id'));
      if (response.statusCode == 200) {
        final product = Product.fromJson(json.decode(response.body));
        // Возвращаем только если есть валидные цены
        return product.hasValidPrices ? product : null;
      }
      return null;
    } catch (e) {
      print('API Error: $e');
      return null;
    }
  }

  /// Получить продукты со скидками
  Future<ProductsResponse> getDiscountedProducts({
    String? categorySlug,
    List<String>? stores,
    int? minDiscount,
    String sortBy = 'discount',
    int page = 1,
    int perPage = 20,
  }) async {
    return getProducts(
      hasDiscount: true,
      categorySlug: categorySlug,
      stores: stores,
      minDiscount: minDiscount ?? 1,  // Минимум 1% скидки
      sortBy: sortBy,
      page: page,
      perPage: perPage,
    );
  }

  // ============ CATEGORIES ============

  /// Получить все категории
  Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((e) => Category.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('API Error getting categories: $e');
      return [];
    }
  }

  // ============ STORES ============

  /// Получить все магазины
  Future<List<Store>> getStores() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stores'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((e) => Store.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('API Error getting stores: $e');
      return [];
    }
  }

  // ============ STATS ============

  /// Получить статистику продуктов
  Future<Map<String, dynamic>> getProductsStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/stats'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print('API Error: $e');
      return {};
    }
  }

  // ============ SEARCH ============

  /// Поиск продуктов
  Future<ProductsResponse> searchProducts(String query, {
    int page = 1,
    int perPage = 20,
  }) async {
    return getProducts(
      search: query,
      page: page,
      perPage: perPage,
      sortBy: 'name',
    );
  }

  // ============ HEALTH CHECK ============

  /// Проверить доступность API
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl.replaceAll('/api/v1', '/health')),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Ответ со списком продуктов и пагинацией
class ProductsResponse {
  final List<Product> products;
  final int total;
  final int page;
  final int perPage;

  ProductsResponse({
    required this.products,
    required this.total,
    required this.page,
    required this.perPage,
  });

  bool get hasMore => page * perPage < total;
  
  /// Количество валидных товаров
  int get validCount => products.length;
}
