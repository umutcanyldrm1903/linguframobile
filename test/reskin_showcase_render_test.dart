import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingufranca_mobile/src/features/instructor/homeworks/instructor_homeworks_screen.dart';
import 'package:lingufranca_mobile/src/features/student/homeworks/student_homeworks_screen.dart';
import 'package:lingufranca_mobile/src/features/student/notifications/student_notifications_screen.dart';

import 'support/critical_flow_fakes.dart';

// Yeniden tasarlanan ekranları DOLU veriyle gerçek piksele döker (cihazsız).
Future<void> _shoot(WidgetTester tester, GlobalKey key, String name) async {
  for (var i = 0; i < 45; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final out = File('test_out/$name.png');
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
  expect(File('test_out/$name.png').existsSync(), isTrue);
}

void main() {
  testWidgets('Öğrenci ödevleri (yeni tasarım) render', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: wrapForTest(
          StudentHomeworksScreen(
            repository: FakeStudentHomeworksRepository(
              payload: buildStudentHomeworksPayload(),
            ),
          ),
        ),
      ),
    );
    await _shoot(tester, key, 'reskin_student_homeworks');
  });

  testWidgets('Öğrenci bildirimleri (yeni tasarım) render', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: wrapForTest(
          StudentNotificationsScreen(
            repository: FakeStudentNotificationsRepository(
              items: buildStudentNotifications(),
            ),
          ),
        ),
      ),
    );
    await _shoot(tester, key, 'reskin_student_notifications');
  });

  testWidgets('Eğitmen ödevleri (yeni tasarım) render', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: wrapForTest(
          InstructorHomeworksScreen(
            repository: FakeInstructorHomeworksRepository(
              payload: buildInstructorHomeworksPayload(),
            ),
            studentsRepository: FakeInstructorStudentsRepository(),
          ),
        ),
      ),
    );
    await _shoot(tester, key, 'reskin_instructor_homeworks');
  });
}
