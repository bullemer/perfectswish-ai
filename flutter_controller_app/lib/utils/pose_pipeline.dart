import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// PosePipeline handles throttled pose inference with a latest-frame-wins buffer.
/// This prevents backpressure by dropping intermediate frames.
class PosePipeline {
  final PoseDetector _poseDetector;
  final void Function(List<Pose> poses, int imageWidth, int imageHeight, int sensorOrientation, bool isFrontCamera) onPosesDetected;
  
  bool _isProcessing = false;
  CameraImage? _latestFrame;
  int? _latestRotation;
  bool _isFrontCamera = false;
  DateTime _lastInferenceTime = DateTime.now();
  
  // Target 15-20 FPS = 50-66ms between frames
  static const int _minIntervalMs = 50;
  
  PosePipeline({
    required this.onPosesDetected,
    PoseDetectorOptions? options,
  }) : _poseDetector = PoseDetector(
    options: options ?? PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );
  
  /// Queue a frame for processing. Uses latest-frame-wins strategy.
  void processFrame(CameraImage image, int rotationDegrees, bool isFrontCamera) {
    _latestFrame = image;
    _latestRotation = rotationDegrees;
    _isFrontCamera = isFrontCamera;
    
    _tryProcessLatestFrame();
  }
  
  void _tryProcessLatestFrame() async {
    if (_isProcessing) return;
    if (_latestFrame == null) return;
    
    // Throttle to target FPS
    final now = DateTime.now();
    final elapsed = now.difference(_lastInferenceTime).inMilliseconds;
    if (elapsed < _minIntervalMs) return;
    
    _isProcessing = true;
    _lastInferenceTime = now;
    
    // Grab the frame and clear buffer (latest-frame-wins)
    final frame = _latestFrame!;
    final rotation = _latestRotation!;
    final isFront = _isFrontCamera;
    _latestFrame = null;
    
    try {
      final inputImage = _convertCameraImageToInputImage(frame, rotation);
      if (inputImage != null) {
        final poses = await _poseDetector.processImage(inputImage);
        onPosesDetected(poses, frame.width, frame.height, rotation, isFront);
      }
    } catch (e) {
      debugPrint('[PosePipeline] Error processing frame: $e');
    } finally {
      _isProcessing = false;
      // Check if new frame arrived while processing
      if (_latestFrame != null) {
        _tryProcessLatestFrame();
      }
    }
  }
  
  InputImage? _convertCameraImageToInputImage(CameraImage image, int sensorOrientation) {
    final inputImageRotation = _rotationFromInt(sensorOrientation);
    if (inputImageRotation == null) return null;
    
    // Get the image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    
    // Use WriteBuffer for efficient byte concatenation (avoids multiple list copies)
    final WriteBuffer allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: inputImageRotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }
  
  InputImageRotation? _rotationFromInt(int rotation) {
    switch (rotation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return null;
    }
  }
  
  Future<void> dispose() async {
    await _poseDetector.close();
  }
}
