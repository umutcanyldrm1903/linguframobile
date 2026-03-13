import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lingufranca_mobile/src/features/instructor/homeworks/instructor_homeworks_screen.dart';
import 'package:lingufranca_mobile/src/features/student/homeworks/student_homeworks_screen.dart';
import 'package:lingufranca_mobile/src/features/student/notifications/student_notifications_screen.dart';

import '../test/support/critical_flow_fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Critical device smoke flows', () {
    testWidgets('student can update homework submission note',
        (tester) async {
      final repository = FakeStudentHomeworksRepository(
        payload: buildStudentHomeworksPayload(),
      );

      await tester.pumpWidget(
        wrapForTest(StudentHomeworksScreen(repository: repository)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Essay Draft'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Update Submission'),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Device flow note');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repository.submitCalls.length, 1);
      expect(repository.submitCalls.single.note, 'Device flow note');
      expect(find.text('Submission updated.'), findsOneWidget);
    });

    testWidgets('student can mark all notifications as read',
        (tester) async {
      final repository = FakeStudentNotificationsRepository(
        items: buildStudentNotifications(),
      );

      await tester.pumpWidget(
        wrapForTest(StudentNotificationsScreen(repository: repository)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Mark all as read'));
      await tester.pumpAndSettle();

      expect(repository.markAllAsReadCalls, 1);
      expect(
        tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Mark all as read'),
        ).onPressed,
        isNull,
      );
    });

    testWidgets('instructor can save a homework review', (tester) async {
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

      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review Submission').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Reviewed on device');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repository.reviewCalls.length, 1);
      expect(repository.reviewCalls.single.instructorNote, 'Reviewed on device');
    });
  });
}
