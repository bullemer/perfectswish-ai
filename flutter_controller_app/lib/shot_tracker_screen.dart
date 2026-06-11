import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:ultralytics_yolo/yolo_performance_metrics.dart';
import 'package:permission_handler/permission_handler.dart';

import 'utils/ball_kalman_filter.dart';
import 'utils/rim_calibration.dart';
import 'utils/make_miss_detector.dart';
import 'widgets/rim_calibration_overlay.dart';

class ShotTrackerScreen extends StatefulWidget {
  final String? title;
  const ShotTrackerScreen({super.key, this.title});

  @override
  State<ShotTrackerScreen> createState() => _ShotTrackerScreenState();
}

class _ShotTrackerScreenState extends State<ShotTrackerScreen>
    with WidgetsBindingObserver {
  final YOLOViewController _yoloController = YOLOViewController();

  // Core tracking components
  final BallKalmanFilter _kalman = BallKalmanFilter(
    qPos: 1e-4,
    qVel: 5e-4,
    rPos: 3e-3,
    gravityNps2: 9.8,
  );
  final MakeMissDetector _detector = MakeMissDetector();
  RimCalibration? _rim;

  // Stats
  int _makes = 0;
  int _misses = 0;
  List<ShotResult> _recentShots = [];

  // Ball display
  Offset? _ballN;       // current smoothed ball position (normalized)
  double _currentFps = 0;
  int _detectionCount = 0;

  // Timing
  int _lastFrameMs = 0;

  // Feedback flash
  ShotResult? _flashResult;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRimCalibration();
    _initCamera();
  }

  Future<void> _loadRimCalibration() async {
    final rim = await RimCalibration.load();
    if (mounted) setState(() => _rim = rim);
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (var i = 0; i < 50; i++) {
        if (_yoloController.isInitialized) break;
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_yoloController.isInitialized) {
        try {
          await _yoloController.setStreamingConfig(
            YOLOStreamingConfig.custom(
              includeDetections: true,
              includeFps: true,
              includeProcessingTimeMs: true,
            ),
          );
        } catch (e) {
          debugPrint('Config error: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flashTimer?.cancel();
    super.dispose();
  }

  // ── YOLO callbacks ──────────────────────────────────────────────

  void _onYoloResult(List<YOLOResult> results) {
    if (!mounted) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final dtSeconds = _lastFrameMs == 0
        ? 0.033
        : (nowMs - _lastFrameMs) / 1000.0;
    _lastFrameMs = nowMs;

    // Find ball detection (highest confidence)
    YOLOResult? bestBall;
    for (final r in results) {
      final tag = r.className.toLowerCase();
      if (tag == 'basketball' || tag == 'ball' || tag == 'sports ball') {
        if (bestBall == null || r.confidence > bestBall.confidence) {
          bestBall = r;
        }
      }
    }

    final ballVisible = bestBall != null && bestBall.confidence > 0.30;
    double mx = 0, my = 0;

    if (bestBall != null) {
      final b = bestBall.normalizedBox;
      mx = b.center.dx;
      my = b.center.dy;
      _kalman.update(mx, my, dtSeconds);
    } else {
      _kalman.predict(dtSeconds);
    }

    final kx = _kalman.x;
    final ky = _kalman.y;

    // Run make/miss detector if rim is calibrated
    ShotResult? result;
    if (_rim != null) {
      result = _detector.update(
        ballVisible: ballVisible || _kalman.isInitialized,
        ballX: kx,
        ballY: ky,
        ballVx: _kalman.vx,
        ballVy: _kalman.vy,
        rim: _rim!,
      );
    }

    setState(() {
      _ballN = _kalman.isInitialized ? Offset(kx, ky) : null;
      _detectionCount = results.length;

      if (result != null) {
        if (result == ShotResult.make) {
          _makes++;
        } else {
          _misses++;
        }
        _recentShots = [result, ..._recentShots].take(10).toList();
        _showFlash(result);
      }
    });
  }

  void _onPerformanceMetrics(YOLOPerformanceMetrics m) {
    if (mounted) setState(() => _currentFps = m.fps);
  }

  // ── Rim calibration ──────────────────────────────────────────────

  Future<void> _startRimCalibration() async {
    final cal = await RimCalibrationOverlay.show(context);
    if (cal != null && mounted) {
      _detector.reset();
      _kalman.reset();
      setState(() => _rim = cal);
    }
  }

  // ── Flash feedback ───────────────────────────────────────────────

  void _showFlash(ShotResult result) {
    _flashTimer?.cancel();
    _flashResult = result;
    _flashTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _flashResult = null);
    });
  }

  // ── UI ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (_, constraints) {
          final size = constraints.biggest;
          return Stack(
            children: [
              // Camera + YOLO
              SizedBox(
                width: size.width,
                height: size.height,
                child: YOLOView(
                  modelPath: 'basketball_yolo11n.tflite',
                  task: YOLOTask.detect,
                  controller: _yoloController,
                  showNativeUI: false,
                  streamingConfig: YOLOStreamingConfig.custom(
                    includeDetections: true,
                    includeFps: true,
                    includeProcessingTimeMs: true,
                    inferenceFrequency: null,
                  ),
                  onResult: _onYoloResult,
                  onPerformanceMetrics: _onPerformanceMetrics,
                  confidenceThreshold: 0.25,
                  iouThreshold: 0.45,
                ),
              ),

              // Overlay painter
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ShotOverlayPainter(
                      ballN: _ballN,
                      rim: _rim,
                      size: size,
                    ),
                  ),
                ),
              ),

              // Flash result
              if (_flashResult != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: Container(
                        color: _flashResult == ShotResult.make
                            ? Colors.green.withValues(alpha: 0.25)
                            : Colors.red.withValues(alpha: 0.25),
                        child: Center(
                          child: Text(
                            _flashResult == ShotResult.make ? 'MAKE!' : 'MISS',
                            style: TextStyle(
                              color: _flashResult == ShotResult.make
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                              shadows: const [
                                Shadow(color: Colors.black, blurRadius: 8)
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Score board (top right)
              Positioned(
                top: 20,
                right: 20,
                child: _ScoreBoard(
                    makes: _makes,
                    misses: _misses,
                    recentShots: _recentShots),
              ),

              // Debug info (bottom left)
              Positioned(
                bottom: 20,
                left: 20,
                child: _DebugPanel(
                  fps: _currentFps,
                  detections: _detectionCount,
                  rimCalibrated: _rim != null,
                  ballVisible: _ballN != null,
                ),
              ),

              // Back button
              Positioned(
                top: 20,
                left: 20,
                child: FloatingActionButton(
                  heroTag: 'back',
                  mini: true,
                  backgroundColor: Colors.black54,
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Calibrate rim button
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton.extended(
                  heroTag: 'calibrate',
                  backgroundColor: _rim == null
                      ? Colors.deepOrange
                      : Colors.blueGrey.shade700,
                  icon: const Icon(Icons.sports_basketball),
                  label: Text(_rim == null ? 'Set Rim' : 'Re-Calibrate'),
                  onPressed: _startRimCalibration,
                ),
              ),

              // No rim warning
              if (_rim == null)
                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Tap "Set Rim" to calibrate the basket',
                        style:
                            TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Overlay painter ───────────────────────────────────────────────

class _ShotOverlayPainter extends CustomPainter {
  final Offset? ballN;
  final RimCalibration? rim;
  final Size size;

  _ShotOverlayPainter(
      {required this.ballN, required this.rim, required this.size});

  Offset _p(Offset n) => Offset(n.dx * size.width, n.dy * size.height);

  @override
  void paint(Canvas canvas, Size _) {
    // Draw rim
    if (rim != null) {
      final lPx = _p(rim!.leftN);
      final rPx = _p(rim!.rightN);
      final cx = (lPx.dx + rPx.dx) / 2;
      final cy = (lPx.dy + rPx.dy) / 2;
      final rw = (rPx.dx - lPx.dx).abs() / 2;
      final rh = rw * 0.3;

      final rimPaint = Paint()
        ..color = Colors.orangeAccent
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      canvas.drawLine(lPx, rPx, rimPaint);
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(cx, cy), width: rw * 2, height: rh * 2),
        3.14159,
        3.14159,
        false,
        rimPaint..color = Colors.orangeAccent.withValues(alpha: 0.5),
      );

      // Zone lines (subtle)
      final zonePaint = Paint()
        ..color = Colors.orange.withValues(alpha: 0.25)
        ..strokeWidth = 1;
      final topY = rim!.topZoneN * size.height;
      final botY = rim!.bottomZoneN * size.height;
      final leftX = (rim!.centerN.dx - rim!.xMarginN) * size.width;
      final rightX = (rim!.centerN.dx + rim!.xMarginN) * size.width;
      canvas.drawRect(
          Rect.fromLTRB(leftX, topY, rightX, botY), zonePaint);
    }

    // Draw ball
    if (ballN != null) {
      final center = _p(ballN!);
      canvas.drawCircle(
          center,
          14,
          Paint()
            ..color = Colors.greenAccent.withValues(alpha: 0.9)
            ..style = PaintingStyle.fill);
      canvas.drawCircle(
          center,
          14,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(_ShotOverlayPainter old) =>
      old.ballN != ballN || old.rim != rim;
}

// ── Score board widget ────────────────────────────────────────────

class _ScoreBoard extends StatelessWidget {
  final int makes;
  final int misses;
  final List<ShotResult> recentShots;

  const _ScoreBoard(
      {required this.makes,
      required this.misses,
      required this.recentShots});

  @override
  Widget build(BuildContext context) {
    final total = makes + misses;
    final pct = total == 0 ? 0.0 : makes / total * 100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              _statBox('MAKE', makes.toString(), Colors.greenAccent),
              const SizedBox(width: 12),
              _statBox('MISS', misses.toString(), Colors.redAccent),
              const SizedBox(width: 12),
              _statBox('PCT', '${pct.toStringAsFixed(0)}%', Colors.white),
            ],
          ),
          if (recentShots.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: recentShots
                  .take(8)
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child: Icon(
                          s == ShotResult.make
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: s == ShotResult.make
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          size: 18,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}

// ── Debug panel ───────────────────────────────────────────────────

class _DebugPanel extends StatelessWidget {
  final double fps;
  final int detections;
  final bool rimCalibrated;
  final bool ballVisible;

  const _DebugPanel({
    required this.fps,
    required this.detections,
    required this.rimCalibrated,
    required this.ballVisible,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FPS: ${fps.toStringAsFixed(1)}',
              style: const TextStyle(
                  color: Colors.greenAccent, fontSize: 12)),
          Text('Det: $detections',
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text('Rim: ${rimCalibrated ? "OK" : "not set"}',
              style: TextStyle(
                  color: rimCalibrated ? Colors.blueAccent : Colors.orange,
                  fontSize: 11)),
          Text('Ball: ${ballVisible ? "tracked" : "lost"}',
              style: TextStyle(
                  color: ballVisible ? Colors.greenAccent : Colors.red,
                  fontSize: 11)),
        ],
      ),
    );
  }
}
