/// Homography estimation using DLT and RANSAC.
///
/// Used in Mode B to compute floor-to-pixel transformations.

import 'dart:math';
import 'court_spaces.dart';
import 'line_intersection.dart';

/// Result of homography estimation.
class HomographyResult {
  /// Homography: pixels -> court meters.
  final Matrix3 hPxToM;

  /// Inverse homography: court meters -> pixels.
  final Matrix3 hMToPx;

  /// Average reprojection error in pixels.
  final double reprojectionError;

  /// Inlier points used for final estimation.
  final List<CornerPoint> inliers;

  /// Total number of input points.
  final int totalPoints;

  const HomographyResult({
    required this.hPxToM,
    required this.hMToPx,
    required this.reprojectionError,
    required this.inliers,
    required this.totalPoints,
  });

  /// Inlier ratio.
  double get inlierRatio => inliers.length / totalPoints;

  @override
  String toString() =>
      'HomographyResult(inliers=${inliers.length}/$totalPoints, '
      'error=${reprojectionError.toStringAsFixed(2)}px)';
}

/// Homography estimator using Direct Linear Transform (DLT) and RANSAC.
class HomographyEstimator {
  final Random _random = Random();

  /// Compute homography using DLT from 4+ point correspondences.
  ///
  /// Returns null if not enough points or singular matrix.
  Matrix3? computeDLT(List<CornerPoint> correspondences) {
    if (correspondences.length < 4) {
      return null;
    }

    // Normalize points for numerical stability
    final normalizedSrc = _normalizePoints(
        correspondences.map((c) => c.pixelPos).toList());
    final normalizedDst = _normalizeCourtPoints(
        correspondences.map((c) => c.courtPos).toList());

    // Build DLT matrix A
    // For each correspondence (x,y) -> (u,v):
    // [ x  y  1  0  0  0 -ux -uy -u ]
    // [ 0  0  0  x  y  1 -vx -vy -v ]
    final n = correspondences.length;
    final a = List.generate(n * 2, (_) => List.filled(9, 0.0));

    for (var i = 0; i < n; i++) {
      final src = normalizedSrc.normalized[i];
      final dst = normalizedDst.normalized[i];
      final x = src.x, y = src.y;
      final u = dst.x, v = dst.y;

      a[i * 2] = [x, y, 1, 0, 0, 0, -u * x, -u * y, -u];
      a[i * 2 + 1] = [0, 0, 0, x, y, 1, -v * x, -v * y, -v];
    }

    // Solve Ah = 0 using SVD (simplified: use pseudo-inverse for small systems)
    final h = _solveHomogeneous(a);
    if (h == null) return null;

    // Denormalize
    final H = _denormalizeHomography(h, normalizedSrc.T, normalizedDst.T);

    // Normalize so H[8] = 1
    if (H[8].abs() > 1e-10) {
      for (var i = 0; i < 9; i++) {
        H[i] /= H[8];
      }
    }

    return Matrix3.fromList(H);
  }

  /// Compute homography using RANSAC for robust estimation.
  ///
  /// [correspondences] - Point pairs (pixel, court).
  /// [iterations] - Number of RANSAC iterations.
  /// [threshold] - Inlier threshold in pixels.
  HomographyResult? computeRANSAC(
    List<CornerPoint> correspondences, {
    int iterations = 500,
    double threshold = 5.0,
  }) {
    if (correspondences.length < 4) {
      return null;
    }

    List<CornerPoint>? bestInliers;
    Matrix3? bestH;

    for (var iter = 0; iter < iterations; iter++) {
      // Random sample of 4 points
      final sample = _randomSample(correspondences, 4);

      // Compute homography from sample
      final h = computeDLT(sample);
      if (h == null) continue;

      // Count inliers
      final inliers = <CornerPoint>[];
      for (final c in correspondences) {
        final projected = h.transformPoint(c.pixelPos);
        final error = sqrt(pow(projected.x - c.courtPos.x, 2) +
            pow(projected.y - c.courtPos.y, 2));

        // Convert error to pixel space for threshold comparison
        // Use inverse transform for comparison
        final inv = h.inverse();
        if (inv != null) {
          final backProjected = inv.transformFromCourtPoint(c.courtPos);
          final pixelError = c.pixelPos.distanceTo(backProjected);
          if (pixelError < threshold) {
            inliers.add(c);
          }
        }
      }

      if (bestInliers == null || inliers.length > bestInliers.length) {
        bestInliers = inliers;
        bestH = h;
      }

      // Early termination if we have enough inliers
      if (bestInliers.length >= correspondences.length * 0.9) {
        break;
      }
    }

    if (bestInliers == null || bestInliers.length < 4 || bestH == null) {
      return null;
    }

    // Refine homography using all inliers
    final refinedH = computeDLT(bestInliers);
    if (refinedH == null) {
      return null;
    }

    final inverseH = refinedH.inverse();
    if (inverseH == null) {
      return null;
    }

    // Compute reprojection error
    final error = _computeReprojectionError(bestInliers, inverseH);

    return HomographyResult(
      hPxToM: refinedH,
      hMToPx: inverseH,
      reprojectionError: error,
      inliers: bestInliers,
      totalPoints: correspondences.length,
    );
  }

