/// Court calibrator for Mode B — Floor Homography.
///
/// Orchestrates line detection and homography computation.
/// Falls back to depth-scale vector when full homography isn't possible.

import 'dart:math';
import 'court_spaces.dart';
import 'line_intersection.dart';
import 'homography_estimator.dart';
import 'rim_calibrator.dart';

/// Result of court calibration.
class CalibrationResult {
  /// Calibration type: "full", "approx_depth_scale", "rim_only".
  final String calibrationType;

  /// Full homography result (if available).
  final HomographyResult? homography;

  /// Depth scale along rim↔FT vector (fallback).
  final double? depthMetersPerPixel;

  /// Visual scale from rim.
  final RimScaleResult? rimScale;

  /// Whether calibration is partial.
  bool get isPartial => calibrationType != 'full';

  const CalibrationResult({
    required this.calibrationType,
    this.homography,
    this.depthMetersPerPixel,
    this.rimScale,
  });

  @override
  String toString() =>
      'CalibrationResult(type=$calibrationType, '
      'hasHomography=${homography != null}, '
      'depthScale=${depthMetersPerPixel?.toStringAsFixed(4)})';
}

/// Court calibrator that computes floor-to-pixel transformations.
class CourtCalibrator {
  final HomographyEstimator _homographyEstimator = HomographyEstimator();

  /// Attempt to calibrate from detected court lines and rim.
  ///
  /// [classifiedLines] - Detected and classified court lines.
  /// [rimScale] - Visual scale result from rim detection.
  ///
  /// Returns [CalibrationResult] with best available calibration.
  CalibrationResult? calibrateFromLines({
    required ClassifiedLines classifiedLines,
    required RimScaleResult rimScale,
  }) {
    // Check if we have enough lines for homography
    if (!classifiedLines.hasMinimumForHomography) {
      // Fall back to depth vector approach
      return _calibrateDepthVector(
        rimCenter: rimScale.rimCenter,
        freeThrowLine: classifiedLines.freeThrowLine,
        rimScale: rimScale,
      );
    }

    // Find corner correspondences
    final corners = LineIntersection.findKeyCorners(
      classifiedLines,
      rimCenter: rimScale.rimCenter,
    );

    if (corners.length < 4) {
      // Not enough corners for homography
      return _calibrateDepthVector(
        rimCenter: rimScale.rimCenter,
        freeThrowLine: classifiedLines.freeThrowLine,
        rimScale: rimScale,
      );
    }

    // Compute homography with RANSAC
    final homography = _homographyEstimator.computeRANSAC(
      corners,
      iterations: 500,
      threshold: 5.0,
    );

    if (homography == null || homography.reprojectionError > 10.0) {
      // Homography failed or too noisy, fall back
      return _calibrateDepthVector(
        rimCenter: rimScale.rimCenter,
        freeThrowLine: classifiedLines.freeThrowLine,
        rimScale: rimScale,
      );
    }

    return CalibrationResult(
      calibrationType: 'full',
      homography: homography,
      rimScale: rimScale,
    );
  }

  /// Fallback: Compute depth scale using rim + free-throw line.
  ///
  /// Uses the known distance from rim center to FT line (~4.19m).
  CalibrationResult? _calibrateDepthVector({
    required ImagePoint rimCenter,
    required LineSegment? freeThrowLine,
    required RimScaleResult rimScale,
  }) {
    if (freeThrowLine == null) {
      // Can only provide rim scale
      return CalibrationResult(
        calibrationType: 'rim_only',
        rimScale: rimScale,
      );
    }

    // Find closest point on FT line to rim center
    final ftMidpoint = freeThrowLine.midpoint;

    // Distance in pixels from rim center to FT line midpoint
    final pixelDist = rimCenter.distanceTo(ftMidpoint);

    if (pixelDist < 10) {
      // Too close, unreliable
      return CalibrationResult(
        calibrationType: 'rim_only',
        rimScale: rimScale,
      );
    }

    // Known distance: rim center to FT line ≈ 4.19m
    // (15 ft from backboard - 15" rim offset = ~13.75 ft)
    final depthMetersPerPixel =
        CourtConstants.rimToFreeThrowMeters / pixelDist;

    return CalibrationResult(
      calibrationType: 'approx_depth_scale',
      depthMetersPerPixel: depthMetersPerPixel,
      rimScale: rimScale,
    );
  }

  /// Calibrate using rim and free-throw line endpoints.
  ///
  /// [rimCenter] - Detected rim center.
  /// [ftLineEndpoints] - Free-throw line start/end points.
  /// [hasBackboard] - If backboard plane was detected (affects distance).
  CalibrationResult? calibrateFromRimAndFT({
    required ImagePoint rimCenter,
    required LineSegment freeThrowLine,
    required RimScaleResult rimScale,
    bool hasBackboard = false,
  }) {
    final ftMidpoint = freeThrowLine.midpoint;
    final pixelDist = rimCenter.distanceTo(ftMidpoint);

    if (pixelDist < 10) {
      return null;
    }

    // Adjust distance based on whether we have backboard plane
    final realDistance = hasBackboard
        ? CourtConstants.freeThrowDistanceMeters // 15 ft from backboard face
        : CourtConstants.rimToFreeThrowMeters;   // ~13.75 ft from rim center

    final depthMetersPerPixel = realDistance / pixelDist;

    return CalibrationResult(
      calibrationType: hasBackboard ? 'backboard_depth_scale' : 'approx_depth_scale',
      depthMetersPerPixel: depthMetersPerPixel,
      rimScale: rimScale,
    );
  }

  /// Compute a simple affine approximation for near-hoop analytics.
  ///
  /// Uses rim scale + depth scale to create local coordinate system.
  LocalAffineCalibration? computeLocalAffine({
    required RimScaleResult rimScale,
    required double depthMetersPerPixel,
  }) {
    // At hoop depth, we have pixelsPerMeter from rim
    final lateralScale = rimScale.pixelsPerMeterAtHoop;

    // Depth direction uses the depth scale
    final depthScale = 1.0 / depthMetersPerPixel;

    return LocalAffineCalibration(
      originPixel: rimScale.rimCenter,
      lateralPixelsPerMeter: lateralScale,
      depthPixelsPerMeter: depthScale,
    );
  }
}

/// Local affine calibration for near-hoop analytics.
///
/// Provides approximate coordinate conversion without full homography.
class LocalAffineCalibration {
  /// Origin point in pixels (typically rim center).
  final ImagePoint originPixel;

  /// Pixels per meter in lateral (sideline) direction.
  final double lateralPixelsPerMeter;

  /// Pixels per meter in depth (baseline) direction.
  final double depthPixelsPerMeter;

  const LocalAffineCalibration({
    required this.originPixel,
    required this.lateralPixelsPerMeter,
    required this.depthPixelsPerMeter,
  });

  /// Convert pixel offset from origin to meters.
  CourtPoint pixelToMeters(ImagePoint pixel) {
    final dx = pixel.x - originPixel.x;
    final dy = pixel.y - originPixel.y;

    return CourtPoint(
      dx / lateralPixelsPerMeter,
      dy / depthPixelsPerMeter,
    );
  }

  /// Convert court meters to pixel position.
  ImagePoint metersToPixel(CourtPoint court) {
    return ImagePoint(
      originPixel.x + court.x * lateralPixelsPerMeter,
      originPixel.y + court.y * depthPixelsPerMeter,
    );
  }

  /// Check if a point is within 3-point range.
  ///
  /// [feetPixel] - Player's foot position in pixels.
  /// [isNba] - Use NBA distance (7.24m) vs FIBA (6.75m).
  bool is3PointShot(ImagePoint feetPixel, {bool isNba = true}) {
    final court = pixelToMeters(feetPixel);
    final distance = sqrt(court.x * court.x + court.y * court.y);

    final threshold = isNba
        ? CourtConstants.threePointDistanceNbaMeters
        : CourtConstants.threePointDistanceFibaMeters;

    return distance >= threshold;
  }
}
