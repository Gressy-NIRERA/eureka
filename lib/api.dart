import 'package:dio/dio.dart';

class Api {
  final String baseurl = "https://client.duma.africa/api/v1";
  late final Dio dio;
   Api(this.dio);

  Future<Map<String, dynamic>> userlogin(
    String email,
    String password,
  ) async {
    final response = await dio.post(
      "$baseurl/user/login",
      options: Options(
        headers: {
          "Content-Type": "application/json",
        },
      ),
      data: {
        "email": email,
        "password": password,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }
  Future<Map<String, dynamic>> register(
    String firstname,
    String lastname,
    String phonenumber,
    String email,
    String country,
    String password,
    String confirmPassword,
  ) async {
    try {
      final response = await dio.post(
        "$baseurl/user/register",
        options: Options(
          headers: {
            "Content-Type": "application/json",
          },
        ),
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

      print("REGISTER RESPONSE: ${response.data}");

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      print("REGISTER STATUS : ${e.response?.statusCode}");
      print("REGISTER ERROR : ${e.response?.data}");

      rethrow;
    }
  }
  Future<List> searchProducts(String query) async {
    try {
      final response = await dio.get(
        "https://food.duma.africa/api/v1/search",
        queryParameters: {
          "query": query,
        },
      );

      final data = response.data;

      if (data is Map &&
          data["suggestions"] is Map &&
          data["suggestions"]["products"] is List) {
        return data["suggestions"]["products"];
      }

      return [];
    } catch (e) {
      print("Erreur recherche : $e");
      return [];
    }
  }
  Future<List> searchDeliveryPlace(String query) async {
    try {
      final response = await dio.post(
        "https://taxi.duma.africa/api/v1/search/place/new",
        data: {
          "language": "fr",
          "country": "BI",
          "textQuery": query,
        },
        options: Options(
          headers: {
            "Content-Type": "application/json",
          },
        ),
      );

      print(response.data);

      return List<dynamic>.from(
        response.data["data"] ?? [],
      );
    } on DioException catch (e) {
      print(e.response?.data);
      return [];
    }
  }
  Future<Map<String, dynamic>?> getDistance({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    try {
      final response = await dio.get(
        "https://taxi.duma.africa/api/v1/get/distance/v2",
        queryParameters: {
          "origin": "$originLng,$originLat",
          "destination": "$destinationLng,$destinationLat",
        },
      );

      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      print("Erreur distance : $e");
      return null;
    }
  }
  Future<List> getPrice(
    double distance, {
    String country = "BI",
  }) async {
    try {
      final now = DateTime.now();

      final time =
          "${now.year.toString().padLeft(4, '0')}-"
          "${now.month.toString().padLeft(2, '0')}-"
          "${now.day.toString().padLeft(2, '0')} "
          "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}";

      final response = await dio.post(
        "https://taxi.duma.africa/api/v1/price/2",
        options: Options(
          headers: {
            "Content-Type": "application/json",
          },
        ),
        data: {
          "distance": distance,
          "time": time,
          "country": country,
        },
      );

      print("PRICE RESPONSE: ${response.data}");

      if (response.data is Map &&
          response.data["prices"] is List) {
        return List<dynamic>.from(
          response.data["prices"],
        );
      }

      return [];
    } on DioException catch (e) {
      print("Erreur prix : ${e.response?.data}");
      return [];
    } catch (e) {
      print("Erreur prix : $e");
      return [];
    }
  }

  Future<List> getCompanies(
    String isoCode, {
    int page = 1,
  }) async {
    try {
      final response = await dio.get(
        "https://food.duma.africa/api/v1/company/$isoCode",
        queryParameters: {
          "page": page,
        },
      );

      print("COMPANIES STATUS: ${response.statusCode}");
      print("COMPANIES RESPONSE: ${response.data}");

      final body = response.data;

      if (body is Map && body["data"] is List) {
        return List<dynamic>.from(body["data"]);
      }

      if (body is Map &&
          body["data"] is Map &&
          body["data"]["data"] is List) {
        return List<dynamic>.from(
          body["data"]["data"],
        );
      }

      if (body is Map && body["companies"] is List) {
        return List<dynamic>.from(
          body["companies"],
        );
      }

      if (body is Map && body["result"] is List) {
        return List<dynamic>.from(
          body["result"],
        );
      }

      if (body is List) {
        return List<dynamic>.from(body);
      }

      print(
        "COMPANIES : format de réponse inattendu, "
        "voir COMPANIES RESPONSE ci-dessus",
      );

      return [];
    } on DioException catch (e) {
      print(
        "Erreur restaurants (Dio) : "
        "${e.response?.statusCode} "
        "${e.response?.data}",
      );

      return [];
    } catch (e) {
      print("Erreur restaurants : $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCompanyDetail(
    dynamic id,
  ) async {
    try {
      final response = await dio.get(
        "https://food.duma.africa/api/v1/company/detail/$id",
      );

      print(
        "COMPANY DETAIL STATUS: ${response.statusCode}",
      );

      print(
        "COMPANY DETAIL RESPONSE: ${response.data}",
      );

      final body = response.data;

      if (body is Map && body["data"] is Map) {
        return Map<String, dynamic>.from(
          body["data"],
        );
      }

      if (body is Map) {
        return Map<String, dynamic>.from(body);
      }

      print(
        "COMPANY DETAIL : format de réponse inattendu, "
        "voir COMPANY DETAIL RESPONSE ci-dessus",
      );

      return null;
    } on DioException catch (e) {
      print(
        "Erreur détail restaurant (Dio) : "
        "${e.response?.statusCode} "
        "${e.response?.data}",
      );

      return null;
    } catch (e) {
      print("Erreur détail restaurant : $e");
      return null;
    }
  }
}