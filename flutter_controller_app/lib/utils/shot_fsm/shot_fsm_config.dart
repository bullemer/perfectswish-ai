/// Configuration for the Shot Scoring Engine FSM.
///
/// All thresholds and timing parameters are configurable to allow tuning
/// for different camera setups, frame rates, and court conditions.

/// Configuration class with all tunable parameters for the Shot FSM.
class ShotFSMConfig {
  // ─────────────────────────────────────────────────────────────────────────
  // Confidence thresholds
  // ─────────────────────────────────────────────────────────────────────────

  /// Minimum confidence for ball tracking (0-1).
  /// Below this, velocity won't be updated from raw deltas.
  final double ballConfMin;

  /// Minimum confidence for hand/wrist keypoints (0-1).
  final double handConfMin;

  // ─────────────────────────────────────────────────────────────────────────
  // Possession detection (IDLE → PREPARE → RELEASE)
  // ─────────────────────────────────────────────────────────────────────────

  /// Distance threshold for ball-near-hand (entry to PREPARE), in pixels.
  final double dHoldPx;

  /// Distance threshold for release separation (exit from PREPARE), in pixels.
  /// Must be > dHoldPx for hysteresis.
  final double dReleasePx;

  /// Minimum consecutive frames with ball near hand to enter PREPARE.
  final int prepareMinFrames;

  // ─────────────────────────────────────────────────────────────────────────
  // Release detection (RELEASE → AIRBORNE)
  // ─────────────────────────────────────────────────────────────────────────

  /// Minimum upward velocity (px/sec) for release confirmation.
  /// Note: In image coordinates where Y increases downward, upward = negative vy.
  final double vReleaseMinPxS;

  /// Minimum velocity toward rim (px/sec) for layups.
  /// Used when upward velocity is small but ball is moving toward rim.
  final double vToRimMinPxS;

  /// Frames to confirm AIRBORNE after release velocity threshold met.
  final int airborneConfirmFrames;

  /// Maximum time (ms) after RELEASE to wait for AIRBORNE confirmation.
  /// Falls back to IDLE if not confirmed within this window.
  final int releaseTimeoutMs;

  // ─────────────────────────────────────────────────────────────────────────
  // Apex detection (AIRBORNE → APEX)
  // ─────────────────────────────────────────────────────────────────────────

  /// Frames to confirm apex (velocity sign change stable).
  final int apexConfirmFrames;

  // ─────────────────────────────────────────────────────────────────────────
  // Rim vicinity and make/miss detection (TARGET state)
  // ─────────────────────────────────────────────────────────────────────────

  /// Scale factor for rim vicinity radius.
  /// Vicinity radius = rimVicinityScale * rim_radius_px.
  final double rimVicinityScale;

  /// Exit multiplier for rim vicinity (for COOLDOWN exit).
  /// Must leave this radius to rearm.
  final double rimVicinityExitScale;

  /// Minimum time window (ms) for top→bottom rim crossing to count as MAKE.
  final int makeWindowMsMin;

  /// Maximum time window (ms) for rim crossing.
  final int makeWindowMsMax;

  /// Constant K for adaptive make window calculation.
  /// Window = clamp(K / |vy_at_top|, min, max).
  final double makeWindowK;

  /// Lateral tolerance for MAKE: |ball.x - rim.x| <= rimRadiusPx * lateralTolerance.
  final double lateralTolerance;

  /// Timeout (ms) in TARGET state before declaring MISS.
  final int missTimeoutMs;

  /// Grace period (ms) after entering TARGET before allowing MISS on exit.
  final int targetGraceMs;

  // ─────────────────────────────────────────────────────────────────────────
  // Block detection
  // ─────────────────────────────────────────────────────────────────────────

  /// Time window (ms) after RELEASE within which a block can be detected.
  final int blockWindowMs;

  /// Threshold for velocity flip detection (ratio or absolute).
  /// If velocity reverses sharply, it's a potential block.
  final double blockVelFlipThreshold;

  // ─────────────────────────────────────────────────────────────────────────
  // Cooldown (prevents double triggers)
  // ─────────────────────────────────────────────────────────────────────────

  /// Minimum cooldown duration (ms) regardless of other conditions.
  final int cooldownMinMs;

  /// Maximum cooldown duration (ms) before forced reset to IDLE.
  final int cooldownMaxMs;

  /// Margin below rim bottom (px) for reset condition.
  /// Ball must drop below rim_bottom_y + margin to rearm.
  final double resetBelowRimMarginPx;

  // ─────────────────────────────────────────────────────────────────────────
  // Filtering and occlusion handling
  // ─────────────────────────────────────────────────────────────────────────

  /// Maximum prediction time (ms) during low-confidence/occlusion.
  /// Beyond this, filter resets.
  final int occlusionMsMax;

  /// Smoothing factor for EMA position filter (if not using Kalman).
  /// Lower = smoother, higher = more responsive.
  final double emaSmoothingFactor;

  // ─────────────────────────────────────────────────────────────────────────
  // Rolling buffer
  // ─────────────────────────────────────────────────────────────────────────

  /// Duration (ms) of ball observations to keep in rolling buffer.
  final int bufferDurationMs;

  // ─────────────────────────────────────────────────────────────────────────
  // Debug options
  // ─────────────────────────────────────────────────────────────────────────

  /// Whether to record state transitions for debug trace.
  final bool enableStateTrace;

  /// Whether to log transitions to console.
  final bool logTransitions;

