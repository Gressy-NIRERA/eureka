import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:eureka/api.dart';
import 'package:eureka/paiement.dart';

class PlaceModel {
  final String name;
  final String address;
  final double lat;
  final double lng;

  PlaceModel({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    final loc = json["geometry"]?["location"] ?? {};
    return PlaceModel(
      name: (json["name"] ?? "").toString(),
      address: (json["formatted_address"] ?? "").toString(),
      lat: double.tryParse(loc["lat"].toString()) ?? 0,
      lng: double.tryParse(loc["lng"].toString()) ?? 0,
    );
  }
}

class RestaurantOrigin {
  final String name;
  final double lat;
  final double lng;

  RestaurantOrigin({
    required this.name,
    required this.lat,
    required this.lng,
  });
}

class PriceOption {
  final String name;
  final String photo;
  final num price;
  final String currency;
  final String maxPerson;

  PriceOption({
    required this.name,
    required this.photo,
    required this.price,
    required this.currency,
    required this.maxPerson,
  });

  factory PriceOption.fromJson(Map<String, dynamic> json) {
    final type = json["race_type"] ?? {};
    return PriceOption(
      name: (type["name"] ?? "").toString(),
      photo: (type["photo"] ?? "").toString(),
      price: num.tryParse(json["price"].toString()) ?? 0,
      currency: (json["currency"] ?? "").toString(),
      maxPerson: (type["max_person"] ?? "").toString(),
    );
  }
}

class DeliveryWidget extends StatefulWidget {
  final double cartTotal;
  final List<Map<String, dynamic>> origins;

  const DeliveryWidget({
    super.key,
    required this.cartTotal,
    this.origins = const [],
  });

  @override
  State<DeliveryWidget> createState() => _DeliveryWidgetState();
}

class _DeliveryWidgetState extends State<DeliveryWidget> {
  final Api api = Api(Dio());
  final originCtrl = TextEditingController();
  final destCtrl = TextEditingController();

  List<PlaceModel> originResults = [];
  List<PlaceModel> destResults = [];
  PlaceModel? origin;
  PlaceModel? destination;

  Timer? _debounceOrigin;
  Timer? _debounceDest;
  bool loading = false;

  double? distanceKm;
  List<PriceOption> prices = [];
  int? selectedPriceIndex;
static const int minChars = 3;

  late final List<RestaurantOrigin> restaurantOrigins;

  @override
  void initState() {
    super.initState();
    restaurantOrigins = widget.origins
        .map((o) => RestaurantOrigin(
              name: (o["name"] ?? "Restaurant").toString(),
              lat: (o["lat"] is num)
                  ? (o["lat"] as num).toDouble()
                  : double.tryParse(o["lat"].toString()) ?? 0,
              lng: (o["lng"] is num)
                  ? (o["lng"] as num).toDouble()
                  : double.tryParse(o["lng"].toString()) ?? 0,
            ))
        .toList();
  }

  bool get useAutoOrigins => restaurantOrigins.isNotEmpty;

  void onOriginChanged(String v) {
    _debounceOrigin?.cancel();
    _debounceOrigin = Timer(const Duration(milliseconds: 400), () {
      search(v, true);
    });
  }

  void onDestChanged(String v) {
    _debounceDest?.cancel();
    _debounceDest = Timer(const Duration(milliseconds: 400), () {
      search(v, false);
    });
  }

  Future<void> search(String query, bool isOrigin) async {
    if (query.trim().length < minChars) {
      setState(() {
        if (isOrigin) {
          originResults = [];
        } else {
          destResults = [];
        }
      });
      return;
    }

    final raw = await api.searchDeliveryPlace(query);
    final places = raw
        .whereType<Map>()
        .map((e) => PlaceModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    if (!mounted) return;

    setState(() {
      if (isOrigin) {
        originResults = places;
      } else {
        destResults = places;
      }
    });
  }

  void select(PlaceModel place, bool isOrigin) {
    setState(() {
      if (isOrigin) {
        origin = place;
        originCtrl.text = place.name;
        originResults = [];
      } else {
        destination = place;
        destCtrl.text = place.name;
        destResults = [];
      }
      distanceKm = null;
      prices = [];
      selectedPriceIndex = null;
    });
  }
  double _extractDistanceKm(dynamic response) {
    if (response == null) return 0;

    dynamic node = response;
    if (response is Map && response["data"] is Map) {
      node = response["data"];
    }

    if (node is! Map) return 0;

    final distanceField = node["distance"];

    if (distanceField is num) return distanceField.toDouble();
    if (distanceField is String) {
      final parsed = double.tryParse(distanceField);
      if (parsed != null) return parsed;
      // Cas "5.8 km" -> on extrait le nombre
      final match = RegExp(r'[\d.]+').firstMatch(distanceField);
      if (match != null) return double.tryParse(match.group(0)!) ?? 0;
    }
    if (distanceField is Map) {
      if (distanceField["value"] != null) {
        final meters = double.tryParse(distanceField["value"].toString());
        if (meters != null) return meters / 1000;
      }
      if (distanceField["text"] != null) {
        final match =
            RegExp(r'[\d.]+').firstMatch(distanceField["text"].toString());
        if (match != null) return double.tryParse(match.group(0)!) ?? 0;
      }
    }

    return 0;
  }

  Future<void> calculer() async {
    if (destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Choisissez une destination")),
      );
      return;
    }
    List<RestaurantOrigin> effectiveOrigins;
    if (useAutoOrigins) {
      effectiveOrigins = restaurantOrigins;
    } else {
      if (origin == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Choisissez un point de départ")),
        );
        return;
      }
      effectiveOrigins = [
        RestaurantOrigin(name: origin!.name, lat: origin!.lat, lng: origin!.lng),
      ];
    }

