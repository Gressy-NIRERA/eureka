
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:eureka/delivery.dart';

class Shop extends StatelessWidget {
  const Shop({super.key});
  
  static const Color kPrimary = Color(0xFFFF5722);
  static const Color kPrimaryLight = Color(0xFFFFF0EC);
  static const Color kBg = Color(0xFFF9FAFC);
  static const Color kSurface = Colors.white;
  static const Color kTextDark = Color(0xFF1E2022);
  static const Color kTextGrey = Color(0xFF8A94A6);
  static const Color kBorderColor = Color(0xFFF0F2F5);

  List _extrasOf(dynamic item) {
    return (item["extras"] as List?) ?? [];
  }

  bool _isFree(dynamic extra) {
    final type =
        (extra["type"] ?? "PAYANT").toString().toUpperCase();

    return type == "GRATUIT";
  }

  num _extrasTotal(dynamic item) {
    num sum = 0;

    for (var extra in _extrasOf(item)) {
      if (!_isFree(extra)) {
        sum += extra["price"] ?? 0;
      }
    }

    return sum;
  }

  num _unitPrice(dynamic item) {
    return (item["price"] ?? 0) + _extrasTotal(item);
  }

  num _lineTotal(dynamic item) {
    return _unitPrice(item) * (item["quantity"] ?? 1);
  }

  List<Map<String, dynamic>> _extractOrigins(Box box) {
    final Map<String, Map<String, dynamic>> unique = {};

    for (var item in box.values) {
      final lat = item["company_lat"];
      final lng = item["company_lng"];

      if (lat == null || lng == null) continue;

      final latVal = lat is num
          ? lat.toDouble()
          : double.tryParse(lat.toString());

      final lngVal = lng is num
          ? lng.toDouble()
          : double.tryParse(lng.toString());

      if (latVal == null || lngVal == null) continue;

      final key = "$latVal,$lngVal";

      unique[key] = {
        "name": item["company_name"] ?? "Restaurant",
        "lat": latVal,
        "lng": lngVal,
      };
    }

    return unique.values.toList();
  }

  Widget _productImage(String? image) {
    if (image == null || image.isEmpty) {
      return Container(
        width: 92,
        height: 92,
        color: kPrimaryLight,
        child: const Icon(
          Icons.fastfood_rounded,
          color: kPrimary,
          size: 30,
        ),
      );
    }

    return Image.network(
      image,
      width: 92,
      height: 92,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          width: 92,
          height: 92,
          color: kPrimaryLight,
          child: const Icon(
            Icons.fastfood_rounded,
            color: kPrimary,
            size: 30,
          ),
        );
      },
    );
  }
  Widget _extraRow(dynamic extra) {
    final free = _isFree(extra);

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: kPrimary,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              extra["name"] ?? "",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: kTextDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: free
                  ? const Color(0xFFEAF8EF)
                  : kPrimaryLight,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              free
                  ? "Gratuit"
                  : "+${extra["price"]} FBU",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: free
                    ? Colors.green.shade700
                    : kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityControl({
    required dynamic item,
    required Box box,
    required int index,
  }) {
    final quantity = item["quantity"] ?? 1;

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kBorderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            onPressed: quantity > 1
                ? () {
                    item["quantity"]--;
                    box.putAt(index, item);
                  }
                : null,
            icon: Icon(
              Icons.remove_rounded,
              size: 18,
              color: quantity > 1
                  ? kTextDark
                  : kTextGrey,
            ),
          ),

          Container(
            width: 30,
            alignment: Alignment.center,
            child: Text(
              quantity.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: kTextDark,
              ),
            ),
          ),

          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            onPressed: () {
              item["quantity"]++;
              box.putAt(index, item);
            },
            icon: const Icon(
              Icons.add_rounded,
              size: 18,
              color: kPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartItem({
    required BuildContext context,
    required dynamic item,
    required Box box,
    required int index,
  }) {
    final extras = _extrasOf(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: kBorderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _productImage(
                  item["image"]?.toString(),
                ),
              ),

              const SizedBox(width: 13),

              // INFORMATIONS
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item["title"] ?? "Produit",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: kTextDark,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        GestureDetector(
                          onTap: () {
                            box.deleteAt(index);
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEEEE),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFE53935),
                              size: 17,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "${item["price"]} FBU",
                      style: const TextStyle(
                        color: kPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    if (extras.isNotEmpty) ...[
                      const SizedBox(height: 10),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius:
                              BorderRadius.circular(13),
                          border: Border.all(
                            color: kBorderColor,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 14,
                                  color: kPrimary,
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  "Accompagnements",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: kTextDark,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 7),

                            ...extras.map(
                              (extra) => _extraRow(extra),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            height: 1,
            color: kBorderColor,
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              // SOUS TOTAL
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Sous-total",
                      style: TextStyle(
                        color: kTextGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${_lineTotal(item).toStringAsFixed(0)} FBU",
                      style: const TextStyle(
                        color: kTextDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              _quantityControl(
                item: item,
                box: box,
                index: index,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: kPrimaryLight,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: kPrimary,
                size: 42,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Votre panier est vide",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: kTextDark,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              "Ajoutez vos produits préférés\npour commencer votre commande.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: kTextGrey,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Continuer mes achats",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Hive.box("cart");

    return Scaffold(
    backgroundColor: const Color.fromARGB(255, 237, 228, 216),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 237, 228, 216),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,

        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: kSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: kBorderColor,
                width: 1.5,
              ),
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
                size: 17,
                color: kTextDark,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),

        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              "COMMANDE",
              style: TextStyle(
                color: kPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Mon panier",
              style: TextStyle(
                color: kTextDark,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),

      body: ValueListenableBuilder(
        valueListenable: cart.listenable(),

        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return _emptyCart(context);
          }

          double total = 0;

          for (var item in box.values) {
            total += _lineTotal(item);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    20,
                  ),
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final item = box.getAt(index);

                    return _cartItem(
                      context: context,
                      item: item,
                      box: box,
                      index: index,
                    );
                  },
                ),
              ),
                 Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  20,
                ),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius:
                      const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: kBorderColor,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      // TOTAL
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total de la commande",
                                  style: TextStyle(
                                    color: kTextGrey,
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  "Hors frais de livraison",
                                  style: TextStyle(
                                    color: kTextGrey,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Text(
                            "${total.toStringAsFixed(0)} FBU",
                            style: const TextStyle(
                              color: kTextDark,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),
                      SizedBox(
                        width: 300,
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(17),
                            ),
                          ),
                          onPressed: () {
                            final origins =
                                _extractOrigins(box);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DeliveryWidget(
                                  cartTotal: total,
                                  origins: origins,
                                ),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons
                                    .delivery_dining_outlined,
                                color: Colors.white,
                                size: 21,
                              ),
                              SizedBox(width: 9),
                              Text(
                                "Choisir la livraison",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons
                                    .arrow_forward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
