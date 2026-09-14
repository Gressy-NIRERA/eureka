import 'package:flutter/material.dart';

import 'package:eureka/core/strings/app_strings.dart';
import 'package:eureka/core/theme/app_colors.dart';
import 'package:eureka/data/models/food_models.dart';
import 'package:eureka/widgets/catalog/async_catalog_view.dart';
import 'package:eureka/widgets/catalog/floating_search_bar.dart';
import 'package:eureka/widgets/catalog/product_grid.dart';
import 'package:eureka/widgets/common/top_icon_button.dart';
import 'package:eureka/widgets/home/food_category_bar.dart';
import 'package:eureka/widgets/home/promo_banner_carousel.dart';

/// Landing tab: greeting, promotional carousel, a quick category shortcut
/// row and a preview of the best-rated products. Full browsing (search,
/// category filtering over the whole catalog) lives in the Menu tab so that
/// logic is not duplicated between the two screens — tapping a category or
/// the search bar here simply jumps into Menu already filtered.
class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.categories,
    required this.products,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.cartCount,
    required this.favoriteIds,
    required this.onToggleFavorite,
    required this.onAdd,
    required this.onMenuIconTap,
    required this.onNotificationsTap,
    required this.onCartTap,
    required this.onBrowseCategory,
    required this.onOpenMenuTab,
  });

  final List<FoodCategory> categories;
  final List<FoodProduct> products;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetry;

  final int cartCount;
  final Set<int> favoriteIds;
  final ValueChanged<int> onToggleFavorite;
  final ValueChanged<FoodProduct> onAdd;

  final VoidCallback onMenuIconTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onCartTap;

  /// Switches to the Menu tab pre-filtered on this category id.
  final ValueChanged<int> onBrowseCategory;

  /// Switches to the Menu tab with no filter applied.
  final VoidCallback onOpenMenuTab;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _searchShortcutController = TextEditingController();

  @override
  void dispose() {
    _searchShortcutController.dispose();
    super.dispose();
  }

  List<FoodProduct> get _popularProducts {
    final sorted = [...widget.products]..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRetry,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildGreeting()),
          FloatingSearchBar(
            controller: _searchShortcutController,
            onChanged: (_) {},
            readOnly: true,
            onTap: widget.onOpenMenuTab,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(child: PromoBannerCarousel(onOrderNow: widget.onOpenMenuTab)),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: FoodCategoryBar(
              categories: widget.categories,
              selectedId: kAllCategoriesId,
              onSelected: widget.onBrowseCategory,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(child: _buildPopularSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TopIconButton(icon: Icons.menu_rounded, onTap: widget.onMenuIconTap),
              Row(
                children: [
                  TopIconButton(icon: Icons.notifications_none_rounded, onTap: widget.onNotificationsTap),
                  const SizedBox(width: 10),
                  TopIconButton(
                    icon: Icons.shopping_bag_outlined,
                    onTap: widget.onCartTap,
                    badgeCount: widget.cartCount,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            AppStrings.greeting,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textGrey),
          ),
          const SizedBox(height: 4),
          const Text(
            AppStrings.homeHeadline,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                AppStrings.popularSectionTitle,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              GestureDetector(
                onTap: widget.onOpenMenuTab,
                child: const Text(
                  AppStrings.seeAll,
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        AsyncCatalogView(
          isLoading: widget.isLoading,
          errorMessage: widget.errorMessage,
          isEmpty: _popularProducts.isEmpty,
          onRetry: widget.onRetry,
          child: ProductGrid(
            products: _popularProducts,
            favoriteIds: widget.favoriteIds,
            onToggleFavorite: widget.onToggleFavorite,
            onAdd: widget.onAdd,
          ),
        ),
      ],
    );
  }
}
