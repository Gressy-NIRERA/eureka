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
  static const Color kPrimary = Color(0xFFFF5A1F);
  static const Color kPrimaryDark = Color(0xFFE34B18);
  static const Color kBg = Color(0xFFF7F7F8);
  static const Color kTextDark = Color(0xFF191919);
  static const Color kTextGrey = Color(0xFF77777F);
  static const Color kChipBg = Color(0xFFEFEFF1);

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
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
          content: const Row(
            children: [
              Icon(Icons.favorite, color: kPrimary, size: 18),
              SizedBox(width: 10),
              Text("Ajouté aux favoris"),
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
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
          content: const Text("Déjà dans les favoris"),
        ),
      );
    }
  }

  Widget _sectionHeader({
    required String title,
    required int count,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: kTextDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: kChipBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "$count",
            style: const TextStyle(
              color: kTextGrey,
              fontWeight: FontWeight.w700,
              fontSize: 12,
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
  backgroundColor: Colors.white,
  elevation: 0,
  automaticallyImplyLeading: false,
  titleSpacing: 14,
  title: const Text(
    "Menu",
    style: TextStyle(
      color: kTextDark,
      fontWeight: FontWeight.w800,
      fontSize: 22,
      letterSpacing: -0.3,
    ),
  ),

  centerTitle: false,

  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: kChipBg,
          borderRadius: BorderRadius.circular(19),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedLanguage,
            underline: const SizedBox(),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: kTextGrey,
            ),
            borderRadius: BorderRadius.circular(14),
            items: languages.map((lang) {
              return DropdownMenuItem<String>(
                value: lang[0],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lang[2],
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(width: 4),
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
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: searchProduct,
                        style: const TextStyle(fontSize: 14, color: kTextDark),
                        decoration: InputDecoration(
                          hintText: "Rechercher un produit...",
                          hintStyle:
                              const TextStyle(color: kTextGrey, fontSize: 14),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: kPrimary,
                          ),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      color: kTextGrey),
                                  onPressed: () {
                                    searchController.clear();
                                    searchProduct("");
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _sectionHeader(
                      title: "Catégories",
                      count: categories.length,
                    ),

                    const SizedBox(height: 11),
                    SizedBox(
                      height: 44,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
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
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(color: kChipBg, width: 1.4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 11,
                                    backgroundColor: kChipBg,
                                    backgroundImage: NetworkImage(category.image),
                                  ),
                                  const SizedBox(width: 8),
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

                    const SizedBox(height: 24),

                    _sectionHeader(
                      title: "Produits",
                      count: isSearching ? searchResults.length : products.length,
                    ),

                    const SizedBox(height: 11),
                    SizedBox(
                      height: 295,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount:
                            isSearching ? searchResults.length : products.length,
                        itemBuilder: (context, index) {
                          final product =
                              isSearching ? searchResults[index] : products[index];

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
                              width: 205,
                              margin: const EdgeInsets.only(right: 14),
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        height: 135,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(18),
                                          color: const Color(0xffF3F3F3),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(18),
                                          child: Image.network(
                                            product["images"][0]["image"],
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.08),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: GestureDetector(
                                            onTap: () => addToWishlist(product),
                                            child: const Icon(
                                              Icons.favorite_border_rounded,
                                              size: 18,
                                              color: kPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
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
                                    style: TextStyle(
                                      color: kTextGrey,
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: kPrimary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          "${product["price"]} FBU",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: kPrimaryDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    _sectionHeader(
                      title: "Restaurants",
                      count: restaurants.length,
                    ),

                    const SizedBox(height: 11),

                    if (loadingRestaurants)
                      const SizedBox(
                        height: 60,
                        child: Center(
                            child: CircularProgressIndicator(color: kPrimary)),
                      )
                    else if (restaurantsError != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1EE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kPrimary.withOpacity(0.15)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: kPrimaryDark, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                restaurantsError!,
                                style: const TextStyle(
                                    color: kPrimaryDark, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 175,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
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
                                width: 145,
                                margin: const EdgeInsets.only(right: 14),
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(17),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    )
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: (restaurant["image"] ?? "")
                                              .toString()
                                              .isNotEmpty
                                          ? Image.network(
                                              restaurant["image"],
                                              width: 66,
                                              height: 66,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => Container(
                                                width: 66,
                                                height: 66,
                                                color: kChipBg,
                                                child: const Icon(
                                                    Icons.storefront_rounded,
                                                    color: kTextGrey),
                                              ),
                                            )
                                          : Container(
                                              width: 66,
                                              height: 66,
                                              color: kChipBg,
                                              child: const Icon(
                                                  Icons.storefront_rounded,
                                                  color: kTextGrey),
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
                                        fontSize: 13,
                                        color: kTextDark,
                                      ),
                                    ),
                                    if ((restaurant["address"] ?? "")
                                        .toString()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        restaurant["address"],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: kTextGrey,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
    );
  }
}