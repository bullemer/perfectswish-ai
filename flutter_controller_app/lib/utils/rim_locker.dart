import 'dart:ui';

/// Prevents rim jittering by locking position after stability is detected.
/// Once locked, the rim position is fixed until explicitly unlocked.
class RimLocker {
  final int framesToLock;
  final double pixelVarianceTolerance;

  final List<Rect> _buffer = [];
  Rect? _lockedRim;

  RimLocker({
    this.framesToLock = 30, // 1 second at 30fps
    this.pixelVarianceTolerance = 5.0,
  });

  /// Whether the rim is currently locked
  bool get isLocked => _lockedRim != null;

  /// Get the locked rim position (null if not locked)
  Rect? get rim => _lockedRim;

  /// Update with a new rim detection
  void update(Rect? detectedRim) {
    if (isLocked || detectedRim == null) return;

    _buffer.add(detectedRim);
    if (_buffer.length > framesToLock) {
      _buffer.removeAt(0); // Keep buffer size fixed
      _tryToLock();
    }
  }

  void _tryToLock() {
    if (_buffer.length < framesToLock) return;

    // Calculate average center
    double sumX = 0, sumY = 0;
    for (var r in _buffer) {
      sumX += r.center.dx;
      sumY += r.center.dy;
    }
    double avgX = sumX / _buffer.length;
    double avgY = sumY / _buffer.length;

    // Check variance: Are all detections close to the average?
    bool isStable = _buffer.every((r) =>
        (r.center.dx - avgX).abs() < pixelVarianceTolerance &&
        (r.center.dy - avgY).abs() < pixelVarianceTolerance);

    if (isStable) {
      // Lock it! Use the average size/pos
      double avgWidth = _buffer.map((e) => e.width).reduce((a, b) => a + b) / _buffer.length;
      double avgHeight = _buffer.map((e) => e.height).reduce((a, b) => a + b) / _buffer.length;

      _lockedRim = Rect.fromCenter(
        center: Offset(avgX, avgY),
        width: avgWidth,
        height: avgHeight,
      );
      // Debug print removed - use debugPrint in calling code if needed
    }
  }

  /// Unlock the rim (call when camera moves)
  void unlock() {
    _lockedRim = null;
    _buffer.clear();
    // Debug print removed - use debugPrint in calling code if needed
  }

  /// Reset without logging
  void reset() {
    _lockedRim = null;
    _buffer.clear();
  }
}
