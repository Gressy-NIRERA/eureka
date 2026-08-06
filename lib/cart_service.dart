import 'package:flutter/material.dart';

class CartService {
  static final ValueNotifier<List<Map<String, dynamic>>> cart =
      ValueNotifier([]);

  static void addProduct(Map<String, dynamic> product) {
    cart.value = [...cart.value, product];
  }

  static void removeProduct(Map<String, dynamic> product) {
    cart.value = cart.value.where((e) => e != product).toList();
  }

  static int get count => cart.value.length;
}