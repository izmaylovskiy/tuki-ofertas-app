import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import '../config/theme.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductsProvider>(
      builder: (context, provider, _) {
        if (provider.categories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: provider.categories.length + 1, // +1 для "Todas"
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Chip "Todas"
                  final isSelected = provider.selectedCategoryId == null;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: const Text('Todas'),
                      selected: isSelected,
                      onSelected: (_) => provider.setCategory(null),
                      avatar: Icon(
                        Icons.grid_view,
                        size: 18,
                        color: isSelected ? Colors.white : AppTheme.primaryColor,
                      ),
                      selectedColor: AppTheme.primaryColor,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }

                final category = provider.categories[index - 1];
                final isSelected = provider.selectedCategoryId == category.id;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(category.name),
                    selected: isSelected,
                    onSelected: (_) => provider.setCategory(
                      isSelected ? null : category.id,
                    ),
                    avatar: Icon(
                      category.iconData,
                      size: 18,
                      color: isSelected ? Colors.white : AppTheme.primaryColor,
                    ),
                    selectedColor: AppTheme.primaryColor,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
