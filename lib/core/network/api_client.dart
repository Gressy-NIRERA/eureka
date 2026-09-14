import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Thin, shared [Dio] factory used by every service that talks to the Duma
/// backend. Centralising it keeps timeouts, headers and logging consistent
/// instead of instantiating a raw `Dio()` in every screen.
class ApiClient {
  ApiClient._();

  static Dio create({String? bearerToken}) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          if (bearerToken != null && bearerToken.isNotEmpty)
            'Authorization': 'Bearer $bearerToken',
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: false),
      );
    }

    return dio;
  }
}
