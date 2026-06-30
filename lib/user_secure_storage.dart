import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserSecureStorage {
  
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  
  static const String _keyFirstname = 'firstname';
  static const String _keyToken = 'token';

 
  static Future<void> setFirstname(String name) async {
    await _storage.write(key: _keyFirstname, value: name);
  }

  
  static Future<String?> getFirstname() async {
    return await _storage.read(key: _keyFirstname);
  }

  
  static Future<void> setFirstnames(List<String> names) async {
    final value = json.encode(names);
    await _storage.write(key: _keyFirstname, value: value);
  }

 
  static Future<List<String>?> getFirstnames() async {
    final value = await _storage.read(key: _keyFirstname);
    if (value == null) return null;
    return List<String>.from(json.decode(value));
  }

  
  static Future<void> setToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

 
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
