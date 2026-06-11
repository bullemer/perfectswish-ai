/// Line intersection utilities for computing corner points.
///
/// Used in Mode B to find key corners from detected court lines.

import 'court_spaces.dart';

/// Utilities for computing line intersections.
class LineIntersection {
  LineIntersection._();

  /// Compute intersection of two line segments.
  ///
  /// Returns null if lines are parallel or intersection is outside segments.
  /// Set [extendLines] to true to find intersection even if outside segments.
  static ImagePoint? intersect(
    LineSegment a,
    LineSegment b, {
    bool extendLines = true,
  }) {
    final x1 = a.p1.x, y1 = a.p1.y;
    final x2 = a.p2.x, y2 = a.p2.y;
    final x3 = b.p1.x, y3 = b.p1.y;
    final x4 = b.p2.x, y4 = b.p2.y;

    final denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);

    // Lines are parallel
    if (denom.abs() < 1e-10) {
      return null;
    }

    final t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom;
    final u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / denom;

    if (!extendLines) {
      // Check if intersection is within both segments
      if (t < 0 || t > 1 || u < 0 || u > 1) {
        return null;
      }
    }

    final px = x1 + t * (x2 - x1);
    final py = y1 + t * (y2 - y1);

    return ImagePoint(px, py);
  }

  /// Find key corners from classified court lines.
  ///
  /// Returns corner points with known court positions for homography.
  static List<CornerPoint> findKeyCorners(
    ClassifiedLines lines, {
    required ImagePoint rimCenter,
    bool isNba = true,
  }) {
    final corners = <CornerPoint>[];

    final laneLines = lines.laneLines;
    final ftLine = lines.freeThrowLine;

    if (laneLines == null || laneLines.length < 2 || ftLine == null) {
      return corners;
    }

    // Sort lane lines by X position (left, right)
    final sortedLanes = List<LineSegment>.from(laneLines)
      ..sort((a, b) => a.midpoint.x.compareTo(b.midpoint.x));

    final leftLane = sortedLanes.first;
    final rightLane = sortedLanes.last;

    // Lane width in meters (half on each side of center)
    final halfLaneWidth = CourtConstants.laneWidthMeters / 2;

    // Compute intersections: lane lines with free-throw line
    final ftLeft = intersect(leftLane, ftLine, extendLines: true);
    final ftRight = intersect(rightLane, ftLine, extendLines: true);

    if (ftLeft != null) {
      corners.add(CornerPoint(
        pixelPos: ftLeft,
        courtPos: CourtPoint(-halfLaneWidth, CourtConstants.rimToFreeThrowMeters),
        label: 'FT_LEFT',
      ));
    }

    if (ftRight != null) {
      corners.add(CornerPoint(
        pixelPos: ftRight,
        courtPos: CourtPoint(halfLaneWidth, CourtConstants.rimToFreeThrowMeters),
        label: 'FT_RIGHT',
      ));
    }

    // If baseline is available, compute those corners too
    final baseline = lines.baseline;
    if (baseline != null) {
      final blLeft = intersect(leftLane, baseline, extendLines: true);
      final blRight = intersect(rightLane, baseline, extendLines: true);

      // Baseline is at the plane of the backboard (y=0 relative to rim)
      // Actually rim center is ~0.38m in front of backboard
      const baselineY = -CourtConstants.rimToBackboardMeters;

      if (blLeft != null) {
        corners.add(CornerPoint(
          pixelPos: blLeft,
          courtPos: CourtPoint(-halfLaneWidth, baselineY),
          label: 'BASELINE_LEFT',
        ));
      }

      if (blRight != null) {
        corners.add(CornerPoint(
          pixelPos: blRight,
          courtPos: CourtPoint(halfLaneWidth, baselineY),
          label: 'BASELINE_RIGHT',
        ));
      }
    }

    // Use rim center as known point (0, 0 in court space)
    corners.add(CornerPoint(
      pixelPos: rimCenter,
      courtPos: const CourtPoint(0, 0),
      label: 'RIM_CENTER',
    ));

    return corners;
  }

  /// Compute a rough affine transform from 3 point correspondences.
  ///
  /// Returns a 2x3 affine matrix [a, b, tx, c, d, ty].
  static List<double>? computeAffine(List<CornerPoint> points) {
    if (points.length < 3) return null;

    // Use first 3 points
    final p = points.take(3).toList();

    // Solve for affine transform: court = A * pixel + t
    // This is a simplified version; full solution uses SVD
    final px = [p[0].pixelPos.x, p[1].pixelPos.x, p[2].pixelPos.x];
    final py = [p[0].pixelPos.y, p[1].pixelPos.y, p[2].pixelPos.y];
    final cx = [p[0].courtPos.x, p[1].courtPos.x, p[2].courtPos.x];
    final cy = [p[0].courtPos.y, p[1].courtPos.y, p[2].courtPos.y];

    // Build matrix equation and solve (simplified)
    // For now, return null and let homography handle it
    return null;
  }
}