  const ShotFSMConfig({
    // Confidence
    this.ballConfMin = 0.4,
    this.handConfMin = 0.4,
    // Possession
    this.dHoldPx = 35.0,
    this.dReleasePx = 55.0,
    this.prepareMinFrames = 3,
    // Release
    this.vReleaseMinPxS = 600.0,
    this.vToRimMinPxS = 500.0,
    this.airborneConfirmFrames = 2,
    this.releaseTimeoutMs = 200,
    // Apex
    this.apexConfirmFrames = 2,
    // Rim vicinity
    this.rimVicinityScale = 1.3,
    this.rimVicinityExitScale = 1.4,
    this.makeWindowMsMin = 80,
    this.makeWindowMsMax = 300,
    this.makeWindowK = 15000.0, // Typical: 15000 / 100px/s = 150ms
    this.lateralTolerance = 1.1,
    this.missTimeoutMs = 800,
    this.targetGraceMs = 100,
    // Block
    this.blockWindowMs = 300,
    this.blockVelFlipThreshold = 0.8,
    // Cooldown
    this.cooldownMinMs = 250,
    this.cooldownMaxMs = 1200,
    this.resetBelowRimMarginPx = 20.0,
    // Filtering
    this.occlusionMsMax = 200,
    this.emaSmoothingFactor = 0.3,
    // Buffer
    this.bufferDurationMs = 2000,
    // Debug
    this.enableStateTrace = false,
    this.logTransitions = false,
  });

  /// Create a copy with modified parameters.
  ShotFSMConfig copyWith({
    double? ballConfMin,
    double? handConfMin,
    double? dHoldPx,
    double? dReleasePx,
    int? prepareMinFrames,
    double? vReleaseMinPxS,
    double? vToRimMinPxS,
    int? airborneConfirmFrames,
    int? releaseTimeoutMs,
    int? apexConfirmFrames,
    double? rimVicinityScale,
    double? rimVicinityExitScale,
    int? makeWindowMsMin,
    int? makeWindowMsMax,
    double? makeWindowK,
    double? lateralTolerance,
    int? missTimeoutMs,
    int? targetGraceMs,
    int? blockWindowMs,
    double? blockVelFlipThreshold,
    int? cooldownMinMs,
    int? cooldownMaxMs,
    double? resetBelowRimMarginPx,
    int? occlusionMsMax,
    double? emaSmoothingFactor,
    int? bufferDurationMs,
    bool? enableStateTrace,
    bool? logTransitions,
  }) {
    return ShotFSMConfig(
      ballConfMin: ballConfMin ?? this.ballConfMin,
      handConfMin: handConfMin ?? this.handConfMin,
      dHoldPx: dHoldPx ?? this.dHoldPx,
      dReleasePx: dReleasePx ?? this.dReleasePx,
      prepareMinFrames: prepareMinFrames ?? this.prepareMinFrames,
      vReleaseMinPxS: vReleaseMinPxS ?? this.vReleaseMinPxS,
      vToRimMinPxS: vToRimMinPxS ?? this.vToRimMinPxS,
      airborneConfirmFrames:
          airborneConfirmFrames ?? this.airborneConfirmFrames,
      releaseTimeoutMs: releaseTimeoutMs ?? this.releaseTimeoutMs,
      apexConfirmFrames: apexConfirmFrames ?? this.apexConfirmFrames,
      rimVicinityScale: rimVicinityScale ?? this.rimVicinityScale,
      rimVicinityExitScale: rimVicinityExitScale ?? this.rimVicinityExitScale,
      makeWindowMsMin: makeWindowMsMin ?? this.makeWindowMsMin,
      makeWindowMsMax: makeWindowMsMax ?? this.makeWindowMsMax,
      makeWindowK: makeWindowK ?? this.makeWindowK,
      lateralTolerance: lateralTolerance ?? this.lateralTolerance,
      missTimeoutMs: missTimeoutMs ?? this.missTimeoutMs,
      targetGraceMs: targetGraceMs ?? this.targetGraceMs,
      blockWindowMs: blockWindowMs ?? this.blockWindowMs,
      blockVelFlipThreshold:
          blockVelFlipThreshold ?? this.blockVelFlipThreshold,
      cooldownMinMs: cooldownMinMs ?? this.cooldownMinMs,
      cooldownMaxMs: cooldownMaxMs ?? this.cooldownMaxMs,
      resetBelowRimMarginPx:
          resetBelowRimMarginPx ?? this.resetBelowRimMarginPx,
      occlusionMsMax: occlusionMsMax ?? this.occlusionMsMax,
      emaSmoothingFactor: emaSmoothingFactor ?? this.emaSmoothingFactor,
      bufferDurationMs: bufferDurationMs ?? this.bufferDurationMs,
      enableStateTrace: enableStateTrace ?? this.enableStateTrace,
      logTransitions: logTransitions ?? this.logTransitions,
    );
  }

  /// Validate configuration (throws if invalid).
  void validate() {
    assert(ballConfMin >= 0 && ballConfMin <= 1,
        'ballConfMin must be in [0, 1]');
    assert(handConfMin >= 0 && handConfMin <= 1,
        'handConfMin must be in [0, 1]');
    assert(dReleasePx > dHoldPx,
        'dReleasePx ($dReleasePx) must be > dHoldPx ($dHoldPx) for hysteresis');
    assert(prepareMinFrames >= 1, 'prepareMinFrames must be >= 1');
    assert(vReleaseMinPxS > 0, 'vReleaseMinPxS must be > 0');
    assert(rimVicinityScale > 1, 'rimVicinityScale must be > 1');
    assert(rimVicinityExitScale > rimVicinityScale,
        'rimVicinityExitScale must be > rimVicinityScale');
    assert(makeWindowMsMax > makeWindowMsMin,
        'makeWindowMsMax must be > makeWindowMsMin');
    assert(cooldownMaxMs > cooldownMinMs,
        'cooldownMaxMs must be > cooldownMinMs');
  }
}
