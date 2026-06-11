/// Rim calibrator for Mode A — Visual Scale.
///
/// Computes pixelsPerMeter at hoop depth using rim diameter detection.
/// Uses median filtering over a window for stability.

import 'dart:collection';
import 'dart:ui';

import 'court_spaces.dart';

/// Result of rim scale calibration.
class RimScaleResult {
  /// Pixels per meter at the hoop's depth plane.
  final double pixelsPerMeterAtHoop;

  /// Rim center in image pixels.
  final ImagePoint rimCenter;

  /// Rim diameter in pixels.
  final double rimDiameterPx;

  /// Confidence of the detection (0-1).
  final double confidence;

  /// Timestamp of calibration.
  final DateTime timestamp;

  const RimScaleResult({
    required this.pixelsPerMeterAtHoop,
    required this.rimCenter,
    required this.rimDiameterPx,
    required this.confidence,
    required this.timestamp,
  });

  @override
  String toString() =>
      'RimScaleResult(scale=${pixelsPerMeterAtHoop.toStringAsFixed(1)} px/m, '
      'diameter=${rimDiameterPx.toStringAsFixed(1)}px, conf=${confidence.toStringAsFixed(2)})';
}

/// Internal observation for buffering.
class _RimObservation {
  final double diameterPx;
  final ImagePoint center;
  final double confidence;
  final int timestampMs;

  _RimObservation({
    required this.diameterPx,
    required this.center,
    required this.confidence,
    required this.timestampMs,
  });
}

/// Calibrator that computes visual scale from rim detections.
class RimCalibrator {
  /// Configuration.
  final RimCalibratorConfig config;

  /// Rolling buffer of observations.
  final Queue<_RimObservation> _buffer = Queue();

  /// Last stable result (cached).
  RimScaleResult? _lastStableResult;

  RimCalibrator({this.config = const RimCalibratorConfig()});

  /// Update with a new rim detection.
  ///
  /// [rimBbox] is the bounding box of the detected rim.
  /// [ellipseMajorAxis] is preferred if available (from ellipse fitting).
  /// [confidence] is the detection confidence (0-1).
  /// [timestampMs] is the frame timestamp in milliseconds.
  ///
  /// Returns the immediate scale result (may be unstable).
  RimScaleResult? update({
    required Rect rimBbox,
    double? ellipseMajorAxis,
    required double confidence,
    required int timestampMs,
  }) {
    // Skip low-confidence detections
    if (confidence < config.minConfidence) {
      return null;
    }

    // Prefer ellipse major axis if available
    final diameterPx = ellipseMajorAxis ?? rimBbox.width;

    // Skip if diameter is too small (noise)
    if (diameterPx < config.minDiameterPx) {
      return null;
    }

    final center = ImagePoint(rimBbox.center.dx, rimBbox.center.dy);

    // Add to buffer
    _buffer.addLast(_RimObservation(
      diameterPx: diameterPx,
      center: center,
      confidence: confidence,
      timestampMs: timestampMs,
    ));

    // Prune old observations
    final cutoff = timestampMs - config.bufferDurationMs;
    while (_buffer.isNotEmpty && _buffer.first.timestampMs < cutoff) {
      _buffer.removeFirst();
    }

    // Return immediate result
    return _computeScale(diameterPx, center, confidence, timestampMs);
  }

  /// Get stable scale if buffer has enough stable observations.
  ///
  /// Returns null if not enough observations or too much variance.
  RimScaleResult? getStableScale() {
    if (_buffer.length < config.minObservationsForStable) {
      return null;
    }

    // Calculate median diameter
    final diameters = _buffer.map((o) => o.diameterPx).toList()..sort();
    final medianDiameter = diameters[diameters.length ~/ 2];

    // Check variance
    final variance = _calculateVariance(diameters);
    if (variance > config.maxVarianceForStable) {
      return null;
    }

    // Calculate median center
    final centersX = _buffer.map((o) => o.center.x).toList()..sort();
    final centersY = _buffer.map((o) => o.center.y).toList()..sort();
    final medianCenter = ImagePoint(
      centersX[centersX.length ~/ 2],
      centersY[centersY.length ~/ 2],
    );

    // Average confidence
    final avgConfidence =
        _buffer.map((o) => o.confidence).reduce((a, b) => a + b) /
            _buffer.length;

    final result = _computeScale(
      medianDiameter,
      medianCenter,
      avgConfidence,
      DateTime.now().millisecondsSinceEpoch,
    );

    _lastStableResult = result;
    return result;
  }

  /// Get the last stable result (cached).
  RimScaleResult? get lastStableResult => _lastStableResult;

  /// Clear the observation buffer.
  void reset() {
    _buffer.clear();
    _lastStableResult = null;
  }

  /// Compute scale from rim diameter.
  RimScaleResult _computeScale(
    double diameterPx,
    ImagePoint center,
    double confidence,
    int timestampMs,
  ) {
    // Real rim diameter is 18 inches = 0.4572 meters
    final pixelsPerMeter = diameterPx / CourtConstants.rimDiameterMeters;

    return RimScaleResult(
      pixelsPerMeterAtHoop: pixelsPerMeter,
      rimCenter: center,
      rimDiameterPx: diameterPx,
      confidence: confidence,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
    );
  }

  /// Calculate variance of a sorted list.
  double _calculateVariance(List<double> sorted) {
    if (sorted.isEmpty) return 0;
    final mean = sorted.reduce((a, b) => a + b) / sorted.length;
    final squaredDiffs = sorted.map((v) => (v - mean) * (v - mean));
    return squaredDiffs.reduce((a, b) => a + b) / sorted.length;
  }
}

/// Configuration for RimCalibrator.
class RimCalibratorConfig {
  /// Minimum confidence to accept a rim detection.
  final double minConfidence;

  /// Minimum rim diameter in pixels (rejects noise).
  final double minDiameterPx;

  /// Duration of observation buffer in milliseconds.
  final int bufferDurationMs;

  /// Minimum observations for a stable result.
  final int minObservationsForStable;

  /// Maximum variance allowed for stable result.
  final double maxVarianceForStable;

  const RimCalibratorConfig({
    this.minConfidence = 0.5,
    this.minDiameterPx = 20.0,
    this.bufferDurationMs = 1000, // 1 second
    this.minObservationsForStable = 15, // ~0.5s at 30fps
    this.maxVarianceForStable = 25.0, // 5 pixels std dev
  });
}
