/// Coordinate space types for the Calibration Module.
///
/// Two distinct coordinate spaces:
/// - CourtPlaneSpace: Meters on the floor plane (homography-transformed)
/// - BallAirSpace: Image pixels for airborne ball (scale-converted only)
///
/// CRITICAL: Never apply floor homography to airborne ball positions.

import 'dart:math';

// ─────────────────────────────────────────────────────────────────────────────
// Court Plane Space (Floor - Homography Domain)
// ─────────────────────────────────────────────────────────────────────────────

/// A point on the court floor in meters.
/// Origin is typically at the center of the rim (projected to floor).
class CourtPoint {
  final double x; // Lateral (sideline direction)
  final double y; // Depth (baseline direction)

  const CourtPoint(this.x, this.y);

  double distanceTo(CourtPoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }

  @override
  String toString() => 'CourtPoint($x, $y)';
}

/// A velocity in court space (meters per second).
class CourtVelocity {
  final double vx;
  final double vy;

  const CourtVelocity(this.vx, this.vy);

  double get magnitude => sqrt(vx * vx + vy * vy);

  @override
  String toString() => 'CourtVelocity($vx, $vy)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Ball Air Space (Image Pixels - Scale Domain)
// ─────────────────────────────────────────────────────────────────────────────

/// A point in image pixel coordinates.
class ImagePoint {
  final double x;
  final double y;

  const ImagePoint(this.x, this.y);

  double distanceTo(ImagePoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Convert to record format for compatibility
  (double, double) toRecord() => (x, y);

  factory ImagePoint.fromRecord((double, double) r) => ImagePoint(r.$1, r.$2);

  @override
  String toString() => 'ImagePoint($x, $y)';
}

/// A velocity in image space (pixels per second).
class ImageVelocity {
  final double vx;
  final double vy;

  const ImageVelocity(this.vx, this.vy);

  double get magnitude => sqrt(vx * vx + vy * vy);

  /// Convert to record format for compatibility
  (double, double) toRecord() => (vx, vy);

  factory ImageVelocity.fromRecord((double, double) r) =>
      ImageVelocity(r.$1, r.$2);

  @override
  String toString() => 'ImageVelocity($vx, $vy)';
}

/// Velocity in meters per second (converted from image via scale factor).
class MetricVelocity {
  final double vx;
  final double vy;

  const MetricVelocity(this.vx, this.vy);

  double get magnitude => sqrt(vx * vx + vy * vy);

  @override
  String toString() => 'MetricVelocity($vx m/s, $vy m/s)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Line Geometry
// ─────────────────────────────────────────────────────────────────────────────

/// A line segment in image coordinates.
class LineSegment {
  final ImagePoint p1;
  final ImagePoint p2;

  const LineSegment(this.p1, this.p2);

  /// Length of the segment in pixels.
  double get length => p1.distanceTo(p2);

  /// Angle in radians (0 = horizontal, π/2 = vertical).
  double get angle => atan2(p2.y - p1.y, p2.x - p1.x);

  /// Angle in degrees.
  double get angleDegrees => angle * 180 / pi;

  /// Midpoint of the segment.
  ImagePoint get midpoint => ImagePoint(
        (p1.x + p2.x) / 2,
        (p1.y + p2.y) / 2,
      );

  /// Check if this line is roughly horizontal (within tolerance).
  bool isHorizontal({double toleranceDegrees = 15}) {
    final deg = angleDegrees.abs();
    return deg < toleranceDegrees || deg > (180 - toleranceDegrees);
  }

  /// Check if this line is roughly vertical (within tolerance).
  bool isVertical({double toleranceDegrees = 15}) {
    final deg = angleDegrees.abs();
    return (deg > (90 - toleranceDegrees)) && (deg < (90 + toleranceDegrees));
  }

  @override
  String toString() =>
      'LineSegment(${p1.x.toStringAsFixed(1)},${p1.y.toStringAsFixed(1)} -> '
      '${p2.x.toStringAsFixed(1)},${p2.y.toStringAsFixed(1)}, '
      'len=${length.toStringAsFixed(1)}, ang=${angleDegrees.toStringAsFixed(1)}°)';
}

/// Classified court lines detected in an image.
class ClassifiedLines {
  /// Two parallel lane boundary lines (left and right).
  final List<LineSegment>? laneLines;

  /// The free-throw line (horizontal across lane).
  final LineSegment? freeThrowLine;

  /// The baseline (optional).
  final LineSegment? baseline;

  /// The 3-point arc fragments (optional).
  final List<LineSegment>? arcFragments;

  const ClassifiedLines({
    this.laneLines,
    this.freeThrowLine,
    this.baseline,
    this.arcFragments,
  });

  /// Whether we have enough lines for homography.
  bool get hasMinimumForHomography =>
      laneLines != null && laneLines!.length >= 2 && freeThrowLine != null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Corner Points (for homography correspondence)
// ─────────────────────────────────────────────────────────────────────────────

/// A corner point with known pixel and court positions.
class CornerPoint {
  /// Position in image pixels.
  final ImagePoint pixelPos;

  /// Position in court meters (known from court geometry).
  final CourtPoint courtPos;

  /// Human-readable label (e.g., "FT_LEFT", "LANE_BASELINE_LEFT").
  final String label;

  const CornerPoint({
    required this.pixelPos,
    required this.courtPos,
    required this.label,
  });

  @override
  String toString() => 'CornerPoint($label: $pixelPos -> $courtPos)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Court Constants (NBA/FIBA)
// ─────────────────────────────────────────────────────────────────────────────

/// Standard basketball court dimensions.
class CourtConstants {
  CourtConstants._();

  /// Rim diameter: 18 inches = 0.4572 meters.
  static const double rimDiameterMeters = 0.4572;

  /// Rim radius.
  static const double rimRadiusMeters = rimDiameterMeters / 2;

  /// Lane (key) width: 16 feet = 4.88 meters (NBA).
  static const double laneWidthMeters = 4.88;

  /// Free-throw line distance from backboard face: 15 feet = 4.572 meters.
  static const double freeThrowDistanceMeters = 4.572;

  /// Rim center is ~15 inches (0.381m) in front of backboard face.
  static const double rimToBackboardMeters = 0.381;

  /// Rim center to free-throw line: 15ft - 15in ≈ 13.75ft = 4.19m.
  static const double rimToFreeThrowMeters =
      freeThrowDistanceMeters - rimToBackboardMeters;

  /// 3-point line distance (NBA): 23.75 feet at top = 7.24 meters.
  static const double threePointDistanceNbaMeters = 7.24;

  /// 3-point line distance (FIBA): 6.75 meters.
  static const double threePointDistanceFibaMeters = 6.75;

  /// 3-point corner distance (both): 22 feet = 6.71 meters.
  static const double threePointCornerMeters = 6.71;
}
