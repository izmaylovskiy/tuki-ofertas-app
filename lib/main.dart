import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Edge-to-edge: приложение занимает весь экран включая зону под системной
  // навигацией Android — фон scaffold виден до самого низа, нет тёмной полосы.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const TukiOfertasApp());
}

// API URL
String get apiBaseUrl {
  return 'https://api.tuki-ofertas.com/api/v1';
}

// Основные цвета приложения
class AppColors {
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF388E3C);
  static const Color accent = Color(0xFF66BB6A);
  
  // Цвета магазинов — берём из карты брендов (см. StoreBrand ниже),
  // fallback в случайный цвет из палитры
  static Color getStoreColor(String slug) {
    final brand = storeBrands[slug];
    if (brand != null) return brand.primary;
    return StoreBrand.fallback(slug).primary;
  }

  // Цвета магазинов для маркеров Google Maps (hue 0..360)
  static double getStoreMarkerHue(String slug) {
    const hues = {
      'carulla': BitmapDescriptor.hueRed,
      'exito': BitmapDescriptor.hueYellow,
      'jumbo': BitmapDescriptor.hueGreen,
      'olimpica': BitmapDescriptor.hueAzure,
      'alkosto': BitmapDescriptor.hueOrange,
      'falabella': 120.0,
      'euro': BitmapDescriptor.hueCyan,
    };
    return hues[slug] ?? BitmapDescriptor.hueViolet;
  }
}

/// Иконка + цвет для категории товаров.
/// Используется на главном экране для горизонтальной полосы категорий.
class CategoryStyle {
  final IconData icon;
  final Color color;
  const CategoryStyle(this.icon, this.color);
  
  /// Fallback-стиль для неизвестной категории.
  /// Генерирует цвет из hash slug — чтобы хотя бы каждая категория
  /// имела СВОЙ цвет, даже если её нет в карте стилей.
  factory CategoryStyle.fallback(String slug) {
    const palette = <Color>[
      Color(0xFF5C6BC0), Color(0xFF26A69A), Color(0xFFAB47BC),
      Color(0xFF66BB6A), Color(0xFFFFA726), Color(0xFFEC407A),
      Color(0xFF7E57C2), Color(0xFF42A5F5), Color(0xFFFF7043),
      Color(0xFF26C6DA), Color(0xFF8D6E63), Color(0xFF9CCC65),
    ];
    final idx = slug.hashCode.abs() % palette.length;
    return CategoryStyle(Icons.category_rounded, palette[idx]);
  }
}

/// Бренд-стиль магазина: фирменный цвет + метка для логотипа.
/// Метка обычно 1-3 символа в характерном для бренда виде
/// (например "é" для Éxito, "D1" для Tiendas D1).
class StoreBrand {
  /// Основной цвет бренда — для фона иконки
  final Color primary;
  /// Цвет текста на бейдже (обычно белый, для светлых фонов — тёмный)
  final Color foreground;
  /// Что писать на бейдже (1-3 символа)
  final String label;
  
  const StoreBrand({
    required this.primary,
    this.foreground = Colors.white,
    required this.label,
  });
  
  /// Fallback из первой буквы slug + цвет из палитры
  factory StoreBrand.fallback(String slug) {
    const palette = <Color>[
      Color(0xFF5C6BC0), Color(0xFF26A69A), Color(0xFFAB47BC),
      Color(0xFF66BB6A), Color(0xFFEF5350), Color(0xFFFFA726),
      Color(0xFFEC407A), Color(0xFF7E57C2), Color(0xFF42A5F5),
    ];
    final idx = slug.hashCode.abs() % palette.length;
    return StoreBrand(
      primary: palette[idx],
      label: slug.isNotEmpty ? slug[0].toUpperCase() : '?',
    );
  }
}

/// Карта брендов — фирменные цвета и метки магазинов.
/// Цвета взяты максимально близкими к официальным логотипам.
const Map<String, StoreBrand> storeBrands = {
  // === Парсерные (главные сети) ===
  'carulla':         StoreBrand(primary: Color(0xFFE30613), label: 'C'),         // красный
  'exito':           StoreBrand(primary: Color(0xFFFFE600), foreground: Color(0xFFE60012), label: 'é'),  // фирменный жёлтый
  'jumbo':           StoreBrand(primary: Color(0xFF00873E), label: 'J'),         // зелёный
  'olimpica':        StoreBrand(primary: Color(0xFFE30613), label: 'O'),         // красный (как у них)
  'alkosto':         StoreBrand(primary: Color(0xFFFF6600), label: 'A'),         // оранжевый
  'falabella':       StoreBrand(primary: Color(0xFF96BF0D), label: 'F'),         // зелёный
  'euro':            StoreBrand(primary: Color(0xFF0066B3), label: 'E'),         // синий
  
  // === Каталожные сети (discount stores) ===
  'd1':              StoreBrand(primary: Color(0xFFE30613), label: 'D1'),        // красный фирменный
  'ara':             StoreBrand(primary: Color(0xFF1F2E5C), label: 'ara'),       // тёмно-синий
  'surtimax':        StoreBrand(primary: Color(0xFFE30613), foreground: Color(0xFFFFE600), label: 'S'),  // красно-жёлтый
  'surtimayorista':  StoreBrand(primary: Color(0xFFFF6B00), label: 'SM'),
  'metro':           StoreBrand(primary: Color(0xFF003DA5), label: 'M'),         // синий
  'la-vaquita':      StoreBrand(primary: Color(0xFF2C2C2C), label: 'LV'),
  'pricesmart':      StoreBrand(primary: Color(0xFF0067B1), label: 'PS'),        // синий
  'mercaldas':       StoreBrand(primary: Color(0xFF00853E), label: 'Mc'),
  'cooratiendas':    StoreBrand(primary: Color(0xFF7B5E3C), label: 'Co'),
  'mercados-romi':   StoreBrand(primary: Color(0xFFE85D04), label: 'R'),
  'justo-y-bueno':   StoreBrand(primary: Color(0xFFD32F2F), label: 'JB'),
  'makro':           StoreBrand(primary: Color(0xFF003DA5), foreground: Color(0xFFFFE600), label: 'M'),
  'isimo':           StoreBrand(primary: Color(0xFF6A1B9A), label: 'Í'),
  'surtifruver':     StoreBrand(primary: Color(0xFF388E3C), label: 'SF'),
  'colsubsidio':     StoreBrand(primary: Color(0xFF0078BF), label: 'C'),
};

/// Виджет-бейдж бренда: скруглённый квадрат с градиентом + лейбл.
/// Используется ВЕЗДЕ где раньше был `CircleAvatar` с одной буквой.
class StoreBrandBadge extends StatelessWidget {
  final String slug;
  final double size;
  /// Если true — добавляется тень для эффекта поднятой иконки
  final bool elevated;
  
  const StoreBrandBadge({
    super.key,
    required this.slug,
    this.size = 40,
    this.elevated = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final brand = storeBrands[slug] ?? StoreBrand.fallback(slug);
    
    // Размер шрифта зависит от длины метки и размера бейджа
    final fontSize = brand.label.length == 1
        ? size * 0.5
        : brand.label.length == 2
            ? size * 0.38
            : size * 0.30;
    
    // Чуть более тёмный оттенок для нижнего конца градиента
    final hsl = HSLColor.fromColor(brand.primary);
    final darker = hsl.withLightness((hsl.lightness * 0.82).clamp(0.0, 1.0)).toColor();
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [brand.primary, darker],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: brand.primary.withOpacity(0.35),
                  blurRadius: size * 0.18,
                  offset: Offset(0, size * 0.06),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          brand.label,
          style: TextStyle(
            color: brand.foreground,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class TukiOfertasApp extends StatelessWidget {
  const TukiOfertasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tuki Ofertas',
      debugShowCheckedModeBanner: false,
      
      // Светлая тема
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
        ),
        chipTheme: ChipThemeData(
          selectedColor: AppColors.primary.withOpacity(0.2),
          checkmarkColor: AppColors.primary,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
        ),
      ),
      
      // Тёмная тема
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: AppColors.accent,
          unselectedItemColor: Colors.grey,
          backgroundColor: Color(0xFF1E1E1E),
        ),
        chipTheme: ChipThemeData(
          selectedColor: AppColors.primary.withOpacity(0.3),
          checkmarkColor: AppColors.accent,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.accent,
        ),
      ),
      
      // Автоматический выбор темы по настройкам системы
      themeMode: ThemeMode.system,
      
      home: const MainScreen(),
    );
  }
}

// ==================== CACHE SERVICE ====================

class CacheService {
  static const String _productsKey = 'cached_products';
  static const String _categoriesKey = 'cached_categories';
  static const String _storesKey = 'cached_stores';
  static const String _statsKey = 'cached_stats';
  static const String _matrixKey = 'cached_matrix';
  static const String _locationsKey = 'cached_locations';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _productsHashKey = 'products_hash';
  
  static const Duration cacheValidDuration = Duration(hours: 1);
  
  final SharedPreferences _prefs;
  
  CacheService(this._prefs);
  
