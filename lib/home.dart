import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:eureka/cache_helper.dart';
import 'package:eureka/CategoryDetails.dart';
import 'package:eureka/ProductDetails.dart';
import 'package:eureka/api.dart';
import 'package:eureka/CompanyDetails.dart';

class CategoryModel {
  final Map<String, dynamic> name;
  final String image;

  CategoryModel({
    required this.name,
    required this.image,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      name: jsonDecode(json['name']),
      image: json['image'],
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const Color kPrimary = Color(0xFFFF5722);
  static const Color kPrimaryLight = Color(0xFFFFF0EC);
  static const Color kBg = Color(0xFFF9FAFC);
  static const Color kSurface = Colors.white;
  static const Color kTextDark = Color(0xFF1E2022);
  static const Color kTextGrey = Color(0xFF8A94A6);
  static const Color kBorderColor = Color(0xFFF0F2F5);

  Map mapResponse = {};
  List products = [];
  List restaurants = [];
  bool loadingRestaurants = false;
  String? restaurantsError;
  List searchResults = [];
  List<CategoryModel> categories = [];
  final TextEditingController searchController = TextEditingController();

  bool isSearching = false;
  bool fetchlist = false;

  String selectedLanguage = "fr";
  String token = "";

  final languages = [
    ["fr", "Fr", "🇫🇷"],
    ["en", "En", "🇬🇧"],
    ["sw", "Sw", "🇹🇿"],
    ["rn", "Kir", "🇧🇮"],
  ];

  @override
  void initState() {
    super.initState();
    apicall();
    fetchCategories();
    fetchRestaurants();
    loadToken();
  }

  Future<void> searchProduct(String value) async {
    if (value.isEmpty) {
      setState(() {
        isSearching = false;
        searchResults = [];
      });
      return;
    }
    try {
      setState(() {
        isSearching = true;
      });
      final api = Api(Dio());
      final result = await api.searchProducts(value);
      setState(() {
        searchResults = result;
      });
    } catch (e) {
      debugPrint("Erreur recherche : $e");
    }
  }

  Future<void> apicall() async {
    setState(() {
      fetchlist = true;
    });
    try {
      final response = await Dio().get(
        "https://food.duma.africa/api/v1/products/bi",
      );
      if (response.statusCode == 200) {
        setState(() {
          mapResponse = response.data;
          products = mapResponse['data'];
          fetchlist = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur produits : $e");
      setState(() {
        fetchlist = false;
      });
    }
  }

  Future<void> fetchRestaurants() async {
    setState(() {
      loadingRestaurants = true;
      restaurantsError = null;
    });

    try {
      final api = Api(Dio());
      final data = await api.getCompanies("BI", page: 1);
      final companies = data.whereType<Map>().toList();

      setState(() {
        restaurants = companies
            .map((c) => extractRestaurantInfo(Map<String, dynamic>.from(c)))
            .toList();
        loadingRestaurants = false;
        if (restaurants.isEmpty) {
          restaurantsError =
              "Aucun restaurant reçu (regarde la console : COMPANIES RESPONSE)";
        }
      });
    } catch (e) {
      debugPrint("Erreur restaurants : $e");
      setState(() {
        loadingRestaurants = false;
        restaurantsError = "Impossible de charger les restaurants ($e)";
      });
    }
  }

  Map<String, dynamic> extractRestaurantInfo(Map<String, dynamic> company) {
    final rawName =
        (company["name"] ?? company["company_name"] ?? "").toString();

    String name;
    try {
      final decoded = jsonDecode(rawName);
      name = decoded[selectedLanguage] ?? decoded["fr"] ?? decoded.values.first;
    } catch (e) {
      name = rawName;
    }
    if (name.isEmpty) name = "Restaurant";

    final image = (company["image"] ??
            company["logo"] ??
            company["photo"] ??
            company["cover"] ??
            "")
        .toString();

    final address = (company["address"] ??
            company["company_address"] ??
            company["location"] ??
            company["adresse"] ??
            "")
        .toString();

    return {
      "id": company["id"],
      "name": name,
      "image": image,
      "address": address,
    };
  }

  Future<void> fetchCategories() async {
    try {
      final response = await Dio().get(
        "https://food.duma.africa/api/v1/categorysystem/bi",
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        setState(() {
          categories = data.map((item) => CategoryModel.fromJson(item)).toList();
        });
      }
    } catch (e) {
      debugPrint("Erreur catégories : $e");
    }
  }

  Future<void> loadToken() async {
    token = await CacheHelper.getToken();
    setState(() {});
  }

  String getLocalizedText(String text) {
    try {
      Map<String, dynamic> data = jsonDecode(text);
      return data[selectedLanguage] ?? data["fr"] ?? "";
    } catch (e) {
      return "";
    }
  }

  Future<void> addToWishlist(dynamic product) async {
    final wishlist = Hive.box("wishlist");
    bool exist = false;
    for (int i = 0; i < wishlist.length; i++) {
      if (wishlist.getAt(i)["id"] == product["id"]) {
        exist = true;
        break;
      }
    }

    if (!exist) {
      wishlist.add({
        "id": product["id"],
        "title": getLocalizedText(product["title"]),
        "price": product["price"],
        "image": product["images"][0]["image"],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: kTextDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
          content: const Row(
            children: [
              Icon(Icons.favorite_rounded, color: kPrimary, size: 20),
              SizedBox(width: 12),
              Text(
                "Ajouté aux favoris",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: kTextDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
          content: const Text(
            "Déjà dans les favoris",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  Widget _sectionHeader({
    required String title,
    String? subtitle,
    required int count,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: kTextDark,
                letterSpacing: -0.4,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: kTextGrey,
                ),
              ),
            ],
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: kPrimaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "$count dispo",
            style: const TextStyle(
              color: kPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "LIVRER À",
              style: TextStyle(
                color: kPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.location_on_rounded, color: kTextDark, size: 16),
                SizedBox(width: 4),
                Text(
                  "Bujumbura, Burundi",
                  style: TextStyle(
                    color: kTextDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: kTextDark, size: 18),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kBorderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedLanguage,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: kTextGrey,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  items: languages.map((lang) {
                    return DropdownMenuItem<String>(
                      value: lang[0],
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            lang[2],
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            lang[1],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: kTextDark,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedLanguage = value;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: fetchlist
          ? const Center(
              child: CircularProgressIndicator(color: kPrimary),
            )
          : RefreshIndicator(
              color: kPrimary,
              onRefresh: () async {
                await Future.wait([
                  apicall(),
                  fetchCategories(),
                  fetchRestaurants(),
                ]);
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: kBorderColor, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: searchProduct,
                        style: const TextStyle(fontSize: 14, color: kTextDark, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: "Recherche un produit...",
                          hintStyle: const TextStyle(color: kTextGrey, fontSize: 14, fontWeight: FontWeight.w400),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: kPrimary,
                            size: 22,
                          ),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.cancel_rounded, color: kTextGrey, size: 20),
                                  onPressed: () {
                                    searchController.clear();
                                    searchProduct("");
                                  },
                                )
                              : Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: kPrimaryLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.tune_rounded, color: kPrimary, size: 18),
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    _sectionHeader(
                      title: "Catégories",
                      count: categories.length,
                    ),

                    const SizedBox(height: 14),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryDetails(
                                    category: category,
                                    currentLanguage: selectedLanguage,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: kSurface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: kBorderColor, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      category.image,
                                      width: 28,
                                      height: 28,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(
                                        width: 28,
                                        height: 28,
                                        color: kPrimaryLight,
                                        child: const Icon(Icons.fastfood, color: kPrimary, size: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    category.name[selectedLanguage] ??
                                        category.name["fr"],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: kTextDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 28),
                    _sectionHeader(
                      title: "Products",
                      count: isSearching ? searchResults.length : products.length,
                    ),

                    const SizedBox(height: 14),
                    SizedBox(
                      height: 280,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: isSearching ? searchResults.length : products.length,
                        itemBuilder: (context, index) {
                          final product = isSearching ? searchResults[index] : products[index];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetails(
                                    product: product,
                                    currentLanguage: selectedLanguage,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 210,
                              margin: const EdgeInsets.only(right: 16, bottom: 6),
                              decoration: BoxDecoration(
                                color: kSurface,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: kBorderColor, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                                        child: Image.network(
                                          product["images"][0]["image"],
                                          height: 140,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => Container(
                                            height: 140,
                                            color: kBorderColor,
                                            child: const Icon(Icons.image_not_supported, color: kTextGrey),
                                          ),
                                        ),
                                      ),
                                      // Prix en badge flottant
                                      Positioned(
                                        left: 10,
                                        bottom: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: kTextDark.withOpacity(0.85),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            "${product["price"]} FBU",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Bouton favori
                                      Positioned(
                                        right: 10,
                                        top: 10,
                                        child: GestureDetector(
                                          onTap: () => addToWishlist(product),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: kSurface,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.favorite_rounded,
                                              size: 16,
                                              color: kPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          getLocalizedText(product["title"]),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: kTextDark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          getLocalizedText(product["description"]),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: kTextGrey,
                                            fontSize: 12,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 28),
                    _sectionHeader(
                      title: "Nos Restaurants",
                      count: restaurants.length,
                    ),

                    const SizedBox(height: 14),

                    if (loadingRestaurants)
                      const SizedBox(
                        height: 80,
                        child: Center(
                          child: CircularProgressIndicator(color: kPrimary),
                        ),
                      )
                    else if (restaurantsError != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1EE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kPrimary.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: kPrimary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                restaurantsError!,
                                style: const TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 190,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: restaurants.length,
                          itemBuilder: (context, index) {
                            final restaurant = restaurants[index];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CompanyDetails(
                                      companyId: restaurant["id"],
                                      initialName: restaurant["name"],
                                      initialImage: restaurant["image"],
                                      initialAddress: restaurant["address"],
                                      currentLanguage: selectedLanguage,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 155,
                                margin: const EdgeInsets.only(right: 14, bottom: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: kSurface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: kBorderColor, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    )
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: kPrimaryLight, width: 2),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(50),
                                        child: (restaurant["image"] ?? "").toString().isNotEmpty
                                            ? Image.network(
                                                restaurant["image"],
                                                width: 64,
                                                height: 64,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) => Container(
                                                  width: 64,
                                                  height: 64,
                                                  color: kPrimaryLight,
                                                  child: const Icon(Icons.storefront_rounded, color: kPrimary),
                                                ),
                                              )
                                            : Container(
                                                width: 64,
                                                height: 64,
                                                color: kPrimaryLight,
                                                child: const Icon(Icons.storefront_rounded, color: kPrimary),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      restaurant["name"],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: kTextDark,
                                      ),
                                    ),
                                    if ((restaurant["address"] ?? "").toString().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 12, color: kTextGrey),
                                          const SizedBox(width: 2),
                                          Expanded(
                                            child: Text(
                                              restaurant["address"],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: kTextGrey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}