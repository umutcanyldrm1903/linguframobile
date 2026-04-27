import 'app_event_logger.dart';

class FunnelMetricsSnapshot {
  const FunnelMetricsSnapshot({
    required this.opened,
    required this.startedRecord,
    required this.completedRecord,
    required this.trialTapped,
    required this.trialRequested,
  });

  final int opened;
  final int startedRecord;
  final int completedRecord;
  final int trialTapped;
  final int trialRequested;

  double ratio(int numerator, int denominator) {
    if (denominator <= 0) return 0;
    return numerator / denominator;
  }

  Map<String, dynamic> toJson() {
    return {
      'opened': opened,
      'started_record': startedRecord,
      'completed_record': completedRecord,
      'trial_tapped': trialTapped,
      'trial_requested': trialRequested,
      'record_start_rate': ratio(startedRecord, opened),
      'record_completion_rate': ratio(completedRecord, startedRecord),
      'trial_tap_rate': ratio(trialTapped, completedRecord),
      'trial_request_rate': ratio(trialRequested, trialTapped),
    };
  }
}

class FunnelMetricsService {
  FunnelMetricsService({
    AppEventLogger? logger,
    Future<List<AppAnalyticsEvent>> Function()? eventLoader,
  })  : _logger = logger ?? AppEventLogger.instance,
        _eventLoader = eventLoader;

  final AppEventLogger _logger;
  final Future<List<AppAnalyticsEvent>> Function()? _eventLoader;

  Future<FunnelMetricsSnapshot> speakingFunnel({
    Duration window = const Duration(days: 7),
  }) async {
    final loader = _eventLoader;
    final allEvents = await (loader != null ? loader() : _logger.loadEvents());
    final since = DateTime.now().subtract(window);
    final scoped = allEvents.where((event) {
      final time = DateTime.tryParse(event.timestampIso);
      return time != null && time.isAfter(since);
    });

    var opened = 0;
    var startedRecord = 0;
    var completedRecord = 0;
    var trialTapped = 0;
    var trialRequested = 0;

    for (final event in scoped) {
      switch (event.name) {
        case 'speaking_opened':
          opened += 1;
          break;
        case 'record_started':
          startedRecord += 1;
          break;
        case 'record_completed':
          completedRecord += 1;
          break;
        case 'trial_cta_tapped':
          trialTapped += 1;
          break;
        case 'trial_requested':
          trialRequested += 1;
          break;
      }
    }

    return FunnelMetricsSnapshot(
      opened: opened,
      startedRecord: startedRecord,
      completedRecord: completedRecord,
      trialTapped: trialTapped,
      trialRequested: trialRequested,
    );
  }
}
