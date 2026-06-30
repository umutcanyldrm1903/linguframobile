import 'dart:math';

import 'package:flutter/material.dart';

import 'practice_api_service.dart';

@immutable
class PracticeStats {
  const PracticeStats({
    required this.level,
    required this.xp,
    required this.nextLevelXp,
    required this.streak,
    required this.hearts,
    required this.coins,
    required this.league,
    required this.rank,
    required this.weeklyXp,
    required this.xpMultiplier,
  });

  final int level;
  final int xp;
  final int nextLevelXp;
  final int streak;
  final int hearts;
  final int coins;
  final String league;
  final int rank;
  final int weeklyXp;
  final double xpMultiplier;

  double get levelProgress => xp / nextLevelXp;
}

@immutable
class PracticeLesson {
  const PracticeLesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.xp,
    required this.minutes,
    required this.icon,
    required this.locked,
    this.mode = 'normal',
    this.status = 'unlocked',
  });

  final String id;
  final String title;
  final String subtitle;
  final int xp;
  final int minutes;
  final String icon;
  final bool locked;
  final String mode;
  final String status;

  PracticeLesson copyWith({
    String? mode,
    String? status,
    bool? locked,
    int? xp,
  }) {
    return PracticeLesson(
      id: id,
      title: title,
      subtitle: subtitle,
      xp: xp ?? this.xp,
      minutes: minutes,
      icon: icon,
      locked: locked ?? this.locked,
      mode: mode ?? this.mode,
      status: status ?? this.status,
    );
  }
}

/// Bir ünite: başlık, bölüm (kısım) ve dersleri. Path ekranı bunu çoklu
/// ünite olarak gösterir.
@immutable
class PracticeUnit {
  const PracticeUnit({
    required this.title,
    required this.section,
    required this.subtitle,
    required this.lessons,
  });

  final String title;
  final String section;
  final String subtitle;
  final List<PracticeLesson> lessons;
}

@immutable
class PracticeQuestionOption {
  const PracticeQuestionOption({
    required this.label,
    required this.value,
    this.imageUrl,
  });

  const PracticeQuestionOption.text(String text)
      : label = text,
        value = text,
        imageUrl = null;

  final String label;
  final String value;
  final String? imageUrl;

  factory PracticeQuestionOption.fromJson(Map<String, dynamic> map) {
    final image = '${map['image_url'] ?? ''}'.trim();
    return PracticeQuestionOption(
      label: '${map['label'] ?? map['value'] ?? ''}',
      value: '${map['value'] ?? map['label'] ?? ''}',
      imageUrl: image.isEmpty ? null : image,
    );
  }
}

@immutable
class PracticeQuestion {
  const PracticeQuestion({
    required this.id,
    required this.type,
    required this.prompt,
    required this.questionText,
    required this.answer,
    required this.options,
    required this.hint,
    required this.explanation,
    required this.meta,
  });

  final int id;
  final String type;
  final String prompt;
  final String questionText;

  /// Doğru cevap. Backend güvenlik gereği canlı sorularda bunu GÖNDERMEZ
  /// (boş gelir); sadece offline mock fallback'inde doludur. Canlı akışta
  /// doğruluk server `answerQuestion` yanıtından alınır.
  final String answer;
  final List<PracticeQuestionOption> options;
  final String hint;
  final String explanation;
  final Map<String, dynamic> meta;

  List<String> get optionValues =>
      options.map((option) => option.value).toList(growable: false);

