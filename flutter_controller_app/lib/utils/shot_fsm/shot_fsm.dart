/// Shot Scoring Engine - Finite State Machine implementation.
///
/// Detects basketball shots using an 8-state FSM with filtering,
/// hysteresis, and cooldown logic to prevent ghost shots and double triggers.
///
/// States: IDLE → PREPARE → RELEASE → AIRBORNE → APEX → TARGET → RESULT → COOLDOWN

import 'dart:math';

import 'ball_state_filter.dart';
import 'shot_event.dart';
import 'shot_fsm_config.dart';

/// FSM states for shot detection.
enum ShotFSMState {
  idle,
  prepare,
  release,
  airborne,
  apex,
  target,
  result,
  cooldown,
}

/// Hand/wrist keypoint data.
class HandKeypoint {
  final double x;
  final double y;
  final double conf;

  const HandKeypoint({
    required this.x,
    required this.y,
    this.conf = 1.0,
  });
}

/// Rim geometry in 2D screen coordinates.
class RimGeometry {
  /// Center of the rim (x, y)
  final (double, double) center;

  /// Rim radius in pixels
  final double radiusPx;

  /// Y coordinate of rim top edge
  final double topY;

  /// Y coordinate of rim bottom edge
  final double bottomY;

  const RimGeometry({
    required this.center,
    required this.radiusPx,
    required this.topY,
    required this.bottomY,
  });

  /// Compute vicinity radius based on scale factor.
  double vicinityRadius(double scale) => radiusPx * scale;
}

/// Frame data input to the FSM.
class FrameData {
  /// Timestamp in milliseconds
  final int tMs;

  /// Frame rate (optional, can compute from timestamps)
  final double? fps;

  /// Ball center position (null if not detected)
  final (double, double)? ballPos;

  /// Ball detection confidence (0-1)
  final double ballConf;

  /// Detected hand/wrist keypoints (empty if unavailable)
  final List<HandKeypoint> hands;

  /// Rim geometry
  final RimGeometry rim;

  const FrameData({
    required this.tMs,
    this.fps,
    this.ballPos,
    this.ballConf = 0.0,
    this.hands = const [],
    required this.rim,
  });
}

/// Callback type for shot events.
typedef ShotEventCallback = void Function(ShotEvent event);

/// Shot Scoring Engine - Finite State Machine.
///
/// Call [update] every frame with detection data.
/// Emits [ShotEvent] when a shot result is determined.
class ShotFSM {
  final ShotFSMConfig config;
  final ShotEventCallback? onShotEvent;

  // Internal state
  ShotFSMState _state = ShotFSMState.idle;
  int _stateEnteredMs = 0;
  int? _lastUpdateMs;

  // Ball filter
  late final BallStateFilter _ballFilter;

  // State-specific tracking
  int _prepareFrameCount = 0;
  int _airborneConfirmCount = 0;
  int _apexConfirmCount = 0;
  bool _wasNearHand = false;
  int _distIncreasingFrames = 0;

  // Release tracking
  int? _releaseMs;
  (double, double)? _releasePos;
  (double, double)? _releaseVel;

  // Apex tracking
  int? _apexMs;
  (double, double)? _apexPos;
  double? _prevVy;

  // Target/crossing tracking
  int? _targetEnteredMs;
  final List<RimCrossing> _rimCrossings = [];
  bool _wasAboveTopEdge = false;
  bool _wasBelowBottomEdge = false;
  int? _topCrossingMs;
  (double, double)? _topCrossingVel;

  // Cooldown tracking
  int? _resultMs;
  bool _ballLeftVicinity = false;
  bool _ballBelowRim = false;

  // Debug trace
  final List<String> _stateTrace = [];

  // Pending event (emitted on next update after RESULT)
  ShotEvent? _pendingEvent;

  ShotFSM({
    this.config = const ShotFSMConfig(),
    this.onShotEvent,
  }) {
    config.validate();
    _ballFilter = BallStateFilter(config: config);
  }

  /// Current FSM state.
  ShotFSMState get state => _state;

  /// Current filtered ball state.
  FilteredBallState get filteredBall => _ballFilter.currentState;

