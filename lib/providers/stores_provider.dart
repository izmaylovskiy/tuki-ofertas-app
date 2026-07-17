import 'package:flutter/material.dart';
import '../models/store.dart';
import '../services/api_service.dart';
import '../services/mock_data_service.dart';
import '../config/api_config.dart';

class StoresProvider with ChangeNotifier {
  List<Store> _stores = [];
  Set<String> _selectedStoreSlugs = {};
  bool _isLoading = false;
  String? _error;

  final ApiService _api = ApiService();

  List<Store> get stores => _stores;
  Set<String> get selectedStoreSlugs => _selectedStoreSlugs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  bool get hasSelection => _selectedStoreSlugs.isNotEmpty;

  List<Store> get selectedStores {
    if (_selectedStoreSlugs.isEmpty) return _stores;
    return _stores.where((s) => _selectedStoreSlugs.contains(s.slug)).toList();
  }

  StoresProvider() {
    loadStores();
  }

  Future<void> loadStores() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (ApiConfig.useMockData) {
        // Используем мок-данные
        await Future.delayed(const Duration(milliseconds: 300));
        _stores = MockDataService.getStores();
      } else {
        // Загружаем с API
        _stores = await _api.getStores();
      }
    } catch (e) {
      _error = e.toString();
      // Fallback на мок-данные при ошибке
      _stores = MockDataService.getStores();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  void toggleStore(String slug) {
    if (_selectedStoreSlugs.contains(slug)) {
      _selectedStoreSlugs.remove(slug);
    } else {
      _selectedStoreSlugs.add(slug);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedStoreSlugs.clear();
    notifyListeners();
  }

  void clearSelection() {
    _selectedStoreSlugs.clear();
    notifyListeners();
  }

  bool isStoreSelected(String slug) {
    return _selectedStoreSlugs.isEmpty || _selectedStoreSlugs.contains(slug);
  }

  Store? getStoreBySlug(String slug) {
    try {
      return _stores.firstWhere((s) => s.slug == slug);
    } catch (e) {
      return null;
    }
  }
}
