import '../../../core/network/api_client.dart';

class StudentCartRepository {
  Future<CartPayload> fetchCart({String? currency}) async {
    final response = await ApiClient.dio.get(
      '/cart-list',
      queryParameters: {
        if (currency != null && currency.trim().isNotEmpty)
          'currency': currency,
      },
    );
    final payload = response.data as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>? ?? {};

    final coursesRaw = data['cart_courses'];
    final coursesList = _extractCourseList(coursesRaw);

    return CartPayload(
      totalQty: data['total_qty'] is int
          ? data['total_qty'] as int
          : int.tryParse('${data['total_qty'] ?? 0}') ?? 0,
      totalAmount: (data['total_amount'] ?? '').toString(),
      courses: coursesList
          .whereType<Map<String, dynamic>>()
          .map(CartCourseItem.fromJson)
          .toList(growable: false),
    );
  }

  Future<void> removeFromCart(String slug) async {
    if (slug.trim().isEmpty) return;
    await ApiClient.dio.delete('/remove-from-cart/$slug');
  }

  Future<List<CartPaymentGateway>> fetchPaymentGateways() async {
    final response = await ApiClient.dio.get('/payment-gateway-list');
    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      return const [];
    }

    final data = payload['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((item) => CartPaymentGateway.fromJson('', item))
          .where((item) => item.key.trim().isNotEmpty)
          .toList(growable: false);
    }

    if (data is Map) {
      final out = <CartPaymentGateway>[];
      data.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          out.add(CartPaymentGateway.fromJson(key.toString(), value));
        }
      });
      return out;
    }

    return const [];
  }

  Future<CartCheckoutInit?> startCheckout({
    required String gateway,
    String? currency,
  }) async {
    final response = await ApiClient.dio.get(
      '/payment-api/$gateway',
      queryParameters: {
        if (currency != null && currency.trim().isNotEmpty)
          'currency': currency,
      },
    );

    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      return null;
    }

    final rawUrl = (payload['url'] ?? '').toString().trim();
    if (rawUrl.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(rawUrl);
    final invoiceId = uri?.queryParameters['order_id']?.trim() ?? '';

    return CartCheckoutInit(invoiceId: invoiceId, paymentUrl: rawUrl);
  }

  List<dynamic> _extractCourseList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }
}

class CartPayload {
  const CartPayload({
    required this.totalQty,
    required this.totalAmount,
    required this.courses,
  });

  final int totalQty;
  final String totalAmount;
  final List<CartCourseItem> courses;
}

class CartCourseItem {
  const CartCourseItem({
    required this.slug,
    required this.title,
    required this.thumbnail,
    required this.priceLabel,
    required this.discountLabel,
    required this.instructorName,
    required this.rating,
  });

  final String slug;
  final String title;
  final String thumbnail;
  final String priceLabel;
  final String discountLabel;
  final String instructorName;
  final double rating;

  factory CartCourseItem.fromJson(Map<String, dynamic> json) {
    final instructor = json['instructor'];
    return CartCourseItem(
      slug: (json['slug'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      thumbnail: (json['thumbnail'] ?? '').toString(),
      priceLabel: (json['price'] ?? '').toString(),
      discountLabel: (json['discount'] ?? '').toString(),
      instructorName: instructor is Map
          ? (instructor['name'] ?? '').toString()
          : '',
      rating: json['average_rating'] is num
          ? (json['average_rating'] as num).toDouble()
          : double.tryParse('${json['average_rating'] ?? 0}') ?? 0,
    );
  }
}

class CartPaymentGateway {
  const CartPaymentGateway({
    required this.key,
    required this.name,
    required this.logo,
  });

  final String key;
  final String name;
  final String logo;

  factory CartPaymentGateway.fromJson(
    String fallbackKey,
    Map<String, dynamic> json,
  ) {
    final key = (json['key'] ?? fallbackKey).toString().trim();
    return CartPaymentGateway(
      key: key,
      name: (json['name'] ?? key).toString(),
      logo: (json['logo'] ?? '').toString(),
    );
  }
}

class CartCheckoutInit {
  const CartCheckoutInit({required this.invoiceId, required this.paymentUrl});

  final String invoiceId;
  final String paymentUrl;
}
