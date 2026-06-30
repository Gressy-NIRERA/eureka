import 'package:flutter/material.dart';
import 'cache_helper.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String token = "";

  @override
  void initState() {
    super.initState();
    loadToken();
  }

  Future<void> loadToken() async {
    token = await CacheHelper.getToken();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          token.isEmpty ? "aucun token" : token,
        ),
      ),
    );
  }
}