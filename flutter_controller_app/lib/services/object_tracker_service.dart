import 'dart:ui';
import '../utils/kalman_filter.dart';
import '../utils/rim_locker.dart';

/// State for the ObjectTracker - ALL COORDINATES IN NORMALIZED SPACE (0..1)
class TrackerState {
  Rect? lockedRimN;            // Finalized rim position (normalized)
  Rect? lastBallRectN;         // Raw YOLO ball detection (normalized)
  Offset? smoothedBallCenterN; // Kalman-smoothed ball position (normalized)
  Rect? roiWindowN;            // Region of Interest (normalized)
  bool isRoiMode = false;      // Whether we're using ROI tracking
}

/// ObjectTrackerService handles rim locking and ball tracking
/// All internal coordinates are in NORMALIZED space (0..1)
class ObjectTrackerService {
  final RimLockerN _rimLocker;
  final KalmanFilter2D _ballFilter;
  final TrackerState state = TrackerState();

  // ROI parameters (normalized - relative to frame size)
  static const double roiSizeN = 0.5; // 50% of frame width/height
  static const int ballLostThreshold = 30;
  int _framesSinceBallDetected = 0;

  ObjectTrackerService({
    int framesToLockRim = 30,
    double rimVarianceTolerance = 0.01, // Normalized variance
    double kalmanQ = 0.001,             // Normalized-space tuning
    double kalmanMeasureError = 0.01,
  })  : _rimLocker = RimLockerN(
          framesToLock: framesToLockRim,
          varianceTolerance: rimVarianceTolerance,
        ),
        _ballFilter = KalmanFilter2D(
          q: kalmanQ,
          errMeasure: kalmanMeasureError,
        );

  /// Process YOLO detections for current frame
  /// Expects input in NORMALIZED coordinates (0..1)
  TrackerState processDetectionsNormalized(List<Map<String, dynamic>> detectionsN) {
    Rect? rimN;
    Rect? ballN;

    for (var d in detectionsN) {
      final tag = d['tag'] as String?;
      final boxN = d['boxN'] as Rect?;
      if (tag == null || boxN == null) continue;

      final tagLower = tag.toLowerCase();
      
      if (tagLower == 'rim' || tagLower == 'hoop' || tagLower == 'net' || tag == '2') {
        rimN = boxN;
      } else if (tagLower == 'ball' || tagLower == 'basketball' || tagLower == 'sports ball' || tag == '0') {
        ballN = boxN;
      }
    }

    // Update rim logic (normalized)
    _rimLocker.update(rimN);
    state.lockedRimN = _rimLocker.rim;

    // Update ball logic (normalized)
    if (ballN != null) {
      _framesSinceBallDetected = 0;
      state.lastBallRectN = ballN;

      // Apply Kalman filter (normalized coords)
      final smoothed = _ballFilter.update(
        ballN.center.dx,
        ballN.center.dy,
      );
      state.smoothedBallCenterN = Offset(smoothed.$1, smoothed.$2);

      // Set ROI centered on smoothed position (normalized)
      state.roiWindowN = _calculateRoiN(state.smoothedBallCenterN!);
      state.isRoiMode = true;
    } else {
      _framesSinceBallDetected++;

      if (_framesSinceBallDetected > ballLostThreshold) {
        state.roiWindowN = null;
        state.isRoiMode = false;
        state.lastBallRectN = null;
        state.smoothedBallCenterN = null;
      } else {
        final predicted = _ballFilter.predict();
        state.smoothedBallCenterN = Offset(predicted.$1, predicted.$2);
        state.roiWindowN = _calculateRoiN(state.smoothedBallCenterN!);
      }
    }

    return state;
  }

  /// Calculate ROI (normalized) around a center point (normalized)
  Rect _calculateRoiN(Offset centerN) {
    return Rect.fromCenter(
      center: centerN,
      width: roiSizeN,
      height: roiSizeN,
    ).intersect(const Rect.fromLTWH(0, 0, 1, 1)); // Clamp to valid range
  }

