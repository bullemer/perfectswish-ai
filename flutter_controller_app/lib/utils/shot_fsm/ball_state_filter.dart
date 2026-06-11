/// Ball state filter for the Shot Scoring Engine FSM.
///
/// Provides filtered position and velocity with confidence gating and
/// short-term prediction during occlusions.

import 'dart:collection';
import 'dart:math';

import 'shot_fsm_config.dart';

/// A single ball observation with timestamp.
class BallObservation {
  final int tMs;
  final double x;
  final double y;
  final double conf;

  const BallObservation({
    required this.tMs,
    required this.x,
    required this.y,
    required this.conf,
  });
}

/// Filtered ball state with position and velocity.
class FilteredBallState {
  /// Filtered position (x, y) in pixels.
  final (double, double) pos;

  /// Filtered velocity (vx, vy) in pixels per second.
  final (double, double) vel;

  /// Raw confidence of the latest observation.
  final double conf;

  /// Whether the state is valid (has enough observations).
  final bool isValid;

  /// Whether currently predicting (no recent high-confidence observation).
  final bool isPredicting;

  /// Time since last high-confidence observation (ms).
  final int msSinceGoodObs;

  const FilteredBallState({
    required this.pos,
    required this.vel,
    required this.conf,
    this.isValid = true,
    this.isPredicting = false,
    this.msSinceGoodObs = 0,
  });

  /// Speed magnitude in pixels per second.
  double get speed => sqrt(vel.$1 * vel.$1 + vel.$2 * vel.$2);

  static const invalid = FilteredBallState(
    pos: (0, 0),
    vel: (0, 0),
    conf: 0,
    isValid: false,
  );
}

/// Ball state filter with EMA smoothing and confidence gating.
///
/// Features:
/// - EMA smoothing for position
/// - Finite-difference velocity with smoothing
/// - Confidence gating: skips velocity update when conf < threshold
/// - Short prediction window during occlusion
/// - Rolling buffer of recent observations
class BallStateFilter {
  final ShotFSMConfig config;

  // Rolling buffer of observations
  final Queue<BallObservation> _buffer = Queue();

  // Filtered state
  double? _filteredX;
  double? _filteredY;
  double? _filteredVx;
  double? _filteredVy;

  // Last good observation time
  int? _lastGoodObsMs;
  int? _lastUpdateMs;

  // For velocity calculation
  double? _prevX;
  double? _prevY;
  int? _prevMs;

  BallStateFilter({required this.config});

  /// Update the filter with a new ball observation.
  ///
  /// Returns the filtered state.
  FilteredBallState update({
    required int tMs,
    double? x,
    double? y,
    double conf = 0.0,
  }) {
    _lastUpdateMs = tMs;

    // No ball detected
    if (x == null || y == null) {
      return _handleMissing(tMs);
    }

    // Add to buffer
    final obs = BallObservation(tMs: tMs, x: x, y: y, conf: conf);
    _buffer.addLast(obs);

    // Prune old observations
    final cutoff = tMs - config.bufferDurationMs;
    while (_buffer.isNotEmpty && _buffer.first.tMs < cutoff) {
      _buffer.removeFirst();
    }

    // High confidence: update position and velocity
    if (conf >= config.ballConfMin) {
      _updateFiltered(tMs, x, y, conf);
      _lastGoodObsMs = tMs;
      return _buildState(conf, isPredicting: false);
    }

    // Low confidence: use prediction if within occlusion window
    return _handleLowConfidence(tMs, conf);
  }

  void _updateFiltered(int tMs, double x, double y, double conf) {
    final alpha = config.emaSmoothingFactor;

    if (_filteredX == null || _filteredY == null) {
      // First observation
      _filteredX = x;
      _filteredY = y;
      _filteredVx = 0;
      _filteredVy = 0;
      _prevX = x;
      _prevY = y;
      _prevMs = tMs;
      return;
    }

    // EMA position smoothing
    _filteredX = alpha * x + (1 - alpha) * _filteredX!;
    _filteredY = alpha * y + (1 - alpha) * _filteredY!;

    // Velocity from finite difference (if enough time elapsed)
    if (_prevMs != null && _prevX != null && _prevY != null) {
      final dt = (tMs - _prevMs!) / 1000.0; // seconds
      if (dt > 0.001) {
        // Avoid division by near-zero
        final rawVx = (x - _prevX!) / dt;
        final rawVy = (y - _prevY!) / dt;

        // EMA velocity smoothing
        if (_filteredVx == null) {
          _filteredVx = rawVx;
          _filteredVy = rawVy;
        } else {
          _filteredVx = alpha * rawVx + (1 - alpha) * _filteredVx!;
          _filteredVy = alpha * rawVy + (1 - alpha) * _filteredVy!;
        }
      }
    }

    _prevX = x;
    _prevY = y;
    _prevMs = tMs;
  }

