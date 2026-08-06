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
        .map<Map<String, dynamic>>((extra) => {
              "id": extra["id"],
              "name": _extraName(extra),
              "image": extra["accompagnement_image"],
              "price": extra["price"] ?? 0,
              "type": extra["type"] ?? "PAYANT",
            })
        .toList();
  }

  bool _sameExtras(List a, List b) {
    if (a.length != b.length) return false;
    final idsA = a.map((e) => e["id"]).toList()..sort((x, y) => x.toString().compareTo(y.toString()));
    final idsB = b.map((e) => e["id"]).toList()..sort((x, y) => x.toString().compareTo(y.toString()));
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

    return {
      "name": name ?? "Restaurant",
      "lat": lat,
      "lng": lng,
    };
  }

  @override
  Widget build(BuildContext context) {

    final cart = Hive.box("cart");
    final List availableTimes = widget.product["availableTimes"] ?? [];
    final List accompagnements = widget.product["accompagnements"] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          getLocalizedText(widget.product["title"]),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          ValueListenableBuilder(
            valueListenable: cart.listenable(),
            builder: (context, Box box,_) {
            int total = 0;
            for (int i = 0; i < box.length; i++) {
            total += box.getAt(i)["quantity"] as int;
              }
               return Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Shop(),
                          ),
                        );
                      },
                    ),

                    if (total > 0)
                      Positioned(
                        right: 4,
                        top: 5,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "$total",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
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
        child: Column(
          children: [
          const SizedBox(height: 20),
            Hero(
              tag: widget.product["id"],
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.network(
                    widget.product["images"][0]["image"],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                    getLocalizedText(widget.product["title"]),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),
                    Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30),
                    ),

                    child: Text(
                      "${widget.product["price"]} ${widget.product["currency"]}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Description",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    getLocalizedText(widget.product["description"]),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      color: Colors.black87,
                    ),
                     ),
                 const SizedBox(height: 30),

                  const Text(
                    "Horaires disponibles",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  availableTimes.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Text(
                            "Aucun horaire disponible",
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Column(
                          children: availableTimes.map<Widget>((time) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.black,
                                  child: Icon(
                                    Icons.access_time,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  time["day"],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "${time["start_time"]} - ${time["end_time"]}",
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                  const SizedBox(height: 30),
                  if (accompagnements.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Accompagnements",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (selectedExtraIds.isNotEmpty)
                          Text(
                            "${selectedExtraIds.length} sélectionné(s)",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "Choisissez un ou plusieurs accompagnements",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),

                    const SizedBox(height: 14),

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
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.black.withOpacity(0.04)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey.shade200,
                                width: isSelected ? 1.4 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: (image != null &&
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
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: free
                                                  ? Colors.green.shade50
                                                  : Colors.orange.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              free ? "GRATUIT" : "PAYANT",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: free
                                                    ? Colors.green.shade700
                                                    : Colors.orange.shade700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (!free)
                                            Text(
                                              "+$price FBU",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                Checkbox(
                                  value: isSelected,
                                  activeColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
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

                    if (selectedExtraIds.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 6, bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total avec accompagnements",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "$_totalWithExtras FBU",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),
                  ] else ...[
                    const Text(
                      "Accompagnements",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        "Aucun accompagnement disponible",
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                  Row(
                    children: [
                      const Icon(
                        Icons.store,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.product["companies_name"] ??
                            "Restaurant",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Icon(
                        widget.product["isProductAvailable"] == 1
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: widget.product["isProductAvailable"] == 1
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.product["isProductAvailable"] == 1
                            ? "Produit disponible"
                            : "Produit indisponible",
                        style: TextStyle(
                          fontSize: 16,
                          color: widget.product["isProductAvailable"] == 1
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),

                      onPressed: () {
                        final cart = Hive.box("cart");
                        bool exist = false;
                        final selectedExtras = _buildSelectedExtrasForCart();
                        final companyLocation =
                            _extractCompanyLocation(widget.product);

                        for (int i = 0; i < cart.length; i++) {
                          var item = cart.getAt(i);
                          final itemExtras = List.from(item["extras"] ?? []);

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
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            content: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Produit ajouté au panier",
                                ),
                              ],
                            ),
                          ),
                        );
                      },

                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_checkout,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Ajouter au panier",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),
                                  ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}