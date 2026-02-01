import 'dart:math';
import 'package:flutter/material.dart';
import 'services/object_tracker_service.dart';

/// Visual debugger overlay for ObjectTracker
/// - Locked Rim: BLUE (thick lines)
/// - Raw YOLO Ball: RED (thin lines)
/// - Kalman Ball: GREEN (filled circle)
/// - ROI Window: YELLOW (dashed lines)
class TrackerPainter extends CustomPainter {
  final TrackerState state;
  final int imageWidth;
  final int imageHeight;
  final int rotationDegrees;

  TrackerPainter({
    required this.state,
    required this.imageWidth,
    required this.imageHeight,
    this.rotationDegrees = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Prevent division by zero
    if (imageWidth <= 0 || imageHeight <= 0) return;
    
    // Handle rotation: if 90 or 270 degrees, swap dimensions
    final bool swap = rotationDegrees == 90 || rotationDegrees == 270;
    final double contentWidth = swap ? imageHeight.toDouble() : imageWidth.toDouble();
    final double contentHeight = swap ? imageWidth.toDouble() : imageHeight.toDouble();
    
    // Scale factors for coordinate transformation
    final double scaleX = size.width / contentWidth;
    final double scaleY = size.height / contentHeight;

    // 1. Draw Locked Rim (BLUE, thick)
    if (state.lockedRim != null) {
      _drawRect(
        canvas,
        _scaleRect(state.lockedRim!, scaleX, scaleY),
        Colors.blue,
        strokeWidth: 4.0,
        label: "🔒 RIM LOCKED",
      );
    }

    // 2. Draw Raw YOLO Ball (RED, thin)
    if (state.lastBallRect != null) {
      _drawRect(
        canvas,
        _scaleRect(state.lastBallRect!, scaleX, scaleY),
        Colors.red,
        strokeWidth: 2.0,
        label: "YOLO",
      );
    }

    // 3. Draw Kalman Smoothed Ball (GREEN, filled circle)
    if (state.smoothedBallCenter != null) {
      final center = Offset(
        state.smoothedBallCenter!.dx * scaleX,
        state.smoothedBallCenter!.dy * scaleY,
      );
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

    // 4. Draw ROI Window (YELLOW, dashed)
    if (state.roiWindow != null && state.isRoiMode) {
      _drawDashedRect(
        canvas,
        _scaleRect(state.roiWindow!, scaleX, scaleY),
        Colors.yellow,
        strokeWidth: 2.0,
      );
    }
  }

  Rect _scaleRect(Rect rect, double scaleX, double scaleY) {
    return Rect.fromLTRB(
      rect.left * scaleX,
      rect.top * scaleY,
      rect.right * scaleX,
      rect.bottom * scaleY,
    );
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
      textPainter.paint(canvas, Offset(rect.left, rect.top - 18));
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

    // Draw each side with dashes
    _drawDashedLine(canvas, rect.topLeft, rect.topRight, paint, dashLength, gapLength);
    _drawDashedLine(canvas, rect.topRight, rect.bottomRight, paint, dashLength, gapLength);
    _drawDashedLine(canvas, rect.bottomRight, rect.bottomLeft, paint, dashLength, gapLength);
    _drawDashedLine(canvas, rect.bottomLeft, rect.topLeft, paint, dashLength, gapLength);

    // Label
    final textStyle = TextStyle(
      color: color,
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
    textPainter.paint(canvas, Offset(rect.left + 5, rect.top + 5));
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
    final length = sqrt(dx * dx + dy * dy);
    final unitX = dx / length;
    final unitY = dy / length;

    double drawn = 0;
    bool drawing = true;
    while (drawn < length) {
      final segmentLength = drawing ? dashLength : gapLength;
      final remaining = length - drawn;
      final actualLength = segmentLength < remaining ? segmentLength : remaining;

      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + unitX * drawn, start.dy + unitY * drawn),
          Offset(start.dx + unitX * (drawn + actualLength), start.dy + unitY * (drawn + actualLength)),
          paint,
        );
      }
      drawn += actualLength;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(covariant TrackerPainter oldDelegate) {
    // Only repaint if state or dimensions actually changed
    return oldDelegate.imageWidth != imageWidth ||
        oldDelegate.imageHeight != imageHeight ||
        oldDelegate.state.lockedRim != state.lockedRim ||
        oldDelegate.state.lastBallRect != state.lastBallRect ||
        oldDelegate.state.smoothedBallCenter != state.smoothedBallCenter ||
        oldDelegate.state.roiWindow != state.roiWindow ||
        oldDelegate.state.isRoiMode != state.isRoiMode;
  }
}
