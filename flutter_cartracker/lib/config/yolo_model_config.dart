// YOLO Model Configuration
// This file specifies which YOLO model is currently in use

class YoloModelConfig {
  // Current model in use
  static const String modelPath = 'assets/basketball_custom_float32.tflite';
  static const String labelsPath = 'assets/custom_labels.txt';
  static const String modelVersion = 'yolov8';
  
  // Model metadata
  static const String modelName = 'Basketball Custom Float32';
  static const String modelDescription = 'Custom Trained Basketball/Rim Model (Float32)';
  static const int inputSize = 640; // 640x640 input
  
  // Inference settings
  static const bool quantization = false; // Float32 requires false
  static const int numThreads = 2;
  static const bool useGpu = true; // Enabled GPU for float32
  
  // Detection thresholds
  static const double confThreshold = 0.2;
  static const double classThreshold = 0.2;
  static const double iouThreshold = 0.4;
  
  // Available models (for reference)
  static const Map<String, String> availableModels = {
    'yolov8n': 'assets/yolov8n.tflite',      // Nano (~6MB, fastest)
    'yolov8s': 'assets/yolov8s.tflite',      // Small (~44MB, balanced)
    'yolov8s_landscape': 'assets/yolov8s_landscape.tflite', // Landscape optimized
    'basketball_custom': 'assets/basketball_custom_int8.tflite', // Custom Trained (~3MB)
  };

  // Class Names for custom model (Net = Rim)
  static const List<String> customLabels = [
    'Basketball Court',
    'Basketball',
    'Net',
    'No ball'
  ];
}
