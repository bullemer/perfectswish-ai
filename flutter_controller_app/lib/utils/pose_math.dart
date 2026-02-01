import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Computes the 2D angle at point p2 formed by the vectors p1→p2 and p2→p3.
/// Returns the angle in degrees (0-180).
double computeAngle(PoseLandmark p1, PoseLandmark p2, PoseLandmark p3) {
  final double v1x = p1.x - p2.x;
  final double v1y = p1.y - p2.y;
  final double v2x = p3.x - p2.x;
  final double v2y = p3.y - p2.y;
  
  final double dot = v1x * v2x + v1y * v2y;
  final double mag1 = sqrt(v1x * v1x + v1y * v1y);
  final double mag2 = sqrt(v2x * v2x + v2y * v2y);
  
  if (mag1 == 0 || mag2 == 0) return 0;
  
  double cosAngle = dot / (mag1 * mag2);
  // Clamp to avoid NaN from acos due to floating point errors
  cosAngle = cosAngle.clamp(-1.0, 1.0);
  
  return acos(cosAngle) * 180 / pi;
}

/// Get elbow angle (Shoulder-Elbow-Wrist) for the specified side.
double? getElbowAngle(Pose pose, {required bool isLeft}) {
  final shoulder = pose.landmarks[isLeft ? PoseLandmarkType.leftShoulder : PoseLandmarkType.rightShoulder];
  final elbow = pose.landmarks[isLeft ? PoseLandmarkType.leftElbow : PoseLandmarkType.rightElbow];
  final wrist = pose.landmarks[isLeft ? PoseLandmarkType.leftWrist : PoseLandmarkType.rightWrist];
  
  if (shoulder == null || elbow == null || wrist == null) return null;
  
  // Check confidence thresholds
  if (shoulder.likelihood < 0.5 || elbow.likelihood < 0.5 || wrist.likelihood < 0.5) {
    return null;
  }
  
  return computeAngle(shoulder, elbow, wrist);
}

/// Get knee angle (Hip-Knee-Ankle) for the specified side.
double? getKneeAngle(Pose pose, {required bool isLeft}) {
  final hip = pose.landmarks[isLeft ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip];
  final knee = pose.landmarks[isLeft ? PoseLandmarkType.leftKnee : PoseLandmarkType.rightKnee];
  final ankle = pose.landmarks[isLeft ? PoseLandmarkType.leftAnkle : PoseLandmarkType.rightAnkle];
  
  if (hip == null || knee == null || ankle == null) return null;
  
  if (hip.likelihood < 0.5 || knee.likelihood < 0.5 || ankle.likelihood < 0.5) {
    return null;
  }
  
  return computeAngle(hip, knee, ankle);
}

/// Get shoulder angle (Elbow-Shoulder-Hip) for the specified side.
double? getShoulderAngle(Pose pose, {required bool isLeft}) {
  final elbow = pose.landmarks[isLeft ? PoseLandmarkType.leftElbow : PoseLandmarkType.rightElbow];
  final shoulder = pose.landmarks[isLeft ? PoseLandmarkType.leftShoulder : PoseLandmarkType.rightShoulder];
  final hip = pose.landmarks[isLeft ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip];
  
  if (elbow == null || shoulder == null || hip == null) return null;
  
  if (elbow.likelihood < 0.5 || shoulder.likelihood < 0.5 || hip.likelihood < 0.5) {
    return null;
  }
  
  return computeAngle(elbow, shoulder, hip);
}
