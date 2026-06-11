import 'dart:math' as math;
import 'rim_calibration.dart';

enum ShotResult { make, miss }
enum _State { idle, tracking, atRim }

/// Minimal 3-state shot detector.
///
/// IDLE      — ball not visible or barely moving
/// TRACKING  — ball is visible and moving (in flight)
/// AT_RIM    — ball has entered the rim zone; decide make or miss
class MakeMissDetector {
  _State _state = _State.idle;

  // AT_RIM tracking
  bool _crossedTopZone = false;
  int _atRimFrames = 0;
  static const int _maxAtRimFrames = 45; // ~1.5s at 30fps

  // Minimum speed (normalized/s) to count as "in flight" vs rolling on floor
  static const double _minFlightSpeed = 0.08;

  // How many frames ball must be missing before we give up in TRACKING
  int _missingFrames = 0;
  static const int _maxMissingFrames = 20;

  ShotResult? update({
    required bool ballVisible,
    required double ballX,
    required double ballY,
    required double ballVx,
    required double ballVy,
    required RimCalibration rim,
  }) {
    switch (_state) {
      case _State.idle:
        return _updateIdle(ballVisible, ballX, ballY, ballVx, ballVy);
      case _State.tracking:
        return _updateTracking(ballVisible, ballX, ballY, ballVx, ballVy, rim);
      case _State.atRim:
        return _updateAtRim(ballVisible, ballX, ballY, ballVy, rim);
    }
  }

  ShotResult? _updateIdle(
      bool visible, double x, double y, double vx, double vy) {
    if (!visible) return null;
    final speed = _speed(vx, vy);
    if (speed > _minFlightSpeed) {
      _state = _State.tracking;
      _missingFrames = 0;
    }
    return null;
  }

  ShotResult? _updateTracking(
      bool visible, double x, double y, double vx, double vy,
      RimCalibration rim) {
    if (!visible) {
      _missingFrames++;
      if (_missingFrames > _maxMissingFrames) _reset();
      return null;
    }
    _missingFrames = 0;

    // Drop back to IDLE if ball has stopped
    if (_speed(vx, vy) < _minFlightSpeed * 0.4) {
      _reset();
      return null;
    }

    // Enter AT_RIM when ball is within the horizontal span and near rim Y
    final inX = (x - rim.centerN.dx).abs() < rim.xMarginN;
    final inY = y >= rim.topZoneN - rim.radiusN && y <= rim.bottomZoneN + rim.radiusN;
    if (inX && inY) {
      _state = _State.atRim;
      _atRimFrames = 0;
      _crossedTopZone = y < rim.centerN.dy;
    }
    return null;
  }

  ShotResult? _updateAtRim(
      bool visible, double x, double y, double vy,
      RimCalibration rim) {
    _atRimFrames++;

    if (visible) {
      final inX = (x - rim.centerN.dx).abs() < rim.xMarginN;

      // Passed through top zone coming from above
      if (y < rim.centerN.dy && inX) _crossedTopZone = true;

      // Make: crossed top zone AND is now below bottom zone, moving downward
      if (_crossedTopZone && y > rim.bottomZoneN && vy > 0 && inX) {
        _reset();
        return ShotResult.make;
      }

      // Exited the horizontal rim span — miss
      if (!inX && _atRimFrames > 3) {
        _reset();
        return ShotResult.miss;
      }

      // Ball moving back up out of the zone — bounced off rim, miss
      if (y < rim.topZoneN && vy < 0 && _atRimFrames > 5) {
        _reset();
        return ShotResult.miss;
      }
    }

    // Timeout
    if (_atRimFrames > _maxAtRimFrames) {
      _reset();
      return ShotResult.miss;
    }

    return null;
  }

  void _reset() {
    _state = _State.idle;
    _crossedTopZone = false;
    _atRimFrames = 0;
    _missingFrames = 0;
  }

  void reset() => _reset();

  String get stateName => _state.name;

  static double _speed(double vx, double vy) =>
      math.sqrt(vx * vx + vy * vy);
}
