import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'utils/image_utils.dart';
import 'services/object_tracker_service.dart';
import 'tracker_painter.dart';
import 'config/yolo_model_config.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'utils/pose_pipeline.dart';
import 'utils/one_euro_filter.dart';
import 'utils/pose_math.dart';
import 'pose_painter.dart';

/// Shot Tracker Screen for basketball rim and ball tracking
/// Uses ObjectTrackerService with Kalman filtering and rim locking
class ShotTrackerScreen extends StatefulWidget {
  final String title;

  const ShotTrackerScreen({
    super.key,
    this.title = "Shot Tracker",
  });

  @override
  State<ShotTrackerScreen> createState() => _ShotTrackerScreenState();
}

class _ShotTrackerScreenState extends State<ShotTrackerScreen> {
  late CameraController _cameraController;
  late FlutterVision _vision;
  late ObjectTrackerService _trackerService;

  bool _isCameraInitialized = false;
  bool _isModelLoaded = false;
  bool _isDetecting = false;
  bool _isProcessingFrame = false;
  String? _errorMessage;

  // Display state
  TrackerState _trackerState = TrackerState();
  List<Map<String, dynamic>> _rawDetections = []; // For precise box rendering
  double _imageWidth = 1.0;
  double _imageHeight = 1.0;
  
  // FPS throttling
  DateTime _lastProcessTime = DateTime.now();
  static const int _targetFps = 30; // Process at 30 FPS max (was 15)
  static const Duration _minFrameInterval = Duration(milliseconds: 1000 ~/ _targetFps);
  
  // Debug state for on-screen display
  int _frameCount = 0;
  int _detectionCount = 0;
  List<String> _lastDetectedClasses = [];
  double _currentFps = 0.0;
  DateTime _fpsStartTime = DateTime.now();
  bool _showDebugPanel = false; // Hidden by default for clean UI
  
  // Rotation handling
  int _currentRotation = 0;
  
  // === POSE DETECTION STATE ===
  PosePipeline? _posePipeline;
  List<Pose> _poses = [];
  bool _isFrontCamera = false;
  final Map<PoseLandmarkType, OneEuroFilter2D> _poseFilters = {};
  Map<PoseLandmarkType, (double, double)> _filteredLandmarks = {};
  Map<String, double> _jointAngles = {};
  
