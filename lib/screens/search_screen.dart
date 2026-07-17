import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import '../providers/stores_provider.dart';
import '../widgets/product_card.dart';
import '../config/theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Buscar productos'),
      ),
      body: Column(
        children: [
          // Поле поиска
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ProductsProvider>().setSearchQuery('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                context.read<ProductsProvider>().setSearchQuery(value);
                setState(() {});
              },
            ),
          ),

          // Результаты
          Expanded(
            child: Consumer2<ProductsProvider, StoresProvider>(
              builder: (context, productsProvider, storesProvider, _) {
                final query = productsProvider.searchQuery;

                if (query.isEmpty) {
                  // Показываем популярные категории или подсказки
                  return _buildSearchSuggestions(context, productsProvider);
                }

                final products = productsProvider.getFilteredProducts(
                  storeFilter: storesProvider.selectedStoreSlugs.isEmpty
                      ? null
                      : storesProvider.selectedStoreSlugs,
                );

                if (products.isEmpty) {
                  return Center(
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
                          'No se encontraron resultados para "$query"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) => ProductCard(
                    product: products[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions(BuildContext context, ProductsProvider provider) {
    final recentSearches = ['Leche', 'Arroz', 'Pollo', 'Huevos']; // Можно сохранять в SharedPreferences

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Búsquedas populares',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentSearches.map((search) {
              return ActionChip(
                label: Text(search),
                avatar: const Icon(Icons.trending_up, size: 18),
                onPressed: () {
                  _searchController.text = search;
                  provider.setSearchQuery(search);
                  setState(() {});
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Categorías',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          
          ...provider.categories.map((category) {
            return ListTile(
              leading: Icon(category.iconData, color: AppTheme.primaryColor),
              title: Text(category.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                provider.setCategory(category.id);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}
