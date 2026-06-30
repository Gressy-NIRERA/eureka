import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  
  static Future<void> saveToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
  }

  
  static Future<String> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("token") ?? "";
  }

  
  static Future<void> saveLogin(bool isLoggedIn) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isLoggedIn", isLoggedIn);
  }

  
  static Future<bool> getLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool("isLoggedIn") ?? false;
  }

 
  static Future<void> removeToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }

  
  static Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.remove("token");
    await prefs.remove("isLoggedIn");
  }
}