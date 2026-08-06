import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:eureka/shop.dart';

class ProductDetails extends StatefulWidget {
  final Map<String, dynamic> product;
  final String currentLanguage;

  const ProductDetails({
    Key? key,
    required this.product,
    required this.currentLanguage,
  }) : super(key: key);

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  final Set<dynamic> selectedExtraIds = {};

  String getLocalizedText(String text) {
    try {
      final Map<String, dynamic> data = jsonDecode(text);
      return data[widget.currentLanguage] ?? data["fr"] ?? data.values.first;
    } catch (e) {
      return text;
    }
  }

  bool _isFree(Map extra) {
    final type = (extra["type"] ?? "PAYANT").toString().toUpperCase();
    return type == "GRATUIT";
  }

  num _extraPrice(Map extra) {
    if (_isFree(extra)) return 0;
    return extra["price"] ?? 0;
  }

  String _extraName(Map extra) {
    final raw = extra["accompagnement_name"] ?? extra["name"] ?? "";
    return getLocalizedText(raw.toString());
  }

  num get _selectedExtrasTotal {
    final List accompagnements = widget.product["accompagnements"] ?? [];
    num sum = 0;
    for (var extra in accompagnements) {
      if (selectedExtraIds.contains(extra["id"])) {
        sum += _extraPrice(extra);
      }
    }
    return sum;
  }

  num get _totalWithExtras =>
      (widget.product["price"] ?? 0) + _selectedExtrasTotal;

  List<Map<String, dynamic>> _buildSelectedExtrasForCart() {
    final List accompagnements = widget.product["accompagnements"] ?? [];
    return accompagnements
        .where((extra) => selectedExtraIds.contains(extra["id"]))
        .map<Map<String, dynamic>>(
          (extra) => {
            "id": extra["id"],
            "name": _extraName(extra),
            "image": extra["accompagnement_image"],
            "price": extra["price"] ?? 0,
            "type": extra["type"] ?? "PAYANT",
          },
        )
        .toList();
  }

  bool _sameExtras(List a, List b) {
    if (a.length != b.length) return false;
    final idsA = a.map((e) => e["id"]).toList()
      ..sort((x, y) => x.toString().compareTo(y.toString()));
    final idsB = b.map((e) => e["id"]).toList()
      ..sort((x, y) => x.toString().compareTo(y.toString()));
    for (int i = 0; i < idsA.length; i++) {
      if (idsA[i] != idsB[i]) return false;
    }
    return true;
  }

