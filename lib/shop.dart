import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:eureka/delivery.dart';

class Shop extends StatelessWidget {
  const Shop({super.key});
  List _extrasOf(dynamic item) {
    return (item["extras"] as List?) ?? [];
  }
  bool _isFree(dynamic extra) {
    final type = (extra["type"] ?? "PAYANT").toString().toUpperCase();
    return type == "GRATUIT";
  }
  num _extrasTotal(dynamic item) {
    num sum = 0;
    for (var extra in _extrasOf(item)) {
      if (!_isFree(extra)) {
        sum += (extra["price"] ?? 0);
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

      final latVal = (lat is num) ? lat.toDouble() : double.tryParse(lat.toString());
      final lngVal = (lng is num) ? lng.toDouble() : double.tryParse(lng.toString());
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

  @override
  Widget build(BuildContext context) {
    final cart = Hive.box("cart");
      return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Mon panier",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ValueListenableBuilder(
        valueListenable: cart.listenable(),
        builder: (context, Box box, _) {
        if(box.isEmpty){
            return const Center(
              child: Text(
                "Panier vide",
                style: TextStyle(
                  fontSize:18,
                  fontWeight:FontWeight.bold,
                  color:Colors.grey,
                ),
              ),
            );
          }
          double total = 0;
           for(var item in box.values){
            total += _lineTotal(item);
          }
          return Column(
            children: [
              Expanded(
              child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: box.length,
              itemBuilder: (context,index){
              final item = box.getAt(index);
              final extras = _extrasOf(item);
               return Card(
                     elevation:4,
                      margin:const EdgeInsets.only(bottom:15),
                      shadowColor:Colors.black12,
                      shape:RoundedRectangleBorder(
                        borderRadius:BorderRadius.circular(20),
                      ),

                      child:Padding(
                        padding:const EdgeInsets.all(12),

                        child:Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:[
                           ClipRRect(
                              borderRadius:BorderRadius.circular(15),
                              child:Image.network(
                                item["image"],
                                width:80,
                                height:80,
                                fit:BoxFit.cover,
                              ),
                            ),

                            const SizedBox(width:15),

                            Expanded(
                              child:Column(
                                crossAxisAlignment:CrossAxisAlignment.start,
                                children:[
                                Text(
                                    item["title"],
                                    style:const TextStyle(
                                      fontSize:17,
                                      fontWeight:FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height:8),

                                  Text(
                                    "${item["price"]} FBU",
                                    style:const TextStyle(
                                      color:Colors.green,
                                      fontSize:16,
                                      fontWeight:FontWeight.bold,
                                    ),
                                  ),

                                  if (extras.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Accompagnements",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          ...extras.map((extra) {
                                            final free = _isFree(extra);
                                            return Padding(
                                              padding: const EdgeInsets
                                                  .symmetric(vertical: 2),
                                              child: Row(
                                                children: [
                                                  const Text(
                                                    "• ",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      extra["name"] ?? "",
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    free
                                                        ? "Gratuit"
                                                        : "+${extra["price"]} FBU",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: free
                                                          ? Colors
                                                              .green.shade700
                                                          : Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 10),

                                  Text(
                                    "Sous-total : ${_lineTotal(item).toStringAsFixed(0)} FBU",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54,
                                    ),
                                  ),

                                  Row(
                                    children:[

                                      IconButton(
                                        onPressed:(){

                                          if(item["quantity"] > 1){
                                            item["quantity"]--;
                                            box.putAt(index,item);
                                          }

                                        },
                                        icon:const Icon(
                                          Icons.remove_circle,
                                        ),
                                      ),

                                      Text(
                                        item["quantity"].toString(),
                                        style:const TextStyle(
                                          fontSize:18,
                                          fontWeight:FontWeight.bold,
                                        ),
                                      ),

                                      IconButton(
                                        onPressed:(){

                                          item["quantity"]++;
                                          box.putAt(index,item);

                                        },
                                        icon:const Icon(
                                          Icons.add_circle,
                                        ),
                                      ),

                                      IconButton(
                                        onPressed:(){
                                          box.deleteAt(index);
                                        },
                                        icon:const Icon(
                                          Icons.delete,
                                          color:Colors.red,
                                        ),
                                      ),

                                    ],
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

              Container(
                padding:const EdgeInsets.all(20),

                decoration:const BoxDecoration(
                  color:Colors.white,
                  borderRadius:BorderRadius.vertical(
                    top:Radius.circular(30),
                  ),
                ),

                child:Column(
                  children:[

                    Text(
                      "Total : ${total.toStringAsFixed(0)} FBU",
                      style:const TextStyle(
                        fontSize:24,
                        fontWeight:FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height:15),

                    SizedBox(
                      width:double.infinity,
                      height:50,

                      child:ElevatedButton.icon(
                        style:ElevatedButton.styleFrom(
                          backgroundColor:Colors.black,
                          shape:RoundedRectangleBorder(
                            borderRadius:BorderRadius.circular(15),
                          ),
                        ),

                        onPressed:(){
                          final origins = _extractOrigins(box);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:(_) => DeliveryWidget(
                                cartTotal: total,
                                origins: origins,
                              ),
                            ),
                          );
                        },

                        icon: const Icon(
                          Icons.delivery_dining_outlined,
                          color: Colors.white,
                        ),

                        label:const Text(
                          "Livraison",
                          style:TextStyle(
                            color:Colors.white,
                            fontSize:16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}