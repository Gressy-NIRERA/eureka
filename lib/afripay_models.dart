
class AfripayException implements Exception {
  final String message;
  final int? statusCode;

  AfripayException(this.message, {this.statusCode});

  @override
  String toString() => 'AfripayException: $message';  
}
enum AfripayPaymentMethod {
  lumicash,
  card,
}

extension AfripayPaymentMethodX on AfripayPaymentMethod {
  String get apiValue {
    switch (this) {
      case AfripayPaymentMethod.lumicash:
        return 'Lumicash';
      case AfripayPaymentMethod.card:
        return 'Card';
    }
  }
  String get label {
    switch (this) {
      case AfripayPaymentMethod.lumicash:
        return 'Lumicash';
      case AfripayPaymentMethod.card:
        return 'Carte bancaire';
    }
  }
  bool get requiresOtp {
    switch (this) {
      case AfripayPaymentMethod.lumicash:
        return true;
      case AfripayPaymentMethod.card:
        return false;
    }
  }
}
class PaymentResult {
  final bool success;
  final String rawStatus;
  final String? url;
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    required this.rawStatus,
    this.url,
    this.errorMessage,
  });
  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] ?? '').toString();
    final url = (json['url'] ?? '').toString();
    final isSuccess = status.toLowerCase() == 'success';

    return PaymentResult(
      success: isSuccess,
      rawStatus: status,
      url: url.trim().isEmpty ? null : url.trim(),
      errorMessage:
          isSuccess ? null : 'Le paiement a échoué (statut : "$status").',
    );
  }
  factory PaymentResult.failure(String message) {
    return PaymentResult(success: false, rawStatus: 'error', errorMessage: message);
  }
  bool get hasRedirectUrl => success && url != null && url!.trim().isNotEmpty;
}