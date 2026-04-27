import '../network/api_client.dart';
import 'app_event_logger.dart';

class AnalyticsSyncService {
  AnalyticsSyncService({AppEventLogger? logger})
      : _logger = logger ?? AppEventLogger.instance;

  final AppEventLogger _logger;

  Future<int> syncPendingEvents() async {
    final events = await _logger.loadEvents();
    if (events.isEmpty) return 0;

    final payload = {
      'source': 'mobile',
      'events': events.map((event) => event.toJson()).toList(growable: false),
    };
    try {
      await ApiClient.dio.post('/analytics/events', data: payload);
      await _logger.clear();
      return events.length;
    } catch (_) {
      return 0;
    }
  }
}