  static Future<CacheService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return CacheService(prefs);
  }
  
  bool needsSync() {
    final lastSync = _prefs.getInt(_lastSyncKey) ?? 0;
    final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
    return DateTime.now().difference(lastSyncTime) > cacheValidDuration;
  }
  
  Future<void> updateSyncTime() async {
    await _prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }
  
  Future<void> cacheProducts(List<dynamic> products) async {
    await _prefs.setString(_productsKey, json.encode(products));
    final hash = products.length.toString() + '_' + (products.isNotEmpty ? products[0]['id'].toString() : '0');
    await _prefs.setString(_productsHashKey, hash);
  }
  
  List<dynamic>? getCachedProducts() {
    final data = _prefs.getString(_productsKey);
    if (data == null) return null;
    return json.decode(data) as List<dynamic>;
  }
  
  Future<void> cacheCategories(List<dynamic> categories) async {
    await _prefs.setString(_categoriesKey, json.encode(categories));
  }
  
  List<dynamic>? getCachedCategories() {
    final data = _prefs.getString(_categoriesKey);
    if (data == null) return null;
    return json.decode(data) as List<dynamic>;
  }
  
  Future<void> cacheStores(List<dynamic> stores) async {
    await _prefs.setString(_storesKey, json.encode(stores));
  }
  
  List<dynamic>? getCachedStores() {
    final data = _prefs.getString(_storesKey);
    if (data == null) return null;
    return json.decode(data) as List<dynamic>;
  }
  
  Future<void> cacheStats(Map<String, dynamic> stats) async {
    await _prefs.setString(_statsKey, json.encode(stats));
  }
  
  Map<String, dynamic>? getCachedStats() {
    final data = _prefs.getString(_statsKey);
    if (data == null) return null;
    return json.decode(data) as Map<String, dynamic>;
  }

  Future<void> cacheMatrix(Map<String, dynamic> matrix) async {
    await _prefs.setString(_matrixKey, json.encode(matrix));
  }

  Map<String, dynamic>? getCachedMatrix() {
    final data = _prefs.getString(_matrixKey);
    if (data == null) return null;
    return json.decode(data) as Map<String, dynamic>;
  }

  Future<void> cacheLocations(List<dynamic> locations) async {
    await _prefs.setString(_locationsKey, json.encode(locations));
  }

  List<dynamic>? getCachedLocations() {
    final data = _prefs.getString(_locationsKey);
    if (data == null) return null;
    return json.decode(data) as List<dynamic>;
  }
  
  Future<void> clearCache() async {
    await _prefs.remove(_productsKey);
    await _prefs.remove(_categoriesKey);
    await _prefs.remove(_storesKey);
    await _prefs.remove(_statsKey);
    await _prefs.remove(_matrixKey);
    await _prefs.remove(_locationsKey);
    await _prefs.remove(_lastSyncKey);
    await _prefs.remove(_productsHashKey);
  }
  
  int getCacheSize() {
    int size = 0;
    size += _prefs.getString(_productsKey)?.length ?? 0;
    size += _prefs.getString(_categoriesKey)?.length ?? 0;
    size += _prefs.getString(_storesKey)?.length ?? 0;
    size += _prefs.getString(_statsKey)?.length ?? 0;
    size += _prefs.getString(_matrixKey)?.length ?? 0;
    size += _prefs.getString(_locationsKey)?.length ?? 0;
    return size;
  }
}