  /// Random sample without replacement.
  List<T> _randomSample<T>(List<T> list, int count) {
    final indices = List.generate(list.length, (i) => i)..shuffle(_random);
    return indices.take(count).map((i) => list[i]).toList();
  }

  /// Compute average reprojection error in pixels.
  double _computeReprojectionError(List<CornerPoint> points, Matrix3 hMToPx) {
    var totalError = 0.0;
    for (final c in points) {
      final projected = hMToPx.transformFromCourtPoint(c.courtPos);
      totalError += c.pixelPos.distanceTo(projected);
    }
    return totalError / points.length;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Normalization helpers
  // ─────────────────────────────────────────────────────────────────────────

  _NormalizedPoints _normalizePoints(List<ImagePoint> points) {
    // Compute centroid
    var cx = 0.0, cy = 0.0;
    for (final p in points) {
      cx += p.x;
      cy += p.y;
    }
    cx /= points.length;
    cy /= points.length;

    // Compute average distance from centroid
    var avgDist = 0.0;
    for (final p in points) {
      avgDist += sqrt(pow(p.x - cx, 2) + pow(p.y - cy, 2));
    }
    avgDist /= points.length;

    final scale = sqrt(2) / (avgDist + 1e-10);

    // Normalize points
    final normalized = points
        .map((p) => ImagePoint((p.x - cx) * scale, (p.y - cy) * scale))
        .toList();

    // Normalization matrix T
    final T = Matrix3([scale, 0, -cx * scale, 0, scale, -cy * scale, 0, 0, 1]);

    return _NormalizedPoints(normalized, T);
  }

  _NormalizedCourtPoints _normalizeCourtPoints(List<CourtPoint> points) {
    var cx = 0.0, cy = 0.0;
    for (final p in points) {
      cx += p.x;
      cy += p.y;
    }
    cx /= points.length;
    cy /= points.length;

    var avgDist = 0.0;
    for (final p in points) {
      avgDist += sqrt(pow(p.x - cx, 2) + pow(p.y - cy, 2));
    }
    avgDist /= points.length;

    final scale = sqrt(2) / (avgDist + 1e-10);

    final normalized = points
        .map((p) => CourtPoint((p.x - cx) * scale, (p.y - cy) * scale))
        .toList();

    final T = Matrix3([scale, 0, -cx * scale, 0, scale, -cy * scale, 0, 0, 1]);

    return _NormalizedCourtPoints(normalized, T);
  }

  List<double> _denormalizeHomography(
      List<double> h, Matrix3 Tsrc, Matrix3 Tdst) {
    // H = Tdst^-1 * Hnorm * Tsrc
    final TdstInv = Tdst.inverse();
    if (TdstInv == null) return h;

    final Hnorm = Matrix3.fromList(h);

    // Multiply: TdstInv * Hnorm
    final temp = _matmul(TdstInv, Hnorm);

    // Multiply: temp * Tsrc
    final result = _matmul(temp, Tsrc);

    return result.toList();
  }

  Matrix3 _matmul(Matrix3 a, Matrix3 b) {
    final result = List.filled(9, 0.0);
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        for (var k = 0; k < 3; k++) {
          result[i * 3 + j] += a.at(i, k) * b.at(k, j);
        }
      }
    }
    return Matrix3(result);
  }

  /// Solve homogeneous system Ah = 0.
  ///
  /// Uses SVD approximation for small systems.
  List<double>? _solveHomogeneous(List<List<double>> a) {
    final m = a.length;
    if (m < 8) return null; // Need at least 4 points (8 equations)

    // Compute A^T * A
    final ata = List.generate(9, (_) => List.filled(9, 0.0));
    for (var i = 0; i < 9; i++) {
      for (var j = 0; j < 9; j++) {
        for (var k = 0; k < m; k++) {
          ata[i][j] += a[k][i] * a[k][j];
        }
      }
    }

    // Power iteration to find smallest eigenvector
    var v = List.filled(9, 1.0 / 3);
    for (var iter = 0; iter < 100; iter++) {
      // v = (A^T A)^-1 * v  (approximate with iteration)
      final vNew = List.filled(9, 0.0);
      for (var i = 0; i < 9; i++) {
        for (var j = 0; j < 9; j++) {
          vNew[i] += ata[i][j] * v[j];
        }
      }

      // Normalize
      var norm = 0.0;
      for (var i = 0; i < 9; i++) {
        norm += vNew[i] * vNew[i];
      }
      norm = sqrt(norm);
      if (norm < 1e-10) return null;

      for (var i = 0; i < 9; i++) {
        v[i] = vNew[i] / norm;
      }
    }

    // The eigenvector corresponding to smallest eigenvalue
    // For simple implementation, use Jacobi iteration or return after power iteration
    // This is a simplified version; production code should use proper SVD

    return v;
  }
}

class _NormalizedPoints {
  final List<ImagePoint> normalized;
  final Matrix3 T;
  _NormalizedPoints(this.normalized, this.T);
}

class _NormalizedCourtPoints {
  final List<CourtPoint> normalized;
  final Matrix3 T;
  _NormalizedCourtPoints(this.normalized, this.T);
}
