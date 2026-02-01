import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'utils/pose_pipeline.dart';
import 'utils/one_euro_filter.dart';
import 'utils/pose_math.dart';
import 'pose_painter.dart';

class PoseTrackingScreen extends StatefulWidget {
  final String title;
  
  const PoseTrackingScreen({
    super.key,
    this.title = "Pose Tracker",
  });

  @override
  State<PoseTrackingScreen> createState() => _PoseTrackingScreenState();
}

class _PoseTrackingScreenState extends State<PoseTrackingScreen> {
  CameraController? _cameraController;
  PosePipeline? _posePipeline;
  
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  String? _errorMessage;
  
  // Pose data
  List<Pose> _poses = [];
  int _imageWidth = 1;
  int _imageHeight = 1;
  int _currentRotation = 0; // Dynamic rotation from pipeline
  bool _isFrontCamera = false;
  
  // One Euro Filters for key joints
  final Map<PoseLandmarkType, OneEuroFilter2D> _filters = {};
  Map<PoseLandmarkType, (double, double)> _filteredLandmarks = {};
  Map<String, double> _jointAngles = {};
  
  // Joints to filter
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
  
  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _initializeCamera();
  }
  
  void _initializeFilters() {
    for (final joint in _jointsToFilter) {
      _filters[joint] = OneEuroFilter2D(
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
      
      // Use back camera for pose detection
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      
      await _cameraController!.initialize();
      
      _isFrontCamera = camera.lensDirection == CameraLensDirection.front;
      
      // Initialize pose pipeline
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
      debugPrint('[PoseTrackingScreen] Error initializing: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }
  
  static const _orientations = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  int _computeRotationDegrees() {
    if (_cameraController == null) return 0;
    final sensor = _cameraController!.description.sensorOrientation;
    final device = _orientations[_cameraController!.value.deviceOrientation] ?? 0;
    final isFront = _cameraController!.description.lensDirection == CameraLensDirection.front;

    // rotation compensation for ML Kit
    return isFront ? (sensor + device) % 360 : (sensor - device + 360) % 360;
  }

  void _startDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isDetecting) return;
    
    _isDetecting = true;
    _cameraController!.startImageStream((image) {
      if (!_isDetecting) return;
      final rotation = _computeRotationDegrees();
      _posePipeline?.processFrame(image, rotation, _isFrontCamera);
    });
  }
  
  void _onPosesDetected(List<Pose> poses, int width, int height, int rotation, bool isFront) {
    if (!mounted) return;
    
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final filteredLandmarks = <PoseLandmarkType, (double, double)>{};
    final jointAngles = <String, double>{};
    
    if (poses.isNotEmpty) {
      final pose = poses.first;
      
      // Apply One Euro Filter to key joints
      for (final joint in _jointsToFilter) {
        final landmark = pose.landmarks[joint];
        if (landmark != null && landmark.likelihood > 0.5) {
          final filtered = _filters[joint]!.filter(landmark.x, landmark.y, now);
          filteredLandmarks[joint] = filtered;
        }
      }
      
      // Compute joint angles
      final leftElbow = getElbowAngle(pose, isLeft: true);
      final rightElbow = getElbowAngle(pose, isLeft: false);
      final leftKnee = getKneeAngle(pose, isLeft: true);
      final rightKnee = getKneeAngle(pose, isLeft: false);
      
      if (leftElbow != null) jointAngles['leftElbow'] = leftElbow;
      if (rightElbow != null) jointAngles['rightElbow'] = rightElbow;
      if (leftKnee != null) jointAngles['leftKnee'] = leftKnee;
      if (rightKnee != null) jointAngles['rightKnee'] = rightKnee;
    }
    
    setState(() {
      _poses = poses;
      _imageWidth = width;
      _imageHeight = height;
      _currentRotation = rotation;
      _filteredLandmarks = filteredLandmarks;
      _jointAngles = jointAngles;
    });
  }
  
  @override
  void dispose() {
    _safeDispose();
    super.dispose();
  }
  
  Future<void> _safeDispose() async {
    _isDetecting = false;
    
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      try {
        await _cameraController!.stopImageStream();
      } catch (e) {
        debugPrint('[PoseTrackingScreen] Error stopping stream: $e');
      }
    }
    
    await Future.delayed(const Duration(milliseconds: 100));
    
    try {
      await _cameraController?.dispose();
    } catch (e) {
      debugPrint('[PoseTrackingScreen] Error disposing camera: $e');
    }
    
    try {
      await _posePipeline?.dispose();
    } catch (e) {
      debugPrint('[PoseTrackingScreen] Error disposing pipeline: $e');
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
    
    if (!_isCameraInitialized || _cameraController == null) {
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
          // 1. Camera Preview (fills and maintains aspect ratio)
          CameraPreview(_cameraController!),
          
          // 2. Skeleton Overlay (fills stack, painter handles offset internally)
          CustomPaint(
            painter: PosePainter(
              poses: _poses,
              imageWidth: _imageWidth,
              imageHeight: _imageHeight,
              rotationDegrees: _currentRotation,
              isFrontCamera: _isFrontCamera,
              filteredLandmarks: _filteredLandmarks,
              jointAngles: _jointAngles,
            ),
          ),
          
          // 2. Status overlay
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
                    "🏀 ${widget.title.toUpperCase()}",
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "People Detected: ${_poses.length}",
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  if (_jointAngles.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _jointAngles.entries
                          .map((e) => "${e.key}: ${e.value.toInt()}°")
                          .join(" | "),
                      style: const TextStyle(color: Colors.cyan, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (_poses.isEmpty) ...[
                    const SizedBox(height: 4),
                    const Text(
                      "Point camera at a person to detect pose...",
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
          
          // 3. Status bar at bottom
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _poses.isNotEmpty
                      ? Colors.deepOrange.withOpacity(0.8)
                      : Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _poses.isNotEmpty
                      ? "✅ Pose detected"
                      : "📷 Scanning...",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
          
          // 4. Back button
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              onPressed: () {
                if (_isDetecting && _cameraController != null) {
                  _cameraController!.stopImageStream();
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
