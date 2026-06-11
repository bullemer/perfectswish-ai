import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'services/debug_log_service.dart';
import 'config/yolo_model_config.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:image/image.dart' as img;

// Integrations
import 'services/object_tracker_service.dart';
import 'tracker_painter.dart';
import 'utils/viewport_mapper.dart';
import 'utils/image_utils_isolate.dart';

/// Video Test Mode Screen for debugging detection pipeline
/// Uses same tracking logic as live mode but on pre-recorded video
class VideoTestScreen extends StatefulWidget {
  const VideoTestScreen({super.key});

  @override
  State<VideoTestScreen> createState() => _VideoTestScreenState();
}

class _VideoTestScreenState extends State<VideoTestScreen> {
  VideoPlayerController? _videoController;
  YOLO? _objectDetector;
  
  // Tracking
  // Tracking
  final ObjectTrackerService _trackerService = ObjectTrackerService();
  TrackerState _trackerState = TrackerState();
  
  // Debug toggle
  bool _showDebug = true;
  bool _swapClasses = false; // Toggle to fix M8 class mapping issues (Class 2 -> Ball)
  List<Map<String, dynamic>> _detectionsN = []; // Normalized detections
  
  bool _isModelLoaded = false;
  bool _isProcessing = false;
  bool _isPaused = true;
  String? _errorMessage;
  String _statusMessage = 'Requesting Storage Permission...';
  
  // Detection results
  int _frameCount = 0;
  int _detectionFrames = 0;
  Map<String, int> _classCounts = {};
  double _currentFps = 0.0;
  DateTime _fpsStartTime = DateTime.now();
  int _fpsFrameCount = 0;
  
  // Video paths 
  final List<String> _availableVideos = [];
  String? _selectedVideo;
  static const String _preferedVideo = 'testvideo.mp4';
  List<String> _classLabels = [];
  int _inferenceWidth = 640;
  int _inferenceHeight = 640;
  int _inferenceCount = 0;
  
  // Log output
  final List<String> _logLines = [];
  final int _maxLogLines = 50;
  
  @override
  void initState() {
    super.initState();
    _log('VideoTest starting...');
    _requestPermissionsAndInit();
  }
  
  Future<void> _requestPermissionsAndInit() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      final videoStatus = await Permission.videos.request();
      _log('Storage Permission: $status, Video Permission: $videoStatus');
    }
    _scanForVideos();
    _initializeModel();
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
  
  void _log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final line = '[$timestamp] $message';
    debugPrint(line);
    DebugLogService().info(line);
    if (mounted) {
      setState(() {
        _logLines.add(line);
        if (_logLines.length > _maxLogLines) {
          _logLines.removeAt(0);
        }
      });
    }
  }
  
  Future<void> _scanForVideos() async {
    _log('Scanning for test videos...');
    final searchPaths = [
      '/sdcard/Download',
      '/sdcard/DCIM',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Movies',
    ];
    
    for (final basePath in searchPaths) {
      try {
        final dir = Directory(basePath);
        if (await dir.exists()) {
          await for (final entity in dir.list()) {
            if (entity is File && entity.path.toLowerCase().endsWith('.mp4')) {
              _availableVideos.add(entity.path);
            }
          }
        }
      } catch (e) {
        // skip
      }
    }
    
    if (_availableVideos.isEmpty) {
      _log('⚠️ No videos found! Push with: adb push TESTVIDEOS/testvideo.mp4 /sdcard/Download/');
      setState(() {
        _errorMessage = 'No test videos found.\n\nPush video with:\nadb push TESTVIDEOS/testvideo.mp4 /sdcard/Download/';
      });
    } else {
      _log('Found ${_availableVideos.length} video(s)');
      // Prioritize prefered video
      _selectedVideo = _availableVideos.firstWhere(
        (v) => v.toLowerCase().contains(_preferedVideo),
        orElse: () => _availableVideos.first,
      );
      _log('Selected: ${_selectedVideo!.split("/").last}');
      setState(() {});
      _loadVideo(_selectedVideo!);
    }
  }
  
  Future<void> _initializeModel() async {
    try {
      _log('Loading YOLO model...');
      _statusMessage = 'Loading YOLO model...';
      setState(() {});
      
      final modelPath = YoloModelConfig.modelPath;
      final localPath = await _copyAssetToLocal(modelPath);
      
      _objectDetector = YOLO(
        modelPath: localPath,
        task: YOLOTask.detect,
      );
      
      await _objectDetector!.loadModel();
      
      try {
        _classLabels = YoloModelConfig.customLabels.toList();
      } catch (e) {
        _log('Could not load labels: $e');
      }
      
      _log('✓ Model loaded successfully');
      
      setState(() {
        _isModelLoaded = true;
        _statusMessage = 'Model loaded. Select a video to test.';
      });
      
    } catch (e) {
      _log('✗ Model init failed: $e');
      setState(() {
        _errorMessage = 'Model load failed: $e';
      });
    }
  }
  
  Future<String> _copyAssetToLocal(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getApplicationDocumentsDirectory();
    final file = File('${tempDir.path}/${assetPath.split('/').last}');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }
  
  Future<void> _loadVideo(String videoPath) async {
    try {
      _log('Loading video: ${videoPath.split("/").last}');
      _statusMessage = 'Loading video...';
      setState(() {
        _isPaused = true;
      });
      
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(File(videoPath));
      await _videoController!.initialize();
      
      _trackerService.reset();
      _trackerState = TrackerState();
      _detectionsN.clear();
      
      final size = _videoController!.value.size;
      final duration = _videoController!.value.duration;
      _log('Video loaded: ${size.width.toInt()}x${size.height.toInt()}, ${duration.inSeconds}s');
      
      _frameCount = 0;
      _detectionFrames = 0;
      _classCounts.clear();
      
      setState(() {
        _statusMessage = 'Ready. Press Play to start detection.';
      });
      
    } catch (e) {
      _log('✗ Video load failed: $e');
      setState(() {
        _errorMessage = 'Video load failed: $e';
      });
    }
  }
  
  void _togglePlayPause() {
    if (_videoController == null || !_isModelLoaded) return;
    
    if (_isPaused) {
      _startProcessing();
    } else {
      _videoController!.pause();
      setState(() {
        _isPaused = true;
        _statusMessage = 'Paused at frame $_frameCount';
      });
    }
  }
  
  void _startProcessing() {
    if (_videoController == null) return;
    
    _log('Starting detection...');
    _fpsStartTime = DateTime.now();
    _fpsFrameCount = 0;
    
    _videoController!.play();
    
    setState(() {
      _isPaused = false;
      _statusMessage = 'Processing...';
    });
    
    _processLoop();
  }
  
  Future<void> _processLoop() async {
    while (mounted && !_isPaused && _videoController != null) {
      if (_videoController!.value.position >= _videoController!.value.duration) {
        _onProcessingComplete();
        return;
      }
      
      await _processCurrentFrame();
      
      // Small delay to keep UI responsive but maximize throughput
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }
  
  Future<void> _processCurrentFrame() async {
    if (_isProcessing || _objectDetector == null || _videoController == null || _selectedVideo == null) return;
    
    _isProcessing = true;
    
    try {
      _frameCount++;
      _fpsFrameCount++;
      
      final elapsed = DateTime.now().difference(_fpsStartTime).inMilliseconds;
      if (elapsed > 1000) {
        _currentFps = (_fpsFrameCount * 1000.0) / elapsed;
        _fpsFrameCount = 0;
        _fpsStartTime = DateTime.now();
      }
      
      // Process every frame!
      
      // Extract frame
      final int timestampMs = _videoController!.value.position.inMilliseconds;
      
      final Uint8List? frameData = await VideoThumbnail.thumbnailData(
        video: _selectedVideo!,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 320,
        maxHeight: 320,
        timeMs: timestampMs,
        quality: 50,
      );
      
      if (frameData != null) {
        // Offload heavy image processing to isolate
        final result = await compute(processImageInIsolate, ImageProcessInput(frameData: frameData));
        
        if (result != null) {
           _inferenceCount++;
           
           _inferenceWidth = result.width;
           _inferenceHeight = result.height;
           
           // Run YOLO
           final resultMap = await _objectDetector!.predict(
             result.inferenceInput,
             confidenceThreshold: 0.15,
             iouThreshold: 0.45,
           );
           
           final List<dynamic> boxes = resultMap['boxes'] as List<dynamic>? ?? [];
           
           // Convert to Normalized Detections (0..1)
           final List<Map<String, dynamic>> detectionsN = [];
           
           for (final item in boxes) {
             final Map<String, dynamic> boxMap = Map<String, dynamic>.from(item as Map);
             
             // Box relative to 640x640 letterboxed
             final double x1 = (boxMap['x1'] as num?)?.toDouble() ?? 0.0;
             final double y1 = (boxMap['y1'] as num?)?.toDouble() ?? 0.0;
             final double x2 = (boxMap['x2'] as num?)?.toDouble() ?? 0.0;
             final double y2 = (boxMap['y2'] as num?)?.toDouble() ?? 0.0;
             final double conf = (boxMap['confidence'] as num?)?.toDouble() ?? 0.0;
             String label = boxMap['class'] as String? ?? 'unknown';

             final int? idx = int.tryParse(label);
             if (idx != null && _classLabels.isNotEmpty && idx >= 0 && idx < _classLabels.length) {
               label = _classLabels[idx];
             }

             // Dynamic remapping for Model M8 debugging
             if (_swapClasses) {
               if (idx == 2) label = 'ball'; // Force Rim class to be Ball
             }

             // Normalize back to SOURCE VIDEO coordinates (undo letterbox)
             // result.padX, result.newW
             
             double vLeft = (x1 - result.padX) / result.newW;
             double vTop = (y1 - result.padY) / result.newH;
             double vRight = (x2 - result.padX) / result.newW;
             double vBottom = (y2 - result.padY) / result.newH;
             
             // Clamp
             vLeft = vLeft.clamp(0.0, 1.0);
             vTop = vTop.clamp(0.0, 1.0);
             vRight = vRight.clamp(0.0, 1.0);
             vBottom = vBottom.clamp(0.0, 1.0);
             
             detectionsN.add({
               'boxN': Rect.fromLTRB(vLeft, vTop, vRight, vBottom),
               'conf': conf,
               'tag': label,
               'index': idx ?? -1,
             });
             
             _classCounts[label] = (_classCounts[label] ?? 0) + 1;
           }
           
           // Process with Tracker Service
           final newState = _trackerService.processDetectionsNormalized(detectionsN);
           
           if (detectionsN.isNotEmpty) _detectionFrames++;
           
           if (mounted) {
             setState(() {
               _detectionsN = detectionsN;
               _trackerState = newState;
             });
           }
        }
      }
      
    } catch (e) {
      _log('Frame error: $e');
    } finally {
      _isProcessing = false;
    }
  }
  
  void _onProcessingComplete() {
    _log('Processing complete! Frames: $_frameCount');
    setState(() {
      _isPaused = true;
      _statusMessage = 'Complete!';
    });
  }
  
  void _restart() {
    if (_videoController != null) {
      _videoController!.seekTo(Duration.zero);
      _frameCount = 0;
      _detectionFrames = 0;
      _classCounts.clear();
      _detectionsN.clear();
      _trackerService.reset();
      _trackerState = TrackerState();
      _startProcessing();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('🎬 Video Test Mode (Normalized)'),
        backgroundColor: Colors.purple.shade900,
        actions: [
          if (_availableVideos.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.video_library),
              onSelected: (v) {
                _selectedVideo = v;
                _loadVideo(v);
              },
              itemBuilder: (context) => _availableVideos.map((v) => 
                PopupMenuItem(value: v, child: Text(v.split('/').last))
              ).toList(),
            ),
        ],
      ),
      body: Row(
        children: [
          // Left: Video + Controls
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Video preview
                Expanded(
                  child: Container(
                    color: Colors.grey.shade900,
                    child: _videoController?.value.isInitialized == true
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              // Use the actual video size as the "source"
                              final srcSize = _videoController!.value.size;
                              
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Video Player (BoxFit.contain usually by default)
                                  // We explicitly use FittedBox closely matching standard behavior
                                  // But easier: VideoPlayer handles its own aspect ratio
                                  // Actually, we want EXACTLY what ViewportMapper expects.
                                  // Standard VideoPlayer in Center() behaves like contain.
                                  // Let's force it to cover or contain to match our mapper.
                                  // Since users usually want to see the whole video in test mode,
                                  // let's use Contain.
                                  
                                  FittedBox(
                                    fit: BoxFit.contain,
                                    child: SizedBox(
                                      width: srcSize.width,
                                      height: srcSize.height,
                                      child: VideoPlayer(_videoController!),
                                    ),
                                  ),
                                  
                                  // TrackerPainter Overlay
                                  CustomPaint(
                                    painter: TrackerPainter(
                                      state: _trackerState,
                                      rawDetectionsN: _detectionsN,
                                      srcSize: srcSize, // Pass dynamic video size
                                      boxFit: BoxFit.contain, // Match FittedBox
                                      showDebug: _showDebug, // Toggle debug view
                                    ),
                                    // Make sure CustomPaint fills the constraints so ViewportMapper uses full area
                                    size: Size.infinite,
                                  ),
                                ],
                              );
                            },
                          )
                        : Center(
                            child: _errorMessage != null
                                ? Text(_errorMessage!, style: const TextStyle(color: Colors.red))
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(),
                                      const SizedBox(height: 16),
                                      Text(_statusMessage, style: const TextStyle(color: Colors.white70)),
                                    ],
                                  ),
                          ),
                  ),
                ),
                
                // Controls
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.black,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isModelLoaded && _videoController != null ? _togglePlayPause : null,
                        icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                        label: Text(_isPaused ? 'Play' : 'Pause'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _swapClasses = !_swapClasses),
                        icon: const Icon(Icons.swap_horiz),
                        label: Text(_swapClasses ? 'Map: 2->Ball' : 'Map: Std'),
                        style: ElevatedButton.styleFrom(backgroundColor: _swapClasses ? Colors.purple : Colors.grey),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showDebug = !_showDebug;
                          });
                        },
                        icon: Icon(_showDebug ? Icons.visibility : Icons.visibility_off),
                        label: Text(_showDebug ? 'Hide Debug' : 'Show Debug'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                      ),
                      ElevatedButton.icon(
                        onPressed: _videoController != null ? _restart : null,
                        icon: const Icon(Icons.replay),
                        label: const Text('Restart'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Right: Stats + Log
          Container(
            width: 350,
            color: Colors.grey.shade900,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats panel (updated for tracker info)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.black54,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tracker Status:', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Rim: ${_trackerState.lockedRimN != null ? "LOCKED" : "Searching..."}',
                        style: TextStyle(color: _trackerState.lockedRimN != null ? Colors.blue : Colors.orange),
                      ),
                      Text(
                        'Mode: ${_trackerState.isRoiMode ? "ROI TRACKING" : "GLOBAL SEARCH"}',
                        style: TextStyle(color: _trackerState.isRoiMode ? Colors.yellow : Colors.white),
                      ),
                      const Divider(color: Colors.grey),
                      Text(
                        'Success Rate: ${_inferenceCount > 0 ? (_detectionFrames / _inferenceCount * 100).toStringAsFixed(1) : "0.0"}%',
                        style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Frame: $_frameCount | FPS: ${_currentFps.toStringAsFixed(1)}',
                        style: const TextStyle(color: Colors.cyan),
                      ),
                      Text(
                         'Detections: ${_detectionsN.length}',
                         style: const TextStyle(color: Colors.greenAccent),
                      ),
                    ],
                  ),
                ),
                
                // Log panel
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _logLines.length,
                    itemBuilder: (context, index) {
                      final line = _logLines[index];
                      Color color = Colors.white70;
                      if (line.contains('✓')) color = Colors.green;
                      if (line.contains('✗')) color = Colors.red;
                      return Text(line, style: TextStyle(color: color, fontSize: 11, fontFamily: 'monospace'));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
