import 'package:flutter_tts/flutter_tts.dart';

/// Pratik bölümü için basit metin-okuma (TTS) yardımcısı.
/// Guidebook cümleleri ve dinleme alıştırmalarında kullanılır.
class PracticeTtsService {
  PracticeTtsService._();

  static final FlutterTts _tts = FlutterTts();
  static bool _ready = false;

  static Future<void> _ensureReady() async {
    if (_ready) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
    } on Object {
      // sessizce yut; cihazda TTS yoksa konuşma atlanır
    }
    _ready = true;
  }

  /// Verilen metni seslendirir. Hata olursa sessizce geçer.
  static Future<void> speak(String text, {String language = 'en-US'}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      await _ensureReady();
      await _tts.setLanguage(language);
      await _tts.stop();
      await _tts.speak(trimmed);
    } on Object {
      // TTS yoksa/başarısızsa görmezden gel
    }
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } on Object {
      // yoksay
    }
  }
}