// ==================== MAIN SCREEN ====================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Set<int> _favoriteIds = {};
  CacheService? _cacheService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCache();
    _loadFavorites();
  }

  Future<void> _initCache() async {
    _cacheService = await CacheService.init();
    setState(() => _isInitialized = true);
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> saved = prefs.getStringList('favorites') ?? [];
    setState(() => _favoriteIds = saved.map((s) => int.tryParse(s) ?? 0).where((id) => id > 0).toSet());
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favoriteIds.map((id) => id.toString()).toList());
  }

  void _toggleFavorite(int productId) {
    setState(() {
      if (_favoriteIds.contains(productId)) {
        _favoriteIds.remove(productId);
      } else {
        _favoriteIds.add(productId);
      }
    });
    _saveFavorites();
  }

  bool _isFavorite(int productId) => _favoriteIds.contains(productId);

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      );
    }
    
    return Scaffold(
      body: Stack(
        children: [
          // Контент — занимает весь body, до самого низа экрана
          IndexedStack(
            index: _currentIndex,
            children: [
              HomeScreen(
                favoriteIds: _favoriteIds, 
                onToggleFavorite: _toggleFavorite, 
                isFavorite: _isFavorite,
                cacheService: _cacheService!,
              ),
              const CatalogsScreen(),
              StoresScreen(favoriteIds: _favoriteIds, onToggleFavorite: _toggleFavorite, isFavorite: _isFavorite, cacheService: _cacheService!),
              MapScreen(cacheService: _cacheService!),
              FavoritesScreen(favoriteIds: _favoriteIds, onToggleFavorite: _toggleFavorite, cacheService: _cacheService!),
            ],
          ),
          // Плавающее меню поверх контента, прижато к низу экрана
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassBottomNav(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: const [
                GlassNavItem(icon: Icons.local_offer_outlined, activeIcon: Icons.local_offer, label: 'Ofertas'),
                GlassNavItem(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book_rounded, label: 'Catálogos'),
                GlassNavItem(icon: Icons.store_outlined, activeIcon: Icons.store, label: 'Tiendas'),
                GlassNavItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Mapa'),
                GlassNavItem(icon: Icons.favorite_outline, activeIcon: Icons.favorite, label: 'Favoritos'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== HOME SCREEN ====================

class HomeScreen extends StatefulWidget {
  final Set<int> favoriteIds;
  final Function(int) onToggleFavorite;
  final bool Function(int) isFavorite;
  final CacheService cacheService;

  const HomeScreen({super.key, required this.favoriteIds, required this.onToggleFavorite, required this.isFavorite, required this.cacheService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  List<dynamic> _stores = [];
  Map<String, dynamic> _stats = {};
  Map<String, Map<String, int>> _matrix = {};

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  bool _isOffline = false;

  String? _selectedCategory;
  String? _selectedStore;
  String _sortBy = 'discount';
  int _currentPage = 1;
  static const int _perPage = 20;

  // Стили категорий: Material Icon + индивидуальный цвет для каждой.
  // Покрывает все категории из БД (см. seed.py на backend).
  final categoryStyles = <String, CategoryStyle>{
    'frutas-verduras':   CategoryStyle(Icons.eco_rounded,                Color(0xFF66BB6A)),  // зелёный
    'carnes':            CategoryStyle(Icons.set_meal_rounded,           Color(0xFFC62828)),  // красно-мясной
    'lacteos':           CategoryStyle(Icons.local_drink_rounded,        Color(0xFF42A5F5)),  // молочный голубой
    'panaderia':         CategoryStyle(Icons.bakery_dining_rounded,      Color(0xFFD4A574)),  // золотой хлеб
    'bebidas':           CategoryStyle(Icons.local_cafe_rounded,         Color(0xFFFFA726)),  // янтарный
    'licores':           CategoryStyle(Icons.wine_bar_rounded,           Color(0xFF8E1538)),  // винный
    'despensa':          CategoryStyle(Icons.shopping_basket_rounded,    Color(0xFFFF7043)),  // оранжевый
    'snacks':            CategoryStyle(Icons.cookie_rounded,             Color(0xFFD4A017)),  // печенье
    'congelados':        CategoryStyle(Icons.ac_unit_rounded,            Color(0xFF26C6DA)),  // ледяной
    'aseo-hogar':        CategoryStyle(Icons.cleaning_services_rounded,  Color(0xFF26A69A)),  // бирюзовый
    'limpieza':          CategoryStyle(Icons.soap_rounded,               Color(0xFF4FC3F7)),  // мыльный голубой
    'cuidado-personal':  CategoryStyle(Icons.spa_rounded,                Color(0xFFEC407A)),  // розовый
    'mascotas':          CategoryStyle(Icons.pets_rounded,               Color(0xFF8D6E63)),  // коричневый
    'bebes':             CategoryStyle(Icons.child_friendly_rounded,     Color(0xFFFFB74D)),  // мягкий оранжевый
    'tecnologia':        CategoryStyle(Icons.devices_rounded,            Color(0xFF5C6BC0)),  // тех-синий
    'electrodomesticos': CategoryStyle(Icons.microwave_rounded,          Color(0xFF78909C)),  // серебристый
    'computadores':      CategoryStyle(Icons.laptop_mac_rounded,         Color(0xFF3949AB)),  // тёмно-синий
    'tv-y-audio':        CategoryStyle(Icons.tv_rounded,                 Color(0xFF7E57C2)),  // фиолетовый
    'videojuegos':       CategoryStyle(Icons.sports_esports_rounded,     Color(0xFF00C853)),  // неон-зелёный
    'hogar':             CategoryStyle(Icons.home_rounded,               Color(0xFFA1887F)),  // тёплый коричневый
    'muebles':           CategoryStyle(Icons.chair_rounded,              Color(0xFF6D4C41)),  // дерево
    'decoracion':        CategoryStyle(Icons.format_paint_rounded,       Color(0xFFAB47BC)),  // сиреневый
    'deportes':          CategoryStyle(Icons.sports_soccer_rounded,      Color(0xFF43A047)),  // спорт-зелёный
    'ofertas':           CategoryStyle(Icons.local_offer_rounded,        Color(0xFFE53935)),  // красная скидка
    'general':           CategoryStyle(Icons.category_rounded,           Color(0xFF78909C)),  // нейтральный
    'cocina':            CategoryStyle(Icons.restaurant_rounded,         Color(0xFFEF6C00)),  // кулинария
    'oficina':           CategoryStyle(Icons.business_center_rounded,    Color(0xFF455A64)),  // офисный графит
    'salud':             CategoryStyle(Icons.medical_services_rounded,   Color(0xFFD32F2F)),  // медицинский красный
    'jardin':            CategoryStyle(Icons.grass_rounded,              Color(0xFF7CB342)),  // сад-зелёный
    'autos':             CategoryStyle(Icons.directions_car_rounded,     Color(0xFF1E88E5)),  // авто-синий
    'auto':              CategoryStyle(Icons.directions_car_rounded,     Color(0xFF1E88E5)),  // фоллбэк
    'libros':            CategoryStyle(Icons.menu_book_rounded,          Color(0xFF6A1B9A)),  // книги-пурпур
    'musica':            CategoryStyle(Icons.music_note_rounded,         Color(0xFFD81B60)),  // музыка-розовый
    'belleza':           CategoryStyle(Icons.brush_rounded,              Color(0xFFEC407A)),  // красота-розовый
    'farmacia':          CategoryStyle(Icons.local_pharmacy_rounded,     Color(0xFF00897B)),  // аптека-бирюза
    'oficina-papeleria': CategoryStyle(Icons.edit_note_rounded,          Color(0xFF455A64)),  // канцелярия
    'otros':             CategoryStyle(Icons.more_horiz_rounded,         Color(0xFF78909C)),  // прочее
    // Legacy slugs (на случай если БД отдаст старые)
    'ferreteria':        CategoryStyle(Icons.handyman_rounded,           Color(0xFFFFA000)),
    'moda-mujer':        CategoryStyle(Icons.checkroom_rounded,          Color(0xFFEC407A)),
    'moda-hombre':       CategoryStyle(Icons.checkroom_rounded,          Color(0xFF455A64)),
    'juguetes':          CategoryStyle(Icons.toys_rounded,               Color(0xFFFF7043)),
  };
  
  // Стиль для кнопки "Todas" (все категории)
  static const CategoryStyle _todasStyle = CategoryStyle(
    Icons.local_fire_department_rounded,
    Color(0xFFFF6B35),
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300 && !_isLoadingMore && _hasMore) {
      _loadMoreProducts();
    }
  }

  List<dynamic> get _visibleStores {
    if (_selectedCategory == null || _matrix.isEmpty) return _stores;
    return _stores.where((store) {
      final slug = store['slug'] as String? ?? '';
      final storeCats = _matrix[slug];
      if (storeCats == null) return false;
      return (storeCats[_selectedCategory] ?? 0) > 0;
    }).toList();
  }

  List<dynamic> get _visibleCategories {
    if (_selectedStore == null || _matrix.isEmpty) return _categories;
    final storeCats = _matrix[_selectedStore];
    if (storeCats == null) return _categories;
    return _categories.where((cat) {
      final slug = cat['slug'] as String? ?? '';
      return (storeCats[slug] ?? 0) > 0;
    }).toList();
  }

  Future<void> _loadInitialData() async {
    setState(() { _isLoading = true; _error = null; _isOffline = false; });
    
    final cachedStats = widget.cacheService.getCachedStats();
    final cachedStores = widget.cacheService.getCachedStores();
    final cachedMatrix = widget.cacheService.getCachedMatrix();
    
    if (cachedStats != null && cachedStores != null) {
      setState(() {
        _stats = cachedStats;
        _categories = ((cachedStats['categories'] as List?) ?? [])
            .where((c) => (c['count'] ?? 0) > 0)
            .toList();
        _stores = (cachedStores as List).where((s) => (s['product_count'] ?? 0) > 0).toList();
        if (cachedMatrix != null) _matrix = _parseMatrix(cachedMatrix);
      });
    }
    
    if (!widget.cacheService.needsSync() && cachedStats != null) {
      await _loadProducts(reset: true, useCache: true);
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/products/stats')).timeout(const Duration(seconds: 10)),
        http.get(Uri.parse('$apiBaseUrl/stores')).timeout(const Duration(seconds: 10)),
        http.get(Uri.parse('$apiBaseUrl/filter-matrix')).timeout(const Duration(seconds: 10)),
      ]);

      if (results[0].statusCode == 200) {
        final statsData = json.decode(utf8.decode(results[0].bodyBytes));
        _stats = statsData;
        _categories = ((statsData['categories'] as List?) ?? [])
            .where((c) => (c['count'] ?? 0) > 0)
            .toList();
        await widget.cacheService.cacheStats(statsData);
      }
      
      if (results[1].statusCode == 200) {
        final allStores = json.decode(utf8.decode(results[1].bodyBytes)) ?? [];
        _stores = (allStores as List).where((s) => (s['product_count'] ?? 0) > 0).toList();
        await widget.cacheService.cacheStores(allStores);
      }

      if (results[2].statusCode == 200) {
        final matrixData = json.decode(utf8.decode(results[2].bodyBytes));
        if (matrixData is Map<String, dynamic>) {
          _matrix = _parseMatrix(matrixData);
          await widget.cacheService.cacheMatrix(matrixData);
        }
      }

      await widget.cacheService.updateSyncTime();
      await _loadProducts(reset: true, useCache: false);
      
    } catch (e) {
      debugPrint('Network error: $e');
      if (cachedStats != null) {
        setState(() => _isOffline = true);
        await _loadProducts(reset: true, useCache: true);
      } else {
        setState(() => _error = 'Sin conexión. Verifica tu internet.');
      }
    }
    
    setState(() => _isLoading = false);
  }

  Map<String, Map<String, int>> _parseMatrix(Map<String, dynamic> raw) {
    final result = <String, Map<String, int>>{};
    raw.forEach((store, cats) {
      if (cats is Map) {
        final inner = <String, int>{};
        cats.forEach((cat, count) {
          if (count is num) inner[cat.toString()] = count.toInt();
        });
        result[store] = inner;
      }
    });
    return result;
  }

  Future<void> _loadProducts({bool reset = false, bool useCache = false}) async {
    if (reset) { _currentPage = 1; _hasMore = true; }

    if (useCache && _selectedCategory == null && _selectedStore == null && _searchController.text.isEmpty) {
      final cached = widget.cacheService.getCachedProducts();
      if (cached != null) {
        setState(() {
          _products = cached;
          _hasMore = false;
        });
        return;
      }
    }

    final params = <String, String>{
      'page': _currentPage.toString(),
      'per_page': _perPage.toString(),
      'sort_by': _sortBy,
    };
    if (_searchController.text.isNotEmpty) params['search'] = _searchController.text;
    if (_selectedCategory != null) params['category'] = _selectedCategory!;
    if (_selectedStore != null) params['store'] = _selectedStore!;

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/products').replace(queryParameters: params)
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final items = data['items'] as List? ?? [];
        setState(() {
          if (reset) _products = items; else _products.addAll(items);
          _hasMore = _currentPage < (data['pages'] ?? 1);
          if (_hasMore) _currentPage++;
        });
        
        if (reset && _selectedCategory == null && _selectedStore == null && _searchController.text.isEmpty) {
          await widget.cacheService.cacheProducts(_products);
        }
      }
    } catch (e) { 
      debugPrint('Error loading products: $e'); 
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore || _isOffline) return;
    setState(() => _isLoadingMore = true);
    await _loadProducts(useCache: false);
    setState(() => _isLoadingMore = false);
  }

  Future<void> _refreshData() async {
    await widget.cacheService.clearCache();
    _currentPage = 1;
    _hasMore = true;
    await _loadInitialData();
  }

  void _selectCategory(String? slug) {
    setState(() {
      _selectedCategory = slug;
      if (slug != null && _selectedStore != null && _matrix.isNotEmpty) {
        final storeCats = _matrix[_selectedStore];
        if (storeCats == null || (storeCats[slug] ?? 0) == 0) {
          _selectedStore = null;
        }
      }
      _products = [];
      _isOffline = false;
    });
    _loadProducts(reset: true, useCache: false);
  }

  void _selectStore(String? slug) {
    setState(() {
      _selectedStore = slug;
      if (slug != null && _selectedCategory != null && _matrix.isNotEmpty) {
        final storeCats = _matrix[slug];
        if (storeCats == null || (storeCats[_selectedCategory] ?? 0) == 0) {
          _selectedCategory = null;
        }
      }
      _products = [];
      _isOffline = false;
    });
    _loadProducts(reset: true, useCache: false);
  }

  void _onSearch(String query) {
    setState(() { _products = []; _isOffline = false; });
    _loadProducts(reset: true, useCache: false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: colorScheme.primary,
          onRefresh: _refreshData,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(isDark)),
              SliverToBoxAdapter(child: _buildSearchBar(isDark)),
              SliverToBoxAdapter(child: _buildStoreFilter(isDark)),
              SliverToBoxAdapter(child: _buildStatsBar(isDark)),
              SliverToBoxAdapter(child: _buildCategoriesRow(isDark)),
              SliverToBoxAdapter(child: _buildProductsHeader(isDark)),
              if (_isOffline) SliverToBoxAdapter(child: _buildOfflineBanner()),
              if (_error != null) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))),
              _isLoading
                  ? SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: colorScheme.primary)))
                  : _products.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyState(isDark))
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.58, crossAxisSpacing: 10, mainAxisSpacing: 10),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => ProductCard(
                                product: _products[index],
                                isFavorite: widget.isFavorite(_products[index]['id'] ?? 0),
                                onToggleFavorite: () => widget.onToggleFavorite(_products[index]['id'] ?? 0),
                                favoriteIds: widget.favoriteIds,
                                globalOnToggleFavorite: widget.onToggleFavorite,
                              ),
                              childCount: _products.length,
                            ),
                          ),
                        ),
              if (_isLoadingMore) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: colorScheme.primary)))),
              const SliverPadding(padding: EdgeInsets.only(bottom: 130)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text('Modo sin conexión - mostrando datos guardados', style: TextStyle(color: Colors.orange.shade700, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      // Карман парит с отступами 12px по бокам и 8 сверху
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF2E7D32), const Color(0xFF1B5E20)]
                : [AppColors.primary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(isDark ? 0.35 : 0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/icon.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Text('🦜', style: TextStyle(fontSize: 26)))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tuki Ofertas', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.1)),
                  const SizedBox(height: 2),
                  Text(
                    _isOffline ? 'Modo sin conexión' : 'Las mejores ofertas de Colombia',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.2),
                  ),
                ],
              ),
            ),
            // Круглая полупрозрачная кнопка refresh
            Material(
              color: Colors.white.withOpacity(0.18),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _refreshData,
                child: const SizedBox(
                  width: 38, height: 38,
                  child: Icon(Icons.refresh, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _onSearch(''); })
              : null,
          filled: true,
          fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: isDark ? AppColors.accent : AppColors.primary),
          ),
        ),
        onSubmitted: _onSearch,
      ),
    );
  }

  Widget _buildStoreFilter(bool isDark) {
    final stores = _visibleStores;
    if (stores.isEmpty && _selectedCategory == null) return const SizedBox.shrink();
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Todas'),
              selected: _selectedStore == null,
              onSelected: (_) => _selectStore(null),
              backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              side: isDark ? BorderSide.none : BorderSide(color: _selectedStore == null ? AppColors.primary : Colors.grey[300]!),
            ),
          ),
          ...stores.map((store) {
            final slug = store['slug'] ?? '';
            final name = store['name'] ?? slug;
            final isSelected = _selectedStore == slug;
            final storeColor = AppColors.getStoreColor(slug);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: StoreBrandBadge(slug: slug, size: 22, elevated: false),
                label: Text(name),
                selected: isSelected,
                onSelected: (_) => _selectStore(isSelected ? null : slug),
                selectedColor: storeColor.withOpacity(isDark ? 0.3 : 0.2),
                checkmarkColor: storeColor,
                backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                side: isDark ? BorderSide.none : BorderSide(color: isSelected ? storeColor : Colors.grey[300]!),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatsBar(bool isDark) {
    final total = _stats['total_products'] ?? 0;
    final discounted = _stats['discounted_products'] ?? 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        border: isDark ? null : Border.all(color: Colors.grey[300]!),
        boxShadow: isDark ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 2))] : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('$total', 'Productos', isDark),
          _buildStatItem('$discounted', 'Con descuento', isDark),
          _buildStatItem('${_stores.length}', 'Tiendas', isDark),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, bool isDark) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppColors.accent : AppColors.primary)),
      Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
    ]);
  }

  Widget _buildCategoriesRow(bool isDark) {
    final categories = _visibleCategories;
    if (categories.isEmpty && _selectedStore == null) return const SizedBox.shrink();
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _selectedCategory == null;
            return GestureDetector(
              onTap: () => _selectCategory(null),
              child: Container(
                width: 70,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? _todasStyle.color 
                            : _todasStyle.color.withOpacity(isDark ? 0.18 : 0.12), 
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Icon(
                          _todasStyle.icon, 
                          size: 30,
                          color: isSelected ? Colors.white : _todasStyle.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Todas', style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? _todasStyle.color : (isDark ? Colors.grey[300] : Colors.grey[700]))),
                  ],
                ),
              ),
            );
          }
          final category = categories[index - 1];
          final slug = category['slug'] ?? '';
          final name = category['name'] ?? slug;
          final style = categoryStyles[slug] ?? CategoryStyle.fallback(slug);
          final isSelected = _selectedCategory == slug;
          return GestureDetector(
            onTap: () => _selectCategory(slug),
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? style.color 
                          : style.color.withOpacity(isDark ? 0.18 : 0.12), 
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Icon(
                        style.icon, 
                        size: 28,
                        color: isSelected ? Colors.white : style.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name, 
                    style: TextStyle(
                      fontSize: 11, 
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
                      color: isSelected 
                          ? style.color 
                          : (isDark ? Colors.grey[300] : Colors.grey[700]),
                    ), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis, 
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsHeader(bool isDark) {
    String title = '🔥 Ofertas destacadas';
    final parts = <String>[];
    if (_selectedStore != null) {
      final store = _stores.firstWhere((s) => s['slug'] == _selectedStore, orElse: () => {'name': _selectedStore});
      parts.add(store['name'] ?? _selectedStore!);
    }
    if (_selectedCategory != null) {
      final category = _categories.firstWhere((c) => c['slug'] == _selectedCategory, orElse: () => {'name': _selectedCategory});
      parts.add(category['name'] ?? _selectedCategory!);
    }
    if (parts.isNotEmpty) title = parts.join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF333333)))),
          if (_selectedCategory != null || _selectedStore != null)
            TextButton(onPressed: () {
              setState(() {
                _selectedCategory = null;
                _selectedStore = null;
                _products = [];
                _isOffline = false;
              });
              _loadProducts(reset: true, useCache: false);
            }, child: const Text('Limpiar')),
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, color: isDark ? AppColors.accent : AppColors.primary),
            onSelected: (value) { setState(() => _sortBy = value); _loadProducts(reset: true, useCache: false); },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'discount', child: Row(children: [if (_sortBy == 'discount') Icon(Icons.check, size: 18, color: isDark ? AppColors.accent : AppColors.primary), const SizedBox(width: 8), const Text('Mayor descuento')])),
              PopupMenuItem(value: 'price_low', child: Row(children: [if (_sortBy == 'price_low') Icon(Icons.check, size: 18, color: isDark ? AppColors.accent : AppColors.primary), const SizedBox(width: 8), const Text('Menor precio')])),
              PopupMenuItem(value: 'price_high', child: Row(children: [if (_sortBy == 'price_high') Icon(Icons.check, size: 18, color: isDark ? AppColors.accent : AppColors.primary), const SizedBox(width: 8), const Text('Mayor precio')])),
              PopupMenuItem(value: 'name', child: Row(children: [if (_sortBy == 'name') Icon(Icons.check, size: 18, color: isDark ? AppColors.accent : AppColors.primary), const SizedBox(width: 8), const Text('Nombre A-Z')])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.search_off, size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
      const SizedBox(height: 16),
      Text('No se encontraron productos', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 16)),
      const SizedBox(height: 8),
      TextButton(onPressed: _refreshData, child: const Text('Actualizar')),
    ]));
  }
}

