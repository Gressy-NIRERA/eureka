
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

  static const Color backgroundColor =
      Color.fromARGB(255, 237, 228, 216);

  static const Color primaryColor = Colors.orange;
   static const Color lightOrange = Color(0xFFFFCC80);
   static const Color cardColor = Colors.white;
   static const Color textColor = Colors.black;
   static const Color secondaryTextColor = Color(0xFF757575);

  String getLocalizedText(String text) {
    try {
      final Map<String, dynamic> data = jsonDecode(text);
       return data[widget.currentLanguage] ??
          data["fr"] ??
          data.values.first;
    } catch (e) {
      return text;
    }
  }
  bool _isFree(Map extra) {
    final type =
        (extra["type"] ?? "PAYANT").toString().toUpperCase();
        return type == "GRATUIT";
  }
num _extraPrice(Map extra) {
    if (_isFree(extra)) return 0;
     return extra["price"] ?? 0;
  }
String _extraName(Map extra) {
    final raw =
        extra["accompagnement_name"] ??
        extra["name"] ??
        "";
        return getLocalizedText(raw.toString());
  }
num get _selectedExtrasTotal {
    final List accompagnements =
        widget.product["accompagnements"] ?? [];
  num sum = 0; for (var extra in accompagnements) {
      if (selectedExtraIds.contains(extra["id"])) {
        sum += _extraPrice(extra);
      }
    }
return sum;
  }
  num get _totalWithExtras =>
      (widget.product["price"] ?? 0) + _selectedExtrasTotal;

  List<Map<String, dynamic>> _buildSelectedExtrasForCart() {
    final List accompagnements =
        widget.product["accompagnements"] ?? [];
        return accompagnements
        .where(
          (extra) => selectedExtraIds.contains(extra["id"]),
        )
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
      ..sort((x, y) => x.toString().compareTo(y.toString()), );
      final idsB = b.map((e) => e["id"]).toList()
      ..sort((x, y) => x.toString().compareTo(y.toString()),);
      for (int i = 0; i < idsA.length; i++) {
      if (idsA[i] != idsB[i]) return false;
    }
    return true;
  }

  Widget _extraImagePlaceholder() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.fastfood_outlined,
        color: Colors.orange,
        size: 26,
      ),
    );
  }

  Map<String, dynamic>? _extractCompanyLocation(
    Map<String, dynamic> product,
  ) {
    String? name =
        (product["companies_name"] ?? product["company_name"])?.toString();
         if (name != null && name.isEmpty) {
      name = null;
    }
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

    if (lat == null || lng == null) {
      return null;
    }

    return {
      "name": name ?? "Restaurant",
      "lat": lat,
      "lng": lng,
    };
  }
  Widget _sectionTitle(
    String title, {
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),

        if (trailing != null) trailing,
      ],
    );
  }

  Widget _softIcon(
    IconData icon, {
    double size = 42,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: primaryColor,
        size: size * 0.48,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Hive.box("cart");
    final List availableTimes =widget.product["availableTimes"] ?? [];
      final List accompagnements = widget.product["accompagnements"] ?? [];
       final String title =getLocalizedText(widget.product["title"]);
       final String description = getLocalizedText(widget.product["description"]);
       final String image =(widget.product["images"] != null &&
                widget.product["images"].isNotEmpty)
            ? widget.product["images"][0]["image"].toString()
            : "";
            final bool isAvailable =widget.product["isProductAvailable"] == 1;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,

        leading: Padding(
          padding: const EdgeInsets.only(
            left: 12,
          ),

          child: CircleAvatar(
            backgroundColor: Colors.grey.shade100,

            child: IconButton(
              padding: EdgeInsets.zero,

              icon: const Icon(
                Icons.arrow_back,
                color: Colors.black,
                size: 20,
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
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          ValueListenableBuilder(
            valueListenable: cart.listenable(),
            builder: (context, Box box, _) {
              int total = 0;
               for (int i = 0; i < box.length; i++) {
                total +=(box.getAt(i)["quantity"] ?? 0) as int;
              }
              return Padding(
                padding: const EdgeInsets.only(
                  right: 16,
                ),

                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: Colors.white,
                       child: IconButton(
                        padding: EdgeInsets.zero,

                        icon: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.black,
                          size: 21,
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
                    ),

                    if (total > 0)
                      Positioned(
                        right: -3,
                        top: -3,

                        child: Container(
                          constraints:
                              const BoxConstraints(
                            minWidth: 19,
                            minHeight: 19,
                          ),

                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),

                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),

                          child: Text(
                            "$total",
                            textAlign: TextAlign.center,

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
        physics: const BouncingScrollPhysics(),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
             Padding(
              padding: const EdgeInsets.fromLTRB(20, 8,20, 0,),
               child: Hero(
                tag: widget.product["id"],
                 child: Container(
                  height: 290,
                  width: double.infinity,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                     boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                     child: image.isNotEmpty? Image.network(
                     image,fit: BoxFit.cover,
                     errorBuilder: (context, error, stack) {
                     return Container( color: Colors.white,
                      child: const Icon( Icons.image_not_supported_outlined,
                      color: Colors.orange,size: 50,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.white,
                            child: const Icon(Icons.fastfood_outlined,
                              color: Colors.orange,
                              size: 50,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
             Container(width: double.infinity,
             padding: const EdgeInsets.fromLTRB(22,24,22,30,),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,children: [
                      Expanded(
                        child: Text( title,
                        style: const TextStyle(
                            fontSize: 27,
                            height: 1.15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Container(
                        padding:  const EdgeInsets.symmetric(  horizontal: 10,vertical: 8,  ),
                          decoration: BoxDecoration(
                          color: isAvailable ? const Color(0xFFEAF7EC)  : const Color(0xFFFFEEEE),
                           borderRadius:  BorderRadius.circular(14), ),
                            child: Icon(  isAvailable? Icons.check_circle: Icons.cancel,
                             size: 19,
                              color: isAvailable ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),
                  Row(
                    children: [ _softIcon(
                        Icons.storefront_outlined,
                        size: 38,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          widget.product[  "companies_name"] ??"Restaurant",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                           style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
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
                          horizontal: 16,
                          vertical: 10,
                        ),

                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius:
                              BorderRadius.circular(15),
                        ),

                        child: Text(
                          "${widget.product["price"]} ${widget.product["currency"] ?? "FBU"}",

                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Text(
                        isAvailable
                            ? "Disponible"
                            : "Indisponible",

                        style: TextStyle(
                          color: isAvailable
                              ? Colors.green.shade600
                              : Colors.red.shade600,

                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  _sectionTitle("Description"),
                   const SizedBox(height: 10),
                   Text(description.isEmpty
                        ? "Aucune description disponible."
                        : description,
                         style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 30),

                  _sectionTitle(
                    "Horaires",
                     trailing:
                        availableTimes.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets .symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius:
                                      BorderRadius.circular(
                                    20,
                                  ),
                                ),

                                child: Text(
                                  "${availableTimes.length} créneau${availableTimes.length > 1 ? 'x' : ''}",

                                  style:
                                      const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 10,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                  ),

                  const SizedBox(height: 12),

                  if (availableTimes.isEmpty)
                    Container(width: double.infinity,
                     padding:const EdgeInsets.all(15),
                     decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius:
                            BorderRadius.circular(16),
                      ),

                      child: Row(
                        children: [_softIcon(Icons.access_time, size: 38, ),
                         const SizedBox(width: 10),
                         Text( "Aucun horaire disponible",
                         style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                         fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column( children:availableTimes.map<Widget>(
                        (time) {
                          return Container( margin:const EdgeInsets.only( bottom: 10,  ),

                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),

                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius:BorderRadius.circular( 16,),
                            ),

                            child: Row(
                              children: [ _softIcon(Icons.access_time,size: 38, ),

                                const SizedBox(width: 11),
                                 Expanded(
                                  child: Text(time["day"].toString(),
                                  style: const TextStyle(fontSize: 13,
                                  fontWeight:FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),

                                Text(
                                  "${time["start_time"]} - ${time["end_time"]}",

                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w600,
                                    color:
                                        Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ).toList(),
                    ),

                  const SizedBox(height: 30),

                  _sectionTitle( "Accompagnements",
                   trailing:selectedExtraIds.isNotEmpty ? Container(
                   padding:const EdgeInsets.symmetric( horizontal: 10,vertical: 6,  ),
                    decoration:BoxDecoration(
                    color: backgroundColor,
                    borderRadius:BorderRadius.circular( 20,),),
                     child: Text("${selectedExtraIds.length} sélectionné(s)",
                      style:const TextStyle(color: Colors.orange,fontSize: 10, fontWeight:  FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                  ),

                  const SizedBox(height: 7),

                  Text( "Choisissez un ou plusieurs accompagnements",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 15),
                  if (accompagnements.isEmpty)
                    Container( width: double.infinity,
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                      ),

                      child: Row(
                        children: [ _softIcon(Icons.info_outline, size: 38, ),

                          const SizedBox(width: 10),

                          Text("Aucun accompagnement disponible",
                          style: TextStyle(
                           color: Colors.grey.shade600,fontSize: 12,
                           fontWeight:FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )

                  else
                    Column(
                      children: accompagnements.map<Widget>(
                        (extra) { final id = extra["id"];

                          final name = _extraName(extra);
                          final extraImage = extra[ "accompagnement_image"];
                          final free = _isFree(extra);
                          final price =  extra["price"] ?? 0;
                          final isSelected = selectedExtraIds .contains(id);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) { selectedExtraIds .remove(id);
                                } else {
                                  selectedExtraIds .add(id);
                                }
                              });
                            },

                            child: AnimatedContainer(
                              duration: const Duration( milliseconds: 180,),
                              margin: const EdgeInsets.only( bottom: 10, ),
                              padding:const EdgeInsets.all(10),
                               decoration: BoxDecoration(
                                color: isSelected ? const Color( 0xFFFFF8F0, ) : Colors.white,
                                  borderRadius:BorderRadius.circular(18, ),
                                    border: Border.all(
                                  color: isSelected
                                      ? Colors.orange
                                      : Colors.grey.shade200,
                                       width: isSelected ? 1.5 : 1,
                                ),
                              ),

                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius .circular(14,),

                                    child: (extraImage !=null &&extraImage .toString() .isNotEmpty) ? Image.network( extraImage, width: 58,height: 58, fit: BoxFit .cover,
                                    errorBuilder:( context, error, stack,) {
                                    return _extraImagePlaceholder();
                                     }, ) : _extraImagePlaceholder(),),

                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment .start,
                                       children: [
                                        Text( name, maxLines: 1, overflow:  TextOverflow .ellipsis,
                                        style:const TextStyle(fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),

                                        const SizedBox(
                                            height: 8),

                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 5,
                                              ),

                                              decoration:
                                                  BoxDecoration( color: free ? const Color( 0xFFEAF7EC, ) : backgroundColor,
                                                   borderRadius: BorderRadius .circular(  9,
                                                ),
                                              ),

                                              child: Text( free ? "GRATUIT" : "PAYANT",
                                               style: TextStyle( fontSize: 9,
                                                  fontWeight:FontWeight.bold,color: free
                                                      ? Colors.green.shade700 : Colors.orange,
                                                ),
                                              ),
                                            ),

                                            if (!free) ...[
                                              const SizedBox( width: 8),
                                               Text( "+$price FBU",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:FontWeight.w600,
                                                  color: Colors.grey.shade600,
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
                                    activeColor: Colors.orange,
                                     checkColor: Colors.white,

                                    shape:RoundedRectangleBorder( borderRadius:BorderRadius.circular( 6,
                                      ),
                                    ),

                                    onChanged:  (value) {  setState(() { if (value == true) { selectedExtraIds .add(id);
                                        } else {selectedExtraIds .remove(id);
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),

                  if (selectedExtraIds.isNotEmpty) ...[
                    const SizedBox(height: 5),

                    Container(
                      width: double.infinity,
                       padding: const EdgeInsets.symmetric( horizontal: 18, vertical: 15, ),
                       decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        borderRadius: BorderRadius.circular(17),
                      ),

                      child: Row(
                        mainAxisAlignment:MainAxisAlignment .spaceBetween,
                         children: [
                          const Text(
                            "Total",
                             style: TextStyle(color: Colors.black, fontSize: 14, fontWeight:   FontWeight.w600, ),),
                           Text(
                            "$_totalWithExtras FBU",
                             style: const TextStyle( color: Colors.black,fontSize: 18, fontWeight: FontWeight.bold, ), ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAvailable ? Colors.orange.shade400  : Colors.grey.shade300,
                        disabledBackgroundColor: Colors.grey.shade300,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius:BorderRadius.circular(3),
                        ),
                      ),

                      onPressed: isAvailable
                          ? () {
                              final cart = Hive.box("cart"); bool exist = false;
                               final selectedExtras = _buildSelectedExtrasForCart();
                               final companyLocation =
                                  _extractCompanyLocation(
                                widget.product,
                              );
                              for (
                                int i = 0;
                                i < cart.length;
                                  i++
                              ) {
                                var item =
                                    cart.getAt(i);
                                final itemExtras =
                                    List.from(
                                  item["extras"] ?? [],
                                );

                                if (item["id"] ==
                                        widget.product[
                                            "id"] &&
                                    _sameExtras(
                                      itemExtras,
                                      selectedExtras,
                                    )) {
                                  item["quantity"]++;

                                  cart.putAt(
                                    i,
                                    item,
                                  );

                                  exist = true;

                                  break;
                                }
                              }
                              if (!exist) {
                                cart.add({
                                  "id": widget
                                      .product["id"],

                                  "title":
                                      getLocalizedText(
                                    widget.product[
                                        "title"],
                                  ),

                                  "price": widget
                                      .product["price"],

                                  "image": widget
                                      .product["images"][0]["image"],

                                  "quantity": 1,

                                  "extras":
                                      selectedExtras,

                                  "company_name":
                                      companyLocation?[
                                          "name"],

                                  "company_lat":
                                      companyLocation?[
                                          "lat"],

                                  "company_lng":
                                      companyLocation?[
                                          "lng"],
                                });
                              }
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                SnackBar(
                                  backgroundColor:
                                      Colors.black,

                                  behavior:
                                      SnackBarBehavior
                                          .floating,

                                  margin:
                                      const EdgeInsets
                                          .all(16),

                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      16,
                                    ),
                                  ),

                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons
                                            .check_circle,
                                        color:
                                            Colors.orange,
                                      ),

                                      const SizedBox(
                                          width: 10),

                                      const Text(
                                        "Produit ajouté au panier",

                                        style:
                                            TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          : null,

                      child: const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,

                        children: [
                          Icon(
                            Icons
                                .shopping_bag_outlined,
                            color: Colors.white,
                            size: 21,
                          ),

                          SizedBox(width: 10),

                          Text(
                            "Ajouter au panier",

                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
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