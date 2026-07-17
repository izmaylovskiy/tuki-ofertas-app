import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../providers/favorites_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../screens/product_detail_screen.dart';
import '../utils/formatters.dart';
import '../config/theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final bestPrice = product.bestPrice;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение с бейджем скидки
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen
                  Container(
                    color: Colors.grey.shade100,
                    child: product.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.shade400,
                              size: 40,
                            ),
                          )
                        : Icon(
                            Icons.image_not_supported,
                            color: Colors.grey.shade400,
                            size: 40,
                          ),
                  ),

                  // Badge de descuento
                  if (product.maxDiscount != null && product.maxDiscount! > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.discountBadgeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '-${product.maxDiscount}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                  // Botón favorito
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Consumer<FavoritesProvider>(
                      builder: (context, favorites, _) {
                        final isFav = favorites.isFavorite(product.id);
                        return IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_outline,
                            color: isFav ? Colors.red : Colors.grey.shade600,
                            size: 22,
                          ),
                          onPressed: () => favorites.toggleFavorite(product.id),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            padding: const EdgeInsets.all(6),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Información del producto
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ),

                    // Precios
                    if (bestPrice != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Precio con descuento
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (bestPrice.hasPromo && bestPrice.regularPrice != null)
                                  Text(
                                    Formatters.formatPrice(bestPrice.regularPrice),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Text(
                                  Formatters.formatPrice(bestPrice.effectivePrice),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: bestPrice.hasPromo 
                                        ? Colors.red.shade700 
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Botón agregar
                          Consumer<ShoppingListProvider>(
                            builder: (context, shoppingList, _) {
                              final inList = shoppingList.hasProduct(product.id);
                              return GestureDetector(
                                onTap: () {
                                  if (inList) {
                                    shoppingList.removeProduct(product.id);
                                  } else {
                                    shoppingList.addProduct(product);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${product.name} agregado'),
                                        duration: const Duration(seconds: 1),
                                        action: SnackBarAction(
                                          label: 'Deshacer',
                                          onPressed: () {
                                            shoppingList.removeProduct(product.id);
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: inList 
                                        ? AppTheme.primaryColor 
                                        : AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    inList ? Icons.check : Icons.add,
                                    size: 20,
                                    color: inList ? Colors.white : AppTheme.primaryColor,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 6),

                    // Logos de tiendas con oferta
                    if (product.storesWithPromo.isNotEmpty)
                      Row(
                        children: product.storesWithPromo.take(3).map((slug) {
                          return Container(
                            margin: const EdgeInsets.only(right: 4),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppTheme.storeColors[slug] ?? Colors.grey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              slug[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