// ==================== PRODUCT CARD ====================

class ProductCard extends StatelessWidget {
  final dynamic product;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final Set<int>? favoriteIds;
  final Function(int)? globalOnToggleFavorite;

  const ProductCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.favoriteIds,
    this.globalOnToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = product['name'] ?? 'Sin nombre';
    final imageUrl = product['image_url'] as String?;
    final minPrice = product['min_price'] as num?;
    final maxDiscount = product['max_discount'] as int?;
    final hasDiscount = product['has_discount'] == true;
    final categoryName = product['category_name'] as String?;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(
            product: product,
            initialIsFavorite: isFavorite,
            onToggleFavorite: () {
              final id = product['id'] as int? ?? 0;
              if (globalOnToggleFavorite != null) {
                globalOnToggleFavorite!(id);
              } else {
                onToggleFavorite();
              }
            },
            favoriteIds: favoriteIds,
            globalOnToggleFavorite: globalOnToggleFavorite,
          ),
        ),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            AspectRatio(aspectRatio: 1, child: imageUrl != null 
              ? Image.network(imageUrl, fit: BoxFit.cover, 
                  errorBuilder: (_, __, ___) => Container(color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200], child: const Icon(Icons.image, size: 40, color: Colors.grey)),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
                  },
                ) 
              : Container(color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200], child: const Icon(Icons.image, size: 40, color: Colors.grey))),
            if (hasDiscount && maxDiscount != null) Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)), child: Text('-$maxDiscount%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
            Positioned(top: 8, right: 8, child: GestureDetector(onTap: onToggleFavorite, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]), child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, size: 20, color: isFavorite ? Colors.red : Colors.grey)))),
          ]),
          Expanded(child: Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (categoryName != null) Container(margin: const EdgeInsets.only(bottom: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.primary.withOpacity(isDark ? 0.3 : 0.1), borderRadius: BorderRadius.circular(4)), child: Text(categoryName, style: TextStyle(color: isDark ? AppColors.accent : AppColors.primary, fontSize: 10, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Expanded(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
            if (minPrice != null) Text('\$${_fmt(minPrice)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: hasDiscount ? Colors.red : (isDark ? Colors.white : Colors.black87))),
          ]))),
        ]),
      ),
    );
  }

  String _fmt(num p) => p.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

