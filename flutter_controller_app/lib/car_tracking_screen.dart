import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'box_painter.dart';
import 'package:image/image.dart' as img; // Import image package
import 'utils/image_utils.dart'; // Import YUV converter
import 'utils/box_tracker.dart'; // Import BoxTracker
import 'voice_announcer.dart'; // Import VoiceAnnouncer
import 'config/yolo_model_config.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class CarTrackingScreen extends StatefulWidget {
  final List<String>? classFilter;
  final String title;
  final DisplayManager? displayManager;

  const CarTrackingScreen({
    super.key, 
    this.classFilter,
    this.title = "Object Tracker",
    this.displayManager,
  });

  @override
  State<CarTrackingScreen> createState() => _CarTrackingScreenState();
}

class _CarTrackingScreenState extends State<CarTrackingScreen> {
  late CameraController cameraController;
  YOLO? objectDetector;
  
  // State
  bool isCameraInitialized = false;
  bool isModelLoaded = false;
  bool isDetecting = false;
  
  // Data
  List<Map<String, dynamic>> detections = [];
  double imageWidth = 1.0;
  double imageHeight = 1.0;

  String? errorMessage;

  // Tracking
  final BoxTracker boxTracker = BoxTracker(); // Box Persistence
  final VoiceAnnouncer voiceAnnouncer = VoiceAnnouncer(); // TTS
  bool isProcessingFrame = false; // concurrency control

  @override
  void initState() {
    super.initState();

    initializeCamera();
    loadYoloModel();
  }

// ... (omitting unchanged init/dispose)

  void startDetection() {
    if (!isCameraInitialized || !isModelLoaded || isDetecting) return;
    setState(() {
      isDetecting = true;
    });

    cameraController.startImageStream((image) async {
      if (!isDetecting) return; // Stop immediately if disposing
      if (isProcessingFrame) return; // Drop frame if busy
      isProcessingFrame = true;

      try {
        // 1. Convert YUV to RGB
        img.Image? rawImage = convertYUV420ToImage(image);
        
        if (rawImage != null) {
          // 1b. NO Rotation needed for Landscape!
          // Input: 720x480 (Landscape) -> Model: 640x480 (Landscape)
          final img.Image processedImage = rawImage;

          // 2. Encode to JPEG for yoloOnImage
          Uint8List jpegBytes = Uint8List.fromList(img.encodeJpg(processedImage));

          // 3. Run Inference on the clean JPEG
          if (objectDetector == null) return;
          if (objectDetector == null) return;
          final resultMap = await objectDetector!.predict(jpegBytes, confidenceThreshold: 0.4, iouThreshold: 0.5);
          
          final List<dynamic> boxes = resultMap['boxes'] as List<dynamic>? ?? [];

          final response = boxes.map((item) {
            final Map<String, dynamic> boxMap = Map<String, dynamic>.from(item as Map);
            // Assuming boxMap has 'box' (list) or 'xyxy'
            final List<dynamic> coords = boxMap['box'] ?? boxMap['xyxy'] ?? [0,0,0,0];
            final String label = boxMap['class'] as String? ?? 'unknown';
             // flutter_vision format for BoxTracker: {'box': [x1,y1,x2,y2, prob], 'tag': label}
            final double conf = (boxMap['confidence'] as num?)?.toDouble() ?? 0.0;
            return {
              'box': [coords[0], coords[1], coords[2], coords[3], conf],
              'tag': label,
            };
          }).toList();

          // 4. Apply Box Persistence (Tracker)
          var trackedObjects = boxTracker.process(response);
          
          // 5. Apply Class Filter (if vehicle mode)
          if (widget.classFilter != null) {
            trackedObjects = trackedObjects.where((obj) {
              return widget.classFilter!.contains(obj['tag']);
            }).toList();
          }

          // 6. Coordinate Mapping: Model (640x480) -> Image (720x480)
          // flutter_vision uses "downsize" mode = direct squash (NOT letterbox)
          // It scales 720x480 -> 640x480 directly without preserving aspect ratio.
          // To convert back: multiply X by 720/640, Y unchanged (480/480=1)
          
          double modelWidth = 640.0;
          double modelHeight = 480.0;
          double imgW = processedImage.width.toDouble();  // 720
          double imgH = processedImage.height.toDouble(); // 480
          
          // Direct scaling (no letterbox, no padding)
          double scaleX = imgW / modelWidth;  // 720/640 = 1.125
          double scaleY = imgH / modelHeight; // 480/480 = 1.0

          // Create a Display Copy (Deep Clone)
          List<Map<String, dynamic>> displayDetections = trackedObjects.map((obj) {
             return {
               "tag": obj["tag"],
               "box": List<dynamic>.from(obj["box"]), // Clone the box list
             };
          }).toList();

          for (var obj in displayDetections) {
            List<dynamic> box = obj['box'];
            // Simple direct scaling (no padding offsets)
            box[0] = box[0] * scaleX; // x1
            box[1] = box[1] * scaleY; // y1
            box[2] = box[2] * scaleX; // x2
            box[3] = box[3] * scaleY; // y2
          }

          if (mounted) {
             setState(() {
               detections = displayDetections;
               // Use actual image dimensions for painter
               imageWidth = imgW;
               imageHeight = imgH;
             });
             _sendStatsToDashboard(displayDetections);
              
             // Announce the first detected object if any
             if (displayDetections.isNotEmpty) {
               voiceAnnouncer.announceObject(displayDetections.first['tag']);
             }
           }
        }
      } catch (e) {
        debugPrint("Error detecting: $e");
      } finally {
        isProcessingFrame = false;
      }
    });
  }

