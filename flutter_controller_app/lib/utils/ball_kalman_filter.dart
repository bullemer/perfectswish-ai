import 'dart:math' as math;

/// 4-state Kalman filter: [x, y, vx, vy]
/// Includes a gravity term in the process model so parabolic arc prediction
/// works even when the ball is occluded for several frames.
///
/// Coordinates are in normalized screen space (0..1).
/// gravityN is the per-frame gravity increment in normalized Y per second².
/// At 30 fps, a basketball falls roughly 0.02 normalized-Y per frame² in
/// a typical side-view gym shot.
class BallKalmanFilter {
  // State vector [x, y, vx, vy]
  double _x = 0, _y = 0, _vx = 0, _vy = 0;

  // State covariance (diagonal for simplicity)
  double _px = 1, _py = 1, _pvx = 1, _pvy = 1;

  // Process noise (how much we trust the motion model)
  final double qPos;
  final double qVel;

  // Measurement noise (how much we trust YOLO detections)
  final double rPos;

  // Gravity in normalized-Y per second (downward = positive)
  final double gravityNps2;

  bool _initialized = false;

  BallKalmanFilter({
    this.qPos = 1e-4,
    this.qVel = 1e-3,
    this.rPos = 2e-3,
    this.gravityNps2 = 9.8,
  });

  bool get isInitialized => _initialized;

  double get x => _x;
  double get y => _y;
  double get vx => _vx;
  double get vy => _vy;

  double get speed => math.sqrt(_vx * _vx + _vy * _vy);

  /// Predict forward by [dtSeconds] without a measurement.
  /// Returns predicted (x, y).
  (double, double) predict(double dtSeconds) {
    if (!_initialized) return (0.5, 0.5);

    _x += _vx * dtSeconds;
    _y += _vy * dtSeconds + 0.5 * gravityNps2 * dtSeconds * dtSeconds;
    _vy += gravityNps2 * dtSeconds;

    // Grow covariance
    _px += _pvx * dtSeconds * dtSeconds + qPos;
    _py += _pvy * dtSeconds * dtSeconds + qPos;
    _pvx += qVel;
    _pvy += qVel;

    return (_x.clamp(0.0, 1.0), _y.clamp(0.0, 1.0));
  }

  /// Update with a new measurement [mx], [my].
  /// If [dtSeconds] > 0, predict first then correct.
  /// Returns updated (x, y).
  (double, double) update(double mx, double my, double dtSeconds) {
    if (!_initialized) {
      _x = mx; _y = my; _vx = 0; _vy = 0;
      _px = 0.1; _py = 0.1; _pvx = 0.1; _pvy = 0.1;
      _initialized = true;
      return (_x, _y);
    }

    predict(dtSeconds);

    // Kalman gain
    final kx = _px / (_px + rPos);
    final ky = _py / (_py + rPos);

    // Correct position
    final prevX = _x;
    final prevY = _y;
    _x += kx * (mx - _x);
    _y += ky * (my - _y);

    // Correct velocity (infer from position correction and dt)
    if (dtSeconds > 0) {
      _vx += kx * ((mx - prevX) / dtSeconds - _vx) * 0.5;
      _vy += ky * ((my - prevY) / dtSeconds - _vy) * 0.5;
    }

    // Update covariance
    _px *= (1 - kx);
    _py *= (1 - ky);

    return (_x.clamp(0.0, 1.0), _y.clamp(0.0, 1.0));
  }

  void reset() {
    _initialized = false;
    _x = 0; _y = 0; _vx = 0; _vy = 0;
    _px = 1; _py = 1; _pvx = 1; _pvy = 1;
  }
}
