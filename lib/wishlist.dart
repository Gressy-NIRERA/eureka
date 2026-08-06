import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Wishlist extends StatefulWidget {
  const Wishlist({super.key});

  @override
  State<Wishlist> createState() => _WishlistState();
}

class _WishlistState extends State<Wishlist> {
  final wishlist = Hive.box("wishlist");

  void removeWishlist(int index){
    wishlist.deleteAt(index);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:Text("Retiré des favoris"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:const Color(0xffF7F7F7),
      appBar:AppBar(
        backgroundColor:Colors.white,
        elevation:0,
        centerTitle:true,
          iconTheme:const IconThemeData(
          color:Colors.black,
        ),
        title:const Text(
          "Mes favoris",
          style:TextStyle(
            color:Colors.black,
            fontWeight:FontWeight.bold,
            fontSize:22,
          ),
        ),
      ),
      body:ValueListenableBuilder(
        valueListenable:wishlist.listenable(),
        builder:(context,box,_){
          if(box.isEmpty){
            return const Center(
              child:Column(
                mainAxisAlignment:MainAxisAlignment.center,
                children:[
                  Icon(
                    Icons.favorite_border,
                    size:80,
                    color:Colors.grey,
                  ),
                  SizedBox(height:15),
                  Text(
                    "Aucun favori",
                    style:TextStyle(
                      fontSize:20,
                      fontWeight:FontWeight.bold,
                      color:Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding:const EdgeInsets.all(15),
            itemCount:box.length,
            itemBuilder:(context,index){
              final product=box.getAt(index);

              return Container(
                margin:const EdgeInsets.only(bottom:15),
                padding:const EdgeInsets.all(12),
                decoration:BoxDecoration(
                  color:Colors.white,
                  borderRadius:BorderRadius.circular(20),
                ),
                child:Row(
                  children:[
                    ClipRRect(
                      borderRadius:BorderRadius.circular(15),
                      child:Image.network(
                        product["image"],
                        width:90,
                        height:90,
                        fit:BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width:15),
                    Expanded(
                      child:Column(
                        crossAxisAlignment:CrossAxisAlignment.start,
                        children:[
                          Text(
                            product["title"],
                            maxLines:1,
                            overflow:TextOverflow.ellipsis,
                            style:const TextStyle(
                              fontSize:17,
                              fontWeight:FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height:8),
                          Text(
                            "${product["price"]} FBU",
                            style:const TextStyle(
                              fontWeight:FontWeight.bold,
                              fontSize:16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed:(){
                        removeWishlist(index);
                      },
                      icon:const Icon(
                        Icons.favorite,
                        color:Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}