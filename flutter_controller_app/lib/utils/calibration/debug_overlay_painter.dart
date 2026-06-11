/// Debug overlay painter for calibration visualization.
///
/// Renders court lines, detected lines, and calibration info.

import 'dart:math' show cos, sin;

import 'package:flutter/material.dart';

import 'calibration_manager.dart';
import 'court_spaces.dart';

/// Painter for calibration debug overlays.
class CalibrationDebugPainter extends CustomPainter {
  final CalibrationManager calibration;
  final List<LineSegment>? detectedLines;
  final List<CornerPoint>? corners;
  final bool showCourtLines;
  final bool showDetectedLines;
  final bool showCorners;
  final bool showScaleInfo;

  CalibrationDebugPainter({
    required this.calibration,
    this.detectedLines,
    this.corners,
    this.showCourtLines = true,
    this.showDetectedLines = true,
    this.showCorners = true,
    this.showScaleInfo = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showDetectedLines && detectedLines != null) {
      _drawDetectedLines(canvas, detectedLines!);
    }

    if (showCourtLines && calibration.hasFloorHomography) {
      _drawCourtLines(canvas);
    }

    if (showCorners && corners != null) {
      _drawCorners(canvas, corners!);
    }

    if (showScaleInfo && calibration.hasVisualScale) {
      _drawScaleInfo(canvas, size);
    }

    // Always draw rim center if available
    final rimCenter = calibration.activeProfile?.rimCenter;
    if (rimCenter != null) {
      _drawRimMarker(canvas, rimCenter);
    }
  }

  void _drawDetectedLines(Canvas canvas, List<LineSegment> lines) {
    final paint = Paint()
      ..color = Colors.yellow.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final line in lines) {
      canvas.drawLine(
        Offset(line.p1.x, line.p1.y),
        Offset(line.p2.x, line.p2.y),
        paint,
      );
    }
  }

  void _drawCourtLines(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw lane boundaries
    _drawCourtLine(canvas, paint,
        from: CourtPoint(-CourtConstants.laneWidthMeters / 2, 0),
        to: CourtPoint(-CourtConstants.laneWidthMeters / 2,
            CourtConstants.rimToFreeThrowMeters));

    _drawCourtLine(canvas, paint,
        from: CourtPoint(CourtConstants.laneWidthMeters / 2, 0),
        to: CourtPoint(CourtConstants.laneWidthMeters / 2,
            CourtConstants.rimToFreeThrowMeters));

    // Draw free-throw line
    _drawCourtLine(canvas, paint,
        from: CourtPoint(-CourtConstants.laneWidthMeters / 2,
            CourtConstants.rimToFreeThrowMeters),
        to: CourtPoint(CourtConstants.laneWidthMeters / 2,
            CourtConstants.rimToFreeThrowMeters));

    // Draw 3-point arc (approximate with line segments)
    _draw3PointArc(canvas, paint);
  }

  void _drawCourtLine(Canvas canvas, Paint paint,
      {required CourtPoint from, required CourtPoint to}) {
    final p1 = calibration.floorMetricToPixel(from);
    final p2 = calibration.floorMetricToPixel(to);

    if (p1 != null && p2 != null) {
      canvas.drawLine(
        Offset(p1.x, p1.y),
        Offset(p2.x, p2.y),
        paint,
      );
    }
  }

  void _draw3PointArc(Canvas canvas, Paint paint) {
    const segments = 20;
    const radius = CourtConstants.threePointDistanceFibaMeters;

    final points = <Offset>[];
    for (var i = 0; i <= segments; i++) {
      final angle = -3.14159 / 2 + (3.14159) * i / segments;
      final court = CourtPoint(
        radius * cos(angle),
        radius * sin(angle).abs(), // Only positive Y (in front of basket)
      );
      final pixel = calibration.floorMetricToPixel(court);
      if (pixel != null) {
        points.add(Offset(pixel.x, pixel.y));
      }
    }

    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint..color = Colors.orange.withOpacity(0.6));
    }
  }

  void _drawCorners(Canvas canvas, List<CornerPoint> cornersList) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final corner in cornersList) {
      // Draw corner point
      canvas.drawCircle(
        Offset(corner.pixelPos.x, corner.pixelPos.y),
        6,
        paint,
      );

      // Draw label
      textPainter.text = TextSpan(
        text: corner.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          backgroundColor: Colors.black54,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(corner.pixelPos.x + 8, corner.pixelPos.y - 5),
      );
    }
  }

  void _drawScaleInfo(Canvas canvas, Size size) {
    final snapshot = calibration.debugSnapshot();

    final info = [
      'Scale: ${snapshot.pixelsPerMeterAtHoop?.toStringAsFixed(1) ?? "?"} px/m',
      'Type: ${snapshot.calibrationType ?? "?"}',
      if (snapshot.reprojectionError != null)
        'Error: ${snapshot.reprojectionError!.toStringAsFixed(2)}px',
      if (snapshot.gymName != null) 'Gym: ${snapshot.gymName}',
    ];

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    var y = 10.0;
    for (final line in info) {
      textPainter.text = TextSpan(
        text: line,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          backgroundColor: Colors.black87,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(10, y));
      y += 16;
    }
  }

  void _drawRimMarker(Canvas canvas, (double, double) rimCenter) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw crosshair at rim center
    const size = 15.0;
    canvas.drawLine(
      Offset(rimCenter.$1 - size, rimCenter.$2),
      Offset(rimCenter.$1 + size, rimCenter.$2),
      paint,
    );
    canvas.drawLine(
      Offset(rimCenter.$1, rimCenter.$2 - size),
      Offset(rimCenter.$1, rimCenter.$2 + size),
      paint,
    );

    // Draw rim diameter circle if available
    final diameter = calibration.activeProfile?.rimDiameterPx;
    if (diameter != null) {
      canvas.drawCircle(
        Offset(rimCenter.$1, rimCenter.$2),
        diameter / 2,
        paint..color = Colors.red.withOpacity(0.5),
      );
    }
  }

  @override
  bool shouldRepaint(CalibrationDebugPainter oldDelegate) {
    return true; // Always repaint for live debug
  }
}
