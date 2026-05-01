import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';

class StudentPaymentRepository {
  Future<PaymentInit?> startPlanPayment(String planKey,
      {String? currency}) async {
    final response = await ApiClient.dio.post(
      '/student-plans/purchase',
      data: {
        'plan_key': planKey,
        if (currency != null && currency.isNotEmpty) 'currency': currency,
      },
    );
    final data = ApiResponseParser.tryMap(response.data);
    return data == null ? null : PaymentInit.fromJson(data);
  }

  Future<Iyzico3dsInit?> initIyzico3dsPlanPayment({
    required String planKey,
    required String cardHolderName,
    required String cardNumber,
    required String expireMonth,
    required String expireYear,
    required String cvc,
    String? currency,
  }) async {
    final response = await ApiClient.dio.post(
      '/student-plans/iyzico/3ds-init',
      data: {
        'plan_key': planKey,
        if (currency != null && currency.isNotEmpty) 'currency': currency,
        'card_holder_name': cardHolderName,
        'card_number': cardNumber,
        'expire_month': expireMonth,
        'expire_year': expireYear,
        'cvc': cvc,
      },
    );

    final data = ApiResponseParser.tryMap(response.data);
    return data == null ? null : Iyzico3dsInit.fromJson(data);
  }

  Future<PaymentStatus?> fetchOrderStatus(String invoiceId) async {
    if (invoiceId.isEmpty) return null;
    final response = await ApiClient.dio.get('/orders/$invoiceId');
    final data = ApiResponseParser.tryMap(response.data);
    return data == null ? null : PaymentStatus.fromJson(data);
  }
}

class PaymentInit {
  const PaymentInit({required this.invoiceId, required this.paymentUrl});

  final String invoiceId;
  final String paymentUrl;

  factory PaymentInit.fromJson(Map<String, dynamic> json) {
    return PaymentInit(
      invoiceId: (json['invoice_id'] ?? '').toString(),
      paymentUrl: (json['payment_url'] ?? '').toString(),
    );
  }
}

class PaymentStatus {
  const PaymentStatus({required this.paymentStatus, required this.status});

  final String paymentStatus;
  final String status;

  bool get isSuccess =>
      paymentStatus.toLowerCase() == 'paid' ||
      status.toLowerCase() == 'completed';

  bool get isFailed {
    final payment = paymentStatus.toLowerCase();
    final order = status.toLowerCase();
    return payment == 'cancelled' ||
        payment == 'canceled' ||
        payment == 'failed' ||
        order == 'cancelled' ||
        order == 'canceled' ||
        order == 'failed';
  }

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
      paymentStatus: (json['payment_status'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class Iyzico3dsInit {
  const Iyzico3dsInit({
    required this.invoiceId,
    required this.paymentId,
    required this.htmlContent,
  });

  final String invoiceId;
  final String paymentId;
  final String htmlContent;

  factory Iyzico3dsInit.fromJson(Map<String, dynamic> json) {
    return Iyzico3dsInit(
      invoiceId: (json['invoice_id'] ?? '').toString(),
      paymentId: (json['payment_id'] ?? '').toString(),
      htmlContent: (json['html_content'] ?? '').toString(),
    );
  }
}