    setState(() {
      loading = true;
      distanceKm = null;
      prices = [];
      selectedPriceIndex = null;
    });

    try {
      double totalDistance = 0;
      for (final o in effectiveOrigins) {
        final distRes = await api.getDistance(
          originLat: o.lat,
          originLng: o.lng,
          destinationLat: destination!.lat,
          destinationLng: destination!.lng,
        );

        print("DISTANCE RAW RESPONSE (${o.name}): $distRes");

        totalDistance += _extractDistanceKm(distRes);
      }

      if (totalDistance <= 0) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Distance introuvable, vérifie les coordonnées"),
          ),
        );
        return;
      }

      final rawPrices = await api.getPrice(totalDistance);
      final priceList = rawPrices
          .whereType<Map>()
          .map((e) => PriceOption.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      setState(() {
        distanceKm = totalDistance;
        prices = priceList;
        loading = false;
      });

      if (priceList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aucun prix disponible pour cette distance")),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  void continuerVersPaiement() {
    if (selectedPriceIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Choisissez un moyen de déplacement")),
      );
      return;
    }

    final selected = prices[selectedPriceIndex!];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          cartTotal: widget.cartTotal,
          deliveryPrice: selected.price.toDouble(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    originCtrl.dispose();
    destCtrl.dispose();
    _debounceOrigin?.cancel();
    _debounceDest?.cancel();
    super.dispose();
  }

  Widget searchField({
    required TextEditingController ctrl,
    required String hint,
    required bool isOrigin,
    required List<PlaceModel> results,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: ctrl,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon:
                Icon(isOrigin ? Icons.trip_origin : Icons.location_on_outlined),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: results.length,
              itemBuilder: (_, i) {
                final p = results[i];
                return ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title:
                      Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(p.address,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => select(p, isOrigin),
                );
              },
            ),
          ),
      ],
    );
  }
  Widget originsSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: restaurantOrigins.map((o) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              const Icon(Icons.storefront, color: Colors.black87),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  o.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget priceCard(PriceOption p, int index) {
    final isSelected = selectedPriceIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPriceIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: p.photo.isNotEmpty
                  ? Image.network(
                      p.photo,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.local_shipping),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.local_shipping),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (p.maxPerson.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Max ${p.maxPerson} personne(s)",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              "${p.price} ${p.currency}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? Colors.black : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Livraison",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total du panier",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    "${widget.cartTotal.toStringAsFixed(0)} FBU",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),

            const Text("Point de départ", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (useAutoOrigins)
              originsSummary()
            else
              searchField(
                ctrl: originCtrl,
                hint: "Rechercher un point de départ",
                isOrigin: true,
                results: originResults,
                onChanged: onOriginChanged,
              ),

            const SizedBox(height: 20),
            const Text("Destination", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            searchField(
              ctrl: destCtrl,
              hint: "Rechercher une destination",
              isOrigin: false,
              results: destResults,
              onChanged: onDestChanged,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: loading ? null : calculer,
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text("Calculer",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 25),
            if (distanceKm != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Text(
                  "Distance : ${distanceKm!.toStringAsFixed(1)} km",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            if (prices.isNotEmpty) ...[
              const Text(
                "Choisissez un moyen de déplacement",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 12),
              ...prices.asMap().entries.map((e) => priceCard(e.value, e.key)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: selectedPriceIndex == null ? null : continuerVersPaiement,
                  child: const Text(
                    "Continuer vers le paiement",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}