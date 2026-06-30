import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'practice_api_service.dart';

class PracticeOfflineService {
  const PracticeOfflineService({this.api = const PracticeApiService()});

  static const _packKey = 'practice.offline.pack.v1';
  static const _packSavedAtKey = 'practice.offline.pack.saved_at';
  static const _pendingKey = 'practice.offline.pending_results.v1';

  final PracticeApiService api;

  Future<bool> get isOnline async {
    final results = await Connectivity().checkConnectivity();
    return results.any((item) => item != ConnectivityResult.none);
  }

  Future<Map<String, dynamic>?> refreshPack() async {
    final pack = await api.getOfflinePack();
    if (pack == null) {
      return cachedPack();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_packKey, jsonEncode(pack));
    await prefs.setString(_packSavedAtKey, DateTime.now().toIso8601String());
    return pack;
  }

  Future<Map<String, dynamic>?> cachedPack() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_packKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  }

  Future<DateTime?> cachedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_packSavedAtKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> queueLessonResult({
    required String lessonId,
    required int correct,
    required int total,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = await pendingResults();
    pending.add({
      'type': 'lesson_result',
      'lesson_id': lessonId,
      'correct': correct,
      'total': total,
      'created_at': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_pendingKey, jsonEncode(pending));
  }

  Future<void> queueOfflineSession({
    required String packToken,
    required List<Map<String, dynamic>> answers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = await pendingResults();
    pending.removeWhere(
      (item) =>
          item['type'] == 'offline_session' && item['pack_token'] == packToken,
    );
    pending.add({
      'type': 'offline_session',
      'pack_token': packToken,
      'answers': answers,
      'created_at': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_pendingKey, jsonEncode(pending));
  }

  Future<List<Map<String, dynamic>>> pendingResults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: true);
  }

  Future<int> syncPendingResults() async {
    if (!await isOnline) return 0;
    final prefs = await SharedPreferences.getInstance();
    final pending = await pendingResults();
    var synced = 0;
    final remaining = <Map<String, dynamic>>[];

    for (final item in pending) {
      if (item['type'] == 'offline_session') {
        final rawAnswers = item['answers'];
        final answers = rawAnswers is List
            ? rawAnswers
                .whereType<Map>()
                .map((answer) => Map<String, dynamic>.from(answer))
                .toList(growable: false)
            : const <Map<String, dynamic>>[];
        final response = await api.syncOfflineSession({
          'pack_token': '${item['pack_token'] ?? ''}',
          'answers': answers,
        });
        if (response == null) {
          remaining.add(item);
        } else {
          synced++;
        }
        continue;
      }
      if (item['type'] != 'lesson_result') {
        remaining.add(item);
        continue;
      }
      final response = await api.completeLesson(
        '${item['lesson_id']}',
        correct: _asInt(item['correct']),
        total: _asInt(item['total'], fallback: 1),
      );
      if (response == null) {
        remaining.add(item);
      } else {
        synced++;
      }
    }

    await prefs.setString(_pendingKey, jsonEncode(remaining));
    return synced;
  }

  int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }
}