  String? get audioUrl {
    final value = meta['audio_url'];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  String? get audioText {
    final value = meta['audio_text'] ?? meta['tts_text'];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return type.startsWith('listening') && prompt.trim().isNotEmpty
        ? prompt.trim()
        : null;
  }

  String? get imageUrl {
    final value = meta['image_url'];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  /// order_sentence / word_bank için kullanılacak kelime havuzu.
  List<String> get wordBank {
    final raw = meta['word_bank'] ?? meta['words'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((item) => '$item').toList(growable: false);
    }
    if (options.isNotEmpty) return optionValues;
    return answer
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
  }

  /// Ders sırasında kelimeye dokununca gösterilecek çeviri sözlüğü
  /// (kelime → anlam). Backend `meta['glossary']` döndürürse dolar.
  Map<String, String> get glossary {
    final raw = meta['glossary'] ?? meta['word_hints'];
    if (raw is Map) {
      return raw.map((k, v) => MapEntry('$k'.toLowerCase(), '$v'));
    }
    return const {};
  }

  /// match_pairs için [sol, sağ] çiftleri.
  List<List<String>> get pairs {
    final raw = meta['pairs'];
    final out = <List<String>>[];
    if (raw is List) {
      for (final pair in raw) {
        if (pair is Map) {
          final left = '${pair['left'] ?? pair['a'] ?? pair['term'] ?? ''}';
          final right =
              '${pair['right'] ?? pair['b'] ?? pair['meaning'] ?? ''}';
          if (left.isNotEmpty && right.isNotEmpty) out.add([left, right]);
        } else if (pair is List && pair.length >= 2) {
          out.add(['${pair[0]}', '${pair[1]}']);
        }
      }
    }
    return out;
  }

  factory PracticeQuestion.fromJson(Map<String, dynamic> map) {
    final rawOptions = map['options'];
    final options = <PracticeQuestionOption>[];
    if (rawOptions is List) {
      for (final option in rawOptions) {
        if (option is Map) {
          options.add(
            PracticeQuestionOption.fromJson(Map<String, dynamic>.from(option)),
          );
        } else {
          options.add(PracticeQuestionOption.text('$option'));
        }
      }
    }
    final rawMeta = map['meta'];
    final meta = rawMeta is Map
        ? Map<String, dynamic>.from(rawMeta)
        : <String, dynamic>{};
    int parseId(Object? value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    return PracticeQuestion(
      id: parseId(map['id']),
      type: '${map['type'] ?? 'multiple_choice'}',
      prompt: '${map['prompt'] ?? ''}',
      questionText: '${map['question_text'] ?? ''}',
      answer:
          '${map['correct_answer'] ?? map['offline_answer'] ?? map['correct_value'] ?? meta['answer'] ?? ''}',
      options: options,
      hint: '${meta['hint'] ?? ''}',
      explanation: '${map['explanation'] ?? ''}',
      meta: meta,
    );
  }
}

@immutable
class PracticeLeaderboardItem {
  const PracticeLeaderboardItem({
    required this.name,
    required this.rank,
    required this.xp,
    required this.zone,
  });

  final String name;
  final int rank;
  final int xp;
  final String zone;
}

@immutable
class PracticeSocialFeedItem {
  const PracticeSocialFeedItem({
    required this.name,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String name;
  final String message;
  final IconData icon;
  final Color color;
}

class PracticeRepository {
  const PracticeRepository({this.api = const PracticeApiService()});

  final PracticeApiService api;

  /// Veri gelmeden önce / API boşken gösterilen DÜRÜST varsayılan: yeni
  /// kullanıcı durumu (sıfırlar). Sahte ilerleme YOK. Gerçek değerler API'den
  /// gelince üzerine yazılır.
  PracticeStats loadStats() {
    return const PracticeStats(
      level: 1,
      xp: 0,
      nextLevelXp: 100,
      streak: 0,
      hearts: 5,
      coins: 0,
      league: '',
      rank: 0,
      weeklyXp: 0,
      xpMultiplier: 1,
    );
  }

  /// API henüz cevap vermediğinde ekranın kırılmaması için yerel demo yolundan
  /// ders üretir. Gerçek API verisi geldiğinde bu liste kullanılmaz.
  List<PracticeLesson> loadLessons() =>
      _fallbackUnits().expand((unit) => unit.lessons).toList(growable: false);

  /// Giriş gerektirmeyen "misafir tadımlık" için yerel örnek sorular
  /// (çoktan seçmeli / doğru-yanlış / boşluk / sıralama). Ağ/oturum gerekmez.
  List<PracticeQuestion> loadTasterQuestions() => _fallbackQuestions('taster');

  Future<PracticeStats> fetchStats() async {
    final data = await api.getHome();
    final stats = data?['stats'];
    if (stats is Map) {
      return _statsFromMap(Map<String, dynamic>.from(stats));
    }
    return loadStats();
  }

  Future<List<PracticeLesson>> fetchLessons() async {
    final data = await api.getPath();
    final courses = data?['courses'];
    final parsed = <PracticeLesson>[];
    if (courses is List) {
      for (final course in courses.whereType<Map>()) {
        final units = course['units'];
        if (units is! List) continue;
        for (final unit in units.whereType<Map>()) {
          final lessons = unit['lessons'];
          if (lessons is! List) continue;
          for (final lesson in lessons.whereType<Map>()) {
            final map = Map<String, dynamic>.from(lesson);
            parsed.add(_lessonFromMap(map));
          }
        }
      }
    }
    return parsed;
  }

  /// Path'i ünite yapısını koruyarak çeker (`GET /practice/path`).
  /// Boşsa yerleşik örnek ünitelere düşer.
  Future<List<PracticeUnit>> fetchUnits() async {
    final data = await api.getPath();
    final courses = data?['courses'];
    final units = <PracticeUnit>[];
    if (courses is List) {
      for (final course in courses.whereType<Map>()) {
        final courseTitle = '${course['title'] ?? ''}';
        final rawUnits = course['units'];
        if (rawUnits is! List) continue;
        var index = 1;
        for (final unit in rawUnits.whereType<Map>()) {
          final unitMap = Map<String, dynamic>.from(unit);
          final rawLessons = unitMap['lessons'];
          final lessons = <PracticeLesson>[];
          if (rawLessons is List) {
            for (final lesson in rawLessons.whereType<Map>()) {
              lessons.add(_lessonFromMap(Map<String, dynamic>.from(lesson)));
            }
          }
          if (lessons.isEmpty) continue;
          units.add(
            PracticeUnit(
              title: '${unitMap['title'] ?? '$index. Ünite'}',
              section: courseTitle.isNotEmpty
                  ? courseTitle
                  : '${unitMap['section'] ?? ''}',
              subtitle:
                  '${unitMap['description'] ?? unitMap['subtitle'] ?? ''}',
              lessons: lessons,
            ),
          );
          index++;
        }
      }
    }
    return units;
  }

  /// Veri gelene kadar gösterilecek yerleşik üniteler.
  List<PracticeUnit> loadUnits() => _fallbackUnits();

  List<PracticeUnit> _fallbackUnits() => const <PracticeUnit>[
        PracticeUnit(
          title: '1. Ünite',
          section: '1. Kısım: Çaylak',
          subtitle: 'Kısa pratiklerle ilerle',
          lessons: [
            PracticeLesson(
              id: 'demo-listening',
              title: 'Temel kelimeler',
              subtitle: 'Dinle ve doğru anlamı seç.',
              xp: 10,
              minutes: 3,
              icon: 'listening',
              locked: false,
            ),
            PracticeLesson(
              id: 'demo-sentence',
              title: 'Cümle kur',
              subtitle: 'Kelimeleri doğru sıraya diz.',
              xp: 12,
              minutes: 4,
              icon: 'order_sentence',
              locked: false,
            ),
            PracticeLesson(
              id: 'demo-review',
              title: 'Mini tekrar',
              subtitle: 'Yanlışlarını hızlıca toparla.',
              xp: 8,
              minutes: 3,
              icon: 'review',
              locked: true,
            ),
            PracticeLesson(
              id: 'demo-checkpoint',
              title: 'Ünite testi',
              subtitle: 'Çaylak bölümünü tamamla.',
              xp: 20,
              minutes: 6,
              icon: 'checkpoint',
              locked: false,
            ),
          ],
        ),
        PracticeUnit(
          title: '2. Ünite',
          section: '2. Kısım: Gezgin',
          subtitle: 'Seyahat ve günlük konuşma',
          lessons: [
            PracticeLesson(
              id: 'demo-travel',
              title: 'Seyahat cümleleri',
              subtitle: 'Yol tarifi ve bilet ifadeleri.',
              xp: 12,
              minutes: 4,
              icon: 'normal_lesson',
              locked: true,
            ),
            PracticeLesson(
              id: 'demo-cafe',
              title: 'Kafede sipariş',
              subtitle: 'Kısa diyaloglarla pratik yap.',
              xp: 15,
              minutes: 5,
              icon: 'dialogue_select',
              locked: true,
            ),
          ],
        ),
      ];

  Future<List<PracticeLeaderboardItem>> fetchLeaderboard() async {
    final data = await api.getLeaderboard();
    final items = data?['items'];
    if (items is List) {
      final parsed = items.whereType<Map>().map((item) {
        final map = Map<String, dynamic>.from(item);
        return PracticeLeaderboardItem(
          name: '${map['name'] ?? 'Student'}',
          rank: _int(map['rank'], fallback: 1),
          xp: _int(map['weekly_xp'] ?? map['xp']),
          zone: '${map['zone'] ?? 'safe'}',
        );
      }).toList(growable: false);
      if (parsed.isNotEmpty) return parsed;
    }
    return loadLeaderboard();
  }

  /// Dersin sorularını backend'den çeker (`GET /practice/lessons/{id}`).
  /// Veri yoksa / offline ise yerleşik örnek sorulara düşer.
  Future<List<PracticeQuestion>> loadLessonQuestions(
    PracticeLesson lesson,
  ) async {
    final data = lesson.mode == 'legendary'
        ? await api.getLegendaryLesson(lesson.id)
        : await api.getLesson(lesson.id);
    final lessonMap = data?['lesson'];
    if (lessonMap is Map) {
      final questions = lessonMap['questions'];
      if (questions is List) {
        final parsed = questions
            .whereType<Map>()
            .map(
              (question) => PracticeQuestion.fromJson(
                  Map<String, dynamic>.from(question)),
            )
            .where(
              (question) =>
                  question.prompt.isNotEmpty ||
                  question.questionText.isNotEmpty,
            )
            .toList(growable: false);
        if (parsed.isNotEmpty) return parsed;
      }
    }
    if (lesson.id.startsWith('demo-') || lesson.id == 'taster') {
      return _fallbackQuestions(lesson.id);
    }
    return const <PracticeQuestion>[];
  }

  List<PracticeQuestion> _fallbackQuestions(String lessonId) {
    final base = <PracticeQuestion>[
      const PracticeQuestion(
        id: 9001,
        type: 'multiple_choice',
        prompt: '“Water” kelimesinin Türkçesi hangisi?',
        questionText: '',
        answer: 'Su',
        options: [
          PracticeQuestionOption.text('Su'),
          PracticeQuestionOption.text('Ekmek'),
          PracticeQuestionOption.text('Kahve'),
          PracticeQuestionOption.text('Kalem'),
        ],
        hint: 'Günlük hayatta en çok kullanılan temel kelimelerden biri.',
        explanation: 'Water Türkçede “su” demektir.',
        meta: {},
      ),
      const PracticeQuestion(
        id: 9002,
        type: 'true_false',
        prompt: '“Good morning” Türkçede “Günaydın” demektir.',
        questionText: '',
        answer: 'Doğru',
        options: [
          PracticeQuestionOption.text('Doğru'),
          PracticeQuestionOption.text('Yanlış'),
        ],
        hint: '',
        explanation: 'Good morning sabah selamlaşmasıdır.',
        meta: {},
      ),
      const PracticeQuestion(
        id: 9003,
        type: 'fill_blank',
        prompt: 'Boşluğu doldur: I ___ a student.',
        questionText: '',
        answer: 'am',
        options: [],
        hint: 'I öznesiyle “am” kullanılır.',
        explanation: 'Doğru cümle: I am a student.',
        meta: {},
      ),
      const PracticeQuestion(
        id: 9004,
        type: 'order_sentence',
        prompt: 'Kelimeleri doğru sıraya diz.',
        questionText: 'Ben İngilizce öğreniyorum.',
        answer: 'I am learning English',
        options: [],
        hint: '',
        explanation: 'Doğru sıralama: I am learning English.',
        meta: {
          'word_bank': ['English', 'I', 'learning', 'am'],
        },
      ),
    ];

    if (lessonId.contains('sentence')) {
      return [
        base[3],
        base[0],
        base[1],
        base[2],
      ];
    }
    return base;
  }

  List<PracticeQuestion> _fallbackTatoebaQuestions() {
    const items = <PracticeQuestion>[
      PracticeQuestion(
        id: 9201,
        type: 'multiple_choice',
        prompt: 'I need a ticket to Istanbul.',
        questionText: 'Bu cümlenin Türkçesi hangisi?',
        answer: 'İstanbul için bir bilete ihtiyacım var.',
        options: [
          PracticeQuestionOption.text(
              'İstanbul için bir bilete ihtiyacım var.'),
          PracticeQuestionOption.text('Bugün hava çok güzel.'),
          PracticeQuestionOption.text('Kahve içmek istiyorum.'),
          PracticeQuestionOption.text('Saat kaç?'),
        ],
        hint: '',
        explanation: '',
        meta: {'audio_text': 'I need a ticket to Istanbul.', 'fallback': true},
      ),
      PracticeQuestion(
        id: 9202,
        type: 'multiple_choice',
        prompt: 'Can you speak more slowly?',
        questionText: 'Bu cümlenin Türkçesi hangisi?',
        answer: 'Daha yavaş konuşabilir misiniz?',
        options: [
          PracticeQuestionOption.text('Daha yavaş konuşabilir misiniz?'),
          PracticeQuestionOption.text('Kapıyı kapatabilir misiniz?'),
          PracticeQuestionOption.text('Nerede yaşıyorsunuz?'),
          PracticeQuestionOption.text('Bir bardak su alabilir miyim?'),
        ],
        hint: '',
        explanation: '',
        meta: {'audio_text': 'Can you speak more slowly?', 'fallback': true},
      ),
      PracticeQuestion(
        id: 9203,
        type: 'listening_choice',
        prompt: 'Where is the nearest pharmacy?',
        questionText: 'Dinlediğin cümlenin Türkçesi hangisi?',
        answer: 'En yakın eczane nerede?',
        options: [
          PracticeQuestionOption.text('En yakın eczane nerede?'),
          PracticeQuestionOption.text('Hastane çok kalabalık.'),
          PracticeQuestionOption.text('Bu ilaç pahalı mı?'),
          PracticeQuestionOption.text('Randevum saat üçte.'),
        ],
        hint: '',
        explanation: '',
        meta: {
          'audio_text': 'Where is the nearest pharmacy?',
          'fallback': true
        },
      ),
      PracticeQuestion(
        id: 9204,
        type: 'multiple_choice',
        prompt: 'I am learning English every day.',
        questionText: 'Bu cümlenin Türkçesi hangisi?',
        answer: 'Her gün İngilizce öğreniyorum.',
        options: [
          PracticeQuestionOption.text('Her gün İngilizce öğreniyorum.'),
          PracticeQuestionOption.text('İngilizce kitabı nerede?'),
          PracticeQuestionOption.text('Bugün ders yok.'),
          PracticeQuestionOption.text('Seni yarın arayacağım.'),
        ],
        hint: '',
        explanation: '',
        meta: {
          'audio_text': 'I am learning English every day.',
          'fallback': true
        },
      ),
      PracticeQuestion(
        id: 9205,
        type: 'multiple_choice',
        prompt: 'How much does this cost?',
        questionText: 'Bu cümlenin Türkçesi hangisi?',
        answer: 'Bu ne kadar?',
        options: [
          PracticeQuestionOption.text('Bu ne kadar?'),
          PracticeQuestionOption.text('Bu kim?'),
          PracticeQuestionOption.text('Nereye gidiyorsun?'),
          PracticeQuestionOption.text('Yardıma ihtiyacım var.'),
        ],
        hint: '',
        explanation: '',
        meta: {'audio_text': 'How much does this cost?', 'fallback': true},
      ),
      PracticeQuestion(
        id: 9206,
        type: 'listening_choice',
        prompt: 'I would like to make a reservation.',
        questionText: 'Dinlediğin cümlenin Türkçesi hangisi?',
        answer: 'Rezervasyon yapmak istiyorum.',
        options: [
          PracticeQuestionOption.text('Rezervasyon yapmak istiyorum.'),
          PracticeQuestionOption.text('Hesabı alabilir miyim?'),
          PracticeQuestionOption.text('Bir masa boş mu?'),
          PracticeQuestionOption.text('Menüyü görebilir miyim?'),
        ],
        hint: '',
        explanation: '',
        meta: {
          'audio_text': 'I would like to make a reservation.',
          'fallback': true,
        },
      ),
      PracticeQuestion(
        id: 9207,
        type: 'multiple_choice',
        prompt: 'I forgot my password.',
        questionText: 'Bu cümlenin Türkçesi hangisi?',
        answer: 'Şifremi unuttum.',
        options: [
          PracticeQuestionOption.text('Şifremi unuttum.'),
          PracticeQuestionOption.text('Telefonum kapalı.'),
          PracticeQuestionOption.text('Yeni bir hesap açtım.'),
          PracticeQuestionOption.text('E-postam gelmedi.'),
        ],
        hint: '',
        explanation: '',
        meta: {'audio_text': 'I forgot my password.', 'fallback': true},
      ),
      PracticeQuestion(
        id: 9208,
        type: 'multiple_choice',
        prompt: 'Could you help me, please?',
        questionText: 'Bu cümlenin Türkçesi hangisi?',
        answer: 'Bana yardım edebilir misiniz, lütfen?',
        options: [
          PracticeQuestionOption.text('Bana yardım edebilir misiniz, lütfen?'),
          PracticeQuestionOption.text('Burada bekleyebilir miyim?'),
          PracticeQuestionOption.text('Lütfen tekrar eder misiniz?'),
          PracticeQuestionOption.text('Ders ne zaman başlıyor?'),
        ],
        hint: '',
        explanation: '',
        meta: {'audio_text': 'Could you help me, please?', 'fallback': true},
      ),
      PracticeQuestion(
        id: 9209,
        type: 'multiple_choice',
        prompt: 'The train leaves at six.',
        questionText: 'Bu cümlenin Türkçesi hangisi?',
        answer: 'Tren saat altıda kalkıyor.',
        options: [
          PracticeQuestionOption.text('Tren saat altıda kalkıyor.'),
          PracticeQuestionOption.text('Otobüs çok geç kaldı.'),
          PracticeQuestionOption.text('Uçak yarın geliyor.'),
          PracticeQuestionOption.text('Biletimi kaybettim.'),
        ],
        hint: '',
        explanation: '',
        meta: {'audio_text': 'The train leaves at six.', 'fallback': true},
      ),
      PracticeQuestion(
        id: 9210,
        type: 'listening_choice',
        prompt: 'I need to call my teacher.',
        questionText: 'Dinlediğin cümlenin Türkçesi hangisi?',
        answer: 'Öğretmenimi aramam gerekiyor.',
        options: [
          PracticeQuestionOption.text('Öğretmenimi aramam gerekiyor.'),
          PracticeQuestionOption.text('Dersim erken bitti.'),
          PracticeQuestionOption.text('Kitabımı evde unuttum.'),
          PracticeQuestionOption.text('Sınav çok kolaydı.'),
        ],
        hint: '',
        explanation: '',
        meta: {'audio_text': 'I need to call my teacher.', 'fallback': true},
      ),
      PracticeQuestion(
        id: 9211,
        type: 'multiple_choice',
        prompt: 'I am looking for a hotel.',
        questionText: 'Bu cümlenin Türkçesi hangisi?',
        answer: 'Bir otel arıyorum.',
        options: [
          PracticeQuestionOption.text('Bir otel arıyorum.'),
          PracticeQuestionOption.text('Otobüs durağı nerede?'),
          PracticeQuestionOption.text('Odam çok sıcak.'),
          PracticeQuestionOption.text('Anahtarımı aldım.'),
        ],
        hint: '',
        explanation: '',
        meta: {'audio_text': 'I am looking for a hotel.', 'fallback': true},
      ),
      PracticeQuestion(
        id: 9212,
        type: 'multiple_choice',
        prompt: 'Please write your name here.',
        questionText: 'Bu cümlenin Türkçesi hangisi?',
        answer: 'Lütfen adınızı buraya yazın.',
        options: [
          PracticeQuestionOption.text('Lütfen adınızı buraya yazın.'),
          PracticeQuestionOption.text('Lütfen burada bekleyin.'),
          PracticeQuestionOption.text('Lütfen kapıyı açın.'),
          PracticeQuestionOption.text('Lütfen tekrar deneyin.'),
        ],
        hint: '',
        explanation: '',
        meta: {'audio_text': 'Please write your name here.', 'fallback': true},
      ),
    ];
    final shuffled = items.toList()..shuffle(Random());
    return shuffled.take(10).toList(growable: false);
  }

  /// Mod pratiği sorularını backend'den çeker (`GET /practice/modes/{mode}`).
  /// `mode`: vocabulary | grammar | listening | dialogue. Boşsa örnek sorulara düşer.
  Future<List<PracticeQuestion>> loadModeQuestions(String mode) async {
    final data = await api.getModePractice(mode);
    final modeMap = data?['mode'];
    final raw = modeMap is Map ? modeMap['questions'] : data?['questions'];
    final parsed = _questionsFromRaw(raw);
    if (parsed.isNotEmpty) {
      return parsed;
    }
    return mode == 'tatoeba'
        ? _fallbackTatoebaQuestions()
        : _fallbackQuestions('daily');
  }

  /// Adaptif oturum sorularını çeker (`GET /practice/adaptive/session`).
  Future<List<PracticeQuestion>> loadAdaptiveQuestions({int limit = 12}) async {
    final data = await api.getAdaptiveSession(limit: limit);
    final parsed = _questionsFromRaw(data?['questions']);
    return parsed.isEmpty ? _fallbackQuestions('daily') : parsed;
  }

  List<PracticeQuestion> _questionsFromRaw(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((q) {
          final map = Map<String, dynamic>.from(q);
          // lesson_id'yi meta'ya taşı ki oturum oynatıcı canlı cevap doğrulamasında
          // (`answerQuestion`) kullanabilsin.
          final meta = map['meta'] is Map
              ? Map<String, dynamic>.from(map['meta'] as Map)
              : <String, dynamic>{};
          if (map['lesson_id'] != null) {
            meta['lesson_id'] ??= map['lesson_id'];
          }
          map['meta'] = meta;
          return PracticeQuestion.fromJson(map);
        })
        .where((q) => q.prompt.isNotEmpty || q.questionText.isNotEmpty)
        .toList(
          growable: false,
        );
  }

  List<PracticeQuestion> parseQuestions(Object? raw) => _questionsFromRaw(raw);

  Future<List<PracticeLesson>> fetchLegendaryLessons() async {
    final data = await api.getLegendaryLessons();
    final raw = data?['lessons'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => _lessonFromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  /// Backend `stats` haritasını [PracticeStats]'a çevirir (hearts/streak ekranları
  /// canlı stats için kullanır). Harita yoksa yerel mock'a düşer.
  PracticeStats parseStats(Object? statsMap) {
    if (statsMap is Map) {
      return _statsFromMap(Map<String, dynamic>.from(statsMap));
    }
    return loadStats();
  }

  Future<bool> startLesson(PracticeLesson lesson) async {
    final data = await api.startLesson(lesson.id);
    return data?['started'] == true;
  }

  Future<Map<String, dynamic>?> completeLesson(
    PracticeLesson lesson, {
    required int correct,
    required int total,
  }) {
    if (lesson.mode == 'legendary') {
      return api.completeLegendaryLesson(
        lesson.id,
        correct: correct,
        total: total,
      );
    }
    return api.completeLesson(lesson.id, correct: correct, total: total);
  }

  Future<Map<String, dynamic>?> answerQuestion(
    String questionId, {
    required String lessonId,
    required Object? answer,
  }) {
    return api.answerQuestion(questionId, lessonId: lessonId, answer: answer);
  }

  /// Gerçek sıralama API'den gelir; veri yoksa SAHTE kişi gösterme — boş döndür.
  List<PracticeLeaderboardItem> loadLeaderboard() => const [];

  /// Gerçek arkadaş akışı API'den gelir; veri yoksa SAHTE göstermeden boş döndür.
  List<PracticeSocialFeedItem> loadSocialFeed() => const [];

  Future<List<PracticeSocialFeedItem>> fetchSocialFeed() async {
    final data = await api.getFriends();
    final friends = data?['friends'];
    if (friends is List) {
      final parsed = friends.whereType<Map>().map((item) {
        final map = Map<String, dynamic>.from(item);
        return PracticeSocialFeedItem(
          name: '${map['name'] ?? 'Arkadaş'}',
          message:
              '${_int(map['weekly_xp'])} XP kazandı, ${_int(map['streak_days'])} günlük seri.',
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFF9F1C),
        );
      }).toList(growable: false);
      if (parsed.isNotEmpty) return parsed;
    }
    return loadSocialFeed();
  }

  Future<bool> checkStreakRepairEligible() async {
    final stats = await fetchStats();
    return stats.coins >= 200;
  }

  Future<Map<String, dynamic>> repairStreak() async {
    // Sunucu yanıt vermezse SAHTE başarı dönme — onarım sunucuda yapılır;
    // aksi halde konfeti gösterilir ama seri/coin gerçekte değişmez.
    final remote = await api.repairStreak();
    return remote ?? {'success': false};
  }

  PracticeStats _statsFromMap(Map<String, dynamic> map) {
    final totalXp =
        _int(map['total_xp'] ?? map['xp'], fallback: loadStats().xp);
    final nextLevel = max(100, ((totalXp ~/ 100) + 1) * 100);
    final boost = map['xp_boost'];
    final rawMultiplier =
        boost is Map ? boost['multiplier'] : map['xp_multiplier'];
    final xpMultiplier = rawMultiplier is num
        ? rawMultiplier.toDouble()
        : double.tryParse('$rawMultiplier') ?? 1;
    return PracticeStats(
      level: max(1, (totalXp ~/ 100) + 1),
      xp: totalXp,
      nextLevelXp: nextLevel,
      streak: _int(map['streak_days'] ?? map['streak']),
      hearts: _int(map['hearts'], fallback: 5),
      coins: _int(map['coins'], fallback: 0),
      league: '${map['league'] ?? 'Bronz'}',
      rank: _int(map['rank'], fallback: 1),
      weeklyXp: _int(map['weekly_xp']),
      xpMultiplier: max(1, xpMultiplier),
    );
  }

  PracticeLesson _lessonFromMap(Map<String, dynamic> map) {
    final status = '${map['status'] ?? 'unlocked'}';
    return PracticeLesson(
      id: '${map['id'] ?? 'lesson'}',
      title: '${map['title'] ?? 'Pratik dersi'}',
      subtitle: '${map['description'] ?? map['type'] ?? 'Kısa pratik'}',
      xp: _int(map['xp_reward'] ?? map['xp'], fallback: 10),
      minutes: _int(map['minutes'], fallback: 5),
      icon: '${map['type'] ?? 'lesson'}',
      locked: status == 'locked',
      mode: '${map['mode'] ?? 'normal'}',
      status: status,
    );
  }

  int _int(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }
}
