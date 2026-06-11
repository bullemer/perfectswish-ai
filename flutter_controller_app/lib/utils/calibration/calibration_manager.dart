/// Main calibration manager — unified API for all calibration modes.
///
/// Provides:
/// - Mode A: Visual scale from rim
/// - Mode B: Floor homography from court lines
/// - Mode C: Persistence via Isar
///
/// CRITICAL: Two coordinate spaces are used separately:
/// - CourtPlaneSpace (floor points only)
/// - BallAirSpace (airborne ball via scale factor)

import 'dart:ui';

import 'calibration_profile.dart';
import 'calibration_repository.dart';
import 'court_calibrator.dart';
import 'court_spaces.dart';
import 'line_intersection.dart';
import 'rim_calibrator.dart';

/// Main calibration manager.
class CalibrationManager {
  /// Rim calibrator for visual scale.
  final RimCalibrator rimCalibrator;

  /// Court calibrator for floor homography.
  final CourtCalibrator courtCalibrator;

  /// Persistence repository.
  final CalibrationRepository repository;

  /// Currently active profile.
  CalibrationProfile? _activeProfile;

  /// Current camera signature.
  CameraSignature? _cameraSignature;

  /// Cached homography matrices.
  Matrix3? _hFloorPxToM;
  Matrix3? _hFloorMToPx;

  CalibrationManager({
    RimCalibratorConfig? rimConfig,
  })  : rimCalibrator = RimCalibrator(config: rimConfig ?? const RimCalibratorConfig()),
        courtCalibrator = CourtCalibrator(),
        repository = CalibrationRepository();

  /// Initialize the calibration system.
  Future<void> init() async {
    await repository.init();
  }

  /// Dispose resources.
  Future<void> dispose() async {
    await repository.close();
  }

  /// Get the active profile.
  CalibrationProfile? get activeProfile => _activeProfile;

  /// Check if we have a visual scale.
  bool get hasVisualScale => _activeProfile?.hasVisualScale ?? false;

  /// Check if we have a floor homography.
  bool get hasFloorHomography => _hFloorPxToM != null;

  /// Get pixels per meter at hoop depth.
  double? get pixelsPerMeterAtHoop => _activeProfile?.pixelsPerMeterAtHoop;

  // ─────────────────────────────────────────────────────────────────────────
  // Mode A: Visual Scale (Rim)
  // ─────────────────────────────────────────────────────────────────────────

  /// Update with new rim detection.
  ///
  /// Call this every frame with rim detection results.
  RimScaleResult? updateRim({
    required Rect rimBbox,
    double? ellipseMajorAxis,
    required double confidence,
    required int timestampMs,
  }) {
    final result = rimCalibrator.update(
      rimBbox: rimBbox,
      ellipseMajorAxis: ellipseMajorAxis,
      confidence: confidence,
      timestampMs: timestampMs,
    );

    // Check for stable result
    final stable = rimCalibrator.getStableScale();
    if (stable != null) {
      _updateProfileWithRimScale(stable);
    }

    return result;
  }

