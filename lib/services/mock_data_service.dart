import '../models/store.dart';
import '../models/category.dart';
import '../models/product.dart';

class MockDataService {
  static List<Store> getStores() {
    return [
      Store(
        id: 1,
        name: 'Éxito',
        slug: 'exito',
        logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/25/Logo_%C3%89xito.svg/320px-Logo_%C3%89xito.svg.png',
        websiteUrl: 'https://www.exito.com',
      ),
      Store(
        id: 2,
        name: 'Carulla',
        slug: 'carulla',
        logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Carulla_logo.svg/320px-Carulla_logo.svg.png',
        websiteUrl: 'https://www.carulla.com',
      ),
      Store(
        id: 3,
        name: 'D1',
        slug: 'd1',
        logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/D1_logo.svg/200px-D1_logo.svg.png',
        websiteUrl: 'https://www.tiendasd1.com',
      ),
      Store(
        id: 4,
        name: 'Ara',
        slug: 'ara',
        logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Tiendas_ara_logo.svg/320px-Tiendas_ara_logo.svg.png',
        websiteUrl: 'https://www.ara.com.co',
      ),
      Store(
        id: 5,
        name: 'Euro',
        slug: 'euro',
        logoUrl: 'https://www.supermercadoslaeuropea.com/wp-content/uploads/2021/01/logo-euro.png',
        websiteUrl: 'https://www.euro.com.co',
      ),
    ];
  }

  static List<Category> getCategories() {
    return [
      Category(id: 1, name: 'Frutas y Verduras', slug: 'frutas', icon: 'frutas'),
      Category(id: 2, name: 'Carnes', slug: 'carnes', icon: 'carnes'),
      Category(id: 3, name: 'Lácteos', slug: 'lacteos', icon: 'lacteos'),
      Category(id: 4, name: 'Bebidas', slug: 'bebidas', icon: 'bebidas'),
      Category(id: 5, name: 'Panadería', slug: 'panaderia', icon: 'panaderia'),
      Category(id: 6, name: 'Snacks', slug: 'snacks', icon: 'snacks'),
      Category(id: 7, name: 'Congelados', slug: 'congelados', icon: 'congelados'),
      Category(id: 8, name: 'Despensa', slug: 'despensa', icon: 'despensa'),
      Category(id: 9, name: 'Limpieza', slug: 'limpieza', icon: 'limpieza'),
      Category(id: 10, name: 'Cuidado Personal', slug: 'cuidado_personal', icon: 'cuidado_personal'),
      Category(id: 11, name: 'Mascotas', slug: 'mascotas', icon: 'mascotas'),
    ];
  }

