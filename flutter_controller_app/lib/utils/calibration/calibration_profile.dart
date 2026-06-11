/// Calibration profile model for Isar persistence.
///
/// Stores all calibration data including:
/// - Visual scale from rim detection
/// - Floor homography (if available)
/// - Fallback depth scale vector
/// - Camera signature for validation

import 'package:isar/isar.dart';

part 'calibration_profile.g.dart';

/// Persisted calibration profile for a specific gym/location.
@Collection()
class CalibrationProfile {
  Id id = Isar.autoIncrement;

  // ─────────────────────────────────────────────────────────────────────────
  // Indexing (for lookup)
  // ─────────────────────────────────────────────────────────────────────────

  /// User-defined gym name (e.g., "YMCA Downtown").
  @Index()
  String? gymName;

  /// GPS bucket for location-based lookup.
  /// Format: "lat_37.774_lon_-122.419" (3 decimal places, ~100m precision).
  @Index()
  String? gpsBucket;

  // ─────────────────────────────────────────────────────────────────────────
  // Camera Signature (for invalidation)
  // ─────────────────────────────────────────────────────────────────────────

  /// Image width in pixels.
  int imageWidth = 0;

  /// Image height in pixels.
  int imageHeight = 0;

  /// Camera orientation (0, 90, 180, 270).
  int orientation = 0;

  /// Lens/FOV info if available (e.g., "wide", "standard").
  String? lensInfo;

  // ─────────────────────────────────────────────────────────────────────────
  // Mode A: Visual Scale (Rim Ruler)
  // ─────────────────────────────────────────────────────────────────────────

  /// Pixels per meter at hoop depth (from rim diameter).
  double? pixelsPerMeterAtHoop;

  /// Rim center X in pixels.
  double? rimCenterX;

  /// Rim center Y in pixels.
  double? rimCenterY;

  /// Rim diameter in pixels (ellipse major axis preferred).
  double? rimDiameterPx;

  /// Confidence of rim detection (0-1).
  double? rimConfidence;

  // ─────────────────────────────────────────────────────────────────────────
  // Mode B: Floor Homography (flattened 3x3 matrix)
  // ─────────────────────────────────────────────────────────────────────────

  /// Homography matrix: pixels -> meters (9 elements, row-major).
  /// H_floor_px_to_m
  List<double>? hFloorPxToM;

  /// Inverse homography: meters -> pixels (9 elements, row-major).
  /// H_floor_m_to_px
  List<double>? hFloorMToPx;

  /// Reprojection error if homography was computed via RANSAC.
  double? reprojectionError;

  /// Number of inlier points used for homography.
  int? homographyInliers;

  // ─────────────────────────────────────────────────────────────────────────
  // Fallback: Depth Scale Vector
  // ─────────────────────────────────────────────────────────────────────────

  /// Meters per pixel along depth direction (rim↔FT line).
  double? depthMetersPerPixel;

  /// Whether this is a partial calibration (no full homography).
  bool isPartialCalibration = false;

  /// Calibration type: "full", "approx_depth_scale", "rim_only".
  String calibrationType = 'rim_only';

  // ─────────────────────────────────────────────────────────────────────────
  // Metadata
  // ─────────────────────────────────────────────────────────────────────────

  /// When this profile was created/updated.
  DateTime timestamp = DateTime.now();

  // ─────────────────────────────────────────────────────────────────────────
  // Helper Methods (ignored by Isar)
  // ─────────────────────────────────────────────────────────────────────────

  /// Check if this profile has a visual scale.
  @ignore
  bool get hasVisualScale => pixelsPerMeterAtHoop != null;

  /// Check if this profile has a full homography.
  @ignore
  bool get hasHomography => hFloorPxToM != null && hFloorPxToM!.length == 9;

  /// Check if this profile has a depth scale fallback.
  @ignore
  bool get hasDepthScale => depthMetersPerPixel != null;

  /// Get rim center as tuple (null if not set).
  @ignore
  (double, double)? get rimCenter {
    if (rimCenterX == null || rimCenterY == null) return null;
    return (rimCenterX!, rimCenterY!);
  }

  /// Set rim center from tuple.
  void setRimCenter((double, double)? value) {
    if (value == null) {
      rimCenterX = null;
      rimCenterY = null;
    } else {
      rimCenterX = value.$1;
      rimCenterY = value.$2;
    }
  }
}

/// Camera signature for profile validation.
class CameraSignature {
  final int width;
  final int height;
  final int orientation;
  final String? lensInfo;

  const CameraSignature({
    required this.width,
    required this.height,
    required this.orientation,
    this.lensInfo,
  });

  /// Check if this signature matches a profile.
  bool matches(CalibrationProfile profile, {double tolerance = 0.05}) {
    // Resolution must match within tolerance
    final widthMatch =
        (profile.imageWidth - width).abs() / width.toDouble() < tolerance;
    final heightMatch =
        (profile.imageHeight - height).abs() / height.toDouble() < tolerance;

    // Orientation must match exactly
    final orientationMatch = profile.orientation == orientation;

    return widthMatch && heightMatch && orientationMatch;
  }

  /// Create GPS bucket string from coordinates.
  static String gpsBucket(double latitude, double longitude) {
    // Round to 3 decimal places (~100m precision)
    final lat = (latitude * 1000).round() / 1000;
    final lon = (longitude * 1000).round() / 1000;
    return 'lat_${lat}_lon_$lon';
  }
}
