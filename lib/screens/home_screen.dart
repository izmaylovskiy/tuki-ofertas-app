import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import '../providers/stores_provider.dart';
import '../widgets/store_filter.dart';
import '../widgets/category_chips.dart';
import '../widgets/product_card.dart';
import '../widgets/sort_button.dart';
import '../config/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: AppTheme.primaryColor,
              title: Row(
                children: [
                  Icon(Icons.local_offer, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Ofertas Colombia',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notificaciones - próximamente')),
                    );
                  },
                ),
              ],
            ),

            // Фильтр магазинов
            const SliverToBoxAdapter(
              child: StoreFilter(),
            ),

            // Категории
            const SliverToBoxAdapter(
              child: CategoryChips(),
            ),

            // Заголовок и сортировка
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Consumer<ProductsProvider>(
                      builder: (context, provider, _) {
                        final categoryId = provider.selectedCategoryId;
                        final category = categoryId != null
                            ? provider.categories.firstWhere(
                                (c) => c.id == categoryId,
                                orElse: () => provider.categories.first,
                              )
                            : null;
                        
                        return Text(
                          category?.name ?? 'Mejores ofertas',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        );
                      },
                    ),
                    const SortButton(),
                  ],
                ),
              ),
            ),

            // Сетка продуктов
            Consumer2<ProductsProvider, StoresProvider>(
              builder: (context, productsProvider, storesProvider, _) {
                if (productsProvider.isLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final products = productsProvider.getFilteredProducts(
                  storeFilter: storesProvider.selectedStoreSlugs.isEmpty
                      ? null
                      : storesProvider.selectedStoreSlugs,
                );

                if (products.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay productos',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              productsProvider.clearFilters();
                              storesProvider.clearSelection();
                            },
                            child: const Text('Limpiar filtros'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ProductCard(product: products[index]),
                      childCount: products.length,
                    ),
                  ),
                );
              },
            ),

            // Нижний отступ
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );
  }
}
