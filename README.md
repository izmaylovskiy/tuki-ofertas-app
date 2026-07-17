# Ofertas Colombia 🇨🇴

Приложение для отслеживания скидок и акций в колумбийских супермаркетах.

## Поддерживаемые магазины

- Éxito
- Carulla
- D1
- Ara
- Euro (и возможность добавления новых)

## Функции

- 📊 Сравнение цен между магазинами
- 🏷️ Отслеживание скидок и акций
- ❤️ Избранные товары с уведомлениями
- 🛒 Список покупок с оптимизацией
- 🔍 Поиск и фильтрация по категориям

## Запуск проекта

### Требования

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0

### Установка

```bash
# Клонирование (или скачивание)
cd ofertas_colombia

# Установка зависимостей
flutter pub get

# Запуск на эмуляторе/устройстве
flutter run
```

### Запуск на разных платформах

```bash
# Android
flutter run -d android

# iOS (только на macOS)
flutter run -d ios

# Web (для тестирования)
flutter run -d chrome

# Desktop
flutter run -d windows  # или macos, linux
```

## Структура проекта

```
lib/
├── main.dart              # Точка входа
├── config/
│   ├── theme.dart         # Тема и цвета
│   └── api_config.dart    # Конфигурация API
├── models/
│   ├── store.dart         # Модель магазина
│   ├── product.dart       # Модель продукта и цены
│   ├── category.dart      # Модель категории
│   └── shopping_list.dart # Модель списка покупок
├── services/
│   └── mock_data_service.dart  # Мок-данные для разработки
├── providers/
│   ├── stores_provider.dart      # State магазинов
│   ├── products_provider.dart    # State продуктов
│   ├── favorites_provider.dart   # State избранного
│   └── shopping_list_provider.dart # State списка покупок
├── screens/
│   ├── main_screen.dart          # Главный экран с навигацией
│   ├── home_screen.dart          # Лента акций
│   ├── search_screen.dart        # Поиск
│   ├── favorites_screen.dart     # Избранное
│   ├── shopping_list_screen.dart # Список покупок
│   └── product_detail_screen.dart # Детали продукта
├── widgets/
│   ├── store_filter.dart         # Фильтр магазинов
│   ├── category_chips.dart       # Категории
│   ├── product_card.dart         # Карточка продукта
│   ├── sort_button.dart          # Кнопка сортировки
│   └── shopping_list_item.dart   # Элемент списка покупок
└── utils/
    └── formatters.dart           # Форматирование цен и дат
```

## Следующие шаги

1. **API интеграция** — Заменить `MockDataService` на реальный API
2. **Парсеры** — Подключить парсеры для каждого магазина
3. **Уведомления** — Firebase Cloud Messaging для push-уведомлений
4. **Аналитика** — История цен и графики
5. **Локализация** — Полная поддержка испанского

## Переключение на реальный API

В `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Изменить на false для работы с API
  static const bool useMockData = false;
  
  // URL вашего API сервера
  static const String baseUrl = 'https://api.ofertas-colombia.com/v1';
}
```

## Разработка

```bash
# Анализ кода
flutter analyze

# Тесты
flutter test

# Сборка APK
flutter build apk --release

# Сборка iOS
flutter build ios --release
```

## Мок-данные

Приложение поставляется с реалистичными мок-данными для тестирования:
- 15 продуктов
- 5 магазинов
- 11 категорий
- Цены с акциями и без

Данные находятся в `lib/services/mock_data_service.dart`.

---

Разработано для колумбийского рынка 🛒
