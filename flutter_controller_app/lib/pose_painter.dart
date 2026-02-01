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
  /// Uses BoxFit.contain logic to match CameraPreview's letterboxing behavior.
  Offset _transformPoint(double x, double y, Size size) {
    // Determine effective content dimensions based on rotation
    // If rotation is 90 or 270, the image dimensions are swapped relative to display
    final bool swap = rotationDegrees == 90 || rotationDegrees == 270;
    final double contentWidth = swap ? imageHeight.toDouble() : imageWidth.toDouble();
    final double contentHeight = swap ? imageWidth.toDouble() : imageHeight.toDouble();
    
    // Calculate aspect ratios for BoxFit.contain
    final double contentAspect = contentWidth / contentHeight;
    final double layoutAspect = size.width / size.height;
    
    double scale;
    double offsetX = 0;
    double offsetY = 0;
    
    if (layoutAspect > contentAspect) {
      // Layout is wider than content - letterbox on sides
      scale = size.height / contentHeight;
      double scaledWidth = contentWidth * scale;
      offsetX = (size.width - scaledWidth) / 2;
    } else {
      // Layout is taller than content - letterbox on top/bottom
      scale = size.width / contentWidth;
      double scaledHeight = contentHeight * scale;
      offsetY = (size.height - scaledHeight) / 2;
    }
    
    // Scale and offset the coordinates
    double dx = (x * scale) + offsetX;
    double dy = (y * scale) + offsetY;
    
    // Mirror for front camera
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
  
  @override
  void paint(Canvas canvas, Size size) {
    if (poses.isEmpty) return;
    
    final bonePaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    
    final jointPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;
    
    final filteredJointPaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;
    
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      shadows: [Shadow(color: Colors.black, blurRadius: 2)],
    );
    
    for (final pose in poses) {
      // Draw bones
      for (final bone in _bones) {
        final p1 = pose.landmarks[bone.$1];
        final p2 = pose.landmarks[bone.$2];
        if (p1 != null && p2 != null && p1.likelihood > 0.5 && p2.likelihood > 0.5) {
          final start = _transformPoint(p1.x, p1.y, size);
          final end = _transformPoint(p2.x, p2.y, size);
          canvas.drawLine(start, end, bonePaint);
        }
      }
      
      // Draw joints
      for (final entry in pose.landmarks.entries) {
        final landmark = entry.value;
        if (landmark.likelihood < 0.5) continue;
        
        final isFiltered = _filteredJoints.contains(entry.key);
        final paint = isFiltered ? filteredJointPaint : jointPaint;
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
        _drawAngleLabel(canvas, pose, PoseLandmarkType.leftElbow, 'L Elbow', jointAngles!['leftElbow'], size, textStyle);
        _drawAngleLabel(canvas, pose, PoseLandmarkType.rightElbow, 'R Elbow', jointAngles!['rightElbow'], size, textStyle);
        _drawAngleLabel(canvas, pose, PoseLandmarkType.leftKnee, 'L Knee', jointAngles!['leftKnee'], size, textStyle);
        _drawAngleLabel(canvas, pose, PoseLandmarkType.rightKnee, 'R Knee', jointAngles!['rightKnee'], size, textStyle);
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