  FilteredBallState _handleMissing(int tMs) {
    if (_filteredX == null || _lastGoodObsMs == null) {
      return FilteredBallState.invalid;
    }

    final msSinceGood = tMs - _lastGoodObsMs!;

    // Beyond occlusion window: reset tracking
    if (msSinceGood > config.occlusionMsMax) {
      return FilteredBallState.invalid;
    }

    // Predict position using velocity
    return _predict(tMs, msSinceGood);
  }

  FilteredBallState _handleLowConfidence(int tMs, double conf) {
    if (_filteredX == null || _lastGoodObsMs == null) {
      return FilteredBallState.invalid;
    }

    final msSinceGood = tMs - _lastGoodObsMs!;

    // Beyond occlusion window: filter is stale
    if (msSinceGood > config.occlusionMsMax) {
      return FilteredBallState.invalid;
    }

    // Use prediction (don't update velocity from low-conf observations)
    return _predict(tMs, msSinceGood);
  }

  FilteredBallState _predict(int tMs, int msSinceGood) {
    if (_filteredX == null ||
        _filteredY == null ||
        _filteredVx == null ||
        _filteredVy == null ||
        _lastGoodObsMs == null) {
      return FilteredBallState.invalid;
    }

    // Simple linear prediction
    final dt = msSinceGood / 1000.0;
    final predX = _filteredX! + _filteredVx! * dt;
    final predY = _filteredY! + _filteredVy! * dt;

    return FilteredBallState(
      pos: (predX, predY),
      vel: (_filteredVx!, _filteredVy!),
      conf: 0,
      isValid: true,
      isPredicting: true,
      msSinceGoodObs: msSinceGood,
    );
  }

  FilteredBallState _buildState(double conf, {required bool isPredicting}) {
    if (_filteredX == null ||
        _filteredY == null ||
        _filteredVx == null ||
        _filteredVy == null) {
      return FilteredBallState.invalid;
    }

    return FilteredBallState(
      pos: (_filteredX!, _filteredY!),
      vel: (_filteredVx!, _filteredVy!),
      conf: conf,
      isValid: true,
      isPredicting: isPredicting,
      msSinceGoodObs: 0,
    );
  }

  /// Get current filtered state without updating.
  FilteredBallState get currentState {
    if (_filteredX == null ||
        _filteredY == null ||
        _filteredVx == null ||
        _filteredVy == null) {
      return FilteredBallState.invalid;
    }

    final msSinceGood = _lastUpdateMs != null && _lastGoodObsMs != null
        ? _lastUpdateMs! - _lastGoodObsMs!
        : 0;

    return FilteredBallState(
      pos: (_filteredX!, _filteredY!),
      vel: (_filteredVx!, _filteredVy!),
      conf: _buffer.isNotEmpty ? _buffer.last.conf : 0,
      isValid: true,
      isPredicting: msSinceGood > 0,
      msSinceGoodObs: msSinceGood,
    );
  }

  /// Get observations from the rolling buffer within a time range.
  List<BallObservation> getObservationsInRange(int fromMs, int toMs) {
    return _buffer
        .where((obs) => obs.tMs >= fromMs && obs.tMs <= toMs)
        .toList();
  }

  /// Get all observations in the buffer.
  List<BallObservation> get allObservations => _buffer.toList();

  /// Clear the filter state and buffer.
  void reset() {
    _buffer.clear();
    _filteredX = null;
    _filteredY = null;
    _filteredVx = null;
    _filteredVy = null;
    _prevX = null;
    _prevY = null;
    _prevMs = null;
    _lastGoodObsMs = null;
    _lastUpdateMs = null;
  }

  /// Check if we have valid tracking.
  bool get hasValidTracking =>
      _filteredX != null &&
      _filteredY != null &&
      _lastGoodObsMs != null &&
      (_lastUpdateMs == null ||
          _lastUpdateMs! - _lastGoodObsMs! <= config.occlusionMsMax);
}
