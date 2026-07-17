import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/shopping_list.dart';
import '../utils/formatters.dart';
import '../config/theme.dart';

class ShoppingListItemWidget extends StatelessWidget {
  final ShoppingListItem item;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
  final Function(int) onQuantityChanged;

  const ShoppingListItemWidget({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final bestPrice = product?.bestPrice;

    return Dismissible(
      key: Key('shopping_item_${item.productId}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Checkbox
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: item.isChecked 
                        ? AppTheme.primaryColor 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: item.isChecked 
                          ? AppTheme.primaryColor 
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: item.isChecked
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
                const SizedBox(width: 12),

                // Imagen
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: product?.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: product!.imageUrl!,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.shopping_basket,
                          color: Colors.grey.shade400,
                        ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product?.name ?? 'Producto',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: item.isChecked 
                              ? TextDecoration.lineThrough 
                              : null,
                          color: item.isChecked 
                              ? Colors.grey.shade500 
                              : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (bestPrice != null)
                        Row(
                          children: [
                            Text(
                              Formatters.formatPrice(bestPrice.effectivePrice),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: bestPrice.hasPromo 
                                    ? Colors.red.shade700 
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.storeColors[bestPrice.storeSlug]
                                    ?.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                bestPrice.storeName,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.storeColors[bestPrice.storeSlug],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Cantidad
                Column(
                  children: [
                    // Subtotal
                    if (bestPrice != null)
                      Text(
                        Formatters.formatPrice(
                          bestPrice.effectivePrice * item.quantity,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Controles de cantidad
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => onQuantityChanged(item.quantity - 1),
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.remove,
                                size: 16,
                                color: item.quantity > 1 
                                    ? AppTheme.textPrimary 
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => onQuantityChanged(item.quantity + 1),
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(8),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.add,
                                size: 16,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
