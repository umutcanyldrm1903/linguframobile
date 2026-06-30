import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';

class PracticeApiService {
  const PracticeApiService();

  static const Duration _requestTimeout = Duration(seconds: 5);

  Future<Map<String, dynamic>?> getHome() => _getMap('/practice/home');

  Future<Map<String, dynamic>?> getHub() => _getMap('/practice/hub');

  Future<Map<String, dynamic>?> getAdaptiveSession({int limit = 12}) =>
      _getMap('/practice/adaptive/session?limit=$limit');

  Future<Map<String, dynamic>?> getOfflinePack() =>
      _getMap('/practice/offline-pack');

  Future<Map<String, dynamic>?> syncOfflineSession(
    Map<String, dynamic> data,
  ) =>
      _postMap('/practice/offline/sync', data: data);

  Future<Map<String, dynamic>?> getAnalyticsDashboard() =>
      _getMap('/practice/analytics/dashboard');

  Future<Map<String, dynamic>?> getAssistantInsight({
    required String route,
    required String locale,
  }) =>
      _getMap(
        '/practice/assistant/insight'
        '?route=${Uri.encodeQueryComponent(route)}'
        '&locale=${Uri.encodeQueryComponent(locale)}',
        timeout: const Duration(seconds: 18),
      );

  Future<Map<String, dynamic>?> recordAssistantEvent({
    required String name,
    required String route,
    Map<String, dynamic> properties = const <String, dynamic>{},
  }) =>
      _postMap('/practice/assistant/events', data: {
        'name': name,
        'route': route,
        'properties': properties,
      });

  Future<Map<String, dynamic>?> sendAssistantMessage({
    required String message,
    required String route,
    required String locale,
  }) =>
      _postMap('/practice/assistant/chat',
          data: {
            'message': message,
            'route': route,
            'locale': locale,
          },
          timeout: const Duration(seconds: 18));

  Future<Map<String, dynamic>?> getAssistantPreferences() =>
      _getMap('/practice/assistant/preferences');

  Future<Map<String, dynamic>?> updateAssistantPreferences(
    Map<String, dynamic> data,
  ) =>
      _postMap('/practice/assistant/preferences', data: data);

  Future<Map<String, dynamic>?> getPath() => _getMap('/practice/path');

  Future<Map<String, dynamic>?> getProfile() => _getMap('/practice/profile');

  Future<Map<String, dynamic>?> getStats() => _getMap('/practice/stats');

  Future<Map<String, dynamic>?> getStreak() => _getMap('/practice/streak');

  Future<Map<String, dynamic>?> getSettings() => _getMap('/practice/settings');

  Future<Map<String, dynamic>?> updateSettings(Map<String, dynamic> data) =>
      _postMap('/practice/settings', data: data);

  Future<Map<String, dynamic>?> getModePractice(String mode) => _getMap(
        mode == 'tatoeba'
            ? '/practice/modes/$mode?fresh=${DateTime.now().millisecondsSinceEpoch}'
            : '/practice/modes/$mode',
        timeout:
            mode == 'tatoeba' ? const Duration(seconds: 20) : _requestTimeout,
      );

  Future<Map<String, dynamic>?> completeModePractice(
    String mode,
    Map<String, dynamic> data,
  ) =>
      _postMap('/practice/modes/$mode/complete', data: data);

  Future<Map<String, dynamic>?> getPlacementStatus() =>
      _getMap('/practice/placement/status');

  Future<Map<String, dynamic>?> completePlacement(Map<String, dynamic> data) =>
      _postMap('/practice/placement/complete', data: data);

  Future<Map<String, dynamic>?> getLesson(String lessonId) =>
      _getMap('/practice/lessons/$lessonId');

  Future<Map<String, dynamic>?> getLegendaryLessons() =>
      _getMap('/practice/legendary');

