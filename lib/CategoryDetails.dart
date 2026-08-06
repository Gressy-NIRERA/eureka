import 'package:flutter/material.dart';
import 'package:eureka/home.dart';

class CategoryDetails extends StatelessWidget {
  final CategoryModel category;
  final String currentLanguage;

  const CategoryDetails({
    super.key,
    required this.category,
    required this.currentLanguage,
  });

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

        title:Text(
          category.name[currentLanguage] 
          ?? category.name["fr"] 
          ?? "",
          style:const TextStyle(
            color:Colors.black,
            fontWeight:FontWeight.bold,
            fontSize:20,
          ),
        ),
      ),
       body:SingleChildScrollView(
        padding:const EdgeInsets.all(20),

        child:Column(
          children:[
          Container(
              height:280,
              width:double.infinity,
               decoration:BoxDecoration(
                color:Colors.white,
                borderRadius:BorderRadius.circular(30),
                boxShadow:[
                  BoxShadow(
                    color:Colors.black,
                    blurRadius:15,
                    offset:const Offset(0,5),
                  ),
                ],
              ),

              child:ClipRRect(
                borderRadius:BorderRadius.circular(30),

                child:Image.network(
                  category.image,
                  fit:BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height:25),
             Container(
              width:double.infinity,
              padding:const EdgeInsets.all(20),
             decoration:BoxDecoration(
                color:Colors.white,
                borderRadius:BorderRadius.circular(25),
              ),

              child:Column(
                children:[
                 Text(
                    category.name[currentLanguage]
                    ??
                    category.name["fr"]
                    ??
                    "",
                textAlign:TextAlign.center,
                  style:const TextStyle(
                      fontSize:26,
                      fontWeight:FontWeight.bold,
                    ),
                  ),
                  ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}