// ==================== PRODUCT DETAIL SCREEN ====================

class ProductDetailScreen extends StatefulWidget {
  final dynamic product;
  final bool initialIsFavorite;
  final VoidCallback onToggleFavorite;
  // Опционально — для рекурсивного открытия detail из похожих товаров.
  // Если переданы, секция "Похожие товары" будет открывать вложенный detail
  // с корректными фаворитами.
  final Set<int>? favoriteIds;
  final Function(int)? globalOnToggleFavorite;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.initialIsFavorite,
    required this.onToggleFavorite,
    this.favoriteIds,
    this.globalOnToggleFavorite,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late bool _isFavorite;
  
  // Похожие товары
  List<dynamic> _similar = [];
  bool _similarLoading = true;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initialIsFavorite;
    _loadSimilar();
  }

  Future<void> _loadSimilar() async {
    final id = widget.product['id'] as int?;
    if (id == null) {
      setState(() => _similarLoading = false);
      return;
    }
    try {
      final response = await http
          .get(Uri.parse('$apiBaseUrl/products/$id/similar?limit=5'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _similar = (data['items'] as List?) ?? [];
        _similarLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _similarLoading = false);
    }
  }

  void _handleToggle() {
    setState(() => _isFavorite = !_isFavorite);
    widget.onToggleFavorite();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = widget.product;
    final name = product['name'] ?? 'Sin nombre';
    final imageUrl = product['image_url'] as String?;
    final prices = product['prices'] as List? ?? [];
    final maxDiscount = product['max_discount'] as int?;
    final categoryName = product['category_name'] as String?;
    final unit = product['unit'] as String?;
    final description = product['description'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            color: _isFavorite ? Colors.red : Colors.white,
            onPressed: _handleToggle,
          ),
        ],
      ),
      body: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(aspectRatio: 1, child: imageUrl != null ? Image.network(imageUrl, fit: BoxFit.contain) : Container(color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200], child: const Icon(Icons.image, size: 80, color: Colors.grey))),
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (categoryName != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.primary.withOpacity(isDark ? 0.3 : 0.1), borderRadius: BorderRadius.circular(6)), child: Text(categoryName, style: TextStyle(color: isDark ? AppColors.accent : AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600))),
          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3)),
          if (unit != null && unit.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Unidad: $unit', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 14))),
          if (maxDiscount != null && maxDiscount > 0) Container(margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)), child: Text('-$maxDiscount%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
          const SizedBox(height: 20),
          const Text('Precios por tienda:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...prices.map((p) => _priceCard(p, isDark)),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Descripción:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!)), child: SelectableText(description, style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.grey[800], height: 1.7))),
          ],
          // Похожие товары — после описания
          _buildSimilarSection(isDark),
          const SizedBox(height: 20),
        ])),
      ])),
    );
  }
  
  Widget _buildSimilarSection(bool isDark) {
    if (_similarLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Productos similares:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (_similar.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Productos similares:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: _similar.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) => _SimilarProductCard(
                product: _similar[i],
                isDark: isDark,
                isFavorite: widget.favoriteIds?.contains(_similar[i]['id'] as int? ?? -1) ?? false,
                onTap: () => _openSimilar(_similar[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _openSimilar(dynamic product) {
    final id = product['id'] as int? ?? 0;
    final isFav = widget.favoriteIds?.contains(id) ?? false;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: product,
          initialIsFavorite: isFav,
          onToggleFavorite: () {
            if (widget.globalOnToggleFavorite != null) {
              widget.globalOnToggleFavorite!(id);
            }
          },
          // Передаём дальше — для рекурсивного открытия из новых похожих
          favoriteIds: widget.favoriteIds,
          globalOnToggleFavorite: widget.globalOnToggleFavorite,
        ),
      ),
    );
  }

  Widget _priceCard(dynamic p, bool isDark) {
    final storeName = p['store_name'] ?? '';
    final storeSlug = p['store_slug'] ?? '';
    final regularPrice = p['regular_price'] as num? ?? 0;
    final promoPrice = p['promo_price'] as num?;
    final discount = p['discount_percent'] as int?;
    final hasPromo = promoPrice != null && promoPrice > 0;
    final storeColor = AppColors.getStoreColor(storeSlug);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Row(children: [
        StoreBrandBadge(slug: storeSlug, size: 44),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          if (discount != null && discount > 0) Text('-$discount%', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (hasPromo) ...[
            Text('\$${_fmt(regularPrice)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 13)),
            Text('\$${_fmt(promoPrice)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
          ] else Text('\$${_fmt(regularPrice)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
      ])),
    );
  }

  String _fmt(num p) => p.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

/// Компактная карточка товара для горизонтального списка "Похожие товары".
class _SimilarProductCard extends StatelessWidget {
  final dynamic product;
  final bool isDark;
  final bool isFavorite;
  final VoidCallback onTap;

  const _SimilarProductCard({
    required this.product,
    required this.isDark,
    required this.isFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = product['name'] ?? '';
    final imageUrl = product['image_url'] as String?;
    final minPrice = product['min_price'] as num?;
    final maxDiscount = product['max_discount'] as int?;
    final hasDiscount = product['has_discount'] == true;

    return SizedBox(
      width: 140,
      child: Material(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
                              child: const Icon(Icons.image, size: 32, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
                            child: const Icon(Icons.image, size: 32, color: Colors.grey),
                          ),
                  ),
                  if (hasDiscount && maxDiscount != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-$maxDiscount%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  if (isFavorite)
                    const Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(Icons.favorite, size: 16, color: Colors.red),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (minPrice != null)
                        Text(
                          '\$${_fmt(minPrice)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: hasDiscount
                                ? Colors.red
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(num p) => p.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
}

class StoresScreen extends StatefulWidget {
  final Set<int> favoriteIds;
  final Function(int) onToggleFavorite;
  final bool Function(int) isFavorite;
  final CacheService cacheService;

  const StoresScreen({super.key, required this.favoriteIds, required this.onToggleFavorite, required this.isFavorite, required this.cacheService});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  List<dynamic> _stores = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadStores(); }

  Future<void> _loadStores() async {
    setState(() => _isLoading = true);
    
    final cached = widget.cacheService.getCachedStores();
    if (cached != null) {
      setState(() {
        _stores = (cached as List).where((s) => (s['product_count'] ?? 0) > 0).toList();
        _isLoading = false;
      });
    }
    
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/stores')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final allStores = json.decode(utf8.decode(response.bodyBytes)) ?? [];
        setState(() => _stores = (allStores as List).where((s) => (s['product_count'] ?? 0) > 0).toList());
        await widget.cacheService.cacheStores(allStores);
      }
    } catch (e) { debugPrint('Error: $e'); }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(width: 36, height: 36, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset('assets/icon.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Text('🦜', style: TextStyle(fontSize: 20)))))),
          const Text('Tiendas'),
        ]),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : _stores.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.store_outlined, size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]), const SizedBox(height: 16), Text('No hay tiendas disponibles', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]))]))
              : RefreshIndicator(onRefresh: _loadStores, child: ListView.builder(padding: const EdgeInsets.fromLTRB(16, 16, 16, 130), itemCount: _stores.length, itemBuilder: (context, index) {
                  final store = _stores[index];
                  final slug = store['slug'] ?? '';
                  final name = store['name'] ?? slug;
                  final count = store['product_count'] ?? 0;
                  final color = AppColors.getStoreColor(slug);
                  return Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(
                    leading: StoreBrandBadge(slug: slug, size: 52),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('$count productos'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StoreProductsScreen(storeSlug: slug, storeName: name, favoriteIds: widget.favoriteIds, onToggleFavorite: widget.onToggleFavorite, isFavorite: widget.isFavorite))),
                  ));
                })),
    );
  }
}

// ==================== STORE PRODUCTS SCREEN ====================

class StoreProductsScreen extends StatefulWidget {
  final String storeSlug;
  final String storeName;
  final Set<int> favoriteIds;
  final Function(int) onToggleFavorite;
  final bool Function(int) isFavorite;

  const StoreProductsScreen({super.key, required this.storeSlug, required this.storeName, required this.favoriteIds, required this.onToggleFavorite, required this.isFavorite});

  @override
  State<StoreProductsScreen> createState() => _StoreProductsScreenState();
}

