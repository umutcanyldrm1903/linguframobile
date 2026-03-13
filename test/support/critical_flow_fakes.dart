import 'package:flutter/material.dart';
import 'package:lingufranca_mobile/src/features/instructor/homeworks/instructor_homeworks_repository.dart';
import 'package:lingufranca_mobile/src/features/instructor/students/instructor_students_repository.dart';
import 'package:lingufranca_mobile/src/features/student/homeworks/student_homeworks_repository.dart';
import 'package:lingufranca_mobile/src/features/student/notifications/student_notifications_repository.dart';

Widget wrapForTest(Widget child) {
  return MaterialApp(home: child);
}

StudentHomeworksPayload buildStudentHomeworksPayload() {
  return StudentHomeworksPayload(
    active: [
      StudentHomeworkItem(
        id: 11,
        title: 'Essay Draft',
        description: 'Upload your final essay revision.',
        status: 'pending',
        dueAt: DateTime(2026, 3, 15, 18),
        attachmentName: 'essay.pdf',
        attachmentPath: 'https://example.com/essay.pdf',
        instructorName: 'Mete Taner',
        instructorImage: '',
        submission: HomeworkSubmission(
          status: 'submitted',
          submissionName: 'draft-v1.pdf',
          submissionPath: 'https://example.com/draft-v1.pdf',
          submittedAt: DateTime(2026, 3, 10, 9),
          note: 'Initial note',
          studentNote: 'Initial note',
          instructorNote: 'Add more examples',
          reviewedAt: DateTime(2026, 3, 11, 14),
        ),
      ),
    ],
    archived: const [],
  );
}

List<StudentNotificationItem> buildStudentNotifications() {
  return const [
    StudentNotificationItem(
      id: 'n1',
      title: 'New message',
      subtitle: 'Your instructor sent feedback.',
      time: '09:10',
      type: StudentNotificationType.message,
      unread: true,
    ),
    StudentNotificationItem(
      id: 'n2',
      title: 'Payment approved',
      subtitle: 'Your package is now active.',
      time: '10:30',
      type: StudentNotificationType.payment,
      unread: false,
    ),
  ];
}

InstructorHomeworksPayload buildInstructorHomeworksPayload() {
  return InstructorHomeworksPayload(
    active: [
      InstructorHomeworkItem(
        id: 31,
        title: 'Speaking Homework',
        description: 'Review the speaking recording.',
        status: 'submitted',
        statusLabel: 'Submitted',
        studentName: 'Ayse',
        dueAt: DateTime(2026, 3, 14, 12),
        attachmentName: 'task.pdf',
        attachmentPath: 'https://example.com/task.pdf',
        submission: InstructorHomeworkSubmission(
          status: 'submitted',
          submissionName: 'answer.pdf',
          submissionPath: 'https://example.com/answer.pdf',
          submittedAt: DateTime(2026, 3, 13, 10),
          studentNote: 'Please check pronunciation',
          instructorNote: '',
          reviewedAt: null,
        ),
      ),
    ],
    archived: const [],
  );
}

class FakeStudentHomeworksRepository extends StudentHomeworksRepository {
  FakeStudentHomeworksRepository({required this.payload});

  final StudentHomeworksPayload payload;
  final List<StudentSubmitCallRecord> submitCalls = [];

  @override
  Future<StudentHomeworksPayload?> fetchHomeworks() async => payload;

  @override
  Future<HomeworkSubmission?> submitHomework({
    required int homeworkId,
    String? filePath,
    String? fileName,
    String? note,
  }) async {
    submitCalls.add(
      StudentSubmitCallRecord(
        homeworkId: homeworkId,
        filePath: filePath,
        fileName: fileName,
        note: note,
      ),
    );
    return HomeworkSubmission(
      status: 'submitted',
      submissionName: fileName ?? 'updated.pdf',
      submissionPath: filePath ?? 'https://example.com/updated.pdf',
      submittedAt: DateTime(2026, 3, 13, 12),
      note: note ?? '',
      studentNote: note ?? '',
      instructorNote: '',
      reviewedAt: null,
    );
  }
}

class FakeStudentNotificationsRepository
    extends StudentNotificationsRepository {
  FakeStudentNotificationsRepository({required this.items});

  final List<StudentNotificationItem> items;
  int markAllAsReadCalls = 0;

  @override
  Future<List<StudentNotificationItem>> fetchNotifications() async => items;

  @override
  Future<void> markAllAsRead() async {
    markAllAsReadCalls += 1;
  }
}

class FakeInstructorHomeworksRepository extends InstructorHomeworksRepository {
  FakeInstructorHomeworksRepository({required this.payload});

  final InstructorHomeworksPayload payload;
  final List<InstructorReviewCallRecord> reviewCalls = [];

  @override
  Future<InstructorHomeworksPayload?> fetchHomeworks() async => payload;

  @override
  Future<void> reviewHomework({
    required int id,
    required String status,
    String? instructorNote,
  }) async {
    reviewCalls.add(
      InstructorReviewCallRecord(
        id: id,
        status: status,
        instructorNote: instructorNote,
      ),
    );
  }

  @override
  Future<void> createHomework({
    required int studentId,
    required String title,
    String? description,
    DateTime? dueAt,
  }) async {}

  @override
  Future<void> updateHomework({
    required int id,
    required String title,
    String? description,
    DateTime? dueAt,
    String? status,
  }) async {}

  @override
  Future<void> archiveHomework(int id) async {}
}

class FakeInstructorStudentsRepository extends InstructorStudentsRepository {
  @override
  Future<List<InstructorStudent>> fetchStudents() async => const [];
}

class StudentSubmitCallRecord {
  const StudentSubmitCallRecord({
    required this.homeworkId,
    required this.filePath,
    required this.fileName,
    required this.note,
  });

  final int homeworkId;
  final String? filePath;
  final String? fileName;
  final String? note;
}

class InstructorReviewCallRecord {
  const InstructorReviewCallRecord({
    required this.id,
    required this.status,
    required this.instructorNote,
  });

  final int id;
  final String status;
  final String? instructorNote;
}
