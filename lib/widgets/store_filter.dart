import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/stores_provider.dart';
import '../config/theme.dart';

class StoreFilter extends StatelessWidget {
  const StoreFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StoresProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tiendas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (provider.hasSelection)
                      TextButton(
                        onPressed: () => provider.clearSelection(),
                        child: const Text('Ver todas'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: provider.stores.length,
                  itemBuilder: (context, index) {
                    final store = provider.stores[index];
                    final isSelected = provider.isStoreSelected(store.slug);
                    final storeColor = AppTheme.storeColors[store.slug] ?? Colors.grey;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => provider.toggleStore(store.slug),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 70,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? storeColor.withOpacity(0.15) 
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? storeColor : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo o inicial
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: storeColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: store.logoUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: CachedNetworkImage(
                                          imageUrl: store.logoUrl!,
                                          width: 30,
                                          height: 30,
                                          fit: BoxFit.contain,
                                          errorWidget: (_, __, ___) => Text(
                                            store.name.substring(0, 1),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        store.name.substring(0, 1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                store.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? storeColor : AppTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
