import 'package:flutter/material.dart';

import 'package:eureka/data/models/food_models.dart';
import 'package:eureka/widgets/home/food_product_card.dart';

/// Two-column product grid shared by every screen that lists
/// [FoodProduct]s (Menu, Offers, the home preview), so the grid layout and
/// badge rules live in a single place instead of being re-implemented per
/// screen.
class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.products,
    required this.favoriteIds,
    required this.onToggleFavorite,
    required this.onAdd,
    this.badgeResolver,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final List<FoodProduct> products;
  final Set<int> favoriteIds;
  final ValueChanged<int> onToggleFavorite;
  final ValueChanged<FoodProduct> onAdd;
  final ProductBadge Function(FoodProduct product, int index)? badgeResolver;
  final EdgeInsets padding;

  static ProductBadge defaultBadge(FoodProduct product, int index) {
    if (product.hasDiscount) return ProductBadge.discount;
    if (index == 0) return ProductBadge.bestseller;
    if (product.rating >= 4.5) return ProductBadge.popular;
    return ProductBadge.none;
  }

  @override
  Widget build(BuildContext context) {
    final resolver = badgeResolver ?? defaultBadge;

    return GridView.builder(
      padding: padding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.66,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return FoodProductCard(
          product: product,
          badge: resolver(product, index),
          isFavorite: favoriteIds.contains(product.id),
          onToggleFavorite: () => onToggleFavorite(product.id),
          onAdd: () => onAdd(product),
        );
      },
    );
  }
}