  Future<Map<String, dynamic>?> getLegendaryLesson(String lessonId) =>
      _getMap('/practice/lessons/$lessonId/legendary');

  Future<Map<String, dynamic>?> completeLegendaryLesson(
    String lessonId, {
    required int correct,
    required int total,
  }) =>
      _postMap(
        '/practice/lessons/$lessonId/legendary/complete',
        data: {
          'correct_count': correct,
          'total_count': total,
        },
      );

  Future<Map<String, dynamic>?> getMatchMadness() =>
      _getMap('/practice/match-madness');

  Future<Map<String, dynamic>?> completeMatchMadness(
    String sessionToken,
    List<int> matchedPairIds,
  ) =>
      _postMap(
        '/practice/match-madness/complete',
        data: {
          'session_token': sessionToken,
          'matched_pair_ids': matchedPairIds,
        },
      );

  Future<Map<String, dynamic>?> getLeaderboard() =>
      _getMap('/practice/leaderboard');

  Future<Map<String, dynamic>?> getFriendLeaderboard() =>
      _getMap('/practice/leaderboard/friends');

  Future<Map<String, dynamic>?> getFriends() => _getMap('/practice/friends');

  Future<Map<String, dynamic>?> getFriendInvite() =>
      _getMap('/practice/friends/invite');

  Future<Map<String, dynamic>?> getFriendQuests() =>
      _getMap('/practice/friend-quests');

  Future<Map<String, dynamic>?> searchFriends(String query) =>
      _getMap('/practice/friends/search?q=${Uri.encodeQueryComponent(query)}');

  Future<Map<String, dynamic>?> requestFriend(int userId) =>
      _postMap('/practice/friends/request', data: {'user_id': userId});

  Future<Map<String, dynamic>?> acceptFriend(int id) =>
      _postMap('/practice/friends/$id/accept');

  Future<Map<String, dynamic>?> removeFriend(int id) =>
      _deleteMap('/practice/friends/$id');

  Future<Map<String, dynamic>?> claimFriendQuest(String key) =>
      _postMap('/practice/friend-quests/$key/claim');

  Future<Map<String, dynamic>?> getDailyQuests() =>
      _getMap('/practice/daily-quests');

  Future<Map<String, dynamic>?> claimDailyQuest(int id) =>
      _postMap('/practice/daily-quests/$id/claim');

  Future<Map<String, dynamic>?> getWeeklyQuests() =>
      _getMap('/practice/weekly-quests');

  Future<Map<String, dynamic>?> claimWeeklyQuest(int id) =>
      _postMap('/practice/weekly-quests/$id/claim');

  Future<Map<String, dynamic>?> getHearts() => _getMap('/practice/hearts');

  Future<Map<String, dynamic>?> refillHearts() =>
      _postMap('/practice/hearts/refill');

  Future<Map<String, dynamic>?> getEnergy() => _getMap('/practice/energy');

  Future<Map<String, dynamic>?> refillEnergy() =>
      _postMap('/practice/energy/refill');

  Future<Map<String, dynamic>?> getActivity({int days = 30}) =>
      _getMap('/practice/activity?days=$days');

  Future<Map<String, dynamic>?> getXpLogs() => _getMap('/practice/xp/logs');

  Future<Map<String, dynamic>?> getCoinLogs() =>
      _getMap('/practice/coins/logs');

  Future<Map<String, dynamic>?> getMistakes() => _getMap('/practice/mistakes');

  Future<Map<String, dynamic>?> resolveMistake(int id) =>
      _postMap('/practice/mistakes/$id/resolve');

  Future<Map<String, dynamic>?> getWeakWords() =>
      _getMap('/practice/words/weak');

  Future<Map<String, dynamic>?> reviewWord(int id, {required bool correct}) =>
      _postMap('/practice/words/$id/review', data: {'correct': correct});

  Future<Map<String, dynamic>?> getShop() => _getMap('/practice/shop');

