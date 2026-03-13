import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingufranca_mobile/src/features/instructor/homeworks/instructor_homeworks_repository.dart';
import 'package:lingufranca_mobile/src/features/instructor/homeworks/instructor_homeworks_screen.dart';
import 'package:lingufranca_mobile/src/features/instructor/students/instructor_students_repository.dart';
import 'package:lingufranca_mobile/src/features/student/homeworks/student_homeworks_repository.dart';
import 'package:lingufranca_mobile/src/features/student/homeworks/student_homeworks_screen.dart';
import 'package:lingufranca_mobile/src/features/student/notifications/student_notifications_repository.dart';
import 'package:lingufranca_mobile/src/features/student/notifications/student_notifications_screen.dart';

void main() {
  Widget wrapForTest(Widget child) {
    return MaterialApp(home: child);
  }

  group('Student homework flow', () {
    testWidgets('updates an existing submission from the homework detail sheet',
        (tester) async {
      final repository = FakeStudentHomeworksRepository(
        payload: StudentHomeworksPayload(
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
        ),
      );

      await tester.pumpWidget(
        wrapForTest(StudentHomeworksScreen(repository: repository)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Essay Draft'), findsOneWidget);

      await tester.tap(find.text('Essay Draft'));
      await tester.pumpAndSettle();

      expect(find.text('Submission Details'), findsOneWidget);
      expect(find.text('Update Submission'), findsOneWidget);

      final updateButton =
          find.widgetWithText(ElevatedButton, 'Update Submission');
      await tester.ensureVisible(updateButton);
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Updated student note');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repository.submitCalls.length, 1);
      expect(repository.submitCalls.single.homeworkId, 11);
      expect(repository.submitCalls.single.note, 'Updated student note');
      expect(find.text('Submission updated.'), findsOneWidget);
    });
  });

  group('Student notifications flow', () {
    testWidgets('marks all notifications as read via repository',
        (tester) async {
      final repository = FakeStudentNotificationsRepository(
        items: const [
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
        ],
      );

      await tester.pumpWidget(
        wrapForTest(StudentNotificationsScreen(repository: repository)),
      );
      await tester.pumpAndSettle();

      final markAllFinder = find.widgetWithText(TextButton, 'Mark all as read');
      expect(markAllFinder, findsOneWidget);

      await tester.tap(markAllFinder);
      await tester.pumpAndSettle();

      expect(repository.markAllAsReadCalls, 1);
      final button = tester.widget<TextButton>(markAllFinder);
      expect(button.onPressed, isNull);
    });
  });

  group('Instructor homework flow', () {
    testWidgets('submits a review for student homework', (tester) async {
      final repository = FakeInstructorHomeworksRepository(
        payload: InstructorHomeworksPayload(
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
        ),
      );

      await tester.pumpWidget(
        wrapForTest(
          InstructorHomeworksScreen(
            repository: repository,
            studentsRepository: FakeInstructorStudentsRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Speaking Homework'), findsOneWidget);

      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review Submission').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Great progress.');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repository.reviewCalls.length, 1);
      expect(repository.reviewCalls.single.id, 31);
      expect(repository.reviewCalls.single.status, 'submitted');
      expect(repository.reviewCalls.single.instructorNote, 'Great progress.');
    });
  });
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
