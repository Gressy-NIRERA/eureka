import 'package:flutter/material.dart';

import 'package:eureka/core/theme/app_colors.dart';
import 'package:eureka/data/models/food_models.dart';
import 'package:eureka/data/services/food_service.dart';
import 'package:eureka/widgets/home/food_category_bar.dart';
import 'package:eureka/widgets/home/food_product_card.dart';
import 'package:eureka/widgets/home/home_bottom_nav.dart';
import 'package:eureka/widgets/home/promo_banner_carousel.dart';

/// Default ISO country code used to browse the food catalog before the user
/// picks (or logs into) a specific country — same fallback ('bi') the
/// official Duma app uses when no country context is available yet
/// (see `payment_handler.dart` / `register.dart`).
const String kDefaultIsoCode = 'bi';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FoodService _foodService = FoodService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;

  List<FoodCategory> _categories = [];
  List<FoodProduct> _products = [];

  int _selectedCategoryId = kAllCategoriesId;
  int _navIndex = 0;
  String _query = '';

  final Set<int> _favoriteIds = {};
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _foodService.fetchCategories(kDefaultIsoCode),
        _foodService.fetchProducts(kDefaultIsoCode),
      ]);

      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<FoodCategory>;
        _products = results[1] as List<FoodProduct>;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Impossible de charger le menu. Vérifiez votre connexion.";
      });
    }
  }

  void _toggleFavorite(int productId) {
    setState(() {
      if (_favoriteIds.contains(productId)) {
        _favoriteIds.remove(productId);
      } else {
        _favoriteIds.add(productId);
      }
    });
  }

  void _addToCart(FoodProduct product) {
    setState(() => _cartCount++);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.title} ajouté au panier'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textDark,
      ),
    );
  }

  List<FoodProduct> get _visibleProducts {
    var list = _products;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      return list.where((p) => p.title.toLowerCase().contains(q)).toList();
    }
    if (_selectedCategoryId != kAllCategoriesId) {
      // The Duma API nests the translated category name inside each
      // product's `category_system_id` field (see FoodProduct.fromJson),
      // so matching is done on that localized name rather than a numeric id.
      final category = _categories.where((c) => c.id == _selectedCategoryId).toList();
      if (category.isNotEmpty) {
        final name = category.first.name.toLowerCase();
        list = list.where((p) => p.categorySystemName.toLowerCase() == name).toList();
      }
    }
    return list;
  }

  ProductBadge _badgeFor(FoodProduct product, int index) {
    if (product.hasDiscount) return ProductBadge.discount;
    if (index == 0) return ProductBadge.bestseller;
    if (product.rating >= 4.5) return ProductBadge.popular;
    return ProductBadge.none;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadCatalog,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              SliverToBoxAdapter(
                child: PromoBannerCarousel(onOrderNow: () => setState(() => _navIndex = 1)),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              if (_query.isEmpty)
                SliverToBoxAdapter(
                  child: FoodCategoryBar(
                    categories: _categories,
                    selectedId: _selectedCategoryId,
                    onSelected: (id) => setState(() => _selectedCategoryId = id),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(child: _buildSectionContent()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _navIndex,
        cartCount: _cartCount,
        onTap: (index) => setState(() => _navIndex = index),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _squareIconButton(icon: Icons.menu_rounded, onTap: () {}),
              Row(
                children: [
                  _squareIconButton(icon: Icons.notifications_none_rounded, onTap: () {}),
                  const SizedBox(width: 10),
                  _squareIconButton(
                    icon: Icons.shopping_bag_outlined,
                    onTap: () => setState(() => _navIndex = 2),
                    badgeCount: _cartCount,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Text(
                'Hi, Chicken Lover! ',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textGrey),
              ),
              Text('👋', style: TextStyle(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Crispy. Juicy.\nAlways Delicious.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2, color: AppColors.textDark),
          ),
          const SizedBox(height: 18),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _squareIconButton({required IconData icon, required VoidCallback onTap, int badgeCount = 0}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Icon(icon, color: AppColors.textDark, size: 22),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: const BoxDecoration(color: AppColors.badge, shape: BoxShape.circle),
                child: Text(
                  '$badgeCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim()),
              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
              decoration: const InputDecoration(
                hintText: 'Search for your favorite chicken...',
                hintStyle: TextStyle(color: AppColors.textGrey, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: AppColors.textGrey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.tune_rounded, color: AppColors.textDark),
        ),
      ],
    );
  }

  Widget _buildSectionContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.textGrey, size: 40),
            const SizedBox(height: 12),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCatalog,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final products = _visibleProducts;

    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Text('Aucun article trouvé', style: TextStyle(color: AppColors.textGrey, fontSize: 15)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular Combos',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _selectedCategoryId = kAllCategoriesId;
                  _query = '';
                  _searchController.clear();
                }),
                child: const Text(
                  'View All',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
              badge: _badgeFor(product, index),
              isFavorite: _favoriteIds.contains(product.id),
              onToggleFavorite: () => _toggleFavorite(product.id),
              onAdd: () => _addToCart(product),
            );
          },
        ),
      ],
    );
  }
}