  Widget _extraImagePlaceholder() {
    return Container(
      width: 55,
      height: 55,
      color: Colors.grey.shade200,
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 26),
    );
  }

  Map<String, dynamic>? _extractCompanyLocation(Map<String, dynamic> product) {
    String? name = (product["companies_name"] ?? product["company_name"])
        ?.toString();
    if (name != null && name.isEmpty) name = null;

    dynamic company = product["company"];

    final latCandidates = [
      product["companies_latitude"],
      product["company_latitude"],
      product["latitude"],
      if (company is Map) company["latitude"],
      if (company is Map) company["lat"],
    ];
    final lngCandidates = [
      product["companies_longitude"],
      product["company_longitude"],
      product["longitude"],
      if (company is Map) company["longitude"],
      if (company is Map) company["lng"],
    ];

    double? lat;
    double? lng;
    for (final c in latCandidates) {
      if (c != null) {
        lat = double.tryParse(c.toString());
        if (lat != null) break;
      }
    }
    for (final c in lngCandidates) {
      if (c != null) {
        lng = double.tryParse(c.toString());
        if (lng != null) break;
      }
    }

    if (lat == null || lng == null) return null;

    return {"name": name ?? "Restaurant", "lat": lat, "lng": lng};
  }

  @override
  Widget build(BuildContext context) {
    final cart = Hive.box("cart");

    final List availableTimes = widget.product["availableTimes"] ?? [];

    final List accompagnements = widget.product["accompagnements"] ?? [];

    final String title = getLocalizedText(widget.product["title"]);

    final String description = getLocalizedText(widget.product["description"]);

    final String image =
        (widget.product["images"] != null &&
            widget.product["images"].isNotEmpty)
        ? widget.product["images"][0]["image"].toString()
        : "";

    final bool isAvailable = widget.product["isProductAvailable"] == 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFC),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,

        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF0F2F5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF1E2022),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),

        title: const Text(
          "Détails du produit",
          style: TextStyle(
            color: Color(0xFF1E2022),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),

        actions: [
          ValueListenableBuilder(
            valueListenable: cart.listenable(),
            builder: (context, Box box, _) {
              int total = 0;

              for (int i = 0; i < box.length; i++) {
                total += (box.getAt(i)["quantity"] ?? 0) as int;
              }

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF0F2F5),
                          width: 1.5,
                        ),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Color(0xFF1E2022),
                          size: 21,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Shop()),
                          );
                        },
                      ),
                    ),

                    if (total > 0)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 19,
                            minHeight: 19,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5722),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "$total",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Hero(
                tag: widget.product["id"],
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFFF0F2F5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: image.isNotEmpty
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) {
                              return Container(
                                color: const Color(0xFFF0F2F5),
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Color(0xFF8A94A6),
                                  size: 45,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: const Color(0xFFF0F2F5),
                            child: const Icon(
                              Icons.fastfood_outlined,
                              color: Color(0xFF8A94A6),
                              size: 45,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom + disponibilité
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 25,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Color(0xFF1E2022),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? const Color(0xFFEAF8EF)
                              : const Color(0xFFFFEEEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isAvailable
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 18,
                          color: isAvailable
                              ? Colors.green.shade600
                              : Colors.red.shade500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0EC),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Color(0xFFFF5722),
                          size: 17,
                        ),
                      ),

                      const SizedBox(width: 9),

                      Expanded(
                        child: Text(
                          widget.product["companies_name"] ?? "Restaurant",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8A94A6),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0EC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          "${widget.product["price"]} ${widget.product["currency"] ?? "FBU"}",
                          style: const TextStyle(
                            color: Color(0xFFFF5722),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      if (isAvailable)
                        const Text(
                          "Disponible",
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else
                        const Text(
                          "Indisponible",
                          style: TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  const Text(
                    "Description",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2022),
                    ),
                  ),

                  const SizedBox(height: 9),

                  Text(
                    description.isEmpty
                        ? "Aucune description disponible."
                        : description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: Color(0xFF8A94A6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Horaires",
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2022),
                        ),
                      ),

                      if (availableTimes.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0EC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${availableTimes.length} créneau${availableTimes.length > 1 ? 'x' : ''}",
                            style: const TextStyle(
                              color: Color(0xFFFF5722),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (availableTimes.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFC),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFFF0F2F5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: Color(0xFF8A94A6),
                            size: 18,
                          ),
                          SizedBox(width: 9),
                          Text(
                            "Aucun horaire disponible",
                            style: TextStyle(
                              color: Color(0xFF8A94A6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: availableTimes.map<Widget>((time) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 9),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFC),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color(0xFFF0F2F5)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0EC),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.access_time_rounded,
                                  color: Color(0xFFFF5722),
                                  size: 18,
                                ),
                              ),

                              const SizedBox(width: 11),

                              Expanded(
                                child: Text(
                                  time["day"].toString(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E2022),
                                  ),
                                ),
                              ),

                              Text(
                                "${time["start_time"]} - ${time["end_time"]}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8A94A6),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 28),
                    Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Accompagnements",
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2022),
                        ),
                      ),

                      if (selectedExtraIds.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0EC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${selectedExtraIds.length} sélectionné(s)",
                            style: const TextStyle(
                              color: Color(0xFFFF5722),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    "Choisissez un ou plusieurs accompagnements",
                    style: TextStyle(
                      color: Color(0xFF8A94A6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (accompagnements.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFC),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFFF0F2F5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF8A94A6),
                            size: 18,
                          ),
                          SizedBox(width: 9),
                          Text(
                            "Aucun accompagnement disponible",
                            style: TextStyle(
                              color: Color(0xFF8A94A6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: accompagnements.map<Widget>((extra) {
                        final id = extra["id"];
                        final name = _extraName(extra);
                        final image = extra["accompagnement_image"];
                        final free = _isFree(extra);
                        final price = extra["price"] ?? 0;

                        final isSelected = selectedExtraIds.contains(id);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedExtraIds.remove(id);
                              } else {
                                selectedExtraIds.add(id);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFF7F4)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFF5722)
                                    : const Color(0xFFF0F2F5),
                                width: isSelected ? 1.4 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child:
                                      (image != null &&
                                          image.toString().isNotEmpty)
                                      ? Image.network(
                                          image,
                                          width: 55,
                                          height: 55,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) =>
                                              _extraImagePlaceholder(),
                                        )
                                      : _extraImagePlaceholder(),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E2022),
                                        ),
                                      ),

                                      const SizedBox(height: 7),

                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: free
                                                  ? const Color(0xFFEAF8EF)
                                                  : const Color(0xFFFFF0EC),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              free ? "GRATUIT" : "PAYANT",
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: free
                                                    ? Colors.green.shade700
                                                    : const Color(0xFFFF5722),
                                              ),
                                            ),
                                          ),

                                          if (!free) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              "+$price FBU",
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF8A94A6),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                Checkbox(
                                  value: isSelected,
                                  activeColor: const Color(0xFFFF5722),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedExtraIds.add(id);
                                      } else {
                                        selectedExtraIds.remove(id);
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  if (selectedExtraIds.isNotEmpty) ...[
                    const SizedBox(height: 5),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "$_totalWithExtras FBU",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAvailable
                            ? const Color(0xFFFF5722)
                            : const Color(0xFFD5D7DA),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),

                      onPressed: isAvailable
                          ? () {
                              final cart = Hive.box("cart");

                              bool exist = false;

                              final selectedExtras =
                                  _buildSelectedExtrasForCart();

                              final companyLocation = _extractCompanyLocation(
                                widget.product,
                              );

                              for (int i = 0; i < cart.length; i++) {
                                var item = cart.getAt(i);

                                final itemExtras = List.from(
                                  item["extras"] ?? [],
                                );

                                if (item["id"] == widget.product["id"] &&
                                    _sameExtras(itemExtras, selectedExtras)) {
                                  item["quantity"]++;
                                  cart.putAt(i, item);
                                  exist = true;
                                  break;
                                }
                              }

                              if (!exist) {
                                cart.add({
                                  "id": widget.product["id"],
                                  "title": getLocalizedText(
                                    widget.product["title"],
                                  ),
                                  "price": widget.product["price"],
                                  "image": widget.product["images"][0]["image"],
                                  "quantity": 1,
                                  "extras": selectedExtras,
                                  "company_name": companyLocation?["name"],
                                  "company_lat": companyLocation?["lat"],
                                  "company_lng": companyLocation?["lng"],
                                });
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF1E2022),
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  content: const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFFFF5722),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "Produit ajouté au panier",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          : null,

                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.white,
                            size: 21,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Ajouter au panier",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
