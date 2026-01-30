import 'package:flutter/material.dart';

class YoloBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  final double imageWidth;
  final double imageHeight;

  YoloBoxPainter({
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty || imageWidth == 0 || imageHeight == 0) return;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0  // Thicker for visibility
      ..color = Colors.green;

    final Paint backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final TextStyle textStyle = TextStyle(
      color: Colors.white,
      fontSize: 18.0,  // Larger for visibility
      fontWeight: FontWeight.bold,
    );

    // Dimensions now come pre-swapped from CarTrackingScreen to match rotation
    final Size contentSize = Size(imageWidth, imageHeight);
    final Size layoutSize = size;

    // CameraPreview maintains aspect ratio and centers itself (BoxFit.contain behavior)
    // We need to calculate the same offset to align our boxes
    final double contentAspect = contentSize.width / contentSize.height; // 720/480 = 1.5
    final double layoutAspect = layoutSize.width / layoutSize.height;    // e.g., 2340/1080 = 2.17
    
    double scale;
    double offsetX = 0;
    double offsetY = 0;
    
    if (layoutAspect > contentAspect) {
      // Layout is wider than content - letterbox on sides
      scale = layoutSize.height / contentSize.height;
      double scaledWidth = contentSize.width * scale;
      offsetX = (layoutSize.width - scaledWidth) / 2;
    } else {
      // Layout is taller than content - letterbox on top/bottom
      scale = layoutSize.width / contentSize.width;
      double scaledHeight = contentSize.height * scale;
      offsetY = (layoutSize.height - scaledHeight) / 2;
    }

    for (var detection in detections) {
      final box = detection['box'];
      
      // Transform coordinates with offset
      double x1 = (box[0] * scale) + offsetX;
      double y1 = (box[1] * scale) + offsetY;
      double x2 = (box[2] * scale) + offsetX;
      double y2 = (box[3] * scale) + offsetY;

      final rect = Rect.fromLTRB(x1, y1, x2, y2);
      canvas.drawRect(rect, paint);
      
      // Distance estimation
      double height = y2 - y1;
      String distanceText = "";
      if (height > 300) {
        distanceText = " | NEAR";
      } else if (height < 100) {
        distanceText = " | FAR";
      }

      // Label drawing
      String label = "${detection['tag']} ${(box[4] * 100).toStringAsFixed(0)}%$distanceText";
      final TextSpan textSpan = TextSpan(text: label, style: textStyle);
      final TextPainter textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final double textX = x1;
      final double textY = y1 - textPainter.height - 4;

      canvas.drawRect(
        Rect.fromLTWH(textX - 2, textY - 2, textPainter.width + 4, textPainter.height + 4),
        backgroundPaint,
      );
      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint when detections change
  }
}