  Future<Map<String, dynamic>?> buyShopItem(int itemId) =>
      _postMap('/practice/shop/buy', data: {'item_id': itemId});

  Future<Map<String, dynamic>?> getInventory() =>
      _getMap('/practice/inventory');

  Future<Map<String, dynamic>?> useInventoryItem(int inventoryId) =>
      _postMap('/practice/inventory/use', data: {'inventory_id': inventoryId});

  Future<Map<String, dynamic>?> getAchievements() =>
      _getMap('/practice/achievements');

  Future<Map<String, dynamic>?> getGuidebook() =>
      _getMap('/practice/guidebook');

  Future<Map<String, dynamic>?> getBadges() => _getMap('/practice/badges');

  Future<Map<String, dynamic>?> getTreasureChest() =>
      _getMap('/practice/treasure-chest');

  Future<Map<String, dynamic>?> openTreasureChest() =>
      _postMap('/practice/treasure-chest/open');

  Future<Map<String, dynamic>?> getMonthlyChallenge() =>
      _getMap('/practice/monthly-challenge');

  Future<Map<String, dynamic>?> claimMonthlyChallenge() =>
      _postMap('/practice/monthly-challenge/claim');

  Future<Map<String, dynamic>?> getFriendStreak() =>
      _getMap('/practice/friend-streak');

  // ── Pratik oyunlaştırma mekanikleri ────────────────────────────────────

  Future<Map<String, dynamic>?> getDailyChests() =>
      _getMap('/practice/daily-chests');

  Future<Map<String, dynamic>?> openDailyChest(String type) =>
      _postMap('/practice/daily-chests/open', data: {'type': type});

  Future<Map<String, dynamic>?> getStreakWager() =>
      _getMap('/practice/streak-wager');

  Future<Map<String, dynamic>?> startStreakWager() =>
      _postMap('/practice/streak-wager/start');

  Future<Map<String, dynamic>?> claimStreakWager() =>
      _postMap('/practice/streak-wager/claim');

  Future<Map<String, dynamic>?> getStreakMilestones() =>
      _getMap('/practice/streak-milestones');

  Future<Map<String, dynamic>?> claimStreakMilestone(int days) =>
      _postMap('/practice/streak-milestones/claim', data: {'days': days});

  Future<Map<String, dynamic>?> nudgeFriend(int friendId, {String? message}) =>
      _postMap('/practice/friends/nudge', data: {
        'friend_id': friendId,
        if (message != null) 'message': message,
      });

  Future<Map<String, dynamic>?> claimAchievement(int id) =>
      _postMap('/practice/achievements/$id/claim');

  Future<Map<String, dynamic>?> getStories() => _getMap('/practice/stories');

  Future<Map<String, dynamic>?> getStory(int id) =>
      _getMap('/practice/stories/$id');

  Future<Map<String, dynamic>?> completeStory(
    int id, {
    List<Map<String, dynamic>>? answers,
  }) =>
      _postMap(
        '/practice/stories/$id/complete',
        data: {'answers': answers ?? const <Map<String, dynamic>>[]},
      );

  Future<Map<String, dynamic>?> getRadio() => _getMap('/practice/radio');

  Future<Map<String, dynamic>?> getRadioLesson(int id) =>
      _getMap('/practice/radio/$id');

  Future<Map<String, dynamic>?> completeRadio(
    int id, {
    List<Map<String, dynamic>>? answers,
  }) =>
      _postMap(
        '/practice/radio/$id/complete',
        data: {'answers': answers ?? const <Map<String, dynamic>>[]},
      );

  Future<Map<String, dynamic>?> getAdventures() =>
      _getMap('/practice/adventures');

  Future<Map<String, dynamic>?> getAdventure(int id) =>
      _getMap('/practice/adventures/$id');

