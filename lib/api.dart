import 'package:dio/dio.dart';

import 'package:eureka/core/network/duma_endpoints.dart';

/// Authentication client for the Duma **client** service.
///
/// Endpoints match `ClientEndpoints` in the official Duma app
/// (`duma_taxi/lib/core/api/endpoints.dart`): `POST /user/login` and
/// `POST /user/register`, not the previously guessed `/login` / `/register`.
class Api {
  late final Dio dio;

  Api(this.dio);

  Future<Map<String, dynamic>> userlogin(
      String email,
      String password) async {
    final response = await dio.post(
      ClientEndpoints.login,
      data: {
        "email": email,
        "password": password,
      },
      options: Options(headers: {'Accept': 'application/json'}),
    );

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
      ClientEndpoints.register,
      data: {
        "firstname": firstname,
        "lastname": lastname,
        "phonenumber": phonenumber,
        "email": email,
        "country": country,
        "password": password,
        "confirm_password": confirmPassword,
      },
      options: Options(headers: {'Accept': 'application/json'}),
    );

    return Map<String, dynamic>.from(response.data);
  }
}