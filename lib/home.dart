import 'package:flutter/material.dart';

import 'package:eureka/core/strings/app_strings.dart';
import 'package:eureka/core/theme/app_colors.dart';
import 'package:eureka/data/models/food_models.dart';
import 'package:eureka/data/services/food_service.dart';
import 'package:eureka/screens/home_tab.dart';
import 'package:eureka/screens/menu_tab.dart';
import 'package:eureka/screens/offers_tab.dart';
import 'package:eureka/screens/orders_tab.dart';
import 'package:eureka/screens/profile_tab.dart';
import 'package:eureka/widgets/home/food_category_bar.dart';
import 'package:eureka/widgets/home/home_bottom_nav.dart';

/// Default ISO country code used to browse the food catalog before the user
/// picks (or logs into) a specific country — same fallback ('bi') the
/// official Duma app uses when no country context is available yet
/// (see `payment_handler.dart` / `register.dart`).
const String kDefaultIsoCode = 'bi';

/// Bottom navigation tab indices, named to keep call sites (e.g. "jump to
/// Orders after adding to cart") readable instead of bare integers.
abstract final class HomeTabIndex {
  static const int home = 0;
  static const int menu = 1;
  static const int orders = 2;
  static const int offers = 3;
  static const int profile = 4;
}

/// App shell: owns the catalog data and cross-tab state (favorites, cart,
/// the Menu tab's search/category filter) once, and lays out the five
/// bottom-navigation destinations in an [IndexedStack] so switching tabs
/// never re-fetches data, loses scroll position, or duplicates a screen.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FoodService _foodService = FoodService();

  bool _isLoading = true;
  String? _errorMessage;

  List<FoodCategory> _categories = [];
  List<FoodProduct> _products = [];

  int _navIndex = HomeTabIndex.home;
  int _menuCategoryId = kAllCategoriesId;
  String _menuQuery = '';

  final Set<int> _favoriteIds = {};
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
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
        _errorMessage = AppStrings.loadingError;
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
        content: Text('${product.title} ${AppStrings.addedToCart}'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textDark,
      ),
    );
  }

  void _openMenuTab({int? categoryId, String? query}) {
    setState(() {
      _navIndex = HomeTabIndex.menu;
      if (categoryId != null) _menuCategoryId = categoryId;
      if (query != null) _menuQuery = query;
    });
  }

  void _goToTab(int index) => setState(() => _navIndex = index);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(
        categories: _categories,
        products: _products,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        onRetry: _loadCatalog,
        cartCount: _cartCount,
        favoriteIds: _favoriteIds,
        onToggleFavorite: _toggleFavorite,
        onAdd: _addToCart,
        onMenuIconTap: () {},
        onNotificationsTap: () {},
        onCartTap: () => _goToTab(HomeTabIndex.orders),
        onBrowseCategory: (id) => _openMenuTab(categoryId: id),
        onOpenMenuTab: () => _openMenuTab(),
      ),
      MenuTab(
        categories: _categories,
        products: _products,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        onRetry: _loadCatalog,
        selectedCategoryId: _menuCategoryId,
        onCategoryChanged: (id) => setState(() => _menuCategoryId = id),
        query: _menuQuery,
        onQueryChanged: (q) => setState(() => _menuQuery = q.trim()),
        favoriteIds: _favoriteIds,
        onToggleFavorite: _toggleFavorite,
        onAdd: _addToCart,
        cartCount: _cartCount,
        onCartTap: () => _goToTab(HomeTabIndex.orders),
      ),
      const OrdersTab(),
      OffersTab(
        products: _products,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        onRetry: _loadCatalog,
        favoriteIds: _favoriteIds,
        onToggleFavorite: _toggleFavorite,
        onAdd: _addToCart,
      ),
      const ProfileTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _navIndex, children: tabs),
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _navIndex,
        cartCount: _cartCount,
        onTap: _goToTab,
      ),
    );
  }
}
