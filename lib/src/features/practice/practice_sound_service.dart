import 'dart:async';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class PracticeSoundService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _enabled = true;
  static bool _hapticEnabled = true;

  static void setEnabled(bool value) {
    _enabled = value;
  }

  static void setHapticEnabled(bool value) {
    _hapticEnabled = value;
  }

  static Future<void> _play(String asset, SystemSoundType fallback) async {
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.setAsset('assets/sounds/$asset');
      await _player.play();
    } catch (_) {
      await SystemSound.play(fallback);
    }
  }

  static Future<void> _haptic(Future<void> Function() impact) async {
    if (!_hapticEnabled) return;
    try {
      await impact();
    } catch (_) {
      // haptic yoksa yoksay
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

  // ── Semantik takma adlar (yeni çağrılar; mevcut wav'ları yeniden kullanır) ──

  /// Ders tamamlandı: fanfar + orta titreşim.
  static Future<void> onLessonComplete() async {
    await playComplete();
    await _haptic(HapticFeedback.mediumImpact);
  }

  /// Streak devam: ateş sesi + orta titreşim.
  static Future<void> onStreakContinue() async {
    await playStreak();
    await _haptic(HapticFeedback.mediumImpact);
  }

  /// XP kazanıldı: kısa ses.
  static Future<void> onXpEarned() => playXp();

  /// Buton/seçim dokunuşu: hafif selection tık + tap sesi.
  static Future<void> onTap() async {
    unawaited(_play('tap.wav', SystemSoundType.click));
    await _haptic(HapticFeedback.selectionClick);
  }

  /// Eşleşme (match pairs).
  static Future<void> onMatch() async {
    await playCorrect();
    await _haptic(HapticFeedback.lightImpact);
  }

  /// Lig yükselme: level_up fanfar + güçlü titreşim.
  static Future<void> onLeaguePromotion() async {
    await _play('level_up.wav', SystemSoundType.click);
    await _haptic(HapticFeedback.vibrate);
  }

  /// Rozet/sandık kazanıldı: badge fanfar + güçlü titreşim.
  static Future<void> onBadgeEarned() async {
    await _play('badge.wav', SystemSoundType.click);
    await _haptic(HapticFeedback.vibrate);
  }

  /// Seviye atlama: level_up fanfar.
  static Future<void> onLevelUp() async {
    await _play('level_up.wav', SystemSoundType.click);
    await _haptic(HapticFeedback.vibrate);
  }

  static Future<void> dispose() => _player.dispose();
}
