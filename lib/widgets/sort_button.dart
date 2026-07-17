import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import '../config/theme.dart';

class SortButton extends StatelessWidget {
  const SortButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductsProvider>(
      builder: (context, provider, _) {
        return PopupMenuButton<SortBy>(
          initialValue: provider.sortBy,
          onSelected: (value) => provider.setSortBy(value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sort,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _getSortLabel(provider.sortBy),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
          itemBuilder: (context) => [
            _buildMenuItem(SortBy.discount, 'Mayor descuento', Icons.percent),
            _buildMenuItem(SortBy.priceLow, 'Menor precio', Icons.arrow_downward),
            _buildMenuItem(SortBy.priceHigh, 'Mayor precio', Icons.arrow_upward),
            _buildMenuItem(SortBy.name, 'Nombre A-Z', Icons.sort_by_alpha),
          ],
        );
      },
    );
  }

  PopupMenuItem<SortBy> _buildMenuItem(SortBy value, String label, IconData icon) {
    return PopupMenuItem<SortBy>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  String _getSortLabel(SortBy sortBy) {
    switch (sortBy) {
      case SortBy.discount:
        return 'Descuento';
      case SortBy.priceLow:
        return 'Precio ↓';
      case SortBy.priceHigh:
        return 'Precio ↑';
      case SortBy.name:
        return 'Nombre';
    }
  }
}
