import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class PracticeSoundService {
  static AudioPlayer? _player;
  static bool _enabled = true;
  static bool _hapticEnabled = true;

  static bool get _canUseAssetAudio =>
      !kIsWeb && defaultTargetPlatform != TargetPlatform.android;

  static void setEnabled(bool value) {
    _enabled = value;
  }

  static void setHapticEnabled(bool value) {
    _hapticEnabled = value;
  }

  static Future<void> _play(String asset, SystemSoundType fallback) async {
    if (!_enabled) return;
    if (!_canUseAssetAudio) {
      await SystemSound.play(fallback);
      return;
    }

    try {
      final player = _player ??= AudioPlayer();
      await player.stop();
      await player.setAsset('assets/sounds/$asset');
      await player.play();
    } catch (_) {
      await SystemSound.play(fallback);
    }
  }

  static Future<void> _haptic(Future<void> Function() impact) async {
    if (!_hapticEnabled) return;
    try {
      await impact();
    } catch (_) {
      // Haptic desteklenmiyorsa sessizce geç.
    }
  }

  static Future<void> playCorrect() =>
      _play('correct.wav', SystemSoundType.click);

  static Future<void> playWrong() => _play('wrong.wav', SystemSoundType.alert);

  static Future<void> playComplete() =>
      _play('complete.wav', SystemSoundType.click);

  static Future<void> playStreak() =>
      _play('streak.wav', SystemSoundType.click);

  static Future<void> playXp() => _play('xp.wav', SystemSoundType.click);

  static Future<void> onCorrect() async {
    await playCorrect();
    await _haptic(HapticFeedback.lightImpact);
  }

  static Future<void> onWrong() async {
    await playWrong();
    await _haptic(HapticFeedback.heavyImpact);
  }

  // Semantik takma adlar: yeni çağrılar mevcut wav dosyalarını yeniden kullanır.
  static Future<void> onLessonComplete() async {
    await playComplete();
    await _haptic(HapticFeedback.mediumImpact);
  }

  static Future<void> onStreakContinue() async {
    await playStreak();
    await _haptic(HapticFeedback.mediumImpact);
  }

  static Future<void> onXpEarned() => playXp();

  static Future<void> onTap() async {
    unawaited(_play('tap.wav', SystemSoundType.click));
    await _haptic(HapticFeedback.selectionClick);
  }

  static Future<void> onMatch() async {
    await playCorrect();
    await _haptic(HapticFeedback.lightImpact);
  }

  static Future<void> onLeaguePromotion() async {
    await _play('level_up.wav', SystemSoundType.click);
    await _haptic(HapticFeedback.vibrate);
  }

  static Future<void> onBadgeEarned() async {
    await _play('badge.wav', SystemSoundType.click);
    await _haptic(HapticFeedback.vibrate);
  }

  static Future<void> onLevelUp() async {
    await _play('level_up.wav', SystemSoundType.click);
    await _haptic(HapticFeedback.vibrate);
  }

  static Future<void> dispose() => _player?.dispose() ?? Future.value();
}
