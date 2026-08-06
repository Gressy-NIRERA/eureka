import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:eureka/api.dart';
import 'package:eureka/ProductDetails.dart';

class CompanyDetails extends StatefulWidget {
  final dynamic companyId;
  
  final String? initialName;
  final String? initialImage;
  final String? initialAddress;
  final String currentLanguage;

  const CompanyDetails({
    super.key,
    required this.companyId,
    this.initialName,
    this.initialImage,
    this.initialAddress,
    this.currentLanguage = "fr",
  });

  @override
  State<CompanyDetails> createState() => _CompanyDetailsState();
}

class _CompanyDetailsState extends State<CompanyDetails> {
  final Api api = Api(Dio());

  bool loading = true;
  String? error;
  Map<String, dynamic>? company;

  @override
  void initState() {
    super.initState();
    fetchDetails();
  }

  Future<void> fetchDetails() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await api.getCompanyDetail(widget.companyId);

      if (data == null) {
        setState(() {
          loading = false;
          error = "Restaurant introuvable";
        });
        return;
      }

      setState(() {
        company = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = "Erreur lors du chargement ($e)";
      });
    }
  }

  String _localized(dynamic raw) {
    if (raw == null) return "";
    final text = raw.toString();
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        return (decoded[widget.currentLanguage] ?? decoded["fr"] ?? decoded.values.first)
            .toString();
      }
    } catch (_) {}
    return text;
  }

  String get name {
    if (company != null) {
      final n = _localized(company!["name"] ?? company!["company_name"]);
      if (n.isNotEmpty) return n;
    }
    return widget.initialName ?? "Restaurant";
  }

  String get image {
    if (company != null) {
      final img = (company!["image"] ??
              company!["logo"] ??
              company!["photo"] ??
              company!["cover"] ??
              "")
          .toString();
      if (img.isNotEmpty) return img;
    }
    return widget.initialImage ?? "";
  }

  String get address {
    if (company != null) {
      final a = (company!["address"] ??
              company!["company_address"] ??
              company!["location"] ??
              company!["adresse"] ??
              "")
          .toString();
      if (a.isNotEmpty) return a;
    }
    return widget.initialAddress ?? "";
  }

  String get phone {
    if (company == null) return "";
    return (company!["phone"] ??
            company!["telephone"] ??
            company!["phonenumber"] ??
            "")
        .toString();
  }

  String get description {
    if (company == null) return "";
    return _localized(company!["description"] ?? company!["bio"]);
  }

  List get companyProducts {
    if (company == null) return [];
    final raw = company!["products"] ?? company!["items"];
    if (raw is List) return raw;
    return [];
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
        title: Text(
          name,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: fetchDetails,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                          child: const Text("Réessayer", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: image.isNotEmpty
                              ? Image.network(
                                  image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    color: const Color(0xffF3F3F3),
                                    child: const Icon(Icons.storefront, size: 50),
                                  ),
                                )
                              : Container(
                                  color: const Color(0xffF3F3F3),
                                  child: const Icon(Icons.storefront, size: 50),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),

                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 20, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                address,
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 20, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              phone,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                            ),
                          ],
                        ),
                      ],

                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            description,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                        ),
                      ],

                      if (companyProducts.isNotEmpty) ...[
                        const SizedBox(height: 25),
                        const Text(
                          "Produits",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: companyProducts.length,
                          itemBuilder: (context, index) {
                            final product = Map<String, dynamic>.from(companyProducts[index]);
                            final title = _localized(product["title"]);
                            String img = "";
                            try {
                              img = product["images"][0]["image"];
                            } catch (_) {}

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetails(
                                      product: product,
                                      currentLanguage: widget.currentLanguage,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: img.isNotEmpty
                                          ? Image.network(
                                              img,
                                              width: 65,
                                              height: 65,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 65,
                                              height: 65,
                                              color: const Color(0xffF3F3F3),
                                              child: const Icon(Icons.fastfood),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Text(
                                      "${product["price"]} FBU",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}