  void _updateProfileWithRimScale(RimScaleResult scale) {
    _activeProfile ??= CalibrationProfile();
    _activeProfile!.pixelsPerMeterAtHoop = scale.pixelsPerMeterAtHoop;
    _activeProfile!.rimCenterX = scale.rimCenter.x;
    _activeProfile!.rimCenterY = scale.rimCenter.y;
    _activeProfile!.rimDiameterPx = scale.rimDiameterPx;
    _activeProfile!.rimConfidence = scale.confidence;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Mode B: Court Homography
  // ─────────────────────────────────────────────────────────────────────────

  /// Attempt to calibrate court from detected lines.
  ///
  /// [classifiedLines] - Detected court lines.
  /// Returns calibration result or null if failed.
  CalibrationResult? calibrateCourt(ClassifiedLines classifiedLines) {
    final rimScale = rimCalibrator.getStableScale();
    if (rimScale == null) {
      // Need rim scale first
      return null;
    }

    final result = courtCalibrator.calibrateFromLines(
      classifiedLines: classifiedLines,
      rimScale: rimScale,
    );

    if (result != null) {
      _applyCalibrationResult(result);
    }

    return result;
  }

  void _applyCalibrationResult(CalibrationResult result) {
    _activeProfile ??= CalibrationProfile();
    _activeProfile!.calibrationType = result.calibrationType;
    _activeProfile!.isPartialCalibration = result.isPartial;

    if (result.homography != null) {
      _activeProfile!.hFloorPxToM = result.homography!.hPxToM.toList();
      _activeProfile!.hFloorMToPx = result.homography!.hMToPx.toList();
      _activeProfile!.reprojectionError = result.homography!.reprojectionError;
      _activeProfile!.homographyInliers = result.homography!.inliers.length;

      _hFloorPxToM = result.homography!.hPxToM;
      _hFloorMToPx = result.homography!.hMToPx;
    }

    if (result.depthMetersPerPixel != null) {
      _activeProfile!.depthMetersPerPixel = result.depthMetersPerPixel;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Coordinate Conversions
  // ─────────────────────────────────────────────────────────────────────────

  /// Convert ball velocity from image space to metric (m/s).
  ///
  /// Uses pixelsPerMeter_atHoop (BallAirSpace).
  /// SAFE for airborne ball.
  MetricVelocity? ballVelocityToMetric(ImageVelocity vel) {
    final scale = _activeProfile?.pixelsPerMeterAtHoop;
    if (scale == null || scale <= 0) return null;

    return MetricVelocity(
      vel.vx / scale,
      vel.vy / scale,
    );
  }

  /// Convert ball distance in pixels to meters.
  ///
  /// Uses pixelsPerMeter_atHoop (BallAirSpace).
  /// SAFE for airborne ball.
  double? ballDistanceToMetric(double distancePx) {
    final scale = _activeProfile?.pixelsPerMeterAtHoop;
    if (scale == null || scale <= 0) return null;

    return distancePx / scale;
  }

  /// Convert floor pixel point to court meters.
  ///
  /// Uses floor homography (CourtPlaneSpace).
  /// ONLY for floor points (feet, court markings, grounded ball).
  /// DO NOT use for airborne ball!
  CourtPoint? floorPixelToMetric(ImagePoint pixel) {
    if (_hFloorPxToM == null) {
      // Fall back to local affine if we have depth scale
      return _floorPixelToMetricFallback(pixel);
    }

    return _hFloorPxToM!.transformToCourtPoint(pixel);
  }

  CourtPoint? _floorPixelToMetricFallback(ImagePoint pixel) {
    final rimCenter = _activeProfile?.rimCenter;
    final depthScale = _activeProfile?.depthMetersPerPixel;
    final lateralScale = _activeProfile?.pixelsPerMeterAtHoop;

    if (rimCenter == null || lateralScale == null) return null;

    final dx = pixel.x - rimCenter.$1;
    final dy = pixel.y - rimCenter.$2;

    // Lateral (X) uses rim scale
    final courtX = dx / lateralScale;

    // Depth (Y) uses depth scale if available, else rim scale
    final courtY = depthScale != null ? dy * depthScale : dy / lateralScale;

    return CourtPoint(courtX, courtY);
  }

  /// Convert court meters to floor pixel position.
  ///
  /// Uses inverse floor homography.
  /// For rendering court lines on screen.
  ImagePoint? floorMetricToPixel(CourtPoint court) {
    if (_hFloorMToPx == null) {
      return _floorMetricToPixelFallback(court);
    }

    return _hFloorMToPx!.transformFromCourtPoint(court);
  }

  ImagePoint? _floorMetricToPixelFallback(CourtPoint court) {
    final rimCenter = _activeProfile?.rimCenter;
    final depthScale = _activeProfile?.depthMetersPerPixel;
    final lateralScale = _activeProfile?.pixelsPerMeterAtHoop;

    if (rimCenter == null || lateralScale == null) return null;

    final px = rimCenter.$1 + court.x * lateralScale;

    final py = depthScale != null
        ? rimCenter.$2 + court.y / depthScale
        : rimCenter.$2 + court.y * lateralScale;

    return ImagePoint(px, py);
  }

  /// Refresh scale when ball is near rim (optional depth correction).
  ///
  /// Call when ball enters rim vicinity for best accuracy.
  void refreshScaleNearRim(Rect rimBbox, double confidence, int timestampMs) {
    updateRim(
      rimBbox: rimBbox,
      confidence: confidence,
      timestampMs: timestampMs,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3-Point Detection
  // ─────────────────────────────────────────────────────────────────────────

  /// Check if a floor position is beyond the 3-point line.
  ///
  /// [feetPixel] - Player's foot position in image pixels.
  /// [isNba] - Use NBA (7.24m) vs FIBA (6.75m) distance.
  bool? is3PointShot(ImagePoint feetPixel, {bool isNba = true}) {
    final courtPos = floorPixelToMetric(feetPixel);
    if (courtPos == null) return null;

    final distance = courtPos.distanceTo(const CourtPoint(0, 0));

    final threshold = isNba
        ? CourtConstants.threePointDistanceNbaMeters
        : CourtConstants.threePointDistanceFibaMeters;

    return distance >= threshold;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Mode C: Persistence
  // ─────────────────────────────────────────────────────────────────────────

  /// Set camera signature for profile validation.
  void setCameraSignature({
    required int width,
    required int height,
    required int orientation,
    String? lensInfo,
  }) {
    _cameraSignature = CameraSignature(
      width: width,
      height: height,
      orientation: orientation,
      lensInfo: lensInfo,
    );

    // Apply to active profile
    if (_activeProfile != null) {
      _activeProfile!.imageWidth = width;
      _activeProfile!.imageHeight = height;
      _activeProfile!.orientation = orientation;
      _activeProfile!.lensInfo = lensInfo;
    }
  }

  /// Save current calibration to a gym.
  Future<void> saveToGym(String gymName) async {
    if (_activeProfile == null) return;

    _activeProfile!.gymName = gymName;
    await repository.save(_activeProfile!);
  }

  /// Save current calibration with GPS.
  Future<void> saveWithGPS(double latitude, double longitude) async {
    if (_activeProfile == null) return;

    _activeProfile!.gpsBucket = CameraSignature.gpsBucket(latitude, longitude);
    await repository.save(_activeProfile!);
  }

  /// Load calibration for a gym.
  Future<bool> loadFromGym(String gymName) async {
    final profile = await repository.loadByGym(gymName);
    return _applyProfile(profile);
  }

  /// Load calibration by GPS.
  Future<bool> loadFromGPS(double latitude, double longitude) async {
    final profile = await repository.loadByGPS(latitude, longitude);
    return _applyProfile(profile);
  }

  /// Load matching profile (gym or GPS) with camera validation.
  Future<bool> loadMatching({
    String? gymName,
    double? latitude,
    double? longitude,
  }) async {
    if (_cameraSignature == null) return false;

    final profile = await repository.loadMatching(
      gymName: gymName,
      latitude: latitude,
      longitude: longitude,
      cameraSignature: _cameraSignature!,
    );

    return _applyProfile(profile);
  }

  bool _applyProfile(CalibrationProfile? profile) {
    if (profile == null) return false;

    _activeProfile = profile;

    // Restore homography matrices
    if (profile.hFloorPxToM != null && profile.hFloorPxToM!.length == 9) {
      _hFloorPxToM = Matrix3.fromList(profile.hFloorPxToM!);
    }
    if (profile.hFloorMToPx != null && profile.hFloorMToPx!.length == 9) {
      _hFloorMToPx = Matrix3.fromList(profile.hFloorMToPx!);
    }

    return true;
  }

  /// Reset all calibration data.
  void reset() {
    _activeProfile = null;
    _hFloorPxToM = null;
    _hFloorMToPx = null;
    rimCalibrator.reset();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Debug Info
  // ─────────────────────────────────────────────────────────────────────────

  /// Get debug snapshot of current calibration state.
  CalibrationDebugSnapshot debugSnapshot() {
    return CalibrationDebugSnapshot(
      hasVisualScale: hasVisualScale,
      hasFloorHomography: hasFloorHomography,
      pixelsPerMeterAtHoop: pixelsPerMeterAtHoop,
      calibrationType: _activeProfile?.calibrationType,
      reprojectionError: _activeProfile?.reprojectionError,
      rimCenter: _activeProfile?.rimCenter,
      gymName: _activeProfile?.gymName,
    );
  }
}

/// Debug snapshot of calibration state.
class CalibrationDebugSnapshot {
  final bool hasVisualScale;
  final bool hasFloorHomography;
  final double? pixelsPerMeterAtHoop;
  final String? calibrationType;
  final double? reprojectionError;
  final (double, double)? rimCenter;
  final String? gymName;

  const CalibrationDebugSnapshot({
    required this.hasVisualScale,
    required this.hasFloorHomography,
    this.pixelsPerMeterAtHoop,
    this.calibrationType,
    this.reprojectionError,
    this.rimCenter,
    this.gymName,
  });

  Map<String, dynamic> toJson() => {
        'has_visual_scale': hasVisualScale,
        'has_floor_homography': hasFloorHomography,
        'px_per_m': pixelsPerMeterAtHoop,
        'type': calibrationType,
        'reproj_error': reprojectionError,
        'rim_center': rimCenter != null
            ? {'x': rimCenter!.$1, 'y': rimCenter!.$2}
            : null,
        'gym': gymName,
      };
}
