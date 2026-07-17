import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../providers/favorites_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/stores_provider.dart';
import '../utils/formatters.dart';
import '../config/theme.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, favorites, _) {
              final isFav = favorites.isFavorite(product.id);
              return IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_outline,
                  color: isFav ? Colors.red : null,
                ),
                onPressed: () => favorites.toggleFavorite(product.id),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Compartir - próximamente')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: Stack(
                children: [
                  Center(
                    child: product.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            fit: BoxFit.contain,
                            height: 200,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.image_not_supported,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                          )
                        : Icon(
                            Icons.image_not_supported,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                  ),
                  // Бейдж скидки
                  if (product.maxDiscount != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.discountBadgeColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '-${product.maxDiscount}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Информация
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Категория
                  if (product.categoryName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.categoryName!,
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Название
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Единица измерения
                  if (product.unit != null)
                    Text(
                      'Por ${product.unit}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Лучшая цена
                  if (product.bestPrice != null) ...[
                    Text(
                      'Mejor precio',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.formatPrice(product.bestPrice!.effectivePrice),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (product.bestPrice!.hasPromo &&
                            product.bestPrice!.regularPrice != null)
                          Text(
                            Formatters.formatPrice(product.bestPrice!.regularPrice),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'en ${product.bestPrice!.storeName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Сравнение цен
                  const Text(
                    'Comparar precios',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...product.prices.map((price) => _buildPriceCard(context, price)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Consumer<ShoppingListProvider>(
            builder: (context, shoppingList, _) {
              final inList = shoppingList.hasProduct(product.id);
              return ElevatedButton(
                onPressed: () {
                  if (inList) {
                    shoppingList.removeProduct(product.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Eliminado de la lista')),
                    );
                  } else {
                    shoppingList.addProduct(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Agregado a la lista')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: inList ? Colors.grey.shade200 : AppTheme.primaryColor,
                  foregroundColor: inList ? AppTheme.textPrimary : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(inList ? Icons.remove_shopping_cart : Icons.add_shopping_cart),
                    const SizedBox(width: 8),
                    Text(
                      inList ? 'Quitar de la lista' : 'Agregar a la lista',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPriceCard(BuildContext context, ProductPrice price) {
    final storesProvider = context.read<StoresProvider>();
    final store = storesProvider.getStoreBySlug(price.storeSlug);
    final isBestPrice = price == product.bestPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isBestPrice ? AppTheme.primaryColor.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBestPrice ? AppTheme.primaryColor : Colors.grey.shade200,
          width: isBestPrice ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Logo tienda
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.storeColors[price.storeSlug] ?? Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                store?.name.substring(0, 1) ?? price.storeSlug[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        price.storeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (isBestPrice) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'MEJOR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (price.promoDescription != null)
                    Text(
                      price.promoDescription!,
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                  if (price.validUntil != null)
                    Text(
                      Formatters.formatValidUntil(price.validUntil),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            // Precio
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (price.hasPromo && price.regularPrice != null)
                  Text(
                    Formatters.formatPrice(price.regularPrice),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Text(
                  Formatters.formatPrice(price.effectivePrice),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: price.hasPromo ? Colors.red.shade700 : AppTheme.textPrimary,
                  ),
                ),
                if (price.discountPercent != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.discountBadgeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '-${price.discountPercent}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
