import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';


class SharedPrefService {

 Future<void> writeCache({required String key,required String value, }) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    bool isSaved = await pref.setString(key, value);
    debugPrint("Saved [$key]: $isSaved");
  }
 Future<String?> readCache({ required String key, }) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String? value = pref.getString(key);
    if (value != null) { debugPrint("Read [$key]: $value");
    } else { debugPrint("No value found for [$key]"); }
    return value;
  }
  Future<void> removeCache({required String key,}) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.remove(key);
    debugPrint("Removed [$key]");}}

class CacheHelper {static Future<void> saveToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);}

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
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove("token");
  await prefs.remove("isLoggedIn");
  await prefs.remove("id");
  await prefs.remove("firstname");
  await prefs.remove("lastname");
  await prefs.remove("email");
  await prefs.remove("phone");
  await prefs.remove("country");
}

  static Future<void> saveUserData(Map<String, dynamic> user) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setInt("id", user["id"]);
  await prefs.setString("firstname", user["firstname"] ?? "");
  await prefs.setString("lastname", user["lastname"] ?? "");
  await prefs.setString("email", user["email"] ?? "");
  await prefs.setString("phone", user["phonenumber"] ?? "");
  await prefs.setString("country", user["country"] ?? "");
}

static Future<String> getFirstname() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("firstname") ?? "";
}

static Future<String> getLastname() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("lastname") ?? "";
}

static Future<String> getEmail() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("email") ?? "";
}

static Future<String> getPhone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("phone") ?? "";
}

static Future<String> getCountry() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("country") ?? "";
}
}
