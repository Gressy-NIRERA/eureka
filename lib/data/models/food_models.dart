/// Data models mirroring the JSON payloads returned by the Duma **food**
/// module (`https://food.duma.africa/api/v1`). Field names intentionally
/// match the raw API response so mapping stays a straight `fromJson` with no
/// hidden renaming.
library;

import 'package:eureka/core/utils/localized_text.dart';

/// A food category, e.g. Buckets, Burgers, Tenders, Sides, Drinks.
/// Source: `GET /categorysystem/{iso}` -> `data[]`.
class FoodCategory {
  final int id;
  final String name;
  final String image;

  const FoodCategory({required this.id, required this.name, required this.image});

  factory FoodCategory.fromJson(Map<String, dynamic> json) {
    return FoodCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: LocalizedText.extract(json['name']),
      image: json['image']?.toString() ?? '',
    );
  }
}

/// A restaurant / company selling food.
/// Source: `GET /company/{iso}` -> `data[]`.
class FoodCompany {
  final int id;
  final String name;
  final String? logo;
  final String? coverImage;
  final String description;
  final String address;
  final double rating;
  final bool isOpen;
  final int productCount;

  const FoodCompany({
    required this.id,
    required this.name,
    this.logo,
    this.coverImage,
    required this.description,
    required this.address,
    required this.rating,
    required this.isOpen,
    required this.productCount,
  });

  factory FoodCompany.fromJson(Map<String, dynamic> json) {
    final gallery = json['gallerycompany'] as List<dynamic>? ?? const [];
    final products = json['products'] as List<dynamic>? ?? const [];
    final logo = json['logo']?.toString();
    final cover = gallery.isNotEmpty
        ? (gallery.first as Map<String, dynamic>)['image']?.toString()
        : null;

    return FoodCompany(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      logo: (logo != null && logo.isNotEmpty) ? logo : null,
      coverImage: cover ?? logo,
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isOpen: json['is_open'] == true || json['is_open'] == 1,
      productCount: products.length,
    );
  }
}

/// A single product (a dish / a combo) sold by a [FoodCompany].
/// Source: `GET /products/{iso}` -> `data[]`.
class FoodProduct {
  final int id;
  final String title;
  final String description;

  /// Base selling price, before the company's delivery commission.
  final double price;

  /// Reference price shown struck-through when a promotion applies.
  /// Matches the official app's `ProductCard`, where `discount_price` is the
  /// pre-promo reference price and `price + commission` is what is charged.
  final double discountPrice;

  /// Delivery commission added by the selling company on top of [price].
  final double commission;

  final String currency;
  final double rating;
  final int reviews;
  final String? imageUrl;
  final String? companyLogo;
  final String companyName;
  final bool isLiked;

  /// Localized name of the food category this product belongs to (the API
  /// oddly nests the translated category name under `category_system_id`
  /// instead of a numeric id), used to match it back to a [FoodCategory].
  final String categorySystemName;

  const FoodProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.discountPrice,
    required this.commission,
    required this.currency,
    required this.rating,
    required this.reviews,
    this.imageUrl,
    this.companyLogo,
    required this.companyName,
    required this.isLiked,
    required this.categorySystemName,
  });

  /// The amount actually charged to the customer.
  double get effectivePrice => price + commission;

  bool get hasDiscount => discountPrice > 0 && discountPrice > effectivePrice;

  int get discountPercent => hasDiscount
      ? (((discountPrice - effectivePrice) / discountPrice) * 100).round()
      : 0;

  factory FoodProduct.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>? ?? const [];
    final imageUrl = images.isNotEmpty
        ? (images.first as Map<String, dynamic>)['image']?.toString()
        : null;
    final company = json['company'] as Map<String, dynamic>?;
    final comments = json['comment_list'] as List<dynamic>? ?? const [];

    return FoodProduct(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: LocalizedText.extract(json['title']),
      description: LocalizedText.extract(json['description']),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      discountPrice: (json['discount_price'] as num?)?.toDouble() ?? 0.0,
      commission: (company?['commission'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: comments.length,
      imageUrl: imageUrl,
      companyLogo: company?['logo']?.toString(),
      companyName: company?['name']?.toString() ?? json['companies_name']?.toString() ?? '',
      isLiked: json['is_liked'] == 1 || json['is_liked'] == true,
      categorySystemName: LocalizedText.extract(json['category_system_id']),
    );
  }
}
