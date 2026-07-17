import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/products_provider.dart';
import '../widgets/product_card.dart';
import '../config/theme.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Favoritos'),
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, favorites, _) {
              if (favorites.favoriteIds.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showClearDialog(context, favorites),
              );
            },
          ),
        ],
      ),
      body: Consumer2<FavoritesProvider, ProductsProvider>(
        builder: (context, favorites, products, _) {
          final favoriteProducts = favorites.getFavoriteProducts(products.allProducts);

          if (favoriteProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes favoritos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega productos a favoritos para\nrecibir notificaciones de ofertas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Счётчик и уведомления
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    Text(
                      '${favoriteProducts.length} productos',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.notifications_active, size: 18),
                      label: const Text('Notificar ofertas'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notificaciones activadas para favoritos'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Список
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: favoriteProducts.length,
                  itemBuilder: (context, index) => ProductCard(
                    product: favoriteProducts[index],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showClearDialog(BuildContext context, FavoritesProvider favorites) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar favoritos'),
        content: const Text('¿Eliminar todos los productos de favoritos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              favorites.clearAll();
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
