import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingufranca_mobile/src/features/instructor/homeworks/instructor_homeworks_screen.dart';
import 'package:lingufranca_mobile/src/features/student/homeworks/student_homeworks_screen.dart';
import 'package:lingufranca_mobile/src/features/student/notifications/student_notifications_screen.dart';

import 'support/critical_flow_fakes.dart';

void main() {
  group('Student homework flow', () {
    testWidgets('updates an existing submission from the homework detail sheet',
        (tester) async {
      final repository = FakeStudentHomeworksRepository(
        payload: buildStudentHomeworksPayload(),
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

      // Reskin: "Update Submission" / "Save" artık AppButton (ElevatedButton değil)
      final updateButton = find.text('Update Submission');
      await tester.ensureVisible(updateButton);
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Updated student note');
      await tester.tap(find.text('Save'));
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
        items: buildStudentNotifications(),
      );

      await tester.pumpWidget(
        wrapForTest(StudentNotificationsScreen(repository: repository)),
      );
      await tester.pumpAndSettle();

      // Reskin: "Mark all as read" artık AppGhostButton (içinde OutlinedButton)
      final markAllFinder =
          find.widgetWithText(OutlinedButton, 'Mark all as read');
      expect(markAllFinder, findsOneWidget);

      await tester.tap(markAllFinder);
      await tester.pumpAndSettle();

      expect(repository.markAllAsReadCalls, 1);
      final button = tester.widget<OutlinedButton>(markAllFinder);
      expect(button.onPressed, isNull);
    });
  });

  group('Instructor homework flow', () {
    testWidgets('submits a review for student homework', (tester) async {
      final repository = FakeInstructorHomeworksRepository(
        payload: buildInstructorHomeworksPayload(),
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