  /// Update the FSM with new frame data.
  ///
  /// Returns any pending [ShotEvent], or null if no event.
  ShotEvent? update(FrameData frame) {
    _lastUpdateMs = frame.tMs;

    // Update ball filter
    final ballState = _ballFilter.update(
      tMs: frame.tMs,
      x: frame.ballPos?.$1,
      y: frame.ballPos?.$2,
      conf: frame.ballConf,
    );

    // Process state machine
    switch (_state) {
      case ShotFSMState.idle:
        _processIdle(frame, ballState);
      case ShotFSMState.prepare:
        _processPrepare(frame, ballState);
      case ShotFSMState.release:
        _processRelease(frame, ballState);
      case ShotFSMState.airborne:
        _processAirborne(frame, ballState);
      case ShotFSMState.apex:
        _processApex(frame, ballState);
      case ShotFSMState.target:
        _processTarget(frame, ballState);
      case ShotFSMState.result:
        _processResult(frame, ballState);
      case ShotFSMState.cooldown:
        _processCooldown(frame, ballState);
    }

    // Return and clear pending event
    final event = _pendingEvent;
    _pendingEvent = null;
    return event;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // State processors
  // ─────────────────────────────────────────────────────────────────────────

  void _processIdle(FrameData frame, FilteredBallState ballState) {
    if (!ballState.isValid) return;

    // Check if ball is near any hand
    if (frame.hands.isNotEmpty) {
      final minDist = _minDistToHands(ballState.pos, frame.hands);
      if (minDist != null && minDist < config.dHoldPx) {
        _prepareFrameCount++;
        if (_prepareFrameCount >= config.prepareMinFrames) {
          _transitionTo(ShotFSMState.prepare, frame.tMs);
          _wasNearHand = true;
        }
        return;
      }
    } else {
      // No hands: use velocity-based "possession" heuristic
      // Ball is slow (possession) if speed < some threshold
      if (ballState.speed < 200) {
        // Low speed suggests possession
        _prepareFrameCount++;
        if (_prepareFrameCount >= config.prepareMinFrames) {
          _transitionTo(ShotFSMState.prepare, frame.tMs);
          _wasNearHand = false;
        }
        return;
      }
    }

    _prepareFrameCount = 0;
  }

  void _processPrepare(FrameData frame, FilteredBallState ballState) {
    if (!ballState.isValid) {
      // Lost tracking, return to IDLE
      _transitionTo(ShotFSMState.idle, frame.tMs);
      return;
    }

    if (frame.hands.isNotEmpty && _wasNearHand) {
      final minDist = _minDistToHands(ballState.pos, frame.hands);
      if (minDist != null) {
        // Hysteresis: need to exceed dReleasePx to trigger release
        if (minDist > config.dReleasePx) {
          _distIncreasingFrames++;
          if (_distIncreasingFrames >= 2) {
            _captureRelease(frame.tMs, ballState);
            _transitionTo(ShotFSMState.release, frame.tMs);
          }
        } else if (minDist > config.dHoldPx) {
          // Between hold and release: check if distance is increasing
          // (handled by dReleasePx check above)
        } else {
          // Still near hand
          _distIncreasingFrames = 0;
        }
        return;
      }
    }

    // No hands but was in prepare: check for upward velocity
    final vy = ballState.vel.$2;
    // Y increases downward, so upward velocity is negative
    if (vy < -config.vReleaseMinPxS * 0.5) {
      // Ball moving upward, likely released
      _captureRelease(frame.tMs, ballState);
      _transitionTo(ShotFSMState.release, frame.tMs);
    }
  }

  void _processRelease(FrameData frame, FilteredBallState ballState) {
    if (!ballState.isValid) {
      // Lost tracking shortly after release, go to IDLE
      _transitionTo(ShotFSMState.idle, frame.tMs);
      return;
    }

    final timeInState = frame.tMs - _stateEnteredMs;

    // Check for AIRBORNE confirmation
    final vy = ballState.vel.$2;
    final vx = ballState.vel.$1;

    // Upward velocity check (Y increases downward)
    final isMovingUp = vy < -config.vReleaseMinPxS;

    // Or check velocity toward rim (for layups)
    final toRim = (
      frame.rim.center.$1 - ballState.pos.$1,
      frame.rim.center.$2 - ballState.pos.$2
    );
    final toRimDist = sqrt(toRim.$1 * toRim.$1 + toRim.$2 * toRim.$2);
    final velDotRim =
        toRimDist > 0 ? (vx * toRim.$1 + vy * toRim.$2) / toRimDist : 0;
    final isMovingToRim = velDotRim > config.vToRimMinPxS;

    if (isMovingUp || isMovingToRim) {
      _airborneConfirmCount++;
      if (_airborneConfirmCount >= config.airborneConfirmFrames) {
        _transitionTo(ShotFSMState.airborne, frame.tMs);
        return;
      }
    } else {
      _airborneConfirmCount = 0;
    }

    // Check for block (velocity reversal)
    if (_releaseVel != null && timeInState < config.blockWindowMs) {
      final origVy = _releaseVel!.$2;
      if (origVy < 0 && vy > -origVy * config.blockVelFlipThreshold) {
        // Velocity has reversed significantly
        _emitEvent(ShotResultType.block, frame.tMs);
        return;
      }
    }

    // Timeout
    if (timeInState > config.releaseTimeoutMs) {
      _transitionTo(ShotFSMState.idle, frame.tMs);
    }
  }

  void _processAirborne(FrameData frame, FilteredBallState ballState) {
    // Check for entering rim vicinity
    if (_checkRimVicinity(ballState, frame.rim)) {
      _transitionTo(ShotFSMState.target, frame.tMs);
      return;
    }

    if (!ballState.isValid) {
      // Brief occlusion allowed
      if (ballState.msSinceGoodObs > config.occlusionMsMax) {
        _transitionTo(ShotFSMState.idle, frame.tMs);
      }
      return;
    }

    // Detect apex (velocity sign change: from negative to positive vy)
    final vy = ballState.vel.$2;
    if (_prevVy != null && _prevVy! < 0 && vy > 0) {
      // Velocity changed from up to down
      _apexConfirmCount++;
      if (_apexConfirmCount >= config.apexConfirmFrames) {
        _apexMs = frame.tMs;
        _apexPos = ballState.pos;
        _transitionTo(ShotFSMState.apex, frame.tMs);
      }
    } else {
      _apexConfirmCount = 0;
    }
    _prevVy = vy;
  }

  void _processApex(FrameData frame, FilteredBallState ballState) {
    // Check for entering rim vicinity
    if (_checkRimVicinity(ballState, frame.rim)) {
      _transitionTo(ShotFSMState.target, frame.tMs);
      return;
    }

    if (!ballState.isValid) {
      if (ballState.msSinceGoodObs > config.occlusionMsMax) {
        _transitionTo(ShotFSMState.idle, frame.tMs);
      }
      return;
    }

    // Ball should be moving down now
    final vy = ballState.vel.$2;
    _prevVy = vy;
  }

  void _processTarget(FrameData frame, FilteredBallState ballState) {
    if (_targetEnteredMs == null) {
      _targetEnteredMs = frame.tMs;
      _wasAboveTopEdge = false;
      _wasBelowBottomEdge = false;
    }

    final timeInTarget = frame.tMs - _targetEnteredMs!;
    final rim = frame.rim;

    if (!ballState.isValid) {
      // Lost tracking in target zone
      if (timeInTarget > config.targetGraceMs) {
        _emitEvent(ShotResultType.unknown, frame.tMs);
      }
      return;
    }

    final (bx, by) = ballState.pos;
    final (vx, vy) = ballState.vel;

    // Track rim edge crossings
    _updateRimCrossings(frame.tMs, bx, by, vx, vy, rim);

    // Check for MAKE: top crossing followed by bottom crossing
    if (_checkMake(frame.tMs, bx, rim)) {
      _emitEvent(ShotResultType.make, frame.tMs);
      return;
    }

    // Check for exit from vicinity without make
    final distToRim = _distToRimCenter(ballState.pos, rim);
    final exitRadius = rim.vicinityRadius(config.rimVicinityExitScale);
    if (distToRim > exitRadius && timeInTarget > config.targetGraceMs) {
      _emitEvent(ShotResultType.miss, frame.tMs);
      return;
    }

    // Timeout
    if (timeInTarget > config.missTimeoutMs) {
      _emitEvent(ShotResultType.miss, frame.tMs);
    }
  }

  void _processResult(FrameData frame, FilteredBallState ballState) {
    // Immediately transition to cooldown
    _transitionTo(ShotFSMState.cooldown, frame.tMs);
  }

  void _processCooldown(FrameData frame, FilteredBallState ballState) {
    final timeInCooldown = frame.tMs - _stateEnteredMs;
    final rim = frame.rim;

    // Always enforce minimum cooldown
    if (timeInCooldown < config.cooldownMinMs) return;

    // Check exit conditions
    if (ballState.isValid) {
      final distToRim = _distToRimCenter(ballState.pos, rim);
      final exitRadius = rim.vicinityRadius(config.rimVicinityExitScale);

      // Ball left vicinity?
      if (distToRim > exitRadius) {
        _ballLeftVicinity = true;
      }

      // Ball below rim?
      if (ballState.pos.$2 > rim.bottomY + config.resetBelowRimMarginPx) {
        _ballBelowRim = true;
      }
    }

    // Exit cooldown if conditions met or max time reached
    if ((_ballLeftVicinity && _ballBelowRim) ||
        timeInCooldown > config.cooldownMaxMs) {
      _transitionTo(ShotFSMState.idle, frame.tMs);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _transitionTo(ShotFSMState newState, int tMs) {
    if (config.logTransitions) {
      print('ShotFSM: ${_state.name} → ${newState.name} @ $tMs ms');
    }
    if (config.enableStateTrace) {
      _stateTrace.add('${_state.name}→${newState.name}@$tMs');
    }

    _state = newState;
    _stateEnteredMs = tMs;

    // Reset state-specific variables
    switch (newState) {
      case ShotFSMState.idle:
        _resetAll();
      case ShotFSMState.prepare:
        _distIncreasingFrames = 0;
      case ShotFSMState.release:
        _airborneConfirmCount = 0;
      case ShotFSMState.airborne:
        _apexConfirmCount = 0;
        _prevVy = null;
      case ShotFSMState.apex:
        break;
      case ShotFSMState.target:
        _targetEnteredMs = tMs;
        _rimCrossings.clear();
        _wasAboveTopEdge = false;
        _wasBelowBottomEdge = false;
        _topCrossingMs = null;
        _topCrossingVel = null;
      case ShotFSMState.result:
        break;
      case ShotFSMState.cooldown:
        _ballLeftVicinity = false;
        _ballBelowRim = false;
      default:
        break;
    }
  }

  void _resetAll() {
    _prepareFrameCount = 0;
    _airborneConfirmCount = 0;
    _apexConfirmCount = 0;
    _wasNearHand = false;
    _distIncreasingFrames = 0;
    _releaseMs = null;
    _releasePos = null;
    _releaseVel = null;
    _apexMs = null;
    _apexPos = null;
    _prevVy = null;
    _targetEnteredMs = null;
    _rimCrossings.clear();
    _wasAboveTopEdge = false;
    _wasBelowBottomEdge = false;
    _topCrossingMs = null;
    _topCrossingVel = null;
    _ballLeftVicinity = false;
    _ballBelowRim = false;
    if (config.enableStateTrace) {
      _stateTrace.clear();
    }
  }

  void _captureRelease(int tMs, FilteredBallState ballState) {
    _releaseMs = tMs;
    _releasePos = ballState.pos;
    _releaseVel = ballState.vel;
  }

  double? _minDistToHands(
      (double, double) ballPos, List<HandKeypoint> hands) {
    if (hands.isEmpty) return null;
    double? minDist;
    for (final hand in hands) {
      if (hand.conf < config.handConfMin) continue;
      final dx = ballPos.$1 - hand.x;
      final dy = ballPos.$2 - hand.y;
      final dist = sqrt(dx * dx + dy * dy);
      if (minDist == null || dist < minDist) {
        minDist = dist;
      }
    }
    return minDist;
  }

  double _distToRimCenter((double, double) pos, RimGeometry rim) {
    final dx = pos.$1 - rim.center.$1;
    final dy = pos.$2 - rim.center.$2;
    return sqrt(dx * dx + dy * dy);
  }

  bool _checkRimVicinity(FilteredBallState ballState, RimGeometry rim) {
    if (!ballState.isValid) return false;
    final dist = _distToRimCenter(ballState.pos, rim);
    return dist <= rim.vicinityRadius(config.rimVicinityScale);
  }

  void _updateRimCrossings(
    int tMs,
    double bx,
    double by,
    double vx,
    double vy,
    RimGeometry rim,
  ) {
    // Check top edge crossing (downward)
    final isAboveTop = by < rim.topY;
    if (_wasAboveTopEdge && !isAboveTop && vy > 0) {
      // Crossed from above to below, moving down
      _rimCrossings.add(RimCrossing(
        tMs: tMs,
        edge: 'top',
        direction: 'down',
        position: (bx, by),
        velocity: (vx, vy),
      ));
      _topCrossingMs = tMs;
      _topCrossingVel = (vx, vy);
    }
    _wasAboveTopEdge = isAboveTop;

    // Check bottom edge crossing (downward)
    final isBelowBottom = by > rim.bottomY;
    if (!_wasBelowBottomEdge && isBelowBottom && vy > 0) {
      // Crossed from above to below, moving down
      _rimCrossings.add(RimCrossing(
        tMs: tMs,
        edge: 'bottom',
        direction: 'down',
        position: (bx, by),
        velocity: (vx, vy),
      ));
    }
    _wasBelowBottomEdge = isBelowBottom;
  }

  bool _checkMake(int tMs, double bx, RimGeometry rim) {
    // Need a top crossing first
    if (_topCrossingMs == null) return false;

    // Look for a bottom crossing after the top crossing
    final bottomCrossings =
        _rimCrossings.where((c) => c.edge == 'bottom' && c.tMs > _topCrossingMs!);
    if (bottomCrossings.isEmpty) return false;

    final bottomCrossing = bottomCrossings.first;
    final crossingDelta = bottomCrossing.tMs - _topCrossingMs!;

    // Compute adaptive window based on velocity at top crossing
    final vyAtTop = _topCrossingVel?.$2.abs() ?? 100;
    final window =
        (config.makeWindowK / max(vyAtTop, 1)).clamp(
            config.makeWindowMsMin.toDouble(),
            config.makeWindowMsMax.toDouble());

    if (crossingDelta > window) return false;

    // Lateral constraint: ball must be within rim radius * tolerance
    final lateralDist = (bx - rim.center.$1).abs();
    if (lateralDist > rim.radiusPx * config.lateralTolerance) {
      return false;
    }

    return true;
  }

  void _emitEvent(ShotResultType type, int tMs) {
    _resultMs = tMs;

    final event = ShotEvent(
      type: type,
      tReleaseMs: _releaseMs ?? tMs,
      tResultMs: tMs,
      debug: ShotDebugInfo(
        releasePos: _releasePos,
        vRelease: _releaseVel,
        apexTMs: _apexMs,
        apexPos: _apexPos,
        rimCrossings: List.from(_rimCrossings),
        stateTrace: config.enableStateTrace ? List.from(_stateTrace) : null,
      ),
    );

    _pendingEvent = event;
    onShotEvent?.call(event);
    _transitionTo(ShotFSMState.result, tMs);
  }

  /// Get a debug snapshot of current state.
  ShotFSMSnapshot debugSnapshot() {
    final ball = _ballFilter.currentState;
    return ShotFSMSnapshot(
      state: _state.name,
      tMs: _lastUpdateMs ?? 0,
      ballPos: ball.isValid ? ball.pos : null,
      ballVel: ball.isValid ? ball.vel : null,
      ballConf: ball.isValid ? ball.conf : null,
      // distToHand and distToRim require frame data, can't compute here
      inRimVicinity: _state == ShotFSMState.target,
      timeInStateMs: _lastUpdateMs != null ? _lastUpdateMs! - _stateEnteredMs : 0,
      flags: {
        'prepareFrameCount': _prepareFrameCount,
        'airborneConfirmCount': _airborneConfirmCount,
        'apexConfirmCount': _apexConfirmCount,
        'hasRelease': _releaseMs != null,
        'hasApex': _apexMs != null,
        'rimCrossings': _rimCrossings.length,
      },
    );
  }

  /// Reset the FSM to IDLE state.
  void reset() {
    _transitionTo(ShotFSMState.idle, _lastUpdateMs ?? 0);
    _ballFilter.reset();
  }

  /// Export state trace as JSON (if enabled).
  List<String>? exportStateTrace() =>
      config.enableStateTrace ? List.from(_stateTrace) : null;
}
