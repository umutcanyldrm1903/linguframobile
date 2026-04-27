import 'dart:convert';

import '../storage/secure_storage.dart';

class AppAnalyticsEvent {
  const AppAnalyticsEvent({
    required this.name,
    required this.timestampIso,
    required this.properties,
  });

  final String name;
  final String timestampIso;
  final Map<String, String> properties;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'timestamp_iso': timestampIso,
      'properties': properties,
    };
  }

  factory AppAnalyticsEvent.fromJson(Map<String, dynamic> json) {
    final properties = <String, String>{};
    final rawProperties = json['properties'];
    if (rawProperties is Map<String, dynamic>) {
      rawProperties.forEach((key, value) {
        properties[key] = value.toString();
      });
    }
    return AppAnalyticsEvent(
      name: (json['name'] ?? '').toString(),
      timestampIso: (json['timestamp_iso'] ?? '').toString(),
      properties: properties,
    );
  }
}

class AppEventLogger {
  AppEventLogger._();

  static final AppEventLogger instance = AppEventLogger._();
  static const _eventsKey = 'app_analytics_events_v1';
  static const _maxEvents = 400;

  Future<void> log(
    String name, {
    Map<String, String> properties = const <String, String>{},
  }) async {
    final events = await loadEvents();
    final next = [
      AppAnalyticsEvent(
        name: name,
        timestampIso: DateTime.now().toIso8601String(),
        properties: properties,
      ),
      ...events,
    ].take(_maxEvents).toList(growable: false);
    await _saveEvents(next);
  }

  Future<List<AppAnalyticsEvent>> loadEvents() async {
    final raw = await SecureStorage.getValue(_eventsKey);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(AppAnalyticsEvent.fromJson)
            .toList(growable: false);
      }
    } catch (_) {}
    return const [];
  }

  Future<void> clear() async {
    await SecureStorage.deleteValue(_eventsKey);
  }

  Future<void> _saveEvents(List<AppAnalyticsEvent> events) async {
    await SecureStorage.setValue(
      _eventsKey,
      jsonEncode(events.map((event) => event.toJson()).toList()),
    );
  }
}
