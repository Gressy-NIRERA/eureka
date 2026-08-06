import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eureka/Login.dart';
import 'package:eureka/control.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("cart");
  await Hive.openBox("wishlist");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("isLoggedIn") ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner:false,
      home:FutureBuilder<bool>(
        future:checkLogin(),
        builder:(context,snapshot){
          if(!snapshot.hasData){
            return const Scaffold(
              body:Center(
                child:CircularProgressIndicator(),
              ),
            );
          }
          return snapshot.data == true
              ? const Control()
              : const LoginWidget();
        },
      ),
    );
  }
}