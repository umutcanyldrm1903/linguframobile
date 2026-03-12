import '../../../core/network/api_client.dart';

class SupportRepository {
  Future<List<SupportTicketItem>> fetchTickets() async {
    final response = await ApiClient.dio.get('/support-requests');
    final payload = response.data;

    final list = _extractList(payload);
    if (list.isEmpty) {
      return const [];
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map(SupportTicketItem.fromJson)
        .toList(growable: false);
  }

  Future<void> createRequest({
    required String subject,
    required String message,
    String? phone,
  }) async {
    await ApiClient.dio.post(
      '/support-requests',
      data: {
        'subject': subject,
        'message': message,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );
  }

  List<dynamic> _extractList(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      return data is List ? data : const [];
    }
    return payload is List ? payload : const [];
  }
}

class SupportTicketItem {
  const SupportTicketItem({
    required this.id,
    required this.category,
    required this.subject,
    required this.message,
    required this.createdAtRaw,
    required this.createdAt,
  });

  final int id;
  final String category;
  final String subject;
  final String message;
  final String createdAtRaw;
  final DateTime? createdAt;

  factory SupportTicketItem.fromJson(Map<String, dynamic> json) {
    final raw = (json['created_at'] ?? '').toString();
    return SupportTicketItem(
      id: json['id'] is int ? json['id'] as int : 0,
      category: (json['category'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAtRaw: raw,
      createdAt: DateTime.tryParse(raw),
    );
  }
}