  void unlockRim() {
    _rimLocker.unlock();
    state.lockedRimN = null;
  }

  void reset() {
    _rimLocker.reset();
    _ballFilter.reset();
    state.lockedRimN = null;
    state.lastBallRectN = null;
    state.smoothedBallCenterN = null;
    state.roiWindowN = null;
    state.isRoiMode = false;
    _framesSinceBallDetected = 0;
  }

  bool get isRimLocked => _rimLocker.isLocked;
  bool get shouldUseRoi => state.isRoiMode && state.roiWindowN != null;
  Rect? get roiWindowN => state.roiWindowN;
}

// ===== HELPER: Normalized RimLocker =====

class RimLockerN {
  final int framesToLock;
  final double varianceTolerance;
  final int maxMissedFrames; // How many missed frames before resetting
  
  final List<Rect> _candidates = [];
  Rect? _lockedRim;
  int _missedFrames = 0;
  
  RimLockerN({
    this.framesToLock = 10, // Reduced from 30 for faster locking
    this.varianceTolerance = 0.02, // Slightly more lenient
    this.maxMissedFrames = 5, // Allow up to 5 missed frames
  });

  void update(Rect? rimN) {
    if (rimN == null) {
      _missedFrames++;
      // Only reset if too many consecutive misses
      if (_missedFrames > maxMissedFrames) {
        _candidates.clear();
        _missedFrames = 0;
      }
      return;
    }
    
    // Got a detection, reset miss counter
    _missedFrames = 0;
    
    _candidates.add(rimN);
    if (_candidates.length > framesToLock) {
      _candidates.removeAt(0);
    }
    
    if (_candidates.length >= framesToLock && _isStable()) {
      _lockedRim = _averageRect();
    }
  }

  bool _isStable() {
    if (_candidates.length < framesToLock) return false;
    
    final avgLeft = _candidates.map((r) => r.left).reduce((a, b) => a + b) / _candidates.length;
    final avgTop = _candidates.map((r) => r.top).reduce((a, b) => a + b) / _candidates.length;
    
    for (var r in _candidates) {
      if ((r.left - avgLeft).abs() > varianceTolerance) return false;
      if ((r.top - avgTop).abs() > varianceTolerance) return false;
    }
    return true;
  }

  Rect _averageRect() {
    final left = _candidates.map((r) => r.left).reduce((a, b) => a + b) / _candidates.length;
    final top = _candidates.map((r) => r.top).reduce((a, b) => a + b) / _candidates.length;
    final right = _candidates.map((r) => r.right).reduce((a, b) => a + b) / _candidates.length;
    final bottom = _candidates.map((r) => r.bottom).reduce((a, b) => a + b) / _candidates.length;
    return Rect.fromLTRB(left, top, right, bottom);
  }

  void unlock() {
    _lockedRim = null;
    _candidates.clear();
  }

  void reset() {
    _lockedRim = null;
    _candidates.clear();
  }

  Rect? get rim => _lockedRim;
  bool get isLocked => _lockedRim != null;
}

// ===== HELPER: Coordinate conversion =====

/// Convert normalized rect (0..1) to screen pixels
Rect rectToPixels(Rect n, Size viewSize) {
  return Rect.fromLTWH(
    n.left * viewSize.width,
    n.top * viewSize.height,
    n.width * viewSize.width,
    n.height * viewSize.height,
  );
}

/// Convert screen pixels to normalized rect (0..1)
Rect rectToNormalized(Rect px, Size viewSize) {
  return Rect.fromLTRB(
    (px.left / viewSize.width).clamp(0.0, 1.0),
    (px.top / viewSize.height).clamp(0.0, 1.0),
    (px.right / viewSize.width).clamp(0.0, 1.0),
    (px.bottom / viewSize.height).clamp(0.0, 1.0),
  );
}

/// Check if ROI contains the center of a box (both normalized)
bool roiContainsCenter(Rect roiN, Rect boxN) {
  final cx = boxN.left + boxN.width / 2;
  final cy = boxN.top + boxN.height / 2;
  return roiN.contains(Offset(cx, cy));
}