  static List<Product> getProducts() {
    return [
      // Productos con múltiples precios en diferentes tiendas
      Product(
        id: 1,
        name: 'Leche entera Alquería 1L',
        categoryId: 3,
        categoryName: 'Lácteos',
        imageUrl: 'https://exitocol.vtexassets.com/arquivos/ids/15553513/Leche-ALQUERIA-entera-x1100-ml_118081.jpg',
        unit: 'unidad',
        prices: [
          ProductPrice(
            id: 1,
            storeSlug: 'exito',
            storeName: 'Éxito',
            regularPrice: 5200,
            promoPrice: 4160,
            discountPercent: 20,
            promoDescription: '20% de descuento',
            validUntil: DateTime.now().add(const Duration(days: 5)),
          ),
          ProductPrice(
            id: 2,
            storeSlug: 'd1',
            storeName: 'D1',
            regularPrice: 4800,
            promoPrice: null,
            discountPercent: null,
          ),
          ProductPrice(
            id: 3,
            storeSlug: 'ara',
            storeName: 'Ara',
            regularPrice: 4900,
            promoPrice: 4400,
            discountPercent: 10,
            promoDescription: '10% OFF',
            validUntil: DateTime.now().add(const Duration(days: 3)),
          ),
        ],
      ),
      Product(
        id: 2,
        name: 'Arroz Diana 5kg',
        categoryId: 8,
        categoryName: 'Despensa',
        imageUrl: 'https://exitocol.vtexassets.com/arquivos/ids/5369538/Arroz-DIANA-x5000-g_7386.jpg',
        unit: 'unidad',
        prices: [
          ProductPrice(
            id: 4,
            storeSlug: 'exito',
            storeName: 'Éxito',
            regularPrice: 24900,
            promoPrice: 19920,
            discountPercent: 20,
            promoDescription: '20% dcto',
          ),
          ProductPrice(
            id: 5,
            storeSlug: 'carulla',
            storeName: 'Carulla',
            regularPrice: 26500,
            promoPrice: 21200,
            discountPercent: 20,
          ),
          ProductPrice(
            id: 6,
            storeSlug: 'd1',
            storeName: 'D1',
            regularPrice: 21900,
            promoPrice: null,
          ),
        ],
      ),
      Product(
        id: 3,
        name: 'Coca-Cola 2.5L',
        categoryId: 4,
        categoryName: 'Bebidas',
        imageUrl: 'https://exitocol.vtexassets.com/arquivos/ids/15752908/Gaseosa-COCA-COLA-sabor-original-x25-L_119749.jpg',
        unit: 'unidad',
        prices: [
          ProductPrice(
            id: 7,
            storeSlug: 'exito',
            storeName: 'Éxito',
            regularPrice: 8900,
            promoPrice: 6230,
            discountPercent: 30,
            promoDescription: '30% de descuento',
          ),
          ProductPrice(
            id: 8,
            storeSlug: 'ara',
            storeName: 'Ara',
            regularPrice: 8500,
            promoPrice: 7650,
            discountPercent: 10,
          ),
          ProductPrice(
            id: 9,
            storeSlug: 'euro',
            storeName: 'Euro',
            regularPrice: 8700,
            promoPrice: null,
          ),
        ],
      ),
      Product(
        id: 4,
        name: 'Huevos AAA x30',
        categoryId: 3,
        categoryName: 'Lácteos',
        imageUrl: 'https://exitocol.vtexassets.com/arquivos/ids/18835982/Huevo-AAA-rojo-x-30-und_124954-1.jpg',
        unit: 'unidad',
        prices: [
          ProductPrice(
            id: 10,
            storeSlug: 'd1',
            storeName: 'D1',
            regularPrice: 18900,
            promoPrice: 15120,
            discountPercent: 20,
            promoDescription: '20% menos',
          ),
          ProductPrice(
            id: 11,
            storeSlug: 'ara',
            storeName: 'Ara',
            regularPrice: 19500,
            promoPrice: 16575,
            discountPercent: 15,
          ),
          ProductPrice(
            id: 12,
            storeSlug: 'exito',
            storeName: 'Éxito',
            regularPrice: 21900,
            promoPrice: null,
          ),
        ],
      ),
      Product(
        id: 5,
        name: 'Aceite Girasol 3L',
        categoryId: 8,
        categoryName: 'Despensa',
        imageUrl: 'https://exitocol.vtexassets.com/arquivos/ids/5361456/Aceite-GIRASOL-x3000-ml_7263.jpg',
        unit: 'unidad',
        prices: [
          ProductPrice(
            id: 13,
            storeSlug: 'exito',
            storeName: 'Éxito',
            regularPrice: 35900,
            promoPrice: 28720,
            discountPercent: 20,
            promoDescription: 'Super oferta',
          ),
          ProductPrice(
            id: 14,
            storeSlug: 'd1',
            storeName: 'D1',
            regularPrice: 31900,
            promoPrice: null,
          ),
        ],
      ),
      Product(
        id: 6,
        name: 'Jabón Rey barra x3',
        categoryId: 9,
        categoryName: 'Limpieza',
        imageUrl: 'https://exitocol.vtexassets.com/arquivos/ids/10019774/Jabon-REY-barra-x-3-und-x-235-g-c-u_49099.jpg',
        unit: 'paquete',
        prices: [
          ProductPrice(
            id: 15,
            storeSlug: 'ara',
            storeName: 'Ara',
            regularPrice: 6900,
            promoPrice: 4830,
            discountPercent: 30,
            promoDescription: '30% OFF',
          ),
          ProductPrice(
            id: 16,
            storeSlug: 'exito',
            storeName: 'Éxito',
            regularPrice: 7500,
            promoPrice: 6000,
            discountPercent: 20,
          ),
        ],
      ),
      Product(
        id: 7,
        name: 'Papel higiénico Familia 12 rollos',
        categoryId: 10,
        categoryName: 'Cuidado Personal',
        imageUrl: 'https://exitocol.vtexassets.com/arquivos/ids/17534163/Papel-higienico-FAMILIA-megarollo-x-12-rollos_121379.jpg',
        unit: 'paquete',
        prices: [
          ProductPrice(
            id: 17,
            storeSlug: 'exito',
            storeName: 'Éxito',
            regularPrice: 29900,
            promoPrice: 20930,
            discountPercent: 30,
            promoDescription: '30% dcto',
          ),
          ProductPrice(
            id: 18,
            storeSlug: 'carulla',
            storeName: 'Carulla',
            regularPrice: 31500,
            promoPrice: 25200,
            discountPercent: 20,
          ),
          ProductPrice(
            id: 19,
            storeSlug: 'd1',
            storeName: 'D1',
            regularPrice: 26900,
            promoPrice: null,
          ),
        ],
      ),
      Product(
        id: 8,
        name: 'Pollo entero kg',
        categoryId: 2,
        categoryName: 'Carnes',
        imageUrl: 'https://exitocol.vtexassets.com/arquivos/ids/7609339/Pollo-entero-sin-visceras-x-1-kg_26918.jpg',
        unit: 'kg',
        prices: [
          ProductPrice(
            id: 20,
            storeSlug: 'exito',
            storeName: 'Éxito',
            regularPrice: 12900,
            promoPrice: 9030,
            discountPercent: 30,
            promoDescription: 'Super precio',
          ),
          ProductPrice(
            id: 21,
            storeSlug: 'd1',
            storeName: 'D1',
            regularPrice: 10900,
            promoPrice: null,
          ),
          ProductPrice(
            id: 22,
            storeSlug: 'ara',
            storeName: 'Ara',
            regularPrice: 11500,
            promoPrice: 9775,
            discountPercent: 15,
          ),
        ],
      ),
      Product(
        id: 9,
        name: 'Banano criollo kg',
        categoryId: 1,
        categoryName: 'Frutas y Verduras',
        imageUrl: 'https://exitocol.vtexassets.com/arquivos/ids/15645165/Banano-criollo-x-1-Kg_118892.jpg',
        unit: 'kg',
        prices: [
          ProductPrice(
            id: 23,
            storeSlug: 'exito',
            storeName: 'Éxito',
            regularPrice: 3200,
            promoPrice: 1920,
            discountPercent: 40,
            promoDescription: '40% menos',
          ),
          ProductPrice(
            id: 24,
            storeSlug: 'carulla',
            storeName: 'Carulla',
            regularPrice: 3500,
            promoPrice: 2450,
            discountPercent: 30,
          ),
          ProductPrice(
            id: 25,
            storeSlug: 'ara',
            storeName: 'Ara',
            regularPrice: 2900,
            promoPrice: null,
          ),
        ],
      ),
      Product(
        id: 10,
        name: 'Detergente Ariel 2kg',
        categoryId: 9,
        categoryName: 'Limpieza',
        imageUrl: 'https://exitocol.vtexassets.com/arquivos/ids/14787437/Detergente-ARIEL-poder-concentrado-x-2-kg_108574.jpg',
        unit: 'unidad',
        prices: [
          ProductPrice(
            id: 26,
            storeSlug: 'exito',
            storeName: 'Éxito',
            regularPrice: 42900,
            promoPrice: 32175,
            discountPercent: 25,
            promoDescription: '25% dcto',
          ),
          ProductPrice(
            id: 27,
            storeSlug: 'carulla',
            storeName: 'Carulla',
            regularPrice: 44500,
            promoPrice: 35600,
            discountPercent: 20,
          ),
          ProductPrice(
            id: 28,
            storeSlug: 'd1',
            storeName: 'D1',
            regularPrice: 38900,
            promoPrice: null,
          ),
        ],
      ),
      Product(
        id: 11,
        name: 'Café Sello Rojo 500g',
        categoryId: 8,
        categoryName: 'Despensa',
        imageUrl: 'https://exitocol.vtexassets.com/arquivos/ids/16654591/Cafe-SELLO-ROJO-x-500-g_120467.jpg',
        unit: 'unidad',
        prices: [
          ProductPrice(
            id: 29,
            storeSlug: 'd1',
            storeName: 'D1',
            regularPrice: 14900,
            promoPrice: 11920,
            discountPercent: 20,
            promoDescription: '20% OFF',
          ),
          ProductPrice(
            id: 30,
            storeSlug: 'ara',
            storeName: 'Ara',
            regularPrice: 15500,
            promoPrice: 13175,
            discountPercent: 15,
          ),
          ProductPrice(
            id: 31,
            storeSlug: 'exito',
            storeName: 'Éxito',
            regularPrice: 16900,
            promoPrice: null,
          ),
        ],
      ),
      Product(
        id: 12,
        name: 'Atún Van Camps 160g x4',
        categoryId: 8,
        categoryName: 'Despensa',
        imageUrl: 'https://exitocol.vtexassets.com/arquivos/ids/5407963/Atun-VAN-CAMPS-en-aceite-x-4-latas-x-160-g-c-u_7712.jpg',
        unit: 'paquete',
        prices: [
          ProductPrice(
            id: 32,
            storeSlug: 'exito',
            storeName: 'Éxito',
            regularPrice: 24900,
            promoPrice: 17430,
            discountPercent: 30,
            promoDescription: '2x1',
          ),
          ProductPrice(
            id: 33,
            storeSlug: 'carulla',
            storeName: 'Carulla',
            regularPrice: 26500,
            promoPrice: 21200,
            discountPercent: 20,
          ),
        ],
      ),
      Product(
        id: 13,
        name: 'Yogurt Alpina 1L',
        categoryId: 3,
        categoryName: 'Lácteos',
        imageUrl: 'https://exitocol.vtexassets.com/arquivos/ids/15765269/Yogurt-ALPINA-natural-x-1000-g_119821.jpg',
        unit: 'unidad',
        prices: [
          ProductPrice(
            id: 34,
            storeSlug: 'exito',
            storeName: 'Éxito',
            regularPrice: 9900,
            promoPrice: 7425,
            discountPercent: 25,
            promoDescription: '25% menos',
          ),
          ProductPrice(
            id: 35,
            storeSlug: 'd1',
            storeName: 'D1',
            regularPrice: 8500,
            promoPrice: null,
          ),
        ],
      ),
      Product(
        id: 14,
        name: 'Cerveza Poker x6 latas',
        categoryId: 4,
        categoryName: 'Bebidas',
        imageUrl: 'https://exitocol.vtexassets.com/arquivos/ids/14432161/Cerveza-POKER-lata-x-6-und-x-330-ml-c-u_105061.jpg',
        unit: 'sixpack',
        prices: [
          ProductPrice(
            id: 36,
            storeSlug: 'exito',
            storeName: 'Éxito',
            regularPrice: 18900,
            promoPrice: 15120,
            discountPercent: 20,
            promoDescription: '20% dcto',
          ),
          ProductPrice(
            id: 37,
            storeSlug: 'euro',
            storeName: 'Euro',
            regularPrice: 17500,
            promoPrice: null,
          ),
          ProductPrice(
            id: 38,
            storeSlug: 'ara',
            storeName: 'Ara',
            regularPrice: 18500,
            promoPrice: 16650,
            discountPercent: 10,
          ),
        ],
      ),
      Product(
        id: 15,
        name: 'Papa pastusa kg',
        categoryId: 1,
        categoryName: 'Frutas y Verduras',
        imageUrl: 'https://exitocol.vtexassets.com/arquivos/ids/7676044/Papa-pastusa-x-1-kg_27331.jpg',
        unit: 'kg',
        prices: [
          ProductPrice(
            id: 39,
            storeSlug: 'exito',
            storeName: 'Éxito',
            regularPrice: 4500,
            promoPrice: 2700,
            discountPercent: 40,
            promoDescription: 'Super oferta',
          ),
          ProductPrice(
            id: 40,
            storeSlug: 'd1',
            storeName: 'D1',
            regularPrice: 3200,
            promoPrice: null,
          ),
          ProductPrice(
            id: 41,
            storeSlug: 'ara',
            storeName: 'Ara',
            regularPrice: 3500,
            promoPrice: 2800,
            discountPercent: 20,
          ),
        ],
      ),
    ];
  }

  // Фильтрация по магазину
  static List<Product> getProductsByStore(String storeSlug) {
    return getProducts()
        .where((p) => p.prices.any((price) => price.storeSlug == storeSlug))
        .toList();
  }

  // Фильтрация по категории
  static List<Product> getProductsByCategory(int categoryId) {
    return getProducts()
        .where((p) => p.categoryId == categoryId)
        .toList();
  }

  // Поиск
  static List<Product> searchProducts(String query) {
    final lowerQuery = query.toLowerCase();
    return getProducts()
        .where((p) => p.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  // Топ скидки
  static List<Product> getTopDiscounts({int limit = 10}) {
    final products = getProducts()
        .where((p) => p.maxDiscount != null && p.maxDiscount! > 0)
        .toList();
    products.sort((a, b) => (b.maxDiscount ?? 0).compareTo(a.maxDiscount ?? 0));
    return products.take(limit).toList();
  }
}
