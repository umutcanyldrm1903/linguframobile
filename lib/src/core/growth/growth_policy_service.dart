import '../storage/secure_storage.dart';

class GrowthPolicyDecision {
  const GrowthPolicyDecision({
    required this.segmentId,
    required this.experimentId,
    required this.trialCtaLabel,
    required this.paywallMessage,
    required this.aggressiveNudge,
  });

  final String segmentId;
  final String experimentId;
  final String trialCtaLabel;
  final String paywallMessage;
  final bool aggressiveNudge;
}

class GrowthPolicyService {
  GrowthPolicyService._();

  static final GrowthPolicyService instance = GrowthPolicyService._();
  static const _experimentBucketKey = 'growth_experiment_bucket_v1';

  Future<GrowthPolicyDecision> speakingCoachDecision({
    required int weeklySessions,
    required bool isTurkish,
    Map<String, dynamic> remoteConfig = const <String, dynamic>{},
  }) async {
    final bucket = await _bucket();
    return decisionForBucket(
      bucket: bucket,
      weeklySessions: weeklySessions,
      isTurkish: isTurkish,
      remoteConfig: remoteConfig,
    );
  }

  GrowthPolicyDecision decisionForBucket({
    required int bucket,
    required int weeklySessions,
    required bool isTurkish,
    Map<String, dynamic> remoteConfig = const <String, dynamic>{},
  }) {
    final threshold = _intFrom(remoteConfig['engaged_weekly_sessions'], 4);
    final rollout = _intFrom(remoteConfig['trial_cta_rollout_b'], 50).clamp(0, 100);
    final segmentId = weeklySessions >= threshold ? 'engaged' : 'warming_up';
    final experimentId = bucket < rollout ? 'trial_cta_v1_b' : 'trial_cta_v1_a';
    final aggressiveNudge = segmentId == 'warming_up' && experimentId == 'trial_cta_v1_b';
    final trialLabel = isTurkish
        ? (experimentId == 'trial_cta_v1_a' ? 'Deneme al' : 'Hemen deneme kilitle')
        : (experimentId == 'trial_cta_v1_a' ? 'Free trial' : 'Lock trial now');
    final paywallMessage = isTurkish
        ? (segmentId == 'engaged'
            ? 'Ilerlemeyi korumak icin canli ders adimina gec.'
            : 'Akisi kaybetmeden deneme dersini simdi al.')
        : (segmentId == 'engaged'
            ? 'Move to the live lesson step to protect momentum.'
            : 'Grab your trial now before the flow drops.');
    return GrowthPolicyDecision(
      segmentId: segmentId,
      experimentId: experimentId,
      trialCtaLabel: trialLabel,
      paywallMessage: paywallMessage,
      aggressiveNudge: aggressiveNudge,
    );
  }

  Future<int> _bucket() async {
    final raw = await SecureStorage.getValue(_experimentBucketKey);
    final existing = int.tryParse((raw ?? '').toString());
    if (existing != null && existing >= 0 && existing <= 99) return existing;
    final userId = await SecureStorage.getUserId();
    final base = (userId ?? DateTime.now().millisecondsSinceEpoch.toString()).hashCode;
    final bucket = base.abs() % 100;
    await SecureStorage.setValue(_experimentBucketKey, '$bucket');
    return bucket;
  }

  int _intFrom(dynamic raw, int fallback) {
    if (raw is int) return raw;
    return int.tryParse('${raw ?? ''}') ?? fallback;
  }
}
