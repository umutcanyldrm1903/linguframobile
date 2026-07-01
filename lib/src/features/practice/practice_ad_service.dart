import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/secure_storage.dart';
import 'practice_api_service.dart';

class PracticeAdService {
  PracticeAdService({this.api = const PracticeApiService()});

  static const _configuredInterstitialId = String.fromEnvironment(
    'PRACTICE_INTERSTITIAL_AD_UNIT_ID',
  );
  static const _configuredRewardedId = String.fromEnvironment(
    'PRACTICE_REWARDED_AD_UNIT_ID',
  );
  static const _ssvEnabled = bool.fromEnvironment(
    'PRACTICE_ADMOB_SSV_ENABLED',
    defaultValue: true,
  );
  static const _interstitialCounterKey =
      'practice_interstitial_break_counter_v1';

  static String get interstitialAdUnitId => _configuredInterstitialId.isNotEmpty
      ? _configuredInterstitialId
      : (kDebugMode ? _debugInterstitialAdUnitId : '');

  static String get rewardedAdUnitId => _configuredRewardedId.isNotEmpty
      ? _configuredRewardedId
      : (kDebugMode ? _debugRewardedAdUnitId : '');

  static String get _debugInterstitialAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    return 'ca-app-pub-3940256099942544/1033173712';
  }

  static String get _debugRewardedAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    return 'ca-app-pub-3940256099942544/5224354917';
  }

  static bool _initialized = false;

  final PracticeApiService api;

  bool get _adsSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (_initialized || !_adsSupported) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint('PracticeAdService initialize failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<bool> showInterstitial({required bool premium}) async {
    if (premium || !_adsSupported || interstitialAdUnitId.isEmpty) return false;
    await initialize();
    final ad = await _loadInterstitial();
    if (ad == null) return false;
    final shown = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!shown.isCompleted) shown.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!shown.isCompleted) shown.complete(false);
      },
    );
    ad.show();
    return shown.future;
  }

  Future<bool> showInterstitialAtNaturalBreak({
    required bool premium,
    int every = 4,
  }) async {
    if (premium || !_adsSupported || interstitialAdUnitId.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_interstitialCounterKey) ?? 0) + 1;
    await prefs.setInt(_interstitialCounterKey, count);
    if (every <= 1 || count % every == 0) {
      return showInterstitial(premium: premium);
    }
    return false;
  }

  Future<bool> showRewarded({
    required String rewardType,
    required bool premium,
    String placement = 'practice_rewarded',
  }) async {
    if (premium || !_adsSupported || rewardedAdUnitId.isEmpty) return false;
    await initialize();
    final ad = await _loadRewarded();
    if (ad == null) return false;
    final type = rewardType == 'coin' ? 'coins' : rewardType;
    final userId = await SecureStorage.getUserId();
    final useSsv = _ssvEnabled && userId != null && userId.isNotEmpty;
    if (_ssvEnabled && !useSsv) {
      ad.dispose();
      return false;
    }
    if (useSsv) {
      await ad.setServerSideOptions(
        ServerSideVerificationOptions(
          userId: userId,
          customData: jsonEncode({
            'placement': placement,
            'reward_type': type,
          }),
        ),
      );
    }

    final completed = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completed.isCompleted) completed.complete(false);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completed.isCompleted) completed.complete(false);
      },
    );
    ad.show(
      onUserEarnedReward: (ad, reward) async {
        if (useSsv) {
          if (!completed.isCompleted) completed.complete(true);
          return;
        }
        final res = await api.claimAdReward({
          'placement': placement,
          'reward_type': type,
          'reward_value': reward.amount.toInt().clamp(1, 100),
          'amount': reward.amount,
          'reward_name': reward.type,
          'ad_unit_id': rewardedAdUnitId,
        });
        if (!completed.isCompleted) completed.complete(res?['claimed'] == true);
      },
    );
    return completed.future;
  }

  Future<InterstitialAd?> _loadInterstitial() async {
    final completer = Completer<InterstitialAd?>();
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: completer.complete,
        onAdFailedToLoad: (_) => completer.complete(null),
      ),
    );
    return completer.future;
  }

  Future<RewardedAd?> _loadRewarded() async {
    final completer = Completer<RewardedAd?>();
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: completer.complete,
        onAdFailedToLoad: (_) => completer.complete(null),
      ),
    );
    return completer.future;
  }
}
