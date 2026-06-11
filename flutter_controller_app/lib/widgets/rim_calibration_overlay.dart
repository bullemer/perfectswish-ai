import 'package:flutter/material.dart';
import '../utils/rim_calibration.dart';

/// Overlay that lets the user tap the left and right rim posts.
/// Call [RimCalibrationOverlay.show] to push it as a modal route.
/// Returns the resulting [RimCalibration] when the user confirms, or null if cancelled.
class RimCalibrationOverlay extends StatefulWidget {
  const RimCalibrationOverlay({super.key});

  static Future<RimCalibration?> show(BuildContext context) {
    return Navigator.of(context).push<RimCalibration>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (_, __, ___) => const RimCalibrationOverlay(),
      ),
    );
  }

  @override
  State<RimCalibrationOverlay> createState() => _RimCalibrationOverlayState();
}

class _RimCalibrationOverlayState extends State<RimCalibrationOverlay> {
  Offset? _leftN;
  Offset? _rightN;

  void _onTap(TapUpDetails details, Size size) {
    final norm = Offset(
      details.localPosition.dx / size.width,
      details.localPosition.dy / size.height,
    );
    setState(() {
      if (_leftN == null) {
        _leftN = norm;
      } else if (_rightN == null) {
        // Always assign left = smaller X
        if (norm.dx < _leftN!.dx) {
          _rightN = _leftN;
          _leftN = norm;
        } else {
          _rightN = norm;
        }
      } else {
        // Third tap: reset and start over
        _leftN = norm;
        _rightN = null;
      }
    });
  }

  void _confirm() {
    if (_leftN == null || _rightN == null) return;
    final cal = RimCalibration(leftN: _leftN!, rightN: _rightN!);
    cal.save();
    Navigator.of(context).pop(cal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (_, constraints) {
          final size = constraints.biggest;
          return GestureDetector(
            onTapUp: (d) => _onTap(d, size),
            child: Stack(
              children: [
                // Instruction
                Positioned(
                  top: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _leftN == null
                            ? 'Tap the LEFT rim post'
                            : _rightN == null
                                ? 'Tap the RIGHT rim post'
                                : 'Tap again to reset   •   Press ✓ to confirm',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),

                // Draw tapped points + rim arc
                if (_leftN != null || _rightN != null)
                  CustomPaint(
                    size: size,
                    painter: _RimPainter(
                      leftN: _leftN,
                      rightN: _rightN,
                      size: size,
                    ),
                  ),

                // Confirm button
                if (_leftN != null && _rightN != null)
                  Positioned(
                    bottom: 40,
                    right: 40,
                    child: FloatingActionButton.extended(
                      heroTag: 'confirm_rim',
                      backgroundColor: Colors.deepOrange,
                      icon: const Icon(Icons.check),
                      label: const Text('Confirm Rim'),
                      onPressed: _confirm,
                    ),
                  ),

                // Cancel button
                Positioned(
                  bottom: 40,
                  left: 40,
                  child: FloatingActionButton.extended(
                    heroTag: 'cancel_rim',
                    backgroundColor: Colors.grey.shade800,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RimPainter extends CustomPainter {
  final Offset? leftN;
  final Offset? rightN;
  final Size size;

  _RimPainter({required this.leftN, required this.rightN, required this.size});

  Offset _toPixel(Offset n) =>
      Offset(n.dx * size.width, n.dy * size.height);

  @override
  void paint(Canvas canvas, Size _) {
    final dotPaint = Paint()..color = Colors.orange..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const dotRadius = 10.0;

    if (leftN != null) {
      canvas.drawCircle(_toPixel(leftN!), dotRadius, dotPaint);
    }
    if (rightN != null) {
      canvas.drawCircle(_toPixel(rightN!), dotRadius, dotPaint);
    }

    if (leftN != null && rightN != null) {
      final lPx = _toPixel(leftN!);
      final rPx = _toPixel(rightN!);

      // Horizontal rim line
      canvas.drawLine(lPx, rPx, linePaint);

      // Semi-ellipse showing the rim opening
      final cx = (lPx.dx + rPx.dx) / 2;
      final cy = (lPx.dy + rPx.dy) / 2;
      final rw = (rPx.dx - lPx.dx).abs() / 2;
      final rh = rw * 0.3; // flat ellipse for side-view

      final arcPaint = Paint()
        ..color = Colors.orange.withValues(alpha:0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, cy), width: rw * 2, height: rh * 2),
        3.14159, // start at π (left side)
        3.14159, // sweep π (top half)
        false,
        arcPaint,
      );

      // Center dot
      canvas.drawCircle(
        Offset(cx, cy),
        4,
        Paint()..color = Colors.yellow..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RimPainter old) =>
      old.leftN != leftN || old.rightN != rightN;
}
