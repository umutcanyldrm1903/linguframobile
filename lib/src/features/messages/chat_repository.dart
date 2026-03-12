import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';

class ChatRepository {
  Future<List<ChatThread>> fetchThreads() async {
    final response = await ApiClient.dio.get('/messages/threads');
    return ApiResponseParser.requireList(
      response.data,
      context: '/messages/threads',
    ).map(ChatThread.fromJson).toList(growable: false);
  }

  Future<List<ChatMessage>> fetchThreadMessages(int partnerId) async {
    final response = await ApiClient.dio.get('/messages/thread/$partnerId');
    return ApiResponseParser.requireList(
      response.data,
      context: '/messages/thread/$partnerId',
    ).map(ChatMessage.fromJson).toList(growable: false);
  }

  Future<ChatMessage> sendMessage(int partnerId, String body) async {
    final response = await ApiClient.dio.post(
      '/messages/thread/$partnerId',
      data: {
        'body': body,
      },
    );
    return ChatMessage.fromJson(
      ApiResponseParser.requireMap(
        response.data,
        context: '/messages/thread/$partnerId',
      ),
    );
  }
}

class ChatThread {
  const ChatThread({
    required this.partnerId,
    required this.partnerName,
    required this.partnerImage,
    required this.partnerRole,
    required this.lastMessage,
    required this.lastTimeLabel,
    required this.unreadCount,
  });

  final int partnerId;
  final String partnerName;
  final String partnerImage;
  final String partnerRole;
  final String lastMessage;
  final String lastTimeLabel;
  final int unreadCount;

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    final partner = json['partner'];
    final last = json['last_message'];
    final created = last is Map ? last['created_at']?.toString() ?? '' : '';
    return ChatThread(
      partnerId: partner is Map && partner['id'] is int ? partner['id'] as int : int.tryParse('${partner?['id']}') ?? 0,
      partnerName: partner is Map ? (partner['name'] ?? '').toString() : '',
      partnerImage: partner is Map ? (partner['image'] ?? '').toString() : '',
      partnerRole: partner is Map ? (partner['role'] ?? '').toString() : '',
      lastMessage: last is Map ? (last['body'] ?? '').toString() : '',
      lastTimeLabel: _formatTime(created),
      unreadCount: json['unread_count'] is int
          ? json['unread_count'] as int
          : int.tryParse('${json['unread_count'] ?? 0}') ?? 0,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.timeLabel,
    required this.createdAt,
  });

  final int id;
  final int senderId;
  final String body;
  final String timeLabel;
  final DateTime? createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final createdRaw = (json['created_at'] ?? '').toString();
    final createdAt = DateTime.tryParse(createdRaw);
    return ChatMessage(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      senderId: json['sender_id'] is int
          ? json['sender_id'] as int
          : int.tryParse('${json['sender_id']}') ?? 0,
      body: (json['body'] ?? '').toString(),
      timeLabel: _formatTime(createdRaw),
      createdAt: createdAt,
    );
  }
}

String _formatTime(String iso) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return '';
  return DateFormat('HH:mm').format(parsed.toLocal());
}
