import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class VoiceAnnouncer {
  final FlutterTts _flutterTts = FlutterTts();
  
  String? _lastLabel;
  DateTime? _lastSpokenTime;
  
  // Throttle duration for the SAME label (5 seconds)
  static const Duration _sameLabelThrottle = Duration(seconds: 5);

  VoiceAnnouncer() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    // Ensure it respects system audio output
    await _flutterTts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ],
    );
  }

  Future<void> announceObject(String label) async {
    final now = DateTime.now();

    // Rule A: If the new label is the same as lastLabel, only speak if 5s passed
    if (label == _lastLabel) {
      if (_lastSpokenTime != null && now.difference(_lastSpokenTime!) < _sameLabelThrottle) {
        return; // Skip announcement
      }
    }
    
    // Rule B: If the label is DIFFERENT, speak immediately
    // Or if it's the SAME but 5s passed (handled by fall-through)

    _lastLabel = label;
    _lastSpokenTime = now;

    print("[TTS] Announcing: $label");
    await _flutterTts.speak(label);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
