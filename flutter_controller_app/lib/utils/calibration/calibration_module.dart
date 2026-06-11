/// Calibration module barrel export.
///
/// Provides a single import for all calibration functionality.
///
/// Usage:
/// ```dart
/// import 'package:flutter_cartracker/utils/calibration/calibration_module.dart';
/// ```

export 'calibration_manager.dart';
export 'calibration_profile.dart' hide CameraSignature;
export 'calibration_repository.dart';
export 'court_calibrator.dart';
export 'court_spaces.dart';
export 'debug_overlay_painter.dart';
export 'homography_estimator.dart';
export 'line_intersection.dart';
export 'rim_calibrator.dart';

// Re-export CameraSignature for convenience
export 'calibration_profile.dart' show CameraSignature;
