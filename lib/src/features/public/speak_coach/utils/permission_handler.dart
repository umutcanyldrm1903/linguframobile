import 'package:record/record.dart';

/// Permission handling for microphone access
class PermissionHandler {
  static final _audioRecorder = AudioRecorder();

  /// Request microphone permission
  static Future<bool> requestMicrophonePermission() async {
    try {
      return await _audioRecorder.hasPermission();
    } catch (e) {
      return false;
    }
  }

  /// Check if microphone permission is granted
  static Future<bool> hasMicrophonePermission() async {
    try {
      return await _audioRecorder.hasPermission();
    } catch (e) {
      return false;
    }
  }
}