  // Joints to filter for smooth skeleton
  static const List<PoseLandmarkType> _jointsToFilter = [
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
  ];
  
  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    _vision = FlutterVision();
    _trackerService = ObjectTrackerService();
    _initializePoseFilters();
    _initializeCamera();
    _loadModel();
  }
  
  void _initializePoseFilters() {
    for (final joint in _jointsToFilter) {
      _poseFilters[joint] = OneEuroFilter2D(
        minCutoff: 1.0,
        beta: 0.007,
        dCutoff: 1.0,
      );
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        throw Exception("Camera permission denied");
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception("No cameras found");
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        // CRITICAL: Must use NV21 for ML Kit Pose Detection on Android
        // YUV420 breaks skeleton detection
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController.initialize();
      
      _isFrontCamera = camera.lensDirection == CameraLensDirection.front;
      
      // Initialize pose pipeline for skeleton detection
      _posePipeline = PosePipeline(
        onPosesDetected: _onPosesDetected,
      );

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        _startDetection();
      }
    } catch (e) {
      debugPrint('[ShotTrackerScreen] Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadModel() async {
    try {
      // Load YOLO model based on config
      await _vision.loadYoloModel(
        labels: YoloModelConfig.labelsPath,
        modelPath: YoloModelConfig.modelPath,
        modelVersion: YoloModelConfig.modelVersion,
        quantization: YoloModelConfig.quantization,
        numThreads: YoloModelConfig.numThreads,
        useGpu: YoloModelConfig.useGpu,
      );
      debugPrint('[ShotTrackerScreen] Loaded model: ${YoloModelConfig.modelName}');

      if (mounted) {
        setState(() {
          _isModelLoaded = true;
        });
        _startDetection();
      }
    } catch (e) {
      debugPrint('[ShotTrackerScreen] Error loading model: $e');
      if (mounted) {
        setState(() {
          _errorMessage = "Model load failed: $e";
        });
      }
    }
  }

  /// Computes the rotation angle based on device orientation and camera sensor
  int _computeRotationDegrees() {
    final sensor = _cameraController.description.sensorOrientation;
    final device = _orientations[_cameraController.value.deviceOrientation] ?? 0;
    // For back camera
    return (sensor - device + 360) % 360;
  }

  void _startDetection() {
    if (!_isCameraInitialized || !_isModelLoaded || _isDetecting) return;
    
    setState(() {
      _isDetecting = true;
    });

    _cameraController.startImageStream((image) async {
      if (!_isDetecting) return;
      if (_isProcessingFrame) return;
      
      // No FPS throttling - process as fast as possible like Object Tracker
      
      // Compute rotation for this frame
      _currentRotation = _computeRotationDegrees();
      
      // Send frame to pose pipeline (runs async, doesn't block YOLO)
      _posePipeline?.processFrame(image, _currentRotation, _isFrontCamera);
      
      _isProcessingFrame = true;

      try {
        // 1. Convert NV21 to RGB for YOLO
        img.Image? rawImage = convertNV21ToImage(image);

        if (rawImage != null) {
          // 2. Encode to JPEG for yoloOnImage
          Uint8List jpegBytes = Uint8List.fromList(img.encodeJpg(rawImage));

          // 3. Run YOLO inference with slightly lower thresholds for NV21 sensitivity
          final response = await _vision.yoloOnImage(
            bytesList: jpegBytes,
            imageHeight: rawImage.height,
            imageWidth: rawImage.width,
            iouThreshold: 0.4,
            confThreshold: 0.3,
            classThreshold: 0.3,
          );

          // 4. DEBUG: Log raw box values to determine coordinate space
          double imgW = rawImage.width.toDouble();
          double imgH = rawImage.height.toDouble();
          
          if (response.isNotEmpty) {
            final firstBox = response.first['box'];
            debugPrint('[COORD DEBUG] Raw box: $firstBox, img: ${imgW.toInt()}x${imgH.toInt()}');
          }
          
          // 5. Coordinate mapping using SIMPLE DIRECT SCALING (same as Object Tracker)
          // flutter_vision uses "downsize" mode = direct squash (NOT letterbox)
          // Model input: 640x480, Image: actual camera resolution
          double modelWidth = 640.0;
          double modelHeight = 480.0;
          double scaleX = imgW / modelWidth;
          double scaleY = imgH / modelHeight;
          
          List<Map<String, dynamic>> scaledDetections = response.map((obj) {
            List<dynamic> rawBox = List.from(obj['box'] ?? [0, 0, 0, 0, 0]);
            
            // Simple direct scaling (same as Object Tracker)
            return {
              'tag': obj['tag'],
              'box': [
                (rawBox[0] as num).toDouble() * scaleX, // x1
                (rawBox[1] as num).toDouble() * scaleY, // y1  
                (rawBox[2] as num).toDouble() * scaleX, // x2
                (rawBox[3] as num).toDouble() * scaleY, // y2
                rawBox.length > 4 ? rawBox[4] : 0.0, // confidence
              ],
            };
          }).toList();

          // Debug logging (only log when detections exist)
          if (response.isNotEmpty) {
            debugPrint('[ShotTracker] ${response.length} detections: ${scaledDetections.map((o) => o['tag']).join(', ')}');
          }

          // 6. Process through ObjectTrackerService
          final newState = _trackerService.processDetections(scaledDetections);
          
          // Update debug stats
          _frameCount++;
          final elapsed = DateTime.now().difference(_fpsStartTime).inMilliseconds;
          if (elapsed > 1000) {
            _currentFps = (_frameCount * 1000.0) / elapsed;
            _frameCount = 0;
            _fpsStartTime = DateTime.now();
          }

          if (mounted) {
            setState(() {
              _trackerState = newState;
              _rawDetections = scaledDetections; // Save for precise painting
              _imageWidth = imgW;
              _imageHeight = imgH;
              _detectionCount = response.length;
              _lastDetectedClasses = scaledDetections.map((o) => o['tag'] as String).toList();
            });
          }
        }
      } catch (e) {
        debugPrint('[ShotTrackerScreen] Detection error: $e');
      } finally {
        _isProcessingFrame = false;
      }
    });
  }
  
  /// Callback from PosePipeline when poses are detected
  void _onPosesDetected(List<Pose> poses, int width, int height, int rotation, bool isFront) {
    if (!mounted) return;
    
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final filteredLandmarks = <PoseLandmarkType, (double, double)>{};
    final jointAngles = <String, double>{};
    
    if (poses.isNotEmpty) {
      final pose = poses.first;
      
      // Apply One Euro Filter to key joints for smooth rendering
      for (final joint in _jointsToFilter) {
        final landmark = pose.landmarks[joint];
        if (landmark != null && landmark.likelihood > 0.5) {
          final filtered = _poseFilters[joint]!.filter(landmark.x, landmark.y, now);
          filteredLandmarks[joint] = filtered;
        }
      }
      
      // Compute joint angles for display
      final leftElbow = getElbowAngle(pose, isLeft: true);
      final rightElbow = getElbowAngle(pose, isLeft: false);
      final leftKnee = getKneeAngle(pose, isLeft: true);
      final rightKnee = getKneeAngle(pose, isLeft: false);
      
      if (leftElbow != null) jointAngles['L.Elbow'] = leftElbow;
      if (rightElbow != null) jointAngles['R.Elbow'] = rightElbow;
      if (leftKnee != null) jointAngles['L.Knee'] = leftKnee;
      if (rightKnee != null) jointAngles['R.Knee'] = rightKnee;
    }
    
    setState(() {
      _poses = poses;
      _filteredLandmarks = filteredLandmarks;
      _jointAngles = jointAngles;
    });
  }

  @override
  void dispose() {
    _safeDispose();
    super.dispose();
  }

  /// Un-letterbox a rect from model space (S×S) to image space (imgW×imgH)
  /// YOLO preprocessors letterbox non-square images with padding
  Rect _unletterboxRect(Rect r, double imgW, double imgH, double S) {
    // Calculate the scale factor used during letterboxing
    final scale = (S / imgW < S / imgH) ? (S / imgW) : (S / imgH);
    final newW = imgW * scale;
    final newH = imgH * scale;
    final padX = (S - newW) / 2;
    final padY = (S - newH) / 2;

    // Reverse the transform: subtract padding, then divide by scale
    final left   = (r.left   - padX) / scale;
    final top    = (r.top    - padY) / scale;
    final right  = (r.right  - padX) / scale;
    final bottom = (r.bottom - padY) / scale;

    return Rect.fromLTRB(
      left.clamp(0.0, imgW),
      top.clamp(0.0, imgH),
      right.clamp(0.0, imgW),
      bottom.clamp(0.0, imgH),
    );
  }

  Future<void> _safeDispose() async {
    _isDetecting = false;

    if (_cameraController.value.isStreamingImages) {
      try {
        await _cameraController.stopImageStream();
      } catch (e) {
        debugPrint('[ShotTrackerScreen] Error stopping stream: $e');
      }
    }

    await Future.delayed(const Duration(milliseconds: 100));

    try {
      await _cameraController.dispose();
    } catch (e) {
      debugPrint('[ShotTrackerScreen] Error disposing camera: $e');
    }

    try {
      await _vision.closeYoloModel();
    } catch (e) {
      debugPrint('[ShotTrackerScreen] Error closing model: $e');
    }
    
    try {
      await _posePipeline?.dispose();
    } catch (e) {
      debugPrint('[ShotTrackerScreen] Error disposing pose pipeline: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Error: $_errorMessage",
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Get the preview size for proper aspect-correct rendering
    final previewSize = _cameraController.value.previewSize;
    // App is in landscape mode, use preview dimensions directly (width > height)
    final previewWidth = previewSize?.width ?? _imageWidth;
    final previewHeight = previewSize?.height ?? _imageHeight;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Direct CameraPreview (maintains aspect ratio, centers itself - same as Object Tracker)
          CameraPreview(_cameraController),
          
          // Ball/Rim Detection Overlay using YoloBoxPainter approach
          CustomPaint(
            painter: _SimpleBallPainter(
              detections: _rawDetections,
              imageWidth: _imageWidth,
              imageHeight: _imageHeight,
            ),
          ),
          
          // Skeleton Overlay (ML Kit Pose)
          CustomPaint(
            painter: PosePainter(
              poses: _poses,
              imageWidth: _imageWidth.toInt(),
              imageHeight: _imageHeight.toInt(),
              rotationDegrees: _currentRotation,
              isFrontCamera: _isFrontCamera,
              filteredLandmarks: _filteredLandmarks,
              jointAngles: _jointAngles,
            ),
          ),

          // Status Overlay (Clean style like Object Tracker)
          Positioned(
            top: 50,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "🏀 ${widget.title.toUpperCase()}",
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Objects Found: $_detectionCount",
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  if (_lastDetectedClasses.isNotEmpty)
                    Text(
                      _lastDetectedClasses.map((c) => "$c").join(", "),
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  // Pose info
                  if (_poses.isNotEmpty)
                    Text(
                      "👤 ${_poses.length} person(s) detected",
                      style: const TextStyle(color: Colors.cyan, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
          
          // Bottom status bar
          Positioned(
            bottom: 90,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _detectionCount > 0
                      ? Colors.green.withValues(alpha: 0.8)
                      : Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _detectionCount > 0
                      ? "✓ ${_detectionCount} object(s) detected"
                      : "📷 Scanning...",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),

          // Back button
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              onPressed: () {
                if (_isDetecting) {
                  _cameraController.stopImageStream();
                }
                Navigator.pop(context);
              },
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),

          // Reset Rim button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                _trackerService.unlockRim();
                setState(() {});
              },
              backgroundColor: Colors.blueAccent,
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ),
          
          // Debug toggle button
          Positioned(
            bottom: 90,
            right: 20,
            child: FloatingActionButton.small(
              onPressed: () {
                setState(() {
                  _showDebugPanel = !_showDebugPanel;
                });
              },
              backgroundColor: _showDebugPanel ? Colors.green : Colors.grey,
              child: const Icon(Icons.bug_report, color: Colors.white),
            ),
          ),
          
          // Debug Panel
          if (_showDebugPanel)
            Positioned(
              bottom: 150,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "🔧 DEBUG PANEL",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(color: Colors.green, height: 12),
                    _DebugRow(label: "FPS", value: _currentFps.toStringAsFixed(1)),
                    _DebugRow(label: "Image", value: "${_imageWidth.toInt()}x${_imageHeight.toInt()}"),
                    _DebugRow(label: "Detections", value: "$_detectionCount"),
                    _DebugRow(
                      label: "Classes", 
                      value: _lastDetectedClasses.isEmpty 
                          ? "(none)" 
                          : _lastDetectedClasses.join(", "),
                    ),
                    _DebugRow(
                      label: "Ball Found", 
                      value: _lastDetectedClasses.any((c) => 
                          c.toLowerCase().contains('ball') || 
                          c.toLowerCase().contains('sports')) 
                          ? "✅ YES" 
                          : "❌ NO",
                    ),
                    _DebugRow(label: "Rim Locked", value: _trackerService.isRimLocked ? "✅ YES" : "❌ NO"),
                    _DebugRow(label: "ROI Mode", value: _trackerService.shouldUseRoi ? "✅ YES" : "❌ NO"),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;

  const _StatusIndicator({
    required this.label,
    required this.isActive,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? activeColor : Colors.grey,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _DebugRow extends StatelessWidget {
  final String label;
  final String value;

  const _DebugRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple painter for ball detection boxes - uses exact same coordinate
/// transformation as YoloBoxPainter from Object Tracker
class _SimpleBallPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  final double imageWidth;
  final double imageHeight;

  _SimpleBallPainter({
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty || imageWidth <= 0 || imageHeight <= 0) return;

    final Paint boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green;

    final Paint labelBgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    const TextStyle textStyle = TextStyle(
      color: Colors.white,
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
    );

    // Same coordinate transformation as YoloBoxPainter
    final Size contentSize = Size(imageWidth, imageHeight);
    final Size layoutSize = size;

    final double contentAspect = contentSize.width / contentSize.height;
    final double layoutAspect = layoutSize.width / layoutSize.height;

    double scale;
    double offsetX = 0;
    double offsetY = 0;

    if (layoutAspect > contentAspect) {
      // Layout wider than content - letterbox on sides
      scale = layoutSize.height / contentSize.height;
      double scaledWidth = contentSize.width * scale;
      offsetX = (layoutSize.width - scaledWidth) / 2;
    } else {
      // Layout taller than content - letterbox on top/bottom
      scale = layoutSize.width / contentSize.width;
      double scaledHeight = contentSize.height * scale;
      offsetY = (layoutSize.height - scaledHeight) / 2;
    }

    for (var detection in detections) {
      final box = detection['box'];
      if (box == null || box.length < 4) continue;

      // Transform coordinates with offset (same as YoloBoxPainter)
      double x1 = (box[0] * scale) + offsetX;
      double y1 = (box[1] * scale) + offsetY;
      double x2 = (box[2] * scale) + offsetX;
      double y2 = (box[3] * scale) + offsetY;

      final rect = Rect.fromLTRB(x1, y1, x2, y2);
      canvas.drawRect(rect, boxPaint);

      // Label
      final confidence = box.length > 4 ? box[4] : 0.0;
      String label = "${detection['tag']} ${(confidence * 100).toStringAsFixed(0)}%";
      
      final TextSpan textSpan = TextSpan(text: label, style: textStyle);
      final TextPainter textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final double textX = x1;
      final double textY = y1 - textPainter.height - 4;

      canvas.drawRect(
        Rect.fromLTWH(textX - 2, textY - 2, textPainter.width + 4, textPainter.height + 4),
        labelBgPaint,
      );
      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(covariant _SimpleBallPainter oldDelegate) {
    return true;
  }
}
