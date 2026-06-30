import 'package:dio/dio.dart';

class Api {
  final String baseurl = "https://client.duma.africa/api/v1";

  late final Dio dio;

  Api(this.dio);

  Future<Map<String, dynamic>> userlogin(String email, String password) async {
    final response = await dio.post(
      "$baseurl/login",
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: {"email": email, "password": password},
    );
    print(response);
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> register(
    String firstname,
    String lastname,
    int phonenumber,
    String email,
    String country,
    String password,
    String confirmPassword,
  ) async {
    final response = await dio.post(
      "$baseurl/register",
      data: {
        "firstname": firstname,
        "lastname": lastname,
        "phonenumber": phonenumber,
        "email": email,
        "country": country,
        "password": password,
        "confirm_password": confirmPassword,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }
}
