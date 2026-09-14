import 'package:dio/dio.dart';

import 'package:eureka/core/network/api_client.dart';
import 'package:eureka/core/network/duma_endpoints.dart';
import 'package:eureka/data/models/food_models.dart';

/// Repository responsible for every call to the Duma **food** module
/// (`FoodEndpoints`). Screens never call `Dio` directly: they go through
/// this service so the real endpoints and response parsing live in a single,
/// testable place.
class FoodService {
  FoodService({String? bearerToken})
      : _dio = ApiClient.create(bearerToken: bearerToken);

  final Dio _dio;

  Future<List<FoodCategory>> fetchCategories(String isoCode) async {
    final response = await _dio
        .get(FoodEndpoints.categories(isoCode))
        .timeout(const Duration(seconds: 15));

    final body = response.data;
    if (body is! Map<String, dynamic> || body['data'] is! List) return [];

    return (body['data'] as List)
        .whereType<Map<String, dynamic>>()
        .map(FoodCategory.fromJson)
        .toList();
  }

  Future<List<FoodCompany>> fetchCompanies(String isoCode, {int page = 1}) async {
    final response = await _dio
        .get(FoodEndpoints.companies(isoCode, page: page))
        .timeout(const Duration(seconds: 15));

    final body = response.data;
    if (body is! Map<String, dynamic> || body['data'] is! List) return [];

    return (body['data'] as List)
        .whereType<Map<String, dynamic>>()
        .map(FoodCompany.fromJson)
        .toList();
  }

  Future<List<FoodProduct>> fetchProducts(String isoCode) async {
    final response = await _dio
        .get(FoodEndpoints.products(isoCode))
        .timeout(const Duration(seconds: 15));

    final body = response.data;
    if (body is! Map<String, dynamic> || body['data'] is! List) return [];

    return (body['data'] as List)
        .whereType<Map<String, dynamic>>()
        .map(FoodProduct.fromJson)
        .toList();
  }

  Future<List<FoodProduct>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final response = await _dio
        .get(FoodEndpoints.search(query.trim()))
        .timeout(const Duration(seconds: 15));

    final body = response.data;
    if (body is! Map<String, dynamic> || body['data'] is! List) return [];

    return (body['data'] as List)
        .whereType<Map<String, dynamic>>()
        .map(FoodProduct.fromJson)
        .toList();
  }
}
