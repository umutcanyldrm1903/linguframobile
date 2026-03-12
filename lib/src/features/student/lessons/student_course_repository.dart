import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class StudentCourseRepository {
  Future<CourseLearning> fetchCourse(String slug) async {
    final response = await ApiClient.dio.get('/learning/$slug');
    final payload = response.data as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>;
    return CourseLearning.fromJson(data, slug);
  }

  Future<double> fetchProgress(String slug) async {
    final response = await ApiClient.dio.get('/learning/$slug/progress');
    final payload = response.data as Map<String, dynamic>;
    final raw = payload['data'];
    if (raw is num) {
      return (raw.toDouble() / 100).clamp(0, 1);
    }
    final parsed = double.tryParse(raw?.toString() ?? '');
    if (parsed == null) return 0;
    return (parsed / 100).clamp(0, 1);
  }

  Future<List<CourseReviewItem>> fetchReviews(String slug) async {
    try {
      final response = await ApiClient.dio.get('/course/reviews/$slug');
      final payload = response.data as Map<String, dynamic>;
      final list = payload['data'] as List<dynamic>? ?? [];
      return list
          .map((item) =>
              CourseReviewItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return [];
      }
      rethrow;
    }
  }

  Future<List<QnaQuestion>> fetchQuestions({
    required String slug,
    required int lessonId,
  }) async {
    try {
      final response =
          await ApiClient.dio.get('/questions/$slug/$lessonId');
      final payload = response.data as Map<String, dynamic>;
      final list = payload['data'] as List<dynamic>? ?? [];
      return list
          .map((item) => QnaQuestion.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return [];
      }
      rethrow;
    }
  }

  Future<void> createQuestion({
    required String slug,
    required int lessonId,
    required String question,
    required String description,
  }) async {
    final response = await ApiClient.dio.post(
      '/questions-create/$slug/$lessonId',
      data: {
        'question': question,
        'description': description,
      },
    );
    final payload = response.data as Map<String, dynamic>;
    if (payload['status'] != 'success') {
      throw Exception(payload['message']?.toString() ?? 'Bir hata oluştu');
    }
  }

  Future<LessonInfo> fetchLessonInfo({
    required String slug,
    required String type,
    required int lessonId,
  }) async {
    final response = await ApiClient.dio
        .get('/learning/$slug/get-file-info/$type/$lessonId');
    final payload = response.data as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>;
    return LessonInfo.fromJson(type, data);
  }

  Future<void> markLessonComplete(int lessonId) async {
    await ApiClient.dio.get('/learning/make-lesson-complete/$lessonId');
  }

  Future<QuizDetail> fetchQuiz({
    required String slug,
    required int quizId,
  }) async {
    final response = await ApiClient.dio.get('/learning/$slug/quiz/$quizId');
    final payload = response.data as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>;
    final quiz = data['quiz'] as Map<String, dynamic>;
    final attempt = data['attempt'] as int? ?? 0;
    return QuizDetail.fromJson(quiz, attempt);
  }

  Future<QuizResultDetail> submitQuiz({
    required String slug,
    required int quizId,
    required Map<int, int> answers,
  }) async {
    final payload = {
      'answers': answers.entries
          .map((entry) => {
                'question_id': entry.key,
                'answer_id': entry.value,
              })
          .toList(),
    };
    await ApiClient.dio.post('/learning/$slug/quiz/$quizId', data: payload);
    return fetchQuizResult(slug: slug, quizId: quizId);
  }

  Future<QuizResultDetail> fetchQuizResult({
    required String slug,
    required int quizId,
  }) async {
    final response =
        await ApiClient.dio.get('/learning/$slug/quiz-results/$quizId');
    final payload = response.data as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>;
    return QuizResultDetail.fromJson(data);
  }
}

class CourseLearning {
  CourseLearning({
    required this.slug,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.instructorName,
    required this.instructorImage,
    required this.chapters,
  });

  final String slug;
  final String title;
  final String description;
  final String? thumbnail;
  final String instructorName;
  final String? instructorImage;
  final List<CourseChapter> chapters;

  int? get firstLessonId {
    for (final chapter in chapters) {
      for (final item in chapter.items) {
        if (item.type != 'quiz' && item.id > 0) {
          return item.id;
        }
      }
    }
    return null;
  }

