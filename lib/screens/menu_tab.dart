import 'package:flutter/material.dart';

import 'package:eureka/core/strings/app_strings.dart';
import 'package:eureka/core/theme/app_colors.dart';
import 'package:eureka/data/models/food_models.dart';
import 'package:eureka/widgets/catalog/async_catalog_view.dart';
import 'package:eureka/widgets/catalog/floating_search_bar.dart';
import 'package:eureka/widgets/catalog/product_grid.dart';
import 'package:eureka/widgets/common/page_header.dart';
import 'package:eureka/widgets/home/food_category_bar.dart';

/// Full catalog browser: search + category filter + product grid. This is
/// the single place that owns catalog-filtering logic — the Home tab only
/// shows a small preview and forwards here instead of re-implementing it.
///
/// The selected category and the search query are owned by the parent
/// (`HomePage` shell) so the Home tab can jump straight into a filtered
/// Menu view without either screen keeping its own, divergent copy of that
/// state.
class MenuTab extends StatefulWidget {
  const MenuTab({
    super.key,
    required this.categories,
    required this.products,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.query,
    required this.onQueryChanged,
    required this.favoriteIds,
    required this.onToggleFavorite,
    required this.onAdd,
    required this.cartCount,
    required this.onCartTap,
  });

  final List<FoodCategory> categories;
  final List<FoodProduct> products;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetry;

  final int selectedCategoryId;
  final ValueChanged<int> onCategoryChanged;
  final String query;
  final ValueChanged<String> onQueryChanged;

  final Set<int> favoriteIds;
  final ValueChanged<int> onToggleFavorite;
  final ValueChanged<FoodProduct> onAdd;

  final int cartCount;
  final VoidCallback onCartTap;

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  late final TextEditingController _controller = TextEditingController(text: widget.query);

  @override
  void didUpdateWidget(covariant MenuTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<FoodProduct> get _filteredProducts {
    var list = widget.products;

    if (widget.query.isNotEmpty) {
      final q = widget.query.toLowerCase();
      return list.where((p) => p.title.toLowerCase().contains(q)).toList();
    }

    if (widget.selectedCategoryId != kAllCategoriesId) {
      // The Duma API nests the translated category name inside each
      // product's `category_system_id` field (see FoodProduct.fromJson),
      // so matching is done on that localized name rather than a numeric id.
      final category = widget.categories.where((c) => c.id == widget.selectedCategoryId).toList();
      if (category.isNotEmpty) {
        final name = category.first.name.toLowerCase();
        list = list.where((p) => p.categorySystemName.toLowerCase() == name).toList();
      }
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRetry,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: AppStrings.menuTitle,
              trailingIcon: Icons.shopping_bag_outlined,
              onTrailingTap: widget.onCartTap,
              trailingBadge: widget.cartCount,
            ),
          ),
          FloatingSearchBar(controller: _controller, onChanged: widget.onQueryChanged),
          if (widget.query.isEmpty) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            SliverToBoxAdapter(
              child: FoodCategoryBar(
                categories: widget.categories,
                selectedId: widget.selectedCategoryId,
                onSelected: widget.onCategoryChanged,
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: AsyncCatalogView(
              isLoading: widget.isLoading,
              errorMessage: widget.errorMessage,
              isEmpty: _filteredProducts.isEmpty,
              onRetry: widget.onRetry,
              child: ProductGrid(
                products: _filteredProducts,
                favoriteIds: widget.favoriteIds,
                onToggleFavorite: widget.onToggleFavorite,
                onAdd: widget.onAdd,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