class _StoreProductsScreenState extends State<StoreProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() { super.initState(); _scrollController.addListener(_onScroll); _loadProducts(); }
  @override
  void dispose() { _scrollController.dispose(); super.dispose(); }

  void _onScroll() { if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoading && _hasMore) _loadProducts(); }

  Future<void> _loadProducts() async {
    if (_isLoading && _currentPage > 1) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/products?store=${widget.storeSlug}&page=$_currentPage&per_page=20&sort_by=discount')).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final items = data['items'] as List? ?? [];
        setState(() { if (_currentPage == 1) _products = items; else _products.addAll(items); _hasMore = _currentPage < (data['pages'] ?? 1); _currentPage++; });
      }
    } catch (e) { debugPrint('Error: $e'); }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.storeName)),
      body: _products.isEmpty && _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : GridView.builder(controller: _scrollController, padding: const EdgeInsets.all(12), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.58, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: _products.length + (_hasMore ? 1 : 0), itemBuilder: (context, index) {
              if (index == _products.length) return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
              return ProductCard(
                product: _products[index],
                isFavorite: widget.isFavorite(_products[index]['id'] ?? 0),
                onToggleFavorite: () => widget.onToggleFavorite(_products[index]['id'] ?? 0),
                favoriteIds: widget.favoriteIds,
                globalOnToggleFavorite: widget.onToggleFavorite,
              );
            }),
    );
  }
}

// ==================== MAP SCREEN ====================

class MapScreen extends StatefulWidget {
  final CacheService cacheService;
  const MapScreen({super.key, required this.cacheService});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  List<dynamic> _allLocations = [];
  List<dynamic> _stores = [];
  Set<Marker> _markers = {};
  String? _selectedStore;
  String? _selectedCity;
  bool _isLoading = true;
  String? _error;

  // Начальная позиция — Медельин (центр)
  static const CameraPosition _initialPos = CameraPosition(
    target: LatLng(6.2476, -75.5658),
    zoom: 11,
  );

  /// Города, доступные для выбранного магазина (уникальный отсортированный список).
  List<String> get _citiesForSelectedStore {
    if (_selectedStore == null) return const [];
    final cities = <String>{};
    for (final loc in _allLocations) {
      if (loc['store_slug'] == _selectedStore) {
        final city = loc['city'] as String?;
        if (city != null && city.isNotEmpty) cities.add(city);
      }
    }
    final list = cities.toList()..sort();
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _error = null; });

    // Сначала — кэш
    final cachedLocations = widget.cacheService.getCachedLocations();
    final cachedStores = widget.cacheService.getCachedStores();
    if (cachedLocations != null && cachedStores != null) {
      setState(() {
        _allLocations = cachedLocations;
        _stores = (cachedStores as List).where((s) => (s['product_count'] ?? 0) > 0).toList();
        _rebuildMarkers();
        _isLoading = false;
      });
    }

    // Потом — сеть
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/locations')).timeout(const Duration(seconds: 10)),
        http.get(Uri.parse('$apiBaseUrl/stores')).timeout(const Duration(seconds: 10)),
      ]);
      if (responses[0].statusCode == 200) {
        final data = json.decode(utf8.decode(responses[0].bodyBytes)) as List;
        _allLocations = data;
        await widget.cacheService.cacheLocations(data);
      }
      if (responses[1].statusCode == 200) {
        final allStores = json.decode(utf8.decode(responses[1].bodyBytes)) ?? [];
        _stores = (allStores as List).where((s) => (s['product_count'] ?? 0) > 0).toList();
      }
      setState(() { _rebuildMarkers(); _isLoading = false; });
    } catch (e) {
      debugPrint('Error loading map data: $e');
      setState(() {
        _isLoading = false;
        if (cachedLocations == null) _error = 'Sin conexión';
      });
    }
  }

  void _rebuildMarkers() {
    Iterable<dynamic> filtered = _allLocations;
    if (_selectedStore != null) {
      filtered = filtered.where((l) => l['store_slug'] == _selectedStore);
    }
    if (_selectedCity != null) {
      filtered = filtered.where((l) => l['city'] == _selectedCity);
    }

    _markers = filtered.map<Marker>((loc) {
      final id = loc['id']?.toString() ?? '';
      final lat = (loc['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (loc['longitude'] as num?)?.toDouble() ?? 0;
      final slug = loc['store_slug'] as String? ?? '';
      return Marker(
        markerId: MarkerId(id),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(AppColors.getStoreMarkerHue(slug)),
        onTap: () => _showLocationSheet(loc),
      );
    }).toSet();
  }

  /// Подгоняет камеру под все точки с заданным списком фильтров (store/city).
  /// Используем при явном выборе города.
  Future<void> _fitToFilteredLocations() async {
    if (_mapController == null) return;

    Iterable<dynamic> filtered = _allLocations;
    if (_selectedStore != null) {
      filtered = filtered.where((l) => l['store_slug'] == _selectedStore);
    }
    if (_selectedCity != null) {
      filtered = filtered.where((l) => l['city'] == _selectedCity);
    }
    final list = filtered.toList();
    if (list.isEmpty) return;

    if (list.length == 1) {
      final lat = (list.first['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (list.first['longitude'] as num?)?.toDouble() ?? 0;
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14),
      );
      return;
    }

    double minLat = double.infinity, maxLat = -double.infinity;
    double minLng = double.infinity, maxLng = -double.infinity;
    for (final loc in list) {
      final lat = (loc['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (loc['longitude'] as num?)?.toDouble() ?? 0;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    await _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  void _showLocationSheet(dynamic loc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slug = loc['store_slug'] as String? ?? '';
    final storeName = loc['store_name'] as String? ?? slug;
    final name = loc['name'] as String? ?? storeName;
    final address = loc['address'] as String?;
    final city = loc['city'] as String?;
    final phone = loc['phone'] as String?;
    final hours = loc['hours'] as String?;
    final color = AppColors.getStoreColor(slug);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(children: [
              StoreBrandBadge(slug: slug, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(storeName, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            if (address != null && address.isNotEmpty)
              _infoRow(Icons.place, address + (city != null ? ', $city' : ''), isDark),
            if (phone != null && phone.isNotEmpty)
              _infoRow(Icons.phone, phone, isDark),
            if (hours != null && hours.isNotEmpty)
              _infoRow(Icons.access_time, hours, isDark),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.grey[800])),
          ),
        ],
      ),
    );
  }

  void _selectStoreFilter(String? slug) {
    setState(() {
      _selectedStore = slug;
      _selectedCity = null; // При смене магазина сбрасываем город
      _rebuildMarkers();
    });
    // Намеренно не двигаем камеру — пусть пользователь сам решает, куда смотреть.
    // Зум на конкретный город произойдёт только при явном выборе чипа города ниже.
  }

  void _selectCityFilter(String? city) {
    setState(() {
      _selectedCity = city;
      _rebuildMarkers();
    });
    if (city != null) {
      _fitToFilteredLocations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 36, height: 36,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/icon.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Text('🦜', style: TextStyle(fontSize: 20)))),
            ),
          ),
          const Text('Mapa'),
        ]),
      ),
      body: Column(children: [
        // Фильтр магазинов
        Container(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          child: SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Todas'),
                    selected: _selectedStore == null,
                    onSelected: (_) => _selectStoreFilter(null),
                    backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    side: isDark ? BorderSide.none : BorderSide(color: _selectedStore == null ? AppColors.primary : Colors.grey[300]!),
                  ),
                ),
                ..._stores.map((store) {
                  final slug = store['slug'] ?? '';
                  final name = store['name'] ?? slug;
                  final isSelected = _selectedStore == slug;
                  final storeColor = AppColors.getStoreColor(slug);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: StoreBrandBadge(slug: slug, size: 22, elevated: false),
                      label: Text(name),
                      selected: isSelected,
                      onSelected: (_) => _selectStoreFilter(isSelected ? null : slug),
                      selectedColor: storeColor.withOpacity(isDark ? 0.3 : 0.2),
                      checkmarkColor: storeColor,
                      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      side: isDark ? BorderSide.none : BorderSide(color: isSelected ? storeColor : Colors.grey[300]!),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        // Подменю городов — показывается только если выбран магазин, у которого >1 города
        if (_selectedStore != null && _citiesForSelectedStore.length > 1)
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                    child: ChoiceChip(
                      label: const Text('Todas las ciudades'),
                      selected: _selectedCity == null,
                      onSelected: (_) => _selectCityFilter(null),
                      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      side: isDark ? BorderSide.none : BorderSide(color: _selectedCity == null ? AppColors.primary : Colors.grey[300]!),
                    ),
                  ),
                  ..._citiesForSelectedStore.map((city) {
                    final isSelected = _selectedCity == city;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                      child: ChoiceChip(
                        avatar: Icon(Icons.location_city, size: 16, color: isSelected ? AppColors.primary : (isDark ? Colors.grey[400] : Colors.grey[600])),
                        label: Text(city),
                        selected: isSelected,
                        onSelected: (_) => _selectCityFilter(isSelected ? null : city),
                        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        side: isDark ? BorderSide.none : BorderSide(color: isSelected ? AppColors.primary : Colors.grey[300]!),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        // Карта
        Expanded(
          child: Stack(children: [
            GoogleMap(
              initialCameraPosition: _initialPos,
              markers: _markers,
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.2),
                child: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
              ),
            if (_error != null)
              Positioned(
                top: 12, left: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    Icon(Icons.wifi_off, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: TextStyle(color: Colors.orange.shade700, fontSize: 13))),
                  ]),
                ),
              ),
            if (!_isLoading && _allLocations.isEmpty && _error == null)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('No hay ubicaciones disponibles', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

// ==================== FAVORITES SCREEN ====================

class FavoritesScreen extends StatefulWidget {
  final Set<int> favoriteIds;
  final Function(int) onToggleFavorite;
  final CacheService cacheService;

  const FavoritesScreen({super.key, required this.favoriteIds, required this.onToggleFavorite, required this.cacheService});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<dynamic> _products = [];
  bool _isLoading = false;

  @override
  void didUpdateWidget(FavoritesScreen oldWidget) { super.didUpdateWidget(oldWidget); if (widget.favoriteIds != oldWidget.favoriteIds) _loadFavorites(); }
  @override
  void initState() { super.initState(); _loadFavorites(); }

  Future<void> _loadFavorites() async {
    if (widget.favoriteIds.isEmpty) { setState(() => _products = []); return; }
    setState(() => _isLoading = true);
    
    final cachedProducts = widget.cacheService.getCachedProducts();
    if (cachedProducts != null) {
      final favProducts = cachedProducts.where((p) => widget.favoriteIds.contains(p['id'])).toList();
      if (favProducts.isNotEmpty) {
        setState(() { _products = favProducts; _isLoading = false; });
        return;
      }
    }
    
    List<dynamic> loadedProducts = [];
    for (final id in widget.favoriteIds) {
      try {
        final response = await http.get(Uri.parse('$apiBaseUrl/products/$id')).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) loadedProducts.add(json.decode(utf8.decode(response.bodyBytes)));
      } catch (e) { debugPrint('Error loading product $id: $e'); }
    }
    setState(() { _products = loadedProducts; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(width: 36, height: 36, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset('assets/icon.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Text('🦜', style: TextStyle(fontSize: 20)))))),
          const Text('Favoritos'),
        ]),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : widget.favoriteIds.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.favorite_outline, size: 80, color: isDark ? Colors.grey[600] : Colors.grey[300]), const SizedBox(height: 16), Text('No tienes favoritos', style: TextStyle(fontSize: 18, color: isDark ? Colors.grey[400] : Colors.grey[600])), const SizedBox(height: 8), Text('Añade productos a favoritos\npara verlos aquí', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[500]))]))
              : RefreshIndicator(onRefresh: _loadFavorites, child: GridView.builder(padding: const EdgeInsets.fromLTRB(12, 12, 12, 130), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.58, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: _products.length, itemBuilder: (context, index) {
                  final product = _products[index];
                  final productId = product['id'] as int? ?? 0;
                  return ProductCard(
                    product: product,
                    isFavorite: widget.favoriteIds.contains(productId),
                    onToggleFavorite: () { widget.onToggleFavorite(productId); setState(() => _products.removeWhere((p) => p['id'] == productId)); },
                    favoriteIds: widget.favoriteIds,
                    globalOnToggleFavorite: widget.onToggleFavorite,
                  );
                })),
    );
  }
}

