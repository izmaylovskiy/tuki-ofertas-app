import 'dart:io' show Platform;

class ApiConfig {
  // ВАЖНО: Установить false для использования реального API
  static const bool useMockData = false;

  // URL API сервера
  // Android эмулятор: 10.0.2.2 = localhost хоста
  // iOS симулятор: localhost работает
  // Реальное устройство: IP компьютера в локальной сети
  static String get baseUrl {
    // Для Android эмулятора используем 10.0.2.2
    // Это специальный IP который указывает на localhost хост-машины
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    // Для iOS и десктопа используем localhost
    return 'http://localhost:8000/api/v1';
  }

  // Альтернативный способ - указать IP вручную
  // Раскомментируй и укажи IP твоего компьютера для тестирования на реальном устройстве
  // static const String baseUrl = 'http://192.168.1.XXX:8000/api/v1';

  // Таймауты
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Endpoints
  static const String products = '/products';
  static const String stores = '/stores';
  static const String categories = '/categories';
  static const String favorites = '/users/me/favorites';
  static const String shoppingLists = '/shopping-lists';
  static const String search = '/search';
}
