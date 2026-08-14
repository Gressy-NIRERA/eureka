import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eureka/Cart_Service.dart';
import 'package:eureka/cache_helper.dart';
import 'package:eureka/afripay_models.dart';
import 'package:eureka/afripay_service.dart';
import 'package:eureka/afripay_credentials_provider.dart';

class PaymentPage extends StatefulWidget {
  final double cartTotal;
  final double deliveryPrice;
  final String shippingAddress;
  final String latitude;
  final String longitude;
  final String shippingNameAddress;
  final String companyId;
  final String companyName;
  final String racetypeId;

  const PaymentPage({
    super.key,
    required this.cartTotal,
    required this.deliveryPrice,
    this.shippingAddress = "Bujumbura",
    this.latitude = "-3.3614",
    this.longitude = "29.3599",
    this.shippingNameAddress = "Client",
    this.companyId = "1",
    this.companyName = "Restaurant",
    this.racetypeId = "1",
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final Dio dio = Dio();
  late final AfripayService _afripayService;

  List<dynamic> paymentMethods = [];
  String? selectedPaymentMethod;
  bool isLoading = true;
  String? errorMessage;

  bool isPlacingOrder = false;

  static const Color primary = Color(0xFFFF5A1F);
  static const Color dark = Color(0xFF1A1A1A);
  static const Color background = Color(0xFFF7F7F9);
  static const Color grey = Color(0xFF8A8A8E);

  @override
  void initState() {
    super.initState();
    fetchPaymentMethods();
    _afripayService = AfripayService(
      credentialsProvider: AppConfigAfripayCredentialsProvider(),
    );
  }

  Future<void> fetchPaymentMethods() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await dio.get("https://food.duma.africa/api/v1/afripay/payment_method/BIF");

      if (response.statusCode == 200 &&
          response.data["status"] == "success") {
        setState(() {
          paymentMethods = response.data["list"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = response.data["message"] ??
              "Impossible de récupérer les moyens de paiement.";
        });
      }
    } on DioException catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = _getErrorMessage(e);
      });
    } catch (_) {
      setState(() {
        isLoading = false;
        errorMessage = "Une erreur est survenue.";
      });
    }
  }

  String _getErrorMessage(DioException e) {
    if (e.response != null) { return "Erreur serveur : ${e.response?.statusCode}"; }
    if (e.type == DioExceptionType.connectionTimeout) { return "Connexion expirée.";}
    if (e.type == DioExceptionType.receiveTimeout) {return "Le serveur met trop de temps à répondre.";}
    if (e.type == DioExceptionType.connectionError) {return "Impossible de se connecter au serveur.";}
    return "Erreur de connexion.";
  }
  Widget _buildPaymentIcon(Map<String, dynamic> payment) {
    final String icon = payment["icon"]?.toString() ?? "";
    final String name =
        payment["payment_method_name"]?.toString() ?? "";

    if (icon.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          icon,
          width: 48,
          height: 48,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _defaultIcon(name),
        ),
      );
    }

    return _defaultIcon(name);
  }

  Widget _defaultIcon(String name) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: primary.withOpacity(.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        name.toUpperCase() == "IHELA"
            ? Icons.account_balance_wallet_outlined
            : Icons.payment,
        color: primary,
        size: 25,
      ),
    );
  }

  Widget _buildPaymentMethod(Map<String, dynamic> payment) {
    final String name =payment["payment_method_name"]?.toString() ?? "";
    final String type =payment["payment_method_type"]?.toString() ?? "";
    final String steps =payment["steps_to_follow"]?.toString() ?? "";
    final bool enabled =payment["enable_on_collection"] == 1;
    final bool selected =selectedPaymentMethod == name;
    final double minAmount = double.tryParse(payment["min_amount"]?.toString() ?? "0",) ?? 0;
    final double maxAmount = double.tryParse( payment["max_amount"]?.toString() ?? "0",) ?? 0;
    final double total = widget.cartTotal + widget.deliveryPrice;
    final bool amountValid = total >= minAmount && total <= maxAmount;
    final bool selectable =enabled && amountValid;

    return GestureDetector(
      onTap: selectable
          ? () {
          setState(() {
          selectedPaymentMethod = name;
              });
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selectable
              ? Colors.white
              : const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? primary
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: selectable
              ? const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildPaymentIcon(payment),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: selectable
                              ? dark
                              : grey,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        type.toUpperCase() == "CARD"
                            ? "Carte bancaire"
                            : "Paiement mobile",
                        style: TextStyle(
                          fontSize: 13,
                          color: selectable
                              ? grey
                              : Colors.grey,
                        ),
                      ),
                      if (!amountValid)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 4),
                          child: Text(
                            "${minAmount.toStringAsFixed(0)} - "
                            "${maxAmount.toStringAsFixed(0)} FBU",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? primary
                        : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? primary
                          : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
              ],
            ),
            if (selected && steps.trim().isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primary.withOpacity(.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Instructions de paiement",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: dark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...steps
                        .split(RegExp(r',\s*|\r\n|\n'))
                        .where(
                          (step) => step.trim().isNotEmpty,
                        )
                        .map(
                          (step) => Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 4,
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin:
                                      const EdgeInsets.only(
                                    top: 6,
                                    right: 8,
                                  ),
                                  width: 5,
                                  height: 5,
                                  decoration:
                                      const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primary,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    step.trim(),
                                    style:
                                        const TextStyle(
                                      fontSize: 13,
                                      height: 1.3,
                                      color: dark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  Future<int> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("id") ?? 0;
  }
  Future<String> _getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("phone") ?? "";
  }
  bool _requiresOtp(String paymentMethodType) {
    return paymentMethodType.toUpperCase() != "CARD";
  }
  static const String _kOtpPendingPhoneKey = "afripay_otp_pending_phone";
  static const String _kOtpPendingAtKey = "afripay_otp_pending_at";
  static const String _kLastOrderReferenceKey = "last_order_reference";
  static const String _kOrderReferencesKey = "order_references";
  Future<void> _markOtpRequested(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOtpPendingPhoneKey, phone);
    await prefs.setString(_kOtpPendingAtKey, DateTime.now().toIso8601String());
  }
  Future<void> _clearOtpPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOtpPendingPhoneKey);
    await prefs.remove(_kOtpPendingAtKey);
  }
  Future<void> _saveOrderReference({
    required String reference,
    required String paymentMethodName,
    required double amount,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_kLastOrderReferenceKey, reference);

    final List<String> history =
        prefs.getStringList(_kOrderReferencesKey) ?? <String>[];

    final entry = jsonEncode({
      "reference": reference,
      "payment_method": paymentMethodName,
      "amount": amount.toStringAsFixed(0),
      "currency": "BIF",
      "created_at": DateTime.now().toIso8601String(),
    });

    history.insert(0, entry);
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }

    await prefs.setStringList(_kOrderReferencesKey, history);
  }

  Map<String, dynamic> _buildOrderPayload(
    String paymentMethodName,
    int userId,
  ) {
    final List<Map<String, dynamic>> cartItems = CartService.cart.value;
    final double grandTotal = widget.cartTotal + widget.deliveryPrice;
    final List<Map<String, dynamic>> details = cartItems.map((item) {
      final List extrasRaw = List.from(item["extras"] ?? []);
      final List<Map<String, dynamic>> extras = extrasRaw
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)) .toList();

      return {
        "id": (item["id"] ?? "").toString(),
        "name": (item["title"] ?? item["name"] ?? "").toString(),
        "imageProduct": (item["image"] ?? "").toString(),
        "note": "",
        "price": (item["price"] ?? 0).toString(),
        "quantity": (item["quantity"] ?? 1).toString(),
        "commission": "0",
        "extras": extras,
      };
    }).toList();

    final Map<String, dynamic> companyEntry = {
      "id": widget.companyId,
      "name": widget.companyName,
      "subtotal": widget.cartTotal.toStringAsFixed(0),
      "tva": "0",
      "tax": "0",
      "total": grandTotal.toStringAsFixed(0),
      "commission": "0",
      "shipping_cost": widget.deliveryPrice.toStringAsFixed(0),
      "shipping_status": "1",
      "racetype_id": widget.racetypeId,
      "details": details,
    };

    return {
      "user_id": userId,
      "subtotal": widget.cartTotal.toStringAsFixed(0),
      "tva": "0",
      "discount_percent": 0,
      "discount": 0,
      "country": "BI",
      "shipping_name_address": widget.shippingNameAddress,
      "tax": "0",
      "total": grandTotal.toStringAsFixed(0),
      "commission": "0",
      "shipping_cost": widget.deliveryPrice.toStringAsFixed(0),
      "currency": "BIF",
      "original_currency": "BIF",
      "original_amount": grandTotal.toStringAsFixed(0),
      "shipping_address": widget.shippingAddress,
      "lat": widget.latitude,
      "long": widget.longitude,
      "payment_method": paymentMethodName,
      "companies": [companyEntry],
    };
  }
  Future<void> _placeOrder(
    String paymentMethodName,
    String paymentMethodType,
  ) async {
    setState(() {
      isPlacingOrder = true;
    });

    try {
      final int userId = await _getUserId();
      final String token = await CacheHelper.getToken();

      final payload = _buildOrderPayload(paymentMethodName, userId);

      final response = await dio.post(
        "https://food.duma.africa/api/v1/order/store",
        options: Options(
          headers: {
            "Content-Type": "application/json",
            if (token.isNotEmpty) "Authorization": "Bearer $token",
          },
        ),
        data: jsonEncode(payload),
      );

      setState(() {
        isPlacingOrder = false;
      });

      if (response.statusCode == 200 &&
          response.data["status"] == "success") {
        final String reference = response.data["reference"]?.toString() ?? "";
         if (!mounted) return;
        Navigator.pop(context);
        await _processAfripayPayment(
          reference: reference,
          paymentMethodName: paymentMethodName,
          paymentMethodType: paymentMethodType,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.data["message"]?.toString() ??
                  "Impossible de créer la commande.",
            ),
            backgroundColor: dark,
          ),
        );
      }
    } on DioException catch (e) {
      setState(() {
        isPlacingOrder = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getErrorMessage(e)),
          backgroundColor: dark,
        ),
      );
    } catch (_) {
      setState(() {
        isPlacingOrder = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Une erreur est survenue lors de la commande."),
          backgroundColor: dark,
        ),
      );
    }
  }
  Future<void> _processAfripayPayment({
    required String reference,
    required String paymentMethodName,
    required String paymentMethodType,
  }) async {
    final bool needsOtp = _requiresOtp(paymentMethodType);
    final AfripayPaymentMethod afripayMethod =
        needsOtp ? AfripayPaymentMethod.lumicash : AfripayPaymentMethod.card;

    final double total = widget.cartTotal + widget.deliveryPrice;
    final String amount = total.toStringAsFixed(0); // montant en String (règle n°5)
    final String comment = "Commande #$reference";

    String? cardNumber;
    if (!needsOtp) {
      cardNumber = await _showCardNumberDialog();
      if (cardNumber == null || cardNumber.trim().isEmpty) {
        _showOrderCreatedDialog(reference, paymentConfirmed: false);
        return;
      }
    }

    final String phone = await _getUserPhone();

    final String initiator;
    try {
      initiator = AfripayService.buildInitiator(
        method: afripayMethod,
        phone: phone,
        cardNumber: cardNumber,
      );
    } on AfripayException catch (e) {
      _showPaymentErrorDialog(e.message, reference: reference);
      return;
    }
    String? otp;
    if (needsOtp) {
      if (!mounted) return;
      setState(() => isPlacingOrder = true);

      try {
        await _afripayService.requestOtp(phone: phone);
        await _markOtpRequested(phone);
      } on AfripayException catch (e) {
        if (!mounted) return;
        setState(() => isPlacingOrder = false);
        _showPaymentErrorDialog(e.message, reference: reference);
        return;
      }

      if (!mounted) return;
      setState(() => isPlacingOrder = false);

      otp = await _showOtpDialog(phone);
      await _clearOtpPending();
      if (otp == null) {
        _showOrderCreatedDialog(reference, paymentConfirmed: false);
        return;
      }
      if (otp.trim().isEmpty) {
        _showPaymentErrorDialog(
          "Veuillez saisir le code OTP reçu par SMS.",
          reference: reference,
        );
        return;
      }
    }

    if (!mounted) return;
    setState(() => isPlacingOrder = true);

    PaymentResult? result;
    String? errorMessage;
    try {
      result = await _afripayService.pay(
        paymentMethod: afripayMethod,
        initiator: initiator,
        amount: amount,
        comment: comment,
        otp: otp,
      );
    } on AfripayException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = "Erreur inattendue : $e";
    }

    if (!mounted) return;
    setState(() => isPlacingOrder = false);

    if (errorMessage != null) {
      await _clearOtpPending();
      _showPaymentErrorDialog(errorMessage, reference: reference);
      return;
    }
    if (result == null) return;

    if (!result.success) {
      await _clearOtpPending();
      _showPaymentErrorDialog(
        result.errorMessage ?? "Le paiement a échoué. Veuillez réessayer.",
        reference: reference,
      );
      return;
    }
    await _saveOrderReference(
      reference: reference,
      paymentMethodName: paymentMethodName,
      amount: total,
    );

    if (result.hasRedirectUrl) {
      _showRedirectUrlDialog(result.url!, reference: reference);
    } else {
      // status == success, url vide : paiement confirmé directement.
      _showOrderCreatedDialog(reference, paymentConfirmed: true);
    }
  }

  Future<String?> _showOtpDialog(String phone) {
    final otpController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Vérification OTP",
            style: TextStyle(fontWeight: FontWeight.bold, color: dark),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Un code a été envoyé au $phone. "
                "Veuillez le saisir ci-dessous.",
                style: const TextStyle(color: dark),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Code OTP",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              style: TextButton.styleFrom(foregroundColor: grey),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, otpController.text),
              style: TextButton.styleFrom(foregroundColor: primary),
              child: const Text(
                "Valider",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
  Future<String?> _showCardNumberDialog() {
    final cardController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Numéro de carte",
            style: TextStyle(fontWeight: FontWeight.bold, color: dark),
          ),
          content: TextField(
            controller: cardController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: "Numéro de carte",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              style: TextButton.styleFrom(foregroundColor: grey),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, cardController.text),
              style: TextButton.styleFrom(foregroundColor: primary),
              child: const Text(
                "Valider",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
  void _showRedirectUrlDialog(String url, {required String reference}) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Paiement à finaliser",
            style: TextStyle(fontWeight: FontWeight.bold, color: dark),
          ),
          content: Text(
            "Commande #$reference créée.\n\n"
            "Votre paiement doit être finalisé sur la page suivante :\n\n$url",
            style: const TextStyle(color: dark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(foregroundColor: grey),
              child: const Text("Fermer"),
            ),
            TextButton(
              onPressed: () async {
                final uri = Uri.tryParse(url);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Impossible d'ouvrir ce lien.")),
                  );
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              style: TextButton.styleFrom(foregroundColor: primary),
              child: const Text(
                "Ouvrir le lien",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
  void _showOrderCreatedDialog(String reference, {required bool paymentConfirmed}) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Commande créée",
            style: TextStyle(fontWeight: FontWeight.bold, color: dark),
          ),
          content: Text(
            paymentConfirmed
                ? "Votre commande a été créée et votre paiement a été "
                    "confirmé avec succès.\nRéférence : $reference"
                : "Votre commande a été créée avec succès.\n"
                    "Référence : $reference",
            style: const TextStyle(color: dark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(foregroundColor: primary),
              child: const Text(
                "OK",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
  void _showPaymentErrorDialog(String message, {required String reference}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          "Erreur de paiement",
          style: TextStyle(fontWeight: FontWeight.bold, color: dark),
        ),
        content: Text(
          "Commande #$reference créée, mais le paiement a échoué :\n\n$message",
          style: const TextStyle(color: dark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(foregroundColor: primary),
            child: const Text(
              "OK",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPayment() {
    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Veuillez sélectionner un moyen de paiement.",
          ),
          backgroundColor: dark,
        ),
      );
      return;
    }

    final selected = paymentMethods.firstWhere(
      (element) =>
          element["payment_method_name"] ==
          selectedPaymentMethod,
    );

    final String name =
        selected["payment_method_name"].toString();
    final String type =
        selected["payment_method_type"]?.toString() ?? "";

    final double total =
        widget.cartTotal + widget.deliveryPrice;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isDismissible: !isPlacingOrder,
      enableDrag: !isPlacingOrder,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB( 20,15,20,25, ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Confirmation du paiement",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: dark,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Méthode",
                        style: TextStyle(color: grey),
                      ),
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: dark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total",
                        style: TextStyle(color: grey),
                      ),
                      Text(
                        "${total.toStringAsFixed(0)} FBU",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isPlacingOrder
                          ? null
                          : () async {
                              setModalState(() {});
                              await _placeOrder(name, type);
                            },
                      child: isPlacingOrder
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Continuer",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentMethods() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primary,
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 45,
              color: primary,
            ),
            const SizedBox(height: 10),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: dark,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: fetchPaymentMethods,
              child: const Text("Réessayer"),
            ),
          ],
        ),
      );
    }

    if (paymentMethods.isEmpty) {
      return const Center(
        child: Text(
          "Aucun moyen de paiement disponible.",
          style: TextStyle(
            fontSize: 15,
            color: grey,
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: paymentMethods.length,
      itemBuilder: (context, index) {
        final payment =
            Map<String, dynamic>.from(
          paymentMethods[index],
        );

        return _buildPaymentMethod(payment);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double grandTotal =
        widget.cartTotal + widget.deliveryPrice;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: dark,
        ),
        title: const Text(
          "Paiement",
          style: TextStyle(
            color: dark,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Sous-total",
                          style: TextStyle(
                            color: grey,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "${widget.cartTotal.toStringAsFixed(0)} FBU",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: dark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Livraison",
                          style: TextStyle(
                            color: grey,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "${widget.deliveryPrice.toStringAsFixed(0)} FBU",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: dark,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      child: Divider(height: 1),
                    ),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: dark,
                          ),
                        ),
                        Text(
                          "${grandTotal.toStringAsFixed(0)} FBU",
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Moyen de paiement",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: dark,
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Expanded(
                child: _buildPaymentMethods(),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _confirmPayment,
                  child: const Text(
                    "Confirmer le paiement",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}