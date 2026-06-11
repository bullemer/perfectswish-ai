import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runtime state for YOLO model selection and debug settings
/// Use this singleton to switch models and toggle debug features at runtime
class YoloModelState extends ChangeNotifier {
  static final YoloModelState _instance = YoloModelState._internal();
  factory YoloModelState() => _instance;
  YoloModelState._internal();

  // Available models - single basketball YOLO11n model
  static const Map<String, String> availableModels = {
    'Basketball YOLO11n': 'assets/basketball_yolo11n.tflite',
  };

  // Labels for each model type
  static const Map<String, String> modelLabels = {
    'assets/basketball_yolo11n.tflite': 'assets/custom_labels.txt',
  };

  // State
  String _modelPath = 'assets/basketball_yolo11n.tflite'; // Set as new default
  String _labelsPath = 'assets/custom_labels.txt';
  bool _debugMode = false;
  bool _showAiVision = false;
  bool _initialized = false;

  // Getters
  String get modelPath => _modelPath;
  String get labelsPath => _labelsPath;
  bool get debugMode => _debugMode;
  bool get showAiVision => _showAiVision;
  bool get initialized => _initialized;

  String get modelName {
    return availableModels.entries
        .firstWhere((e) => e.value == _modelPath,
            orElse: () => const MapEntry('Unknown', ''))
        .key;
  }

  /// Initialize from SharedPreferences
  Future<void> init() async {
    if (_initialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _modelPath = prefs.getString('yolo_model_path') ?? _modelPath;
      _labelsPath = modelLabels[_modelPath] ?? 'assets/custom_labels.txt';
      _debugMode = prefs.getBool('debug_mode') ?? false;
      _showAiVision = prefs.getBool('show_ai_vision') ?? false;
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[YoloModelState] Error loading preferences: $e');
    }
  }

  /// Set the active model
  Future<void> setModel(String modelPath) async {
    if (modelPath == _modelPath) return;
    
    _modelPath = modelPath;
    _labelsPath = modelLabels[modelPath] ?? 'assets/custom_labels.txt';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('yolo_model_path', modelPath);
    } catch (e) {
      debugPrint('[YoloModelState] Error saving model path: $e');
    }
    
    notifyListeners();
  }

  /// Toggle debug mode
  Future<void> setDebugMode(bool enabled) async {
    if (enabled == _debugMode) return;
    
    _debugMode = enabled;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('debug_mode', enabled);
    } catch (e) {
      debugPrint('[YoloModelState] Error saving debug mode: $e');
    }
    
    notifyListeners();
  }

  /// Toggle AI vision display
  Future<void> setShowAiVision(bool enabled) async {
    if (enabled == _showAiVision) return;
    
    _showAiVision = enabled;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_ai_vision', enabled);
    } catch (e) {
      debugPrint('[YoloModelState] Error saving AI vision setting: $e');
    }
    
    notifyListeners();
  }
}
