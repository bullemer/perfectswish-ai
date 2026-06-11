/// Shot event types and data structures for the Shot Scoring Engine FSM.
///
/// This module defines the output events emitted when a shot result is determined.

import 'dart:convert';

/// The result type of a detected shot attempt.
enum ShotResultType {
  /// Ball passed through the rim (scored)
  make,

  /// Ball did not pass through the rim
  miss,

  /// Shot was blocked (velocity reversal near release)
  block,

  /// Could not determine the result
  unknown,
}

/// A crossing event when the ball crosses a rim edge.
class RimCrossing {
  /// Timestamp in milliseconds
  final int tMs;

  /// 'top' or 'bottom' edge
  final String edge;

  /// 'down' or 'up' direction
  final String direction;

  /// Ball position at crossing
  final (double, double) position;

  /// Ball velocity at crossing
  final (double, double) velocity;

  const RimCrossing({
    required this.tMs,
    required this.edge,
    required this.direction,
    required this.position,
    required this.velocity,
  });

  Map<String, dynamic> toJson() => {
        't_ms': tMs,
        'edge': edge,
        'direction': direction,
        'position': {'x': position.$1, 'y': position.$2},
        'velocity': {'vx': velocity.$1, 'vy': velocity.$2},
      };
}

/// Debug information for a shot attempt.
class ShotDebugInfo {
  /// Position at release
  final (double, double)? releasePos;

  /// Velocity at release (px/sec)
  final (double, double)? vRelease;

  /// Timestamp of apex (if detected)
  final int? apexTMs;

  /// Apex position (if detected)
  final (double, double)? apexPos;

  /// All rim crossings detected
  final List<RimCrossing> rimCrossings;

  /// State trace (for debugging)
  final List<String>? stateTrace;

  const ShotDebugInfo({
    this.releasePos,
    this.vRelease,
    this.apexTMs,
    this.apexPos,
    this.rimCrossings = const [],
    this.stateTrace,
  });

  Map<String, dynamic> toJson() => {
        if (releasePos != null)
          'release_pos': {'x': releasePos!.$1, 'y': releasePos!.$2},
        if (vRelease != null)
          'v_release': {'vx': vRelease!.$1, 'vy': vRelease!.$2},
        if (apexTMs != null) 'apex_t_ms': apexTMs,
        if (apexPos != null) 'apex_pos': {'x': apexPos!.$1, 'y': apexPos!.$2},
        'rim_crossings': rimCrossings.map((c) => c.toJson()).toList(),
        if (stateTrace != null) 'state_trace': stateTrace,
      };
}

/// A shot event emitted when a result is determined.
class ShotEvent {
  /// The result type (make, miss, block, unknown)
  final ShotResultType type;

  /// Timestamp when the ball was released (ms)
  final int tReleaseMs;

  /// Timestamp when the result was determined (ms)
  final int tResultMs;

  /// Debug information for analysis
  final ShotDebugInfo debug;

  const ShotEvent({
    required this.type,
    required this.tReleaseMs,
    required this.tResultMs,
    required this.debug,
  });

  /// Duration from release to result in milliseconds.
  int get durationMs => tResultMs - tReleaseMs;

  Map<String, dynamic> toJson() => {
        'type': type.name.toUpperCase(),
        't_release_ms': tReleaseMs,
        't_result_ms': tResultMs,
        'duration_ms': durationMs,
        'debug': debug.toJson(),
      };

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  @override
  String toString() =>
      'ShotEvent(${type.name.toUpperCase()}, duration=${durationMs}ms)';
}

/// Current state snapshot for debugging.
class ShotFSMSnapshot {
  /// Current FSM state name
  final String state;

  /// Current timestamp (ms)
  final int tMs;

  /// Filtered ball position (null if not tracked)
  final (double, double)? ballPos;

  /// Filtered ball velocity (px/sec, null if not tracked)
  final (double, double)? ballVel;

  /// Ball confidence (0-1)
  final double? ballConf;

  /// Distance to closest hand (px, null if no hands)
  final double? distToHand;

  /// Distance to rim center (px)
  final double? distToRim;

  /// Whether ball is in rim vicinity
  final bool inRimVicinity;

  /// Time in current state (ms)
  final int timeInStateMs;

  /// Various internal flags
  final Map<String, dynamic> flags;

  const ShotFSMSnapshot({
    required this.state,
    required this.tMs,
    this.ballPos,
    this.ballVel,
    this.ballConf,
    this.distToHand,
    this.distToRim,
    this.inRimVicinity = false,
    this.timeInStateMs = 0,
    this.flags = const {},
  });

  Map<String, dynamic> toJson() => {
        'state': state,
        't_ms': tMs,
        if (ballPos != null) 'ball_pos': {'x': ballPos!.$1, 'y': ballPos!.$2},
        if (ballVel != null)
          'ball_vel': {'vx': ballVel!.$1, 'vy': ballVel!.$2},
        if (ballConf != null) 'ball_conf': ballConf,
        if (distToHand != null) 'dist_to_hand': distToHand,
        if (distToRim != null) 'dist_to_rim': distToRim,
        'in_rim_vicinity': inRimVicinity,
        'time_in_state_ms': timeInStateMs,
        if (flags.isNotEmpty) 'flags': flags,
      };
}