/// Simple 3x3 matrix class for homography operations.
class Matrix3 {
  final List<double> _data;

  Matrix3(this._data) : assert(_data.length == 9);

  /// Create identity matrix.
  factory Matrix3.identity() => Matrix3([1, 0, 0, 0, 1, 0, 0, 0, 1]);

  /// Create from row-major list.
  factory Matrix3.fromList(List<double> data) => Matrix3(List.from(data));

  /// Get element at (row, col).
  double operator [](int index) => _data[index];

  /// Get element at (row, col).
  double at(int row, int col) => _data[row * 3 + col];

  /// Set element at (row, col).
  void setAt(int row, int col, double value) {
    _data[row * 3 + col] = value;
  }

  /// Transform a point: [x', y', w'] = H * [x, y, 1].
  ImagePoint transformPoint(ImagePoint p) {
    final w = at(2, 0) * p.x + at(2, 1) * p.y + at(2, 2);
    if (w.abs() < 1e-10) return p;

    final x = (at(0, 0) * p.x + at(0, 1) * p.y + at(0, 2)) / w;
    final y = (at(1, 0) * p.x + at(1, 1) * p.y + at(1, 2)) / w;
    return ImagePoint(x, y);
  }

  /// Transform to court point (for floor homography).
  CourtPoint transformToCourtPoint(ImagePoint p) {
    final w = at(2, 0) * p.x + at(2, 1) * p.y + at(2, 2);
    if (w.abs() < 1e-10) return CourtPoint(p.x, p.y);

    final x = (at(0, 0) * p.x + at(0, 1) * p.y + at(0, 2)) / w;
    final y = (at(1, 0) * p.x + at(1, 1) * p.y + at(1, 2)) / w;
    return CourtPoint(x, y);
  }

  /// Transform court point to image (for inverse homography).
  ImagePoint transformFromCourtPoint(CourtPoint p) {
    final w = at(2, 0) * p.x + at(2, 1) * p.y + at(2, 2);
    if (w.abs() < 1e-10) return ImagePoint(p.x, p.y);

    final x = (at(0, 0) * p.x + at(0, 1) * p.y + at(0, 2)) / w;
    final y = (at(1, 0) * p.x + at(1, 1) * p.y + at(1, 2)) / w;
    return ImagePoint(x, y);
  }

  /// Compute matrix inverse using adjugate method.
  Matrix3? inverse() {
    final a = _data;

    // Compute determinant
    final det = a[0] * (a[4] * a[8] - a[5] * a[7]) -
        a[1] * (a[3] * a[8] - a[5] * a[6]) +
        a[2] * (a[3] * a[7] - a[4] * a[6]);

    if (det.abs() < 1e-10) return null;

    final invDet = 1.0 / det;

    // Compute adjugate and divide by determinant
    return Matrix3([
      (a[4] * a[8] - a[5] * a[7]) * invDet,
      (a[2] * a[7] - a[1] * a[8]) * invDet,
      (a[1] * a[5] - a[2] * a[4]) * invDet,
      (a[5] * a[6] - a[3] * a[8]) * invDet,
      (a[0] * a[8] - a[2] * a[6]) * invDet,
      (a[2] * a[3] - a[0] * a[5]) * invDet,
      (a[3] * a[7] - a[4] * a[6]) * invDet,
      (a[1] * a[6] - a[0] * a[7]) * invDet,
      (a[0] * a[4] - a[1] * a[3]) * invDet,
    ]);
  }

  /// Get flattened row-major list.
  List<double> toList() => List.from(_data);

  @override
  String toString() {
    return 'Matrix3(\n'
        '  [${at(0, 0).toStringAsFixed(4)}, ${at(0, 1).toStringAsFixed(4)}, ${at(0, 2).toStringAsFixed(4)}]\n'
        '  [${at(1, 0).toStringAsFixed(4)}, ${at(1, 1).toStringAsFixed(4)}, ${at(1, 2).toStringAsFixed(4)}]\n'
        '  [${at(2, 0).toStringAsFixed(4)}, ${at(2, 1).toStringAsFixed(4)}, ${at(2, 2).toStringAsFixed(4)}]\n'
        ')';
  }
}
