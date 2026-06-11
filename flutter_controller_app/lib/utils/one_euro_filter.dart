import 'dart:math';

/// One Euro Filter for smoothing noisy signals while preserving responsiveness.
/// Implements the algorithm from: https://gery.casiez.net/1euro/
class OneEuroFilter {
  final double minCutoff;
  final double beta;
  final double dCutoff;
  
  double? _xPrev;
  double? _dxPrev;
  double? _tPrev;
  
  OneEuroFilter({
    this.minCutoff = 1.0,
    this.beta = 0.007,
    this.dCutoff = 1.0,
  });
  
  /// Compute the filtered value for a new sample.
  /// [x] is the raw value, [t] is the timestamp in seconds.
  double filter(double x, double t) {
    if (_xPrev == null || _tPrev == null) {
      _xPrev = x;
      _dxPrev = 0.0;
      _tPrev = t;
      return x;
    }
    
    final double dt = t - _tPrev!;
    if (dt <= 0) return _xPrev!;
    
    // Compute derivative
    final double dx = (x - _xPrev!) / dt;
    
    // Filter the derivative
    final double alphaDx = _computeAlpha(dt, dCutoff);
    final double dxFiltered = _lowPassFilter(dx, _dxPrev!, alphaDx);
    _dxPrev = dxFiltered;
    
    // Compute cutoff based on derivative (adaptive)
    final double cutoff = minCutoff + beta * dxFiltered.abs();
    
    // Filter the signal
    final double alpha = _computeAlpha(dt, cutoff);
    final double xFiltered = _lowPassFilter(x, _xPrev!, alpha);
    
    _xPrev = xFiltered;
    _tPrev = t;
    
    return xFiltered;
  }
  
  double _computeAlpha(double dt, double cutoff) {
    final double tau = 1.0 / (2.0 * pi * cutoff);
    return 1.0 / (1.0 + tau / dt);
  }
  
  double _lowPassFilter(double x, double xPrev, double alpha) {
    return alpha * x + (1.0 - alpha) * xPrev;
  }
  
  /// Reset the filter state.
  void reset() {
    _xPrev = null;
    _dxPrev = null;
    _tPrev = null;
  }
}

/// Manages One Euro Filters for a 2D point (x, y).
class OneEuroFilter2D {
  final OneEuroFilter _filterX;
  final OneEuroFilter _filterY;
  
  OneEuroFilter2D({
    double minCutoff = 1.0,
    double beta = 0.007,
    double dCutoff = 1.0,
  }) : _filterX = OneEuroFilter(minCutoff: minCutoff, beta: beta, dCutoff: dCutoff),
       _filterY = OneEuroFilter(minCutoff: minCutoff, beta: beta, dCutoff: dCutoff);
  
  /// Smooth preset: Less jitter, more lag (good for static poses)
  factory OneEuroFilter2D.smooth() => OneEuroFilter2D(
    minCutoff: 1.0,
    beta: 0.007,
    dCutoff: 1.0,
  );
  
  /// Responsive preset: More jitter, less lag (good for fast movement/walking)
  factory OneEuroFilter2D.responsive() => OneEuroFilter2D(
    minCutoff: 3.0,
    beta: 0.5,
    dCutoff: 1.0,
  );
  
  /// Filter a 2D point. Returns filtered (x, y).
  (double, double) filter(double x, double y, double t) {
    return (_filterX.filter(x, t), _filterY.filter(y, t));
  }
  
  void reset() {
    _filterX.reset();
    _filterY.reset();
  }
}
