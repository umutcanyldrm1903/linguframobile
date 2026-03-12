import '../../../core/network/api_client.dart';

class StudentOrdersRepository {
  Future<List<OrderListItem>> fetchOrders({int limit = 30}) async {
    final response = await ApiClient.dio.get(
      '/orders',
      queryParameters: {'limit': limit},
    );
    final list = _extractList(response.data);
    return list
        .whereType<Map<String, dynamic>>()
        .map(OrderListItem.fromJson)
        .toList(growable: false);
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is Map) {
      final inner = data['data'];
      if (inner is List) return inner;
      if (inner is Map && inner['data'] is List) return inner['data'] as List;
    }
    if (data is List) return data;
    return const [];
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