// ==================== CATALOGS SCREEN (заглушка) ====================

// ==================== CATALOGS SCREEN ====================

/// Менеджер кеша каталогов.
/// 
/// При синхронизации:
/// 1. Получает актуальный список каталогов и URL всех страниц с сервера
/// 2. Сравнивает с сохранёнными в SharedPreferences URL предыдущей синхронизации
/// 3. Удаляет из файлового кеша картинки которых больше нет на сервере
/// 4. Предзагружает новые картинки в кеш
/// 5. Сохраняет актуальный набор URL для следующего сравнения
/// 
/// Используется flutter_cache_manager (внутри cached_network_image),
/// файлы лежат в системном кеше приложения, переживают перезапуск.
class CatalogCacheManager {
  static const _kPrefsKey = 'cached_catalog_image_urls';
  
  /// Сохранённые с прошлой синхронизации URL.
  static Future<Set<String>> _getStoredUrls() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kPrefsKey) ?? [];
    return list.toSet();
  }
  
  static Future<void> _saveStoredUrls(Set<String> urls) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kPrefsKey, urls.toList());
  }
  
  /// Синхронизация: загружает что нужно, удаляет что не нужно.
  /// onProgress(loaded, total) — для отображения прогресса в UI.
  static Future<void> syncCache({
    required void Function(int loaded, int total) onProgress,
  }) async {
    // 1. Получить список каталогов
    final catalogsRes = await http
        .get(Uri.parse('$apiBaseUrl/catalogs'))
        .timeout(const Duration(seconds: 15));
    if (catalogsRes.statusCode != 200) {
      throw Exception('Failed to load catalogs list');
    }
    final List<dynamic> catalogs =
        json.decode(utf8.decode(catalogsRes.bodyBytes));
    
    // 2. Собрать все URL текущих картинок (обложки + страницы)
    final currentUrls = <String>{};
    for (final c in catalogs) {
      final coverUrl = c['cover_url'] as String?;
      if (coverUrl != null && coverUrl.isNotEmpty) {
        currentUrls.add(coverUrl);
      }
      final catalogId = c['id'] as int;
      try {
        final detailRes = await http
            .get(Uri.parse('$apiBaseUrl/catalogs/$catalogId'))
            .timeout(const Duration(seconds: 10));
        if (detailRes.statusCode == 200) {
          final detail =
              json.decode(utf8.decode(detailRes.bodyBytes)) as Map<String, dynamic>;
          final pages = (detail['pages'] as List?) ?? [];
          for (final p in pages) {
            final url = p['image_url'] as String?;
            if (url != null && url.isNotEmpty) currentUrls.add(url);
          }
        }
      } catch (_) {
        // продолжаем — если один каталог не отдал детали, его страницы пропускаем
      }
    }
    
    // 3. Сравнить с сохранёнными и удалить устаревшие
    final storedUrls = await _getStoredUrls();
    final toRemove = storedUrls.difference(currentUrls);
    for (final url in toRemove) {
      try {
        await DefaultCacheManager().removeFile(url);
      } catch (_) {
        // Игнорируем — файла могло уже не быть
      }
    }
    
    // 4. Предзагрузить актуальные (если нет в кеше — скачаются)
    final urlList = currentUrls.toList();
    final total = urlList.length;
    int loaded = 0;
    onProgress(0, total);
    for (final url in urlList) {
      try {
        await DefaultCacheManager().getSingleFile(url);
      } catch (_) {
        // не критично — продолжаем
      }
      loaded++;
      onProgress(loaded, total);
    }
    
    // 5. Сохранить актуальный набор для следующего раза
    await _saveStoredUrls(currentUrls);
  }
}

/// Модель каталога (краткая инфа для списка).
class CatalogListItem {
  final int id;
  final int storeChainId;
  final String storeSlug;
  final String storeName;
  final String? storeLogoUrl;
  final String slot;
  final String title;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final String? coverUrl;
  final int pageCount;

  CatalogListItem({
    required this.id,
    required this.storeChainId,
    required this.storeSlug,
    required this.storeName,
    this.storeLogoUrl,
    required this.slot,
    required this.title,
    this.validFrom,
    this.validUntil,
    this.coverUrl,
    required this.pageCount,
  });

  factory CatalogListItem.fromJson(Map<String, dynamic> json) {
    return CatalogListItem(
      id: json['id'] as int,
      storeChainId: json['store_chain_id'] as int,
      storeSlug: json['store_slug'] as String,
      storeName: json['store_name'] as String,
      storeLogoUrl: json['store_logo_url'] as String?,
      slot: json['slot'] as String,
      title: json['title'] as String,
      validFrom: json['valid_from'] != null ? DateTime.tryParse(json['valid_from'] as String) : null,
      validUntil: json['valid_until'] != null ? DateTime.tryParse(json['valid_until'] as String) : null,
      coverUrl: json['cover_url'] as String?,
      pageCount: (json['page_count'] as int?) ?? 0,
    );
  }
}

/// Локализация слотов на испанский для UI.
String _localizeSlot(String slot) {
  switch (slot) {
    case 'semanal':
      return 'Semanal';
    case 'festivo':
      return 'Festivo';
    case 'fin_de_semana':
      return 'Fin de semana';
    default:
      return slot;
  }
}

class CatalogsScreen extends StatefulWidget {
  const CatalogsScreen({super.key});

  @override
  State<CatalogsScreen> createState() => _CatalogsScreenState();
}

class _CatalogsScreenState extends State<CatalogsScreen> {
  List<CatalogListItem> _catalogs = [];
  bool _loading = true;
  String? _error;
  
