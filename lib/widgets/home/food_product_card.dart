import 'package:flutter/material.dart';

import 'package:eureka/core/theme/app_colors.dart';
import 'package:eureka/data/models/food_models.dart';

enum ProductBadge { bestseller, popular, discount, none }

class FoodProductCard extends StatelessWidget {
  const FoodProductCard({
    super.key,
    required this.product,
    required this.badge,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onAdd,
    this.onTap,
  });

  final FoodProduct product;
  final ProductBadge badge;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAdd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final displayPrice = product.effectivePrice;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    product.imageUrl ?? '',
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 130,
                      width: double.infinity,
                      color: AppColors.chipBackground,
                      child: const Icon(Icons.fastfood_rounded, color: AppColors.textGrey, size: 30),
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(height: 130, width: double.infinity, color: AppColors.chipBackground);
                    },
                  ),
                ),
                if (badge != ProductBadge.none)
                  Positioned(top: 10, left: 10, child: _BadgeChip(badge: badge, product: product)),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onToggleFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title.isNotEmpty ? product.title : 'Article',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  if (product.companyName.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      product.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 15, color: AppColors.star),
                      const SizedBox(width: 3),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      ),
                      if (product.reviews > 0) ...[
                        const SizedBox(width: 3),
                        Text('(${product.reviews})', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.hasDiscount)
                              Text(
                                '${product.discountPrice.toStringAsFixed(2)} ${product.currency}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textGrey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              '${displayPrice.toStringAsFixed(2)} ${product.currency}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onAdd,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge, required this.product});

  final ProductBadge badge;
  final FoodProduct product;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (badge) {
      ProductBadge.bestseller => ('BESTSELLER', AppColors.badge),
      ProductBadge.popular => ('POPULAR', AppColors.primary),
      ProductBadge.discount => ('SAVE ${product.discountPercent}%', AppColors.success),
      ProductBadge.none => ('', Colors.transparent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.2),
      ),
    );
  }
}
