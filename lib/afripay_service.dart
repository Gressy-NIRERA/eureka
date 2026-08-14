import 'package:dio/dio.dart';
import 'afripay_models.dart';
import 'afripay_credentials_provider.dart';

class AfripayService {
  final Dio _dio;
  final AfripayCredentialsProvider _credentialsProvider;

  static const String _baseUrl = 'https://food.duma.africa/api/v1';

  AfripayService({
    Dio? dio,
    required AfripayCredentialsProvider credentialsProvider,
  })  : _credentialsProvider = credentialsProvider,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 20),
              ),
            );
  static String buildInitiator({
    required AfripayPaymentMethod method,
    String? phone,
    String? cardNumber,
  }) {
    switch (method) {
      case AfripayPaymentMethod.lumicash:
        final normalized = _normalizePhoneWithPlus(phone);
        if (normalized == null) {
          throw AfripayException('Numéro de téléphone du client manquant ou invalide.');
        }
        return normalized;
      case AfripayPaymentMethod.card:
        final card = cardNumber?.trim();
        if (card == null || card.isEmpty) {
          throw AfripayException('Numéro de carte manquant.');
        }
        return card;
    }
  }
  Future<void> requestOtp({required String phone}) async {
    final localNumber = _normalizeLocalNumber(phone);
    if (localNumber == null) {
      throw AfripayException('Numéro de téléphone invalide.');
    }

    try {
      final response = await _dio.get('/afripay/getotp/257$localNumber');

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw AfripayException(
          'Impossible d\'envoyer le code OTP (code ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw AfripayException(_mapDioError(e), statusCode: e.response?.statusCode);
    }
  }
  Future<PaymentResult> pay({
    required AfripayPaymentMethod paymentMethod,
    required String initiator,
    required String amount,
    required String comment,
    String? otp,
  }) async {
    if (paymentMethod.requiresOtp && (otp == null || otp.trim().isEmpty)) {
      throw AfripayException('Le code OTP est requis pour ce moyen de paiement.');
    }

    try {
      final clientToken = await _credentialsProvider.getClientToken();
      final appId = await _credentialsProvider.getAppId();
      final appSecret = await _credentialsProvider.getAppSecret();

      final body = <String, dynamic>{
        'initiator': initiator,
        'amount': amount, 
        'currency': 'BIF', 
        'payment_method': paymentMethod.apiValue,
        'comment': comment,
        'client_token': clientToken,
        'app_id': appId,
        'app_secret': appSecret,
      };
      if (paymentMethod.requiresOtp) {
        body['otp'] = otp;
      }

      final response = await _dio.post('/afripay/payment', data: body);

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw AfripayException(
          'Erreur serveur lors du paiement (code ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw AfripayException('Réponse du serveur invalide (format inattendu).');
      }

      return PaymentResult.fromJson(data);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data.containsKey('status')) {
        return PaymentResult.fromJson(data);
      }
      throw AfripayException(_mapDioError(e), statusCode: e.response?.statusCode);
    } on AfripayException {
      rethrow;
    } catch (e) {
      throw AfripayException('Erreur inattendue lors du paiement : $e');
    }
  }
  static String? _normalizeLocalNumber(String? phone) {
    if (phone == null) return null;
    var p = phone.trim().replaceAll(RegExp(r'[\s-]'), '');
    if (p.isEmpty) return null;
    if (p.startsWith('+257')) {
      p = p.substring(4);
    } else if (p.startsWith('257')) {
      p = p.substring(3);
    } else if (p.startsWith('+')) {
      p = p.substring(1);
    }
    return p.isEmpty ? null : p;
  }
  static String? _normalizePhoneWithPlus(String? phone) {
    final local = _normalizeLocalNumber(phone);
    if (local == null) return null;
    return '+257$local';
  }

  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Le délai de connexion a expiré. Vérifiez votre connexion internet.';
      case DioExceptionType.connectionError:
        return 'Impossible de contacter le serveur Afripay. Vérifiez votre connexion.';
      case DioExceptionType.cancel:
        return 'La requête a été annulée.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final data = e.response?.data;
        String? serverMessage;
        if (data is Map) {
          serverMessage =
              (data['message'] ?? data['error'] ?? data['status'])?.toString();
        }
        return 'Erreur du serveur (${code ?? 'inconnu'})'
            '${serverMessage != null ? ' : $serverMessage' : '.'}';
      case DioExceptionType.badCertificate:
        return 'Certificat de sécurité invalide.';
      case DioExceptionType.unknown:
        return 'Erreur réseau : ${e.message ?? 'inconnue'}.';
    }
  }
}