  // Прогресс синхронизации кеша
  bool _syncing = false;
  int _syncLoaded = 0;
  int _syncTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadCatalogs();
    // Параллельно — синхронизация кеша картинок
    _syncCache();
  }

  Future<void> _loadCatalogs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http
          .get(Uri.parse('$apiBaseUrl/catalogs'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      final catalogs = data
          .map((j) => CatalogListItem.fromJson(j as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _catalogs = catalogs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }
  
  Future<void> _syncCache() async {
    if (_syncing) return;
    if (!mounted) return;
    setState(() {
      _syncing = true;
      _syncLoaded = 0;
      _syncTotal = 0;
    });
    try {
      await CatalogCacheManager.syncCache(
        onProgress: (loaded, total) {
          if (!mounted) return;
          setState(() {
            _syncLoaded = loaded;
            _syncTotal = total;
          });
        },
      );
    } catch (_) {
      // Тихо игнорируем — кеш досинхронизируется при следующем открытии
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogos'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadCatalogs();
          await _syncCache();
        },
        child: Column(
          children: [
            // Индикатор синхронизации кеша
            if (_syncing && _syncTotal > 0)
              Container(
                color: AppColors.primary.withOpacity(isDark ? 0.18 : 0.10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: _syncTotal > 0 ? _syncLoaded / _syncTotal : null,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Descargando catálogos $_syncLoaded / $_syncTotal',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: _buildBody(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      // Распознаём тип ошибки для дружелюбного сообщения
      final errStr = _error!.toLowerCase();
      String friendlyTitle;
      String friendlySubtitle;
      IconData icon;
      
      if (errStr.contains('socketexception') ||
          errStr.contains('failed host lookup') ||
          errStr.contains('network is unreachable') ||
          errStr.contains('no address associated')) {
        friendlyTitle = 'Sin conexión a internet';
        friendlySubtitle = 'Verifica tu conexión Wi-Fi o datos móviles e inténtalo de nuevo.';
        icon = Icons.wifi_off_rounded;
      } else if (errStr.contains('timeout') || errStr.contains('timed out')) {
        friendlyTitle = 'La conexión es muy lenta';
        friendlySubtitle = 'La respuesta del servidor está tardando demasiado. Inténtalo de nuevo.';
        icon = Icons.hourglass_disabled_rounded;
      } else if (errStr.contains('500') ||
          errStr.contains('502') ||
          errStr.contains('503') ||
          errStr.contains('504')) {
        friendlyTitle = 'Servidor no disponible';
        friendlySubtitle = 'Estamos teniendo problemas. Inténtalo más tarde.';
        icon = Icons.cloud_off_rounded;
      } else {
        friendlyTitle = 'No se pudieron cargar los catálogos';
        friendlySubtitle = 'Algo salió mal. Inténtalo de nuevo.';
        icon = Icons.error_outline_rounded;
      }
      
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(icon, size: 72, color: AppColors.primary.withOpacity(0.6)),
          const SizedBox(height: 20),
          Center(
            child: Text(
              friendlyTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                friendlySubtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                _loadCatalogs();
                _syncCache();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (_catalogs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.menu_book_rounded,
            size: 96,
            color: AppColors.primary.withOpacity(0.7),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Aún no hay catálogos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Vuelve pronto — los nuevos catálogos aparecerán aquí.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 130),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _catalogs.length,
      itemBuilder: (context, i) => _CatalogCard(catalog: _catalogs[i]),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final CatalogListItem catalog;
  const _CatalogCard({required this.catalog});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CatalogViewerScreen(catalogId: catalog.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Обложка
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: isDark ? Colors.grey[850] : Colors.grey[200],
                    child: catalog.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: catalog.coverUrl!,
                            fit: BoxFit.cover,
                            placeholder: (ctx, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (ctx, url, err) => Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.menu_book_rounded,
                              size: 48,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                          ),
                  ),
                  // Badge с числом страниц
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.copy_outlined, size: 11, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            '${catalog.pageCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Badge с типом slot
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _localizeSlot(catalog.slot),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Текстовая часть
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    catalog.storeName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    catalog.title,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (catalog.validUntil != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Hasta ${_formatDate(catalog.validUntil!)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    return '${d.day} ${months[d.month - 1]}';
  }
}

// ==================== CATALOG VIEWER ====================

/// Детальная страница одного каталога: PageView со свайпом + пинч-зум.
class CatalogViewerScreen extends StatefulWidget {
  final int catalogId;
  const CatalogViewerScreen({super.key, required this.catalogId});

  @override
  State<CatalogViewerScreen> createState() => _CatalogViewerScreenState();
}

class _CatalogViewerScreenState extends State<CatalogViewerScreen> {
  Map<String, dynamic>? _catalog;
  List<dynamic> _pages = [];
  bool _loading = true;
  String? _error;
  int _currentPage = 0;
  final PageController _pageController = PageController();
  
  // Контролируем зум текущей страницы.
  // Когда _isZoomed=true — InteractiveViewer перехватывает жесты (пан внутри картинки)
  // и PageView блокируется (NeverScrollable).
  // Когда _isZoomed=false — PageView получает свайпы для перелистывания.
  final TransformationController _transformationController = TransformationController();
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformChanged);
    _loadDetail();
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  void _onTransformChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.01;
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
    }
  }
  
  void _onPageChanged(int i) {
    // Сбрасываем зум при перелистывании на новую страницу
    _transformationController.value = Matrix4.identity();
    setState(() {
      _currentPage = i;
      _isZoomed = false;
    });
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http
          .get(Uri.parse('$apiBaseUrl/catalogs/${widget.catalogId}'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _catalog = data;
        _pages = (data['pages'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        foregroundColor: Colors.white,
        elevation: 0,
        title: _catalog != null
            ? Text(
                _catalog!['store_name'] as String? ?? 'Catálogo',
                style: const TextStyle(fontSize: 16),
              )
            : const Text('Catálogo'),
        actions: [
          if (_pages.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${_currentPage + 1} / ${_pages.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 56),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadDetail,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_pages.isEmpty) {
      return const Center(
        child: Text('No hay páginas', style: TextStyle(color: Colors.white70)),
      );
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: _pages.length,
      onPageChanged: _onPageChanged,
      // Когда страница зумлена — PageView НЕ перехватывает свайп,
      // чтобы InteractiveViewer мог панорамировать картинку.
      // Когда не зумлена — стандартная физика для перелистывания.
      physics: _isZoomed
          ? const NeverScrollableScrollPhysics()
          : const PageScrollPhysics(),
      itemBuilder: (ctx, i) {
        final page = _pages[i] as Map<String, dynamic>;
        final url = page['image_url'] as String;
        final isCurrent = i == _currentPage;
        
        // Сама страница — изображение с интерактивным зумом
        final pageContent = InteractiveViewer(
          // Только текущая страница использует наш контроллер.
          // У соседних — свой default (не влияет на наш свайп).
          transformationController: isCurrent ? _transformationController : null,
          // Пан включён только когда страница зумлена — иначе
          // InteractiveViewer не перехватывает горизонтальные свайпы.
          panEnabled: isCurrent && _isZoomed,
          scaleEnabled: true,
          minScale: 1.0,
          maxScale: 4.0,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (ctx, _) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (ctx, _, __) => const Center(
                child: Icon(Icons.broken_image_outlined,
                    size: 64, color: Colors.white24),
              ),
            ),
          ),
        );
        
        // Анимация 3D-переворота: страница вращается вокруг своего края
        return AnimatedBuilder(
          animation: _pageController,
          builder: (ctx, child) {
            double value = 0;
            if (_pageController.position.haveDimensions) {
              value = (_pageController.page ?? _currentPage.toDouble()) - i;
            } else {
              value = (_currentPage - i).toDouble();
            }
            // value: -1 = страница уже улистала влево (предыдущая)
            //         0 = текущая страница, фронтально
            //        +1 = страница ещё справа (следующая)
            
            // Клампим для безопасности
            final clamped = value.clamp(-1.0, 1.0);
            
            // Угол поворота — до 90° в каждую сторону
            final angle = clamped * math.pi / 2;
            
            // Вращаем вокруг левого края если страница уходит влево,
            // вокруг правого если страница приходит справа.
            final alignment = clamped < 0
                ? Alignment.centerRight
                : Alignment.centerLeft;
            
            // Тень за переворачивающейся страницей для эффекта объёма
            final shadowOpacity = clamped.abs() * 0.7;
            
            return Transform(
              alignment: alignment,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015) // перспектива
                ..rotateY(angle),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  child!,
                  if (shadowOpacity > 0)
                    IgnorePointer(
                      child: Container(
                        color: Colors.black.withOpacity(shadowOpacity * 0.5),
                      ),
                    ),
                ],
              ),
            );
          },
          child: pageContent,
        );
      },
    );
  }
}

// ==================== GLASS BOTTOM NAVIGATION ====================

/// Плавающее нижнее меню в стиле Telegram/iOS.
/// Парит над контентом с отступами, blur через ImageFilter,
/// активная иконка — капсула с brand-цветом.
class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final barColor = isDark
        ? Colors.black.withOpacity(0.55)
        : Colors.white.withOpacity(0.75);

    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);

    // Системный нижний inset:
    //  - на жестовой навигации Android: 0 или ~16px (тонкая полоска)
    //  - на трёхкнопочной навигации Android: ~48px (под кнопками)
    //  - на iPhone с Face ID: ~34px (home indicator)
    // Берём максимум этого inset и 8px, чтобы у плашки всегда был визуальный
    // зазор от низа экрана, но при этом она не лезла под системные кнопки.
    final systemBottom = MediaQuery.of(context).padding.bottom;
    final bottomPadding = systemBottom > 0 ? systemBottom + 4 : 8.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  final selected = i == currentIndex;
                  return _GlassNavButton(
                    item: item,
                    selected: selected,
                    onTap: () => onTap(i),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _GlassNavButton extends StatelessWidget {
  final GlassNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _GlassNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppColors.primary;
    final inactiveColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? activeColor.withOpacity(isDark ? 0.22 : 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? item.activeIcon : item.icon,
                size: 24,
                color: selected ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
