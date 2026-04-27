import 'package:flutter_test/flutter_test.dart';
import 'package:lingufranca_mobile/src/core/analytics/app_event_logger.dart';
import 'package:lingufranca_mobile/src/core/analytics/funnel_metrics_service.dart';
import 'package:lingufranca_mobile/src/core/growth/growth_policy_service.dart';

void main() {
  group('FunnelMetricsService', () {
    test('computes speaking funnel counters', () async {
      final now = DateTime.now();
      final service = FunnelMetricsService(
        eventLoader: () async => [
          AppAnalyticsEvent(
            name: 'speaking_opened',
            timestampIso: now.toIso8601String(),
            properties: const {},
          ),
          AppAnalyticsEvent(
            name: 'record_started',
            timestampIso: now.toIso8601String(),
            properties: const {},
          ),
          AppAnalyticsEvent(
            name: 'record_completed',
            timestampIso: now.toIso8601String(),
            properties: const {},
          ),
          AppAnalyticsEvent(
            name: 'trial_requested',
            timestampIso: now.toIso8601String(),
            properties: const {},
          ),
        ],
      );

      final snapshot = await service.speakingFunnel();
      expect(snapshot.opened, 1);
      expect(snapshot.startedRecord, 1);
      expect(snapshot.completedRecord, 1);
      expect(snapshot.trialRequested, 1);
    });
  });

  group('GrowthPolicyService', () {
    test('applies remote rollout and segment threshold', () {
      final service = GrowthPolicyService.instance;
      final decision = service.decisionForBucket(
        bucket: 10,
        weeklySessions: 2,
        isTurkish: true,
        remoteConfig: const {
          'engaged_weekly_sessions': 5,
          'trial_cta_rollout_b': 20,
        },
      );

      expect(decision.segmentId, 'warming_up');
      expect(decision.experimentId, 'trial_cta_v1_b');
      expect(decision.aggressiveNudge, isTrue);
    });
  });
}
