import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';

class StudentOrdersRepository {
  Future<List<OrderListItem>> fetchOrders({int limit = 30}) async {
    final response = await ApiClient.dio.get(
      '/orders',
      queryParameters: {'limit': limit},
    );
    final list = ApiResponseParser.tryList(response.data) ?? const [];
    return list.map(OrderListItem.fromJson).toList(growable: false);
  }
}

class OrderListItem {
  const OrderListItem({
    required this.invoiceId,
    required this.paymentMethod,
    required this.paidAmountLabel,
    required this.paymentStatus,
    required this.status,
  });

  final String invoiceId;
  final String paymentMethod;
  final String paidAmountLabel;
  final String paymentStatus;
  final String status;

  factory OrderListItem.fromJson(Map<String, dynamic> json) {
    return OrderListItem(
      invoiceId: (json['invoice_id'] ?? '').toString(),
      paymentMethod: (json['payment_method'] ?? '').toString(),
      paidAmountLabel: (json['paid_amount'] ?? '').toString(),
      paymentStatus: (json['payment_status'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}