  Future<Map<String, dynamic>?> completeAdventure(
    int id, {
    List<int>? choiceIds,
  }) =>
      _postMap(
        '/practice/adventures/$id/complete',
        data: {'choice_ids': choiceIds ?? const <int>[]},
      );

  Future<Map<String, dynamic>?> getChallenges() =>
      _getMap('/practice/challenges');

  Future<Map<String, dynamic>?> getChallenge(int id) =>
      _getMap('/practice/challenges/$id');

  Future<Map<String, dynamic>?> completeChallenge(int id) =>
      _postMap('/practice/challenges/$id/complete');

  Future<Map<String, dynamic>?> explainWithAi(Map<String, dynamic> data) =>
      _postMapWithApiError('/practice/ai/explain', data: data);

  Future<Map<String, dynamic>?> startRoleplay(Map<String, dynamic> data) =>
      _postMapWithApiError('/practice/ai/roleplay/start', data: data);

  Future<Map<String, dynamic>?> sendRoleplayMessage(
          Map<String, dynamic> data) =>
      _postMapWithApiError('/practice/ai/roleplay/message', data: data);

  Future<Map<String, dynamic>?> endRoleplay(Map<String, dynamic> data) =>
      _postMap('/practice/ai/roleplay/end', data: data);

  Future<Map<String, dynamic>?> getSpeakingHistory() =>
      _getMap('/practice/speaking/history');

  Future<Map<String, dynamic>?> getSpeakingPrompts({int limit = 10}) =>
      _getMap('/practice/speaking/prompts?limit=$limit');

  Future<Map<String, dynamic>?> submitSpeakingAttempt(
    Map<String, dynamic> data,
  ) =>
      _postMap('/practice/speaking/attempt', data: data);

  Future<Map<String, dynamic>?> submitSpeakingAudioAttempt({
    required String targetText,
    required String filePath,
  }) async {
    try {
      final response = await ApiClient.dio
          .post(
            '/practice/speaking/audio-attempt',
            data: FormData.fromMap({
              'target_text': targetText,
              'audio': await MultipartFile.fromFile(
                filePath,
                filename: 'practice.wav',
              ),
            }),
          )
          .timeout(const Duration(seconds: 45));
      return ApiResponseParser.tryMap(response.data);
    } on DioException {
      return null;
    } on Object {
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyzePronunciation(
    Map<String, dynamic> data,
  ) =>
      _postMap('/practice/speaking/pronunciation', data: data);

  Future<Map<String, dynamic>?> startVideoCall(Map<String, dynamic> data) =>
      _postMapWithApiError('/practice/ai/video-call/start', data: data);

  Future<Map<String, dynamic>?> sendVideoCallMessage(
    Map<String, dynamic> data,
  ) =>
      _postMapWithApiError('/practice/ai/video-call/message', data: data);

  Future<Map<String, dynamic>?> endVideoCall(Map<String, dynamic> data) =>
      _postMap('/practice/ai/video-call/end', data: data);

  Future<Map<String, dynamic>?> getNotifications() =>
      _getMap('/practice/notifications');

  Future<Map<String, dynamic>?> readNotifications(List<int> ids) =>
      _postMap('/practice/notifications/read', data: {'ids': ids});

  Future<Map<String, dynamic>?> readAllNotifications() =>
      _postMap('/practice/notifications/read-all');

  Future<Map<String, dynamic>?> readNotification(int id) =>
      _postMap('/practice/notifications/$id/read');

  Future<Map<String, dynamic>?> getNotificationSettings() =>
      _getMap('/practice/notification-settings');

  Future<Map<String, dynamic>?> updateNotificationSettings(
    Map<String, dynamic> data,
  ) =>
      _postMap('/practice/notification-settings/update', data: data);

  Future<Map<String, dynamic>?> getPremiumStatus() =>
      _getMap('/practice/premium/status');

  Future<Map<String, dynamic>?> verifyPremiumPurchase(
    Map<String, dynamic> data,
  ) =>
      _postMap('/practice/premium/verify-purchase', data: data);

  Future<Map<String, dynamic>?> claimAdReward(Map<String, dynamic> data) =>
      _postMap('/practice/ad-rewards/claim', data: data);

  /// Günlük Şans Çarkı ödülünü backend'e kaydeder.
  Future<Map<String, dynamic>?> claimDailySpin() =>
      _postMap('/practice/spin', data: const <String, dynamic>{});

  Future<Map<String, dynamic>?> redeemPromoCode(String code) =>
      _postMap('/practice/promo/redeem', data: {'code': code});

  Future<Map<String, dynamic>?> verifyGemPurchase(Map<String, dynamic> data) =>
      _postMap('/practice/gems/verify-purchase', data: data);

  /// Bildirim içeriği şablonu (TR/EN)
  Future<Map<String, dynamic>?> getNotificationContent({String lang = 'tr'}) =>
      _getMap('/practice/notification-content?lang=$lang');

  Future<Map<String, dynamic>?> startLesson(String lessonId) async {
    try {
      final response = await ApiClient.dio
          .post('/practice/lessons/$lessonId/start')
          .timeout(_requestTimeout);
      return ApiResponseParser.tryMap(response.data);
    } on DioException {
      return null;
    } on Object {
      return null;
    }
  }

  Future<Map<String, dynamic>?> completeLesson(
    String lessonId, {
    required int correct,
    required int total,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/practice/lessons/$lessonId/complete',
        data: {
          'correct_count': correct,
          'total_count': total,
          'correct_answers': correct,
          'total_questions': total,
          'accuracy': total == 0 ? 0 : (correct / total * 100).round(),
        },
      ).timeout(_requestTimeout);
      return ApiResponseParser.tryMap(response.data);
    } on DioException {
      return null;
    } on Object {
      return null;
    }
  }

  Future<Map<String, dynamic>?> answerQuestion(
    String questionId, {
    required String lessonId,
    required Object? answer,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/practice/questions/$questionId/answer',
        data: {'lesson_id': lessonId, 'answer': answer},
      ).timeout(_requestTimeout);
      return ApiResponseParser.tryMap(response.data);
    } on DioException {
      return null;
    } on Object {
      return null;
    }
  }

