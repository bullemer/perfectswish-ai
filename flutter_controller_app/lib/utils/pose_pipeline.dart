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
  
  // Pose pending flag pattern (same as YOLO - don't store CameraImage)
  bool _isProcessing = false;
  bool _posePending = false;
  int _pendingRotation = 0;
  bool _pendingIsFront = false;
  DateTime _lastInferenceTime = DateTime.now();
  
  // Target 15-20 FPS = 50-66ms between frames
  static const int _minIntervalMs = 50;
  
  PosePipeline({
    required this.onPosesDetected,
    PoseDetectorOptions? options,
  }) : _poseDetector = PoseDetector(
    options: options ?? PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base, // Use base for better performance
    ),
  );
  
  /// Queue a frame for processing. Uses pending-flag pattern (no CameraImage storage).
  void processFrame(CameraImage image, int rotationDegrees, bool isFrontCamera) {
    // Throttle to target FPS
    final now = DateTime.now();
    final elapsed = now.difference(_lastInferenceTime).inMilliseconds;
    if (elapsed < _minIntervalMs) return;
    
    if (_isProcessing) {
      // Mark pending but DON'T store the CameraImage (buffers are reused!)
      _posePending = true;
      _pendingRotation = rotationDegrees;
      _pendingIsFront = isFrontCamera;
      return;
    }
    
    _processFrame(image, rotationDegrees, isFrontCamera);
  }
  
  void _processFrame(CameraImage frame, int rotation, bool isFront) async {
    _isProcessing = true;
    _posePending = false;
    _lastInferenceTime = DateTime.now();
    
    try {
      final inputImage = _convertCameraImageToInputImage(frame, rotation);
      if (inputImage != null) {
        final poses = await _poseDetector.processImage(inputImage);
        onPosesDetected(poses, frame.width, frame.height, rotation, isFront);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PosePipeline] Error processing frame: $e');
      }
    } finally {
      _isProcessing = false;
      // Pending flag handled by next incoming frame from stream
      // No recursive call needed - processFrame will be called again by camera stream
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
