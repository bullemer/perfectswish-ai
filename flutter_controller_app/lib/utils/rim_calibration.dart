import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

/// Rim defined by two tapped points in normalized screen coords (0..1).
/// From the side view the rim appears as a horizontal line segment.
class RimCalibration {
  /// Left post of rim in normalized coords
  final Offset leftN;

  /// Right post of rim in normalized coords
  final Offset rightN;

  const RimCalibration({required this.leftN, required this.rightN});

  Offset get centerN => Offset(
        (leftN.dx + rightN.dx) / 2,
        (leftN.dy + rightN.dy) / 2,
      );

  /// Rim radius in normalized space (half the horizontal span)
  double get radiusN => (rightN.dx - leftN.dx).abs() / 2;

  /// Top of the zone considered "through the rim" (±30% of radius above center)
  double get topZoneN => centerN.dy - radiusN * 0.3;

  /// Bottom of the zone considered "through the rim" (±80% of radius below center)
  double get bottomZoneN => centerN.dy + radiusN * 0.8;

  /// Horizontal margin: ball x must be within this of the rim center
  double get xMarginN => radiusN * 1.1;

  static const _kLeft = 'rim_left';
  static const _kRight = 'rim_right';

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${_kLeft}_x', leftN.dx);
    await prefs.setDouble('${_kLeft}_y', leftN.dy);
    await prefs.setDouble('${_kRight}_x', rightN.dx);
    await prefs.setDouble('${_kRight}_y', rightN.dy);
  }

  static Future<RimCalibration?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final lx = prefs.getDouble('${_kLeft}_x');
    final ly = prefs.getDouble('${_kLeft}_y');
    final rx = prefs.getDouble('${_kRight}_x');
    final ry = prefs.getDouble('${_kRight}_y');
    if (lx == null || ly == null || rx == null || ry == null) return null;
    return RimCalibration(
      leftN: Offset(lx, ly),
      rightN: Offset(rx, ry),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_kLeft}_x');
    await prefs.remove('${_kLeft}_y');
    await prefs.remove('${_kRight}_x');
    await prefs.remove('${_kRight}_y');
  }
}