  void _sendStatsToDashboard(List<Map<String, dynamic>> results) {
    if (widget.displayManager == null) return;

    final Map<String, int> stats = {};
    for (var res in results) {
      final String label = res['tag'] ?? 'unknown';
      stats[label] = (stats[label] ?? 0) + 1;
    }

    widget.displayManager!.transferDataToPresentation({
      'stats': stats,
    });
  }

  @override
  void dispose() {
    _safeDispose();
    super.dispose();
  }

  /// Safely dispose camera resources to prevent Impeller crash
  Future<void> _safeDispose() async {
    // 1. Stop TTS
    voiceAnnouncer.stop();
    
    // 2. Mark as not detecting to stop new frames
    isDetecting = false;
    
    // 3. Stop the image stream BEFORE disposing camera
    if (cameraController.value.isStreamingImages) {
      try {
        await cameraController.stopImageStream();
      } catch (e) {
        debugPrint('[CarTrackingScreen] Error stopping stream: $e');
      }
    }
    
    // 4. Wait for any pending frame processing to complete
    await Future.delayed(const Duration(milliseconds: 100));
    
    // 5. Now safely dispose
    try {
      await cameraController.dispose();
    } catch (e) {
      debugPrint('[CarTrackingScreen] Error disposing camera: $e');
    }
    
    // 6. Close YOLO model
    try {
      await objectDetector?.dispose();
      objectDetector = null;
    } catch (e) {
      debugPrint('[CarTrackingScreen] Error closing model: $e');
    }
  }

  Future<void> initializeCamera() async {
    try {
      // Request Camera Permission
      var status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        throw Exception("Camera permission denied. Please enable it in settings.");
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception("No cameras found");
      }

      cameraController = CameraController(cameras[0], ResolutionPreset.medium);
      await cameraController.initialize();
      await loadYoloModel();
      if (mounted) {
        setState(() {
          isCameraInitialized = true;
          isModelLoaded = true;
          errorMessage = null;
        });
        startDetection();
      }
    } catch (e) {
      debugPrint("Error initializing: $e");
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
        });
      }
    }
  }



  Future<void> loadYoloModel() async {
    try {
           final assetPath = YoloModelConfig.modelPath;
           final localPath = await _copyAssetToLocal(assetPath);
           
          // Use the config from YoloModelConfig (ignoring other params for now)
          objectDetector = YOLO(
            modelPath: localPath,
            task: YOLOTask.detect,
          );
          await objectDetector!.loadModel();
      setState(() {
        isModelLoaded = true;
      });
    } catch (e) {
      debugPrint("Error loading YOLO model: $e");
    }
  }

  Future<String> _copyAssetToLocal(String assetPath) async {
    try {
      final filename = assetPath.split('/').last;
      final dir = await getApplicationDocumentsDirectory();
      final File file = File('${dir.path}/$filename');

      if (await file.exists()) {
         return file.path;
      }

      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes, 
        data.lengthInBytes
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      throw Exception('Failed to copy asset $assetPath: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Error: $errorMessage",
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    if (!isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // CameraPreview will maintain its aspect ratio and center itself
          CameraPreview(cameraController),
          // CustomPaint fills the Stack, painter handles offset internally
          CustomPaint(
            painter: YoloBoxPainter(
              detections: detections,
              imageWidth: imageWidth > 0 ? imageWidth : 720,
              imageHeight: imageHeight > 0 ? imageHeight : 480,
            ),
          ),
          // DETECTION LOG OVERLAY - Top of screen
          Positioned(
            top: 50,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "🔍 ${widget.title.toUpperCase()}",
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Objects Found: ${detections.length}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  if (detections.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      detections.map((e) => "${e['tag']} (${(e['box'][4]*100).toInt()}%)").join(", "),
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 12,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (detections.isEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Scanning... Point at objects like cups, chairs, people, phones...",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // STATUS BAR - Bottom of screen
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: detections.isNotEmpty ? Colors.green.withOpacity(0.8) : Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  detections.isNotEmpty 
                    ? "✅ ${detections.length} object(s) detected"
                    : "📷 Scanning...",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
          // BACK BUTTON - Bottom Left
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              onPressed: () {
                // Stop camera stream and navigate back
                if (isDetecting) {
                  cameraController.stopImageStream();
                }
                Navigator.pop(context);
              },
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
