import 'dart:async';
import 'dart:convert';
import 'package:vosk_flutter/vosk_flutter.dart';

/// Normalized command identifiers
class VoiceCommand {
  static const String startObjectTracking = 'CMD_START_OBJECT';
  static const String stopObjectTracking = 'CMD_STOP_OBJECT';
  static const String startCarTracking = 'CMD_START_CAR';
  static const String stopCarTracking = 'CMD_STOP_CAR';
  static const String objectTracking = 'CMD_OBJECT'; // shortcut
  static const String carTracking = 'CMD_CAR'; // shortcut
}

/// Continuous offline voice command service using Vosk
class VoiceCommandService {
  VoskFlutterPlugin? _vosk;
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;
  
  bool _isInitialized = false;
  bool _isListening = false;
  
  StreamSubscription? _resultSubscription;
  
  /// Grammar list for restricted recognition
  static const List<String> _grammar = [
    'swish start object tracking',
    'swish stop object tracking',
    'swish start car tracking',
    'swish stop car tracking',
    'swish object tracking',
    'swish car tracking',
  ];
  
  /// Initialize the voice command service
  /// Call this once at app startup after requesting microphone permission
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _vosk = VoskFlutterPlugin.instance();
      
      // Load model from assets (zip file)
      final modelPath = await ModelLoader().loadFromAssets(
        'assets/models/vosk-model-small-en-us-0.15.zip',
      );
      
      _model = await _vosk!.createModel(modelPath);
      
      // Create recognizer with grammar restriction
      _recognizer = await _vosk!.createRecognizer(
        model: _model!,
        sampleRate: 16000,
        grammar: _grammar,
      );
      
      // Initialize speech service for microphone input
      _speechService = await _vosk!.initSpeechService(_recognizer!);
      
      _isInitialized = true;
      print('[VoiceCommandService] Initialized successfully');
    } catch (e) {
      print('[VoiceCommandService] Initialization error: $e');
      rethrow;
    }
  }
  
  /// Start continuous listening for voice commands
  /// [onCommandDetected] is called when a valid command is recognized
  void startListening(Function(String command) onCommandDetected) {
    if (!_isInitialized || _isListening) return;
    
    _resultSubscription = _speechService!.onResult().listen((result) {
      final command = _parseResult(result);
      if (command != null) {
        print('[VoiceCommandService] Command detected: $command');
        onCommandDetected(command);
      }
    });
    
    _speechService!.start();
    _isListening = true;
    print('[VoiceCommandService] Listening started');
  }
  
  /// Stop listening for commands
  void stopListening() {
    if (!_isListening) return;
    
    _speechService?.stop();
    _resultSubscription?.cancel();
    _resultSubscription = null;
    _isListening = false;
    print('[VoiceCommandService] Listening stopped');
  }
  
  /// Parse Vosk result JSON and return normalized command
  String? _parseResult(String result) {
    try {
      final json = jsonDecode(result);
      final text = (json['text'] as String?)?.toLowerCase().trim();
      
      if (text == null || text.isEmpty) return null;
      
      // Map recognized phrases to normalized commands
      switch (text) {
        case 'swish start object tracking':
          return VoiceCommand.startObjectTracking;
        case 'swish stop object tracking':
          return VoiceCommand.stopObjectTracking;
        case 'swish start car tracking':
          return VoiceCommand.startCarTracking;
        case 'swish stop car tracking':
          return VoiceCommand.stopCarTracking;
        case 'swish object tracking':
          return VoiceCommand.objectTracking;
        case 'swish car tracking':
          return VoiceCommand.carTracking;
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  /// Check if the service is currently listening
  bool get isListening => _isListening;
  
  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;
  
  /// Dispose of all resources
  void dispose() {
    stopListening();
    _recognizer?.dispose();
    _model?.dispose();
    _vosk = null;
    _isInitialized = false;
    print('[VoiceCommandService] Disposed');
  }
}
