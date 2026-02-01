/// A simple 1D Kalman Filter for smooth trajectory tracking.
/// Use two instances: one for X, one for Y.
class SimpleKalmanFilter {
  final double _errMeasure; // Measurement Uncertainty - How much do we trust the YOLO box?
  double _errEstimate;       // Estimate Uncertainty (mutable)
  final double _q;           // Process Noise - How fast can the object move?

  double _currentEstimate = 0.0;
  double _lastEstimate = 0.0;
  double _kalmanGain = 0.0;

  SimpleKalmanFilter({
    double q = 0.1,
    double errMeasure = 0.1,
    double estimate = 0.0,
  })  : _q = q,
        _errMeasure = errMeasure,
        _errEstimate = errMeasure,
        _currentEstimate = estimate;

  /// Update filter with new measurement
  double update(double measurement) {
    _kalmanGain = _errEstimate / (_errEstimate + _errMeasure);
    _currentEstimate = _lastEstimate + _kalmanGain * (measurement - _lastEstimate);
    _errEstimate = (1.0 - _kalmanGain) * _errEstimate + 
                   (_lastEstimate - _currentEstimate).abs() * _q;
    _lastEstimate = _currentEstimate;
    return _currentEstimate;
  }

  /// Predict position when no detection (constant velocity assumption)
  double predict() {
    // For simple position smoothing, return last known good position
    return _lastEstimate;
  }

  /// Get current estimate without updating
  double get estimate => _currentEstimate;

  /// Reset filter to initial state
  void reset([double initial = 0.0]) {
    _currentEstimate = initial;
    _lastEstimate = initial;
    _errEstimate = _errMeasure;
    _kalmanGain = 0.0;
  }
}

/// 2D Kalman Filter using two 1D filters
class KalmanFilter2D {
  final SimpleKalmanFilter _filterX;
  final SimpleKalmanFilter _filterY;

  KalmanFilter2D({
    double q = 0.1,
    double errMeasure = 0.1,
  })  : _filterX = SimpleKalmanFilter(q: q, errMeasure: errMeasure),
        _filterY = SimpleKalmanFilter(q: q, errMeasure: errMeasure);

  /// Update with new (x, y) measurement
  (double, double) update(double x, double y) {
    return (_filterX.update(x), _filterY.update(y));
  }

  /// Predict position when no detection
  (double, double) predict() {
    return (_filterX.predict(), _filterY.predict());
  }

  /// Get current estimate
  (double, double) get estimate => (_filterX.estimate, _filterY.estimate);

  /// Reset both filters
  void reset([double initialX = 0.0, double initialY = 0.0]) {
    _filterX.reset(initialX);
    _filterY.reset(initialY);
  }
}
