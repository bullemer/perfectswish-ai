import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'services/object_tracker_service.dart';
import 'utils/viewport_mapper.dart';

/// Visual debugger overlay for ObjectTracker
/// Expects TrackerState with NORMALIZED coordinates (0..1)
/// Uses ViewportMapper for correct coordinate conversion
class TrackerPainter extends CustomPainter {
  final TrackerState state;
  final List<Map<String, dynamic>>? rawDetectionsN;
  
  // Camera source size (portrait sensor) - should match YOLOView's camera
  // Defaults to 480x640 (portrait) but can be overridden for Video Test Mode
  final Size srcSize;
  final BoxFit boxFit;
  final bool showDebug;

  TrackerPainter({
    required this.state,
    this.rawDetectionsN,
    this.srcSize = const Size(480, 640),
    this.boxFit = BoxFit.cover,
    this.showDebug = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create mapper using Flutter's applyBoxFit
    final m = ViewportMapper(
      src: srcSize,
      dst: size,
      fit: boxFit, // Use provided fit param
    );
    
    // Helper to draw clipped rects (cover crop can push boxes out of view)
    void drawClippedRect(Rect boxN, Color color, {double strokeWidth = 2.0, String? label}) {
      final boxPx = m.srcNormToDst(boxN);
      final clipped = boxPx.intersect(Offset.zero & size);
      if (clipped.isEmpty || clipped.width < 2 || clipped.height < 2) return;
      
      _drawRect(canvas, clipped, color, strokeWidth: strokeWidth, label: label);
    }
    
    // 1. Draw Locked Rim (BLUE, thick)
    if (state.lockedRimN != null) {
      drawClippedRect(state.lockedRimN!, Colors.blue, strokeWidth: 4.0, label: "🔒 RIM");
    }

    // 2. Draw Raw YOLO Ball (RED, thin) - ONLY IN DEBUG
    if (showDebug && state.lastBallRectN != null) {
      drawClippedRect(state.lastBallRectN!, Colors.red, strokeWidth: 2.0, label: "YOLO");
    }

    // 3. Draw Kalman Smoothed Ball (GREEN, filled circle)
    if (state.smoothedBallCenterN != null) {
      final center = m.srcNormPointToDst(state.smoothedBallCenterN!);
      
      // Only draw if visible
      if (center.dx >= 0 && center.dx <= size.width &&
          center.dy >= 0 && center.dy <= size.height) {
        final paint = Paint()
          ..color = Colors.green
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, 15.0, paint);

        // Draw crosshair
        final crossPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 2.0;
        canvas.drawLine(
          Offset(center.dx - 20, center.dy),
          Offset(center.dx + 20, center.dy),
          crossPaint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - 20),
          Offset(center.dx, center.dy + 20),
          crossPaint,
        );
      }
    }

    // 4. Draw ROI Window (YELLOW, dashed)
    if (state.roiWindowN != null && state.isRoiMode) {
      final roiPx = m.srcNormToDst(state.roiWindowN!);
      final clipped = roiPx.intersect(Offset.zero & size);
      if (!clipped.isEmpty && clipped.width > 2 && clipped.height > 2) {
        _drawDashedRect(canvas, clipped, Colors.yellow, strokeWidth: 2.0);
        
        final textStyle = TextStyle(
          color: Colors.yellow,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        );
        final textSpan = TextSpan(text: "ROI", style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(clipped.left, math.max(clipped.top - 16, 0)));
      }
    }

    // 5. Draw raw detections (for debugging) - ONLY IN DEBUG
    if (showDebug && rawDetectionsN != null) {
      for (final d in rawDetectionsN!) {
        final boxN = d['boxN'] as Rect?;
        final conf = d['conf'] as double? ?? 0.0;
        final tag = d['tag'] as String? ?? '';
        
        // Filter noise for cleaner visualization
        if (boxN != null && conf > 0.35) {
          drawClippedRect(
            boxN, 
            Colors.cyan.withOpacity(0.7), 
            strokeWidth: 1.5,
            label: "$tag ${(conf * 100).toStringAsFixed(0)}%",
          );
        }
      }
    }
  }

  void _drawRect(
    Canvas canvas,
    Rect rect,
    Color color, {
    double strokeWidth = 2.0,
    String? label,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRect(rect, paint);

    if (label != null) {
      final textStyle = TextStyle(
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: Colors.black, blurRadius: 2)],
      );
      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left, math.max(rect.top - 18, 0)));
    }
  }

  void _drawDashedRect(
    Canvas canvas,
    Rect rect,
    Color color, {
    double strokeWidth = 2.0,
    double dashLength = 10.0,
    double gapLength = 5.0,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    _drawDashedLine(canvas, rect.topLeft, rect.topRight, paint, dashLength, gapLength);
    _drawDashedLine(canvas, rect.topRight, rect.bottomRight, paint, dashLength, gapLength);
    _drawDashedLine(canvas, rect.bottomRight, rect.bottomLeft, paint, dashLength, gapLength);
    _drawDashedLine(canvas, rect.bottomLeft, rect.topLeft, paint, dashLength, gapLength);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashLength,
    double gapLength,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length == 0) return;
    
    final unitDx = dx / length;
    final unitDy = dy / length;

    double currentDist = 0;
    bool drawing = true;

    while (currentDist < length) {
      final segmentLength = drawing ? dashLength : gapLength;
      final segmentEnd = currentDist + segmentLength > length
          ? length
          : currentDist + segmentLength;

      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + currentDist * unitDx, start.dy + currentDist * unitDy),
          Offset(start.dx + segmentEnd * unitDx, start.dy + segmentEnd * unitDy),
          paint,
        );
      }

      currentDist = segmentEnd;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(covariant TrackerPainter oldDelegate) => true;
}
