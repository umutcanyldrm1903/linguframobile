import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../lessons/student_lessons_repository.dart';

class StudentNotificationsRepository {
  Future<List<StudentNotificationItem>> fetchNotifications() async {
    final response = await ApiClient.dio.get('/notifications');
    return ApiResponseParser.requireList(
      response.data,
      context: '/notifications',
    ).map(StudentNotificationItem.fromJson).toList(growable: false);
  }

  Future<void> markAllAsRead() async {
    await ApiClient.dio.post('/notifications/mark-all-read');
  }
}

enum StudentNotificationType { lesson, payment, message }

class StudentNotificationItem {
  const StudentNotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
    required this.unread,
    this.lesson,
    this.thread,
  });

  final String id;
  final String title;
  final String subtitle;
  final String time;
  final StudentNotificationType type;
  final bool unread;
  final LiveLessonItem? lesson;
  final NotificationThreadTarget? thread;

  factory StudentNotificationItem.fromJson(Map<String, dynamic> json) {
    final typeRaw = (json['type'] ?? '').toString().trim().toLowerCase();
    final type = switch (typeRaw) {
      'lesson' => StudentNotificationType.lesson,
      'payment' => StudentNotificationType.payment,
      'message' => StudentNotificationType.message,
      _ => StudentNotificationType.message,
    };

    final lesson = json['lesson'];
    final thread = json['thread'];

    return StudentNotificationItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      type: type,
      unread:
          json['unread'] == true ||
          (json['unread'] is String &&
              (json['unread'] as String).toLowerCase() == 'true'),
      lesson: lesson is Map<String, dynamic>
          ? LiveLessonItem.fromJson(lesson)
          : null,
      thread: thread is Map<String, dynamic>
          ? NotificationThreadTarget.fromJson(thread)
          : null,
    );
  }

  StudentNotificationItem copyWith({bool? unread}) {
    return StudentNotificationItem(
      id: id,
      title: title,
      subtitle: subtitle,
      time: time,
      type: type,
      unread: unread ?? this.unread,
      lesson: lesson,
      thread: thread,
    );
  }
}

class NotificationThreadTarget {
  const NotificationThreadTarget({
    required this.partnerId,
    required this.partnerName,
  });

  final int partnerId;
  final String partnerName;

  factory NotificationThreadTarget.fromJson(Map<String, dynamic> json) {
    return NotificationThreadTarget(
      partnerId: json['partner_id'] is int
          ? json['partner_id'] as int
          : int.tryParse((json['partner_id'] ?? '').toString()) ?? 0,
      partnerName: (json['partner_name'] ?? '').toString(),
    );
  }
}