  factory CourseLearning.fromJson(Map<String, dynamic> json, String slug) {
    final instructor = json['instructor'] as Map<String, dynamic>? ?? {};
    final chaptersData = json['curriculums'] as List<dynamic>? ?? [];

    return CourseLearning(
      slug: slug,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      thumbnail: json['thumbnail']?.toString(),
      instructorName: (instructor['name'] ?? '').toString(),
      instructorImage: instructor['image']?.toString(),
      chapters: chaptersData
          .map((item) => CourseChapter.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CourseChapter {
  CourseChapter({required this.title, required this.items});

  final String title;
  final List<CourseItem> items;

  factory CourseChapter.fromJson(Map<String, dynamic> json) {
    final itemsData = json['chapters'] as List<dynamic>? ?? [];
    return CourseChapter(
      title: (json['title'] ?? '').toString(),
      items: itemsData
          .map((item) => CourseItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CourseItem {
  CourseItem({
    required this.id,
    required this.type,
    required this.title,
    required this.duration,
  });

  final int id;
  final String type;
  final String title;
  final String duration;

  factory CourseItem.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? '').toString();
    final item = json['item'] as Map<String, dynamic>? ?? {};
    final title = (item['title'] ?? '').toString();
    final duration = item['duration']?.toString() ?? '';
    final rawId = item['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    return CourseItem(
      id: id,
      type: type,
      title: title,
      duration: duration,
    );
  }
}

class CourseReviewItem {
  CourseReviewItem({
    required this.name,
    required this.rating,
    required this.review,
    required this.avatar,
  });

  final String name;
  final double rating;
  final String review;
  final String? avatar;

  factory CourseReviewItem.fromJson(Map<String, dynamic> json) {
    final rawRating = json['rating'];
    final rating = rawRating is num
        ? rawRating.toDouble()
        : double.tryParse(rawRating?.toString() ?? '') ?? 0;
    return CourseReviewItem(
      name: (json['name'] ?? '').toString(),
      rating: rating,
      review: (json['review'] ?? '').toString(),
      avatar: json['avatar']?.toString(),
    );
  }
}

class QnaQuestion {
  QnaQuestion({
    required this.id,
    required this.question,
    required this.description,
    required this.createdAt,
    required this.userName,
    required this.userAvatar,
    required this.replies,
  });

  final int id;
  final String question;
  final String description;
  final String createdAt;
  final String userName;
  final String? userAvatar;
  final List<QnaReply> replies;

  factory QnaQuestion.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final repliesData = json['replies'] as List<dynamic>? ?? [];
    return QnaQuestion(
      id: (json['id'] ?? 0) as int,
      question: (json['question'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      userName: (user['name'] ?? '').toString(),
      userAvatar: user['image']?.toString(),
      replies: repliesData
          .map((item) => QnaReply.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QnaReply {
  QnaReply({
    required this.id,
    required this.reply,
    required this.createdAt,
    required this.userName,
    required this.userAvatar,
  });

  final int id;
  final String reply;
  final String createdAt;
  final String userName;
  final String? userAvatar;

  factory QnaReply.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return QnaReply(
      id: (json['id'] ?? 0) as int,
      reply: (json['reply'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      userName: (user['name'] ?? '').toString(),
      userAvatar: user['image']?.toString(),
    );
  }
}

class LessonInfo {
  LessonInfo({
    required this.type,
    required this.title,
    required this.description,
    this.fileUrl,
    this.joinUrl,
    this.meetingId,
    this.password,
    this.isLiveNow,
  });

  final String type;
  final String title;
  final String description;
  final String? fileUrl;
  final String? joinUrl;
  final String? meetingId;
  final String? password;
  final String? isLiveNow;

  factory LessonInfo.fromJson(String type, Map<String, dynamic> json) {
    if (type == 'live') {
      return LessonInfo(
        type: type,
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        joinUrl: json['join_url']?.toString(),
        meetingId: json['meeting_id']?.toString(),
        password: json['password']?.toString(),
        isLiveNow: json['is_live_now']?.toString(),
      );
    }
    return LessonInfo(
      type: type,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      fileUrl: json['file_path']?.toString(),
    );
  }
}

class QuizDetail {
  QuizDetail({
    required this.id,
    required this.title,
    required this.time,
    required this.attempt,
    required this.passMark,
    required this.totalMark,
    required this.totalQuestions,
    required this.questions,
    required this.attemptUsed,
  });

  final int id;
  final String title;
  final int time;
  final int attempt;
  final int passMark;
  final int totalMark;
  final int totalQuestions;
  final int attemptUsed;
  final List<QuizQuestion> questions;

  factory QuizDetail.fromJson(Map<String, dynamic> json, int attemptUsed) {
    final questionsData = json['questions'] as List<dynamic>? ?? [];
    return QuizDetail(
      id: json['id'] as int? ?? 0,
      title: (json['title'] ?? '').toString(),
      time: json['time'] as int? ?? 0,
      attempt: json['attempt'] as int? ?? 0,
      passMark: json['pass_mark'] as int? ?? 0,
      totalMark: json['total_mark'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      attemptUsed: attemptUsed,
      questions: questionsData
          .map((item) => QuizQuestion.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuizQuestion {
  QuizQuestion({
    required this.id,
    required this.title,
    required this.type,
    required this.answers,
  });

  final int id;
  final String title;
  final String type;
  final List<QuizAnswer> answers;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final answersData = json['answers'] as List<dynamic>? ?? [];
    return QuizQuestion(
      id: json['id'] as int? ?? 0,
      title: (json['title'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      answers: answersData
          .map((item) => QuizAnswer.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuizAnswer {
  QuizAnswer({
    required this.id,
    required this.title,
  });

  final int id;
  final String title;

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      id: json['id'] as int? ?? 0,
      title: (json['title'] ?? '').toString(),
    );
  }
}

class QuizResultDetail {
  QuizResultDetail({
    required this.totalMarks,
    required this.passMarks,
    required this.yourMarks,
    required this.status,
    required this.results,
  });

  final int totalMarks;
  final int passMarks;
  final int yourMarks;
  final String status;
  final List<QuizAnswerResult> results;

  factory QuizResultDetail.fromJson(Map<String, dynamic> json) {
    final resultsData = json['results'] as List<dynamic>? ?? [];
    return QuizResultDetail(
      totalMarks: json['total_marks'] as int? ?? 0,
      passMarks: json['pass_marks'] as int? ?? 0,
      yourMarks: json['your_marks'] as int? ?? 0,
      status: (json['status'] ?? '').toString(),
      results: resultsData
          .map((item) => QuizAnswerResult.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuizAnswerResult {
  QuizAnswerResult({
    required this.question,
    required this.answer,
    required this.correct,
  });

  final String question;
  final String answer;
  final bool correct;

  factory QuizAnswerResult.fromJson(Map<String, dynamic> json) {
    return QuizAnswerResult(
      question: (json['question'] ?? '').toString(),
      answer: (json['answer'] ?? '').toString(),
      correct: json['correct'] as bool? ?? false,
    );
  }
}
