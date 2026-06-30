import 'package:flutter_test/flutter_test.dart';
import 'package:lingufranca_mobile/src/features/practice/practice_api_service.dart';
import 'package:lingufranca_mobile/src/features/practice/practice_repository.dart';

class _UnavailablePracticeApi extends PracticeApiService {
  const _UnavailablePracticeApi();

  @override
  Future<Map<String, dynamic>?> getPath() async => null;

  @override
  Future<Map<String, dynamic>?> getLesson(String lessonId) async => null;
}

void main() {
  const repository = PracticeRepository(api: _UnavailablePracticeApi());

  test('authenticated path does not fall back to demo lessons', () async {
    expect(await repository.fetchUnits(), isEmpty);
    expect(await repository.fetchLessons(), isEmpty);
  });

  test('real lesson does not fall back to local demo questions', () async {
    const lesson = PracticeLesson(
      id: '42',
      title: 'Canlı ders',
      subtitle: '',
      xp: 10,
      minutes: 3,
      icon: 'normal_lesson',
      locked: false,
    );

    expect(await repository.loadLessonQuestions(lesson), isEmpty);
  });

  test('explicit demo lesson can still serve the guest taster', () async {
    const lesson = PracticeLesson(
      id: 'demo-listening',
      title: 'Tadımlık ders',
      subtitle: '',
      xp: 0,
      minutes: 2,
      icon: 'listening',
      locked: false,
    );

    expect(await repository.loadLessonQuestions(lesson), isNotEmpty);
  });
}
