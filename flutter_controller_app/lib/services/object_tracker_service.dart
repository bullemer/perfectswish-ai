import 'dart:ui';
import '../utils/kalman_filter.dart';
import '../utils/rim_locker.dart';

/// State for the ObjectTracker
class TrackerState {
  Rect? lockedRim;            // Finalized rim position
  Rect? lastBallRect;         // Raw YOLO ball detection
  Offset? smoothedBallCenter; // Kalman-smoothed ball position
  Rect? roiWindow;            // Region of Interest for next frame
  bool isRoiMode = false;     // Whether we're using ROI tracking
}

/// ObjectTrackerService handles rim locking and ball tracking
class ObjectTrackerService {
  final RimLocker _rimLocker;
  final KalmanFilter2D _ballFilter;
  final TrackerState state = TrackerState();

  // ROI parameters
  static const double roiSize = 320.0;
  static const int ballLostThreshold = 10; // frames before switching to global search
  int _framesSinceBallDetected = 0;

  ObjectTrackerService({
    int framesToLockRim = 30,
    double rimVarianceTolerance = 5.0,
    double kalmanQ = 0.1,
    double kalmanMeasureError = 0.1,
  })  : _rimLocker = RimLocker(
          framesToLock: framesToLockRim,
          pixelVarianceTolerance: rimVarianceTolerance,
        ),
        _ballFilter = KalmanFilter2D(
          q: kalmanQ,
          errMeasure: kalmanMeasureError,
        );

  /// Process YOLO detections for current frame
  /// Returns updated TrackerState
  TrackerState processDetections(List<Map<String, dynamic>> detections) {
    Rect? rimDetection;
    Rect? ballDetection;

    // Parse detections
    for (var detection in detections) {
      final tag = detection['tag'] as String?;
      final box = detection['box'] as List<dynamic>?;
      
      if (tag == null || box == null || box.length < 4) continue;

      final rect = Rect.fromLTRB(
        (box[0] as num).toDouble(),
        (box[1] as num).toDouble(),
        (box[2] as num).toDouble(),
        (box[3] as num).toDouble(),
      );

      if (tag.toLowerCase() == 'rim' || 
          tag.toLowerCase() == 'hoop' || 
          tag.toLowerCase() == 'net') {
        rimDetection = rect;
      } else if (tag.toLowerCase() == 'ball' || 
                 tag.toLowerCase() == 'basketball' ||
                 tag.toLowerCase() == 'sports ball') {
        ballDetection = rect;
      }
    }

    // Update rim logic
    _rimLocker.update(rimDetection);
    state.lockedRim = _rimLocker.rim;

    // Update ball logic
    if (ballDetection != null) {
      _framesSinceBallDetected = 0;
      state.lastBallRect = ballDetection;

      // Apply Kalman filter
      final smoothed = _ballFilter.update(
        ballDetection.center.dx,
        ballDetection.center.dy,
      );
      state.smoothedBallCenter = Offset(smoothed.$1, smoothed.$2);

      // Set ROI for next frame (centered on smoothed position)
      state.roiWindow = _calculateRoi(state.smoothedBallCenter!);
      state.isRoiMode = true;
    } else {
      _framesSinceBallDetected++;

      if (_framesSinceBallDetected > ballLostThreshold) {
        // Switch to global search
        state.roiWindow = null;
        state.isRoiMode = false;
        state.lastBallRect = null;
        state.smoothedBallCenter = null;
      } else {
        // Predict position using Kalman
        final predicted = _ballFilter.predict();
        state.smoothedBallCenter = Offset(predicted.$1, predicted.$2);
        state.roiWindow = _calculateRoi(state.smoothedBallCenter!);
      }
    }

    return state;
  }

  /// Calculate ROI window around a center point
  Rect _calculateRoi(Offset center) {
    return Rect.fromCenter(
      center: center,
      width: roiSize,
      height: roiSize,
    );
  }

  /// Translate coordinates from ROI space to global space
  static Rect translateToGlobal(Rect localBox, Offset roiOffset, double scaleFactor) {
    return Rect.fromLTWH(
      (localBox.left * scaleFactor) + roiOffset.dx,
      (localBox.top * scaleFactor) + roiOffset.dy,
      localBox.width * scaleFactor,
      localBox.height * scaleFactor,
    );
  }

  /// Unlock rim (call when camera moves)
  void unlockRim() {
    _rimLocker.unlock();
    state.lockedRim = null;
  }

  /// Reset all tracking state
  void reset() {
    _rimLocker.reset();
    _ballFilter.reset();
    state.lockedRim = null;
    state.lastBallRect = null;
    state.smoothedBallCenter = null;
    state.roiWindow = null;
    state.isRoiMode = false;
    _framesSinceBallDetected = 0;
  }

  /// Check if rim is locked
  bool get isRimLocked => _rimLocker.isLocked;

  /// Check if we should use ROI mode
  bool get shouldUseRoi => state.isRoiMode && state.roiWindow != null;

  /// Get current ROI window for cropping
  Rect? get roiWindow => state.roiWindow;
}
