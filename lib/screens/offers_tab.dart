import 'package:flutter/material.dart';

import 'package:eureka/core/strings/app_strings.dart';
import 'package:eureka/data/models/food_models.dart';
import 'package:eureka/widgets/catalog/async_catalog_view.dart';
import 'package:eureka/widgets/catalog/product_grid.dart';
import 'package:eureka/widgets/common/page_header.dart';
import 'package:eureka/widgets/home/food_product_card.dart';

/// Every product currently on promotion (`discount_price` lower than the
/// charged price — see `FoodProduct.hasDiscount`), derived straight from the
/// catalog already loaded by the shell: no separate fetch, no separate
/// state to keep in sync.
class OffersTab extends StatelessWidget {
  const OffersTab({
    super.key,
    required this.products,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.favoriteIds,
    required this.onToggleFavorite,
    required this.onAdd,
  });

  final List<FoodProduct> products;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetry;

  final Set<int> favoriteIds;
  final ValueChanged<int> onToggleFavorite;
  final ValueChanged<FoodProduct> onAdd;

  List<FoodProduct> get _discounted => products.where((p) => p.hasDiscount).toList();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRetry,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: PageHeader(title: AppStrings.offersTitle)),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: AsyncCatalogView(
              isLoading: isLoading,
              errorMessage: errorMessage,
              isEmpty: _discounted.isEmpty,
              onRetry: onRetry,
              emptyMessage: AppStrings.noOffers,
              emptyIcon: Icons.local_offer_outlined,
              child: ProductGrid(
                products: _discounted,
                favoriteIds: favoriteIds,
                onToggleFavorite: onToggleFavorite,
                onAdd: onAdd,
                badgeResolver: (product, index) => ProductBadge.discount,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
