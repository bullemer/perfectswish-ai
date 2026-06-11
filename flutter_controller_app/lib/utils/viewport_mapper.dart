import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';

/// Maps between source-normalized coordinates (0..1) and widget pixels.
/// Uses Flutter's applyBoxFit() for correct cover/contain calculations.
class ViewportMapper {
  ViewportMapper({
    required this.src, // e.g. Size(480, 640) from camera
    required this.dst, // constraints.biggest (logical pixels)
    this.fit = BoxFit.cover, // must match how the preview is rendered
  }) {
    final fs = applyBoxFit(fit, src, dst);

    fittedSrc = fs.source;         // portion of src actually visible (cover crops)
    fittedDst = fs.destination;    // size in dst that the fittedSrc maps to

    scale = fittedDst.width / fittedSrc.width; // same as height ratio
    offset = Offset(
      (dst.width - fittedDst.width) / 2.0,
      (dst.height - fittedDst.height) / 2.0,
    );
    crop = Offset(
      (src.width - fittedSrc.width) / 2.0,
      (src.height - fittedSrc.height) / 2.0,
    );
  }

  final Size src;
  final Size dst;
  final BoxFit fit;

  late final Size fittedSrc;
  late final Size fittedDst;
  late final double scale;
  late final Offset offset; // dx/dy in dst (logical)
  late final Offset crop;   // crop in src pixels

  /// Source-normalized (0..1) -> dst pixels (logical)
  Rect srcNormToDst(Rect n) {
    final srcRect = Rect.fromLTWH(
      n.left * src.width,
      n.top * src.height,
      n.width * src.width,
      n.height * src.height,
    );

    // shift into the *visible* crop window of the source
    final cropped = srcRect.shift(Offset(-crop.dx, -crop.dy));

    return Rect.fromLTWH(
      offset.dx + cropped.left * scale,
      offset.dy + cropped.top * scale,
      cropped.width * scale,
      cropped.height * scale,
    );
  }

  /// Source-normalized point (0..1) -> dst pixels (logical)
  Offset srcNormPointToDst(Offset n) {
    final srcPt = Offset(n.dx * src.width, n.dy * src.height);
    final cropped = srcPt - crop;
    return Offset(
      offset.dx + cropped.dx * scale,
      offset.dy + cropped.dy * scale,
    );
  }

  /// dst pixels (logical) -> source-normalized (0..1) (useful for ROI gestures)
  Rect dstToSrcNorm(Rect r) {
    final left   = ((r.left   - offset.dx) / scale + crop.dx) / src.width;
    final top    = ((r.top    - offset.dy) / scale + crop.dy) / src.height;
    final right  = ((r.right  - offset.dx) / scale + crop.dx) / src.width;
    final bottom = ((r.bottom - offset.dy) / scale + crop.dy) / src.height;

    return Rect.fromLTRB(
      left.clamp(0.0, 1.0),
      top.clamp(0.0, 1.0),
      right.clamp(0.0, 1.0),
      bottom.clamp(0.0, 1.0),
    );
  }

  /// Check if a box is visible after applying the transform
  bool isVisible(Rect n) {
    final dstRect = srcNormToDst(n);
    final visible = dstRect.intersect(Offset.zero & dst);
    return !visible.isEmpty && visible.width > 1 && visible.height > 1;
  }
}
