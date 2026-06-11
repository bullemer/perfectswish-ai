import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// CustomPainter for rendering skeleton overlay on camera preview.
class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final int imageWidth;
  final int imageHeight;
  final int rotationDegrees;
  final bool isFrontCamera;
  final Map<PoseLandmarkType, (double, double)>? filteredLandmarks;
  final Map<String, double>? jointAngles;
  
  PosePainter({
    required this.poses,
    required this.imageWidth,
    required this.imageHeight,
    required this.rotationDegrees,
    required this.isFrontCamera,
    this.filteredLandmarks,
    this.jointAngles,
  });

  /// Transform image coordinates to screen coordinates.
  /// 
  /// ML Kit returns landmarks in the original image coordinate space.
  /// CameraPreview applies rotation to display correctly.
  /// We must:
  ///   1. Rotate landmark coords to match preview orientation
  ///   2. Apply BoxFit.contain scaling with letterbox offsets
  ///   3. Mirror for front camera if needed
  Offset _transformPoint(double x, double y, Size size) {
    // Step 1: ROTATE landmarks to match CameraPreview's rotation
    // This transforms from image space to display space
    double rx = x, ry = y;
    switch (rotationDegrees) {
      case 90:
        // Android back camera typically has 90° sensor rotation
        // Rotate 90° counter-clockwise to match display
        rx = imageHeight - y;
        ry = x;
        break;
      case 180:
        rx = imageWidth - x;
        ry = imageHeight - y;
        break;
      case 270:
        // 270° = 90° clockwise
        rx = y;
        ry = imageWidth - x;
        break;
      default: // 0
        break;
    }
    
    // Step 2: Calculate content dimensions AFTER rotation
    final bool swap = rotationDegrees == 90 || rotationDegrees == 270;
    final double contentWidth = swap ? imageHeight.toDouble() : imageWidth.toDouble();
    final double contentHeight = swap ? imageWidth.toDouble() : imageHeight.toDouble();
    
    // Step 3: BoxFit.contain scaling (matches CameraPreview letterboxing)
    final double contentAspect = contentWidth / contentHeight;
    final double layoutAspect = size.width / size.height;
    
    double scale;
    double offsetX = 0;
    double offsetY = 0;
    
    if (layoutAspect > contentAspect) {
      // Layout is wider than content - letterbox on sides
      scale = size.height / contentHeight;
      offsetX = (size.width - contentWidth * scale) / 2;
    } else {
      // Layout is taller than content - letterbox on top/bottom
      scale = size.width / contentWidth;
      offsetY = (size.height - contentHeight * scale) / 2;
    }
    
    double dx = (rx * scale) + offsetX;
    double dy = (ry * scale) + offsetY;
    
    // Step 4: Mirror for front camera (CameraPreview mirrors front camera)
    if (isFrontCamera) {
      dx = size.width - dx;
    }
    
    return Offset(dx, dy);
  }
  
  // Skeleton bone connections
  static const List<(PoseLandmarkType, PoseLandmarkType)> _bones = [
    // Face
    (PoseLandmarkType.leftEar, PoseLandmarkType.leftEye),
    (PoseLandmarkType.rightEar, PoseLandmarkType.rightEye),
    (PoseLandmarkType.leftEye, PoseLandmarkType.nose),
    (PoseLandmarkType.rightEye, PoseLandmarkType.nose),
    // Torso
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
    // Left Arm
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
    (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
    // Right Arm
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
    (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
    // Left Leg
    (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
    (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
    // Right Leg
    (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
    (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
  ];
  
  // Joints that we filter and display angles for
  static const Set<PoseLandmarkType> _filteredJoints = {
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
  };
  
  // Static paint objects to avoid recreating every frame
  static final Paint _bonePaint = Paint()
    ..color = Colors.greenAccent
    ..strokeWidth = 3.0
    ..style = PaintingStyle.stroke;
  
  static final Paint _jointPaint = Paint()
    ..color = Colors.orange
    ..style = PaintingStyle.fill;
  
  static final Paint _filteredJointPaint = Paint()
    ..color = Colors.cyan
    ..style = PaintingStyle.fill;
  
  static const TextStyle _textStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.bold,
    shadows: [Shadow(color: Colors.black, blurRadius: 2)],
  );
  
  @override
  void paint(Canvas canvas, Size size) {
    if (poses.isEmpty) return;
    
    for (final pose in poses) {
      // Draw bones
      for (final bone in _bones) {
        final p1 = pose.landmarks[bone.$1];
        final p2 = pose.landmarks[bone.$2];
        if (p1 != null && p2 != null && p1.likelihood > 0.5 && p2.likelihood > 0.5) {
          final start = _transformPoint(p1.x, p1.y, size);
          final end = _transformPoint(p2.x, p2.y, size);
          canvas.drawLine(start, end, _bonePaint);
        }
      }
      
      // Draw joints
      for (final entry in pose.landmarks.entries) {
        final landmark = entry.value;
        if (landmark.likelihood < 0.5) continue;
        
        final isFiltered = _filteredJoints.contains(entry.key);
        final paint = isFiltered ? _filteredJointPaint : _jointPaint;
        final radius = isFiltered ? 8.0 : 5.0;
        
        // Use filtered coordinates if available
        Offset point;
        if (isFiltered && filteredLandmarks != null && filteredLandmarks!.containsKey(entry.key)) {
          final filtered = filteredLandmarks![entry.key]!;
          point = _transformPoint(filtered.$1, filtered.$2, size);
        } else {
          point = _transformPoint(landmark.x, landmark.y, size);
        }
        
        canvas.drawCircle(point, radius, paint);
      }
      
      // Draw joint angles
      if (jointAngles != null) {
        _drawAngleLabel(canvas, pose, PoseLandmarkType.leftElbow, 'L Elbow', jointAngles!['leftElbow'], size, _textStyle);
        _drawAngleLabel(canvas, pose, PoseLandmarkType.rightElbow, 'R Elbow', jointAngles!['rightElbow'], size, _textStyle);
        _drawAngleLabel(canvas, pose, PoseLandmarkType.leftKnee, 'L Knee', jointAngles!['leftKnee'], size, _textStyle);
        _drawAngleLabel(canvas, pose, PoseLandmarkType.rightKnee, 'R Knee', jointAngles!['rightKnee'], size, _textStyle);
      }
    }
  }
  
  void _drawAngleLabel(Canvas canvas, Pose pose, PoseLandmarkType type, String label, double? angle, Size size, TextStyle style) {
    if (angle == null) return;
    final landmark = pose.landmarks[type];
    if (landmark == null || landmark.likelihood < 0.5) return;
    
    final point = _transformPoint(landmark.x, landmark.y, size);
    final textSpan = TextSpan(text: '${angle.toInt()}°', style: style);
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, Offset(point.dx + 10, point.dy - 5));
  }
  
  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.poses != poses || 
           oldDelegate.filteredLandmarks != filteredLandmarks ||
           oldDelegate.jointAngles != jointAngles;
  }
}

