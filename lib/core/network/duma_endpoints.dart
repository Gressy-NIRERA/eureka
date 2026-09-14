/// Real API endpoints exposed by the Duma platform.
///
/// These mirror exactly what the official Duma app (`duma_taxi`, package
/// `duma`) uses in `lib/core/api/endpoints.dart` and in the `food` module
/// (`lib/modules/food/**`). Eureka only consumes the endpoints it actually
/// needs: authentication (`ClientEndpoints`) and the food catalog
/// (`FoodEndpoints`).
library;

/// Base hosts for the Duma micro-services.
abstract final class DumaUrls {
  /// Accounts / authentication service.
  static const String client = 'https://client.duma.africa/api/v1';

  /// Food ordering service (catalog, categories, companies, orders, ...).
  static const String food = 'https://food.duma.africa/api/v1';
}

/// Authentication endpoints (used to obtain the bearer token consumed by
/// [FoodEndpoints]).
abstract final class ClientEndpoints {
  static const String _b = DumaUrls.client;

  static const String login = '$_b/user/login';
  static const String register = '$_b/user/register';
}

/// Endpoints of the Duma **food** module.
abstract final class FoodEndpoints {
  static const String _b = DumaUrls.food;

  /// Countries where the food service is available.
  static const String countries = '$_b/country';

  /// Food categories (buckets, burgers, tenders, sides, drinks, ...)
  /// available for a given country ISO code (e.g. `bi`, `rw`).
  static String categories(String isoCode) =>
      '$_b/categorysystem/${isoCode.toLowerCase()}';

  /// Restaurants / companies serving food in [isoCode].
  static String companies(String isoCode, {int page = 1}) =>
      '$_b/company/${isoCode.toLowerCase()}?page=$page';

  static String companyDetail(int companyId) => '$_b/company/detail/$companyId';

  /// Full product catalog for [isoCode].
  static String products(String isoCode) =>
      '$_b/products/${isoCode.toLowerCase()}';

  static String productDetail(int productId) =>
      '$_b/products/details/$productId';

  static String productRelated(int productId) =>
      '$_b/products/products/$productId';

  static String search(String query) => '$_b/search?query=$query';

  static const String favorites = '$_b/favorite/favoritebyuser';
  static String favoriteProduct(int productId) =>
      '$_b/favorite/product/$productId';

  static const String orderStore = '$_b/order/store';
  static const String orderUser = '$_b/order/user';
}