  Future<Map<String, dynamic>?> repairStreak() async {
    try {
      final response = await ApiClient.dio
          .post('/practice/streak/repair')
          .timeout(_requestTimeout);
      return ApiResponseParser.tryMap(response.data);
    } on DioException {
      return null;
    } on Object {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getMap(
    String path, {
    Duration timeout = _requestTimeout,
  }) async {
    try {
      final response = await ApiClient.dio.get(path).timeout(timeout);
      return ApiResponseParser.tryMap(response.data);
    } on DioException {
      return null;
    } on Object {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _postMap(
    String path, {
    Object? data,
    Duration timeout = _requestTimeout,
  }) async {
    try {
      final response =
          await ApiClient.dio.post(path, data: data).timeout(timeout);
      return ApiResponseParser.tryMap(response.data);
    } on DioException {
      return null;
    } on Object {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _postMapWithApiError(
    String path, {
    Object? data,
    Duration timeout = _requestTimeout,
  }) async {
    try {
      final response =
          await ApiClient.dio.post(path, data: data).timeout(timeout);
      return ApiResponseParser.tryMap(response.data);
    } on DioException catch (error) {
      // Premium kota cevapları 429 ile gelir. UI bu yapıdaki
      // premium_required alanını görerek doğru teklif ekranını açar.
      return ApiResponseParser.tryMap(error.response?.data);
    } on Object {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _deleteMap(String path) async {
    try {
      final response =
          await ApiClient.dio.delete(path).timeout(_requestTimeout);
      return ApiResponseParser.tryMap(response.data);
    } on DioException {
      return null;
    } on Object {
      return null;
    }
  }
}
