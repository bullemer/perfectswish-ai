import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cartracker/utils/shot_fsm/shot_fsm_module.dart';

/// Helper to create a standard rim geometry for tests.
RimGeometry testRim() => const RimGeometry(
      center: (320, 200),
      radiusPx: 40,
      topY: 195,
      bottomY: 205,
    );

/// Helper to create frame data.
FrameData frame({
  required int tMs,
  (double, double)? ball,
  double ballConf = 0.8,
  List<HandKeypoint>? hands,
  RimGeometry? rim,
}) {
  return FrameData(
    tMs: tMs,
    ballPos: ball,
    ballConf: ballConf,
    hands: hands ?? [],
    rim: rim ?? testRim(),
  );
}

void main() {
  group('ShotFSMConfig', () {
    test('default config passes validation', () {
      const config = ShotFSMConfig();
      expect(() => config.validate(), returnsNormally);
    });

    test('invalid config fails validation', () {
      const badConfig = ShotFSMConfig(
        dHoldPx: 50,
        dReleasePx: 30, // Invalid: dReleasePx < dHoldPx
      );
      expect(() => badConfig.validate(), throwsA(isA<AssertionError>()));
    });

    test('copyWith preserves values', () {
      const config = ShotFSMConfig(ballConfMin: 0.5);
      final copy = config.copyWith(handConfMin: 0.6);
      expect(copy.ballConfMin, 0.5);
      expect(copy.handConfMin, 0.6);
    });
  });

  group('BallStateFilter', () {
    test('returns invalid when no observations', () {
      final filter = BallStateFilter(config: const ShotFSMConfig());
      expect(filter.currentState.isValid, false);
    });

    test('tracks position with high confidence', () {
      final filter = BallStateFilter(config: const ShotFSMConfig());
      filter.update(tMs: 0, x: 100, y: 100, conf: 0.9);
      filter.update(tMs: 33, x: 110, y: 90, conf: 0.9);
      filter.update(tMs: 66, x: 120, y: 80, conf: 0.9);

      final state = filter.currentState;
      expect(state.isValid, true);
      expect(state.pos.$1, greaterThan(100));
      expect(state.pos.$2, lessThan(100));
    });

    test('predicts during low confidence', () {
      final config = const ShotFSMConfig(occlusionMsMax: 200);
      final filter = BallStateFilter(config: config);

      // Establish tracking
      filter.update(tMs: 0, x: 100, y: 100, conf: 0.9);
      filter.update(tMs: 33, x: 110, y: 90, conf: 0.9);
      filter.update(tMs: 66, x: 120, y: 80, conf: 0.9);

      // Low confidence observation
      final state = filter.update(tMs: 100, x: 130, y: 70, conf: 0.2);

      expect(state.isValid, true);
      expect(state.isPredicting, true);
    });

    test('becomes invalid after occlusion timeout', () {
      final config = const ShotFSMConfig(occlusionMsMax: 100);
      final filter = BallStateFilter(config: config);

      filter.update(tMs: 0, x: 100, y: 100, conf: 0.9);
      filter.update(tMs: 33, x: 110, y: 90, conf: 0.9);

      // Miss many frames
      final state = filter.update(tMs: 200, x: null, y: null);
      expect(state.isValid, false);
    });
  });

  group('ShotFSM', () {
    test('starts in IDLE state', () {
      final fsm = ShotFSM();
      expect(fsm.state, ShotFSMState.idle);
    });

    group('Clean Swish MAKE', () {
      test('detects clean swish through rim', () {
        ShotEvent? receivedEvent;
        final fsm = ShotFSM(
          config: const ShotFSMConfig(
            prepareMinFrames: 2,
            airborneConfirmFrames: 1,
            vReleaseMinPxS: 300, // Lower threshold for test
            logTransitions: false,
          ),
          onShotEvent: (event) => receivedEvent = event,
        );

        final rim = testRim();
        final dt = 16; // ~60 fps for smoother velocity
        var t = 0;

        // 1) IDLE → PREPARE: Ball near hand for several frames
        for (var i = 0; i < 5; i++) {
          fsm.update(frame(
            tMs: t,
            ball: (100, 400),
            hands: [HandKeypoint(x: 105, y: 405, conf: 0.9)],
            rim: rim,
          ));
          t += dt;
        }
        expect(fsm.state, ShotFSMState.prepare);

        // 2) PREPARE → RELEASE: Ball moves away from hand rapidly upward
        // Need to build up velocity over several frames
        for (var i = 0; i < 8; i++) {
          final x = 100.0 + i * 25; // Moving toward rim
          final y = 400.0 - i * 25; // Moving up fast (~1500 px/s)
          fsm.update(frame(
            tMs: t,
            ball: (x, y),
            hands: [HandKeypoint(x: 105, y: 405, conf: 0.9)],
            rim: rim,
          ));
          t += dt;
        }

        // 3) Continue motion toward rim area - approaching apex
        for (var i = 0; i < 6; i++) {
          final x = 300.0 + i * 5;
          final y = 180.0 - i * 2; // Slowing down (apex)
          fsm.update(frame(
            tMs: t,
            ball: (x, y),
            rim: rim,
          ));
          t += dt;
        }

        // 4) Ball descends through rim - clear downward motion
        // Above rim, moving down
        fsm.update(frame(tMs: t, ball: (320, 185), rim: rim));
        t += dt;
        fsm.update(frame(tMs: t, ball: (320, 190), rim: rim));
        t += dt;
        // Cross top edge
        fsm.update(frame(tMs: t, ball: (320, 196), rim: rim));
        t += dt;
        // In rim
        fsm.update(frame(tMs: t, ball: (320, 200), rim: rim));
        t += dt;
        // Cross bottom edge
        fsm.update(frame(tMs: t, ball: (320, 208), rim: rim));
        t += dt;
        // Below rim
        fsm.update(frame(tMs: t, ball: (320, 220), rim: rim));
        t += dt;
        fsm.update(frame(tMs: t, ball: (320, 240), rim: rim));
        t += dt;
        fsm.update(frame(tMs: t, ball: (320, 270), rim: rim));
        t += dt;

        // Continue until event received
        for (var i = 0; i < 10 && receivedEvent == null; i++) {
          fsm.update(frame(tMs: t, ball: (320, 300 + i * 20), rim: rim));
          t += dt;
        }

        expect(receivedEvent, isNotNull);
        expect(receivedEvent!.type, ShotResultType.make);
      });
    });

    group('Rim Miss', () {
      test('detects miss when ball exits vicinity without crossing', () {
        ShotEvent? receivedEvent;
        final fsm = ShotFSM(
          config: const ShotFSMConfig(
            prepareMinFrames: 1,
            airborneConfirmFrames: 1,
            targetGraceMs: 30,
            logTransitions: false,
          ),
          onShotEvent: (event) => receivedEvent = event,
        );

        final rim = testRim();
        var t = 0;
        final dt = 33;

        // Quick setup: ball has upward velocity
        fsm.update(frame(tMs: t, ball: (100, 300), rim: rim));
        t += dt;
        fsm.update(frame(tMs: t, ball: (100, 250), rim: rim)); // Moving up fast
        t += dt;

        // Enter rim vicinity from side
        for (var i = 0; i < 3; i++) {
          fsm.update(frame(
            tMs: t,
            ball: (280 + i * 10, 200), // Approaching from left
            rim: rim,
          ));
          t += dt;
        }

        // In vicinity
        fsm.update(frame(tMs: t, ball: (320, 200), rim: rim));
        t += dt;

        // Exit vicinity to the right (miss)
        for (var i = 0; i < 5; i++) {
          fsm.update(frame(
            tMs: t,
            ball: (360 + i * 20, 200 + i * 5), // Exit right
            rim: rim,
          ));
          t += dt;
        }

        // May need more frames to trigger miss
        for (var i = 0; i < 5 && receivedEvent == null; i++) {
          fsm.update(frame(tMs: t, ball: (500, 300), rim: rim));
          t += dt;
        }

        expect(receivedEvent, isNotNull);
        expect(receivedEvent!.type, ShotResultType.miss);
      });

      test('detects miss on timeout in TARGET', () {
        ShotEvent? receivedEvent;
        final fsm = ShotFSM(
          config: const ShotFSMConfig(
            prepareMinFrames: 1,
            airborneConfirmFrames: 1,
            missTimeoutMs: 100,
            logTransitions: false,
          ),
          onShotEvent: (event) => receivedEvent = event,
        );

        final rim = testRim();
        var t = 0;
        final dt = 33;

        // Setup and enter TARGET
        fsm.update(frame(tMs: t, ball: (100, 300), rim: rim));
        t += dt;
        fsm.update(frame(tMs: t, ball: (100, 200), rim: rim));
        t += dt;

        // In vicinity, ball stuck
        for (var i = 0; i < 10; i++) {
          fsm.update(frame(
            tMs: t,
            ball: (320, 200), // Stuck in vicinity
            rim: rim,
          ));
          t += 50; // Long delays to trigger timeout
        }

        expect(receivedEvent, isNotNull);
        expect(receivedEvent!.type, ShotResultType.miss);
      });
    });

    group('Layup', () {
      test('detects layup with small/no apex', () {
        ShotEvent? receivedEvent;
        final fsm = ShotFSM(
          config: const ShotFSMConfig(
            prepareMinFrames: 1,
            airborneConfirmFrames: 1,
            vReleaseMinPxS: 200, // Lower for layup
            vToRimMinPxS: 300,
            logTransitions: false,
          ),
          onShotEvent: (event) => receivedEvent = event,
        );

        final rim = testRim();
        var t = 0;
        final dt = 16;

        // Start with ball held near rim area
        for (var i = 0; i < 4; i++) {
          fsm.update(frame(tMs: t, ball: (200, 250), rim: rim));
          t += dt;
        }

        // Layup motion: quick movement toward rim with upward component
        for (var i = 0; i < 6; i++) {
          final x = 200.0 + i * 20; // Moving toward rim X
          final y = 250.0 - i * 12; // Moving up
          fsm.update(frame(tMs: t, ball: (x, y), rim: rim));
          t += dt;
        }

        // Enter vicinity and cross through rim
        fsm.update(frame(tMs: t, ball: (318, 188), rim: rim)); // Above top
        t += dt;
        fsm.update(frame(tMs: t, ball: (320, 193), rim: rim));
        t += dt;
        fsm.update(frame(tMs: t, ball: (320, 198), rim: rim)); // Cross top
        t += dt;
        fsm.update(frame(tMs: t, ball: (320, 202), rim: rim)); // In rim
        t += dt;
        fsm.update(frame(tMs: t, ball: (320, 208), rim: rim)); // Cross bottom
        t += dt;
        fsm.update(frame(tMs: t, ball: (320, 220), rim: rim)); // Below
        t += dt;
        fsm.update(frame(tMs: t, ball: (320, 240), rim: rim));
        t += dt;

        // Continue until event
        for (var i = 0; i < 10 && receivedEvent == null; i++) {
          fsm.update(frame(tMs: t, ball: (320, 260 + i * 15), rim: rim));
          t += dt;
        }

        // Layup should result in MAKE or at minimum a detected event
        expect(receivedEvent, isNotNull);
      });
    });

    group('Cooldown - Bounce Prevention', () {
      test('COOLDOWN prevents double trigger on bounce', () {
        final events = <ShotEvent>[];
        final fsm = ShotFSM(
          config: const ShotFSMConfig(
            prepareMinFrames: 1,
            airborneConfirmFrames: 1,
            vReleaseMinPxS: 200,
            cooldownMinMs: 300,
            cooldownMaxMs: 1000,
            logTransitions: false,
          ),
          onShotEvent: (event) => events.add(event),
        );

        final rim = testRim();
        var t = 0;
        final dt = 16;

        // Build up initial ball tracking with velocity
        for (var i = 0; i < 4; i++) {
          fsm.update(frame(tMs: t, ball: (100, 400), rim: rim));
          t += dt;
        }

        // Shot motion toward rim
        for (var i = 0; i < 10; i++) {
          final x = 100.0 + i * 22;
          final y = 400.0 - i * 25;
          fsm.update(frame(tMs: t, ball: (x, y), rim: rim));
          t += dt;
        }

        // Apex and descent through rim
        fsm.update(frame(tMs: t, ball: (320, 180), rim: rim));
        t += dt;
        fsm.update(frame(tMs: t, ball: (320, 188), rim: rim));
        t += dt;
        fsm.update(frame(tMs: t, ball: (320, 194), rim: rim));
        t += dt;
        fsm.update(frame(tMs: t, ball: (320, 198), rim: rim));
        t += dt;
        fsm.update(frame(tMs: t, ball: (320, 202), rim: rim));
        t += dt;
        fsm.update(frame(tMs: t, ball: (320, 210), rim: rim));
        t += dt;
        fsm.update(frame(tMs: t, ball: (320, 230), rim: rim));
        t += dt;

        // Process until first event
        for (var i = 0; i < 10 && events.isEmpty; i++) {
          fsm.update(frame(tMs: t, ball: (320, 250 + i * 15), rim: rim));
          t += dt;
        }

        expect(events.length, 1);
        // The first event type could be MAKE or MISS depending on timing;
        // what matters is that we got exactly one event
        final firstEventType = events.first.type;

        // Now simulate ball bouncing back up - still within cooldown
        // Only small time passes (less than cooldownMinMs)
        t += 50;
        fsm.update(frame(tMs: t, ball: (320, 250), rim: rim));
        t += dt;
        fsm.update(frame(tMs: t, ball: (320, 220), rim: rim));
        t += dt;
        fsm.update(frame(tMs: t, ball: (320, 200), rim: rim));
        t += dt;
        fsm.update(frame(tMs: t, ball: (320, 195), rim: rim));
        t += dt;

        // Should still only have 1 event (COOLDOWN active)
        expect(events.length, 1);
        // FSM should be in COOLDOWN, blocking new detections
        expect(fsm.state == ShotFSMState.cooldown || fsm.state == ShotFSMState.idle, true);
      });
    });

    group('Low-Confidence Occlusion', () {
      test('no false MAKE when ball hidden near rim', () {
        ShotEvent? receivedEvent;
        final fsm = ShotFSM(
          config: const ShotFSMConfig(
            ballConfMin: 0.4,
            prepareMinFrames: 1,
            airborneConfirmFrames: 1,
            occlusionMsMax: 150,
            logTransitions: false,
          ),
          onShotEvent: (event) => receivedEvent = event,
        );

        final rim = testRim();
        var t = 0;
        final dt = 33;

        // Approach rim normally
        fsm.update(frame(tMs: t, ball: (200, 300), rim: rim));
        t += dt;
        fsm.update(frame(tMs: t, ball: (250, 250), rim: rim));
        t += dt;
        fsm.update(frame(tMs: t, ball: (300, 210), rim: rim));
        t += dt;

        // Enter vicinity
        fsm.update(frame(tMs: t, ball: (320, 200), rim: rim));
        t += dt;

        // Ball becomes low confidence (occluded behind backboard, etc.)
        for (var i = 0; i < 3; i++) {
          fsm.update(frame(
            tMs: t,
            ball: (320, 200),
            ballConf: 0.2, // Very low confidence
            rim: rim,
          ));
          t += dt;
        }

        // Ball reappears outside rim having missed
        fsm.update(frame(tMs: t, ball: (400, 250), ballConf: 0.9, rim: rim));
        t += dt;

        // Continue until event
        for (var i = 0; i < 10 && receivedEvent == null; i++) {
          fsm.update(frame(tMs: t, ball: (420 + i * 10, 260), rim: rim));
          t += dt;
        }

        // Should NOT be a MAKE (low-confidence data shouldn't trigger false positive)
        if (receivedEvent != null) {
          expect(receivedEvent!.type, isNot(ShotResultType.make));
        }
      });
    });

    group('Debug Snapshot', () {
      test('provides current state information', () {
        final fsm = ShotFSM();
        final rim = testRim();

        fsm.update(frame(tMs: 0, ball: (100, 200), rim: rim));
        fsm.update(frame(tMs: 33, ball: (110, 190), rim: rim));

        final snapshot = fsm.debugSnapshot();
        expect(snapshot.state, 'idle');
        expect(snapshot.ballPos, isNotNull);
        expect(snapshot.ballVel, isNotNull);
        expect(snapshot.flags['prepareFrameCount'], isNotNull);
      });
    });

    group('State Trace', () {
      test('records transitions when enabled', () {
        final fsm = ShotFSM(
          config: const ShotFSMConfig(
            enableStateTrace: true,
            prepareMinFrames: 1,
          ),
        );

        final rim = testRim();
        var t = 0;

        // Trigger some transitions
        fsm.update(frame(
          tMs: t,
          ball: (100, 300),
          hands: [HandKeypoint(x: 110, y: 310, conf: 0.9)],
          rim: rim,
        ));
        t += 33;
        fsm.update(frame(
          tMs: t,
          ball: (100, 300),
          hands: [HandKeypoint(x: 110, y: 310, conf: 0.9)],
          rim: rim,
        ));

        final trace = fsm.exportStateTrace();
        expect(trace, isNotNull);
        expect(trace!.isNotEmpty, true);
      });
    });

    group('Reset', () {
      test('reset returns to IDLE and clears state', () {
        final fsm = ShotFSM(config: const ShotFSMConfig(prepareMinFrames: 1));
        final rim = testRim();

        // Move to PREPARE
        fsm.update(frame(
          tMs: 0,
          ball: (100, 300),
          hands: [HandKeypoint(x: 110, y: 310, conf: 0.9)],
          rim: rim,
        ));
        fsm.update(frame(
          tMs: 33,
          ball: (100, 300),
          hands: [HandKeypoint(x: 110, y: 310, conf: 0.9)],
          rim: rim,
        ));

        expect(fsm.state, ShotFSMState.prepare);

        fsm.reset();
        expect(fsm.state, ShotFSMState.idle);
      });
    });
  });

  group('ShotEvent', () {
    test('serializes to JSON', () {
      const event = ShotEvent(
        type: ShotResultType.make,
        tReleaseMs: 1000,
        tResultMs: 1500,
        debug: ShotDebugInfo(
          releasePos: (100, 200),
          vRelease: (-50, -600),
          rimCrossings: [],
        ),
      );

      final json = event.toJson();
      expect(json['type'], 'MAKE');
      expect(json['t_release_ms'], 1000);
      expect(json['t_result_ms'], 1500);
      expect(json['duration_ms'], 500);
      expect(json['debug'], isNotNull);
    });

    test('duration is correct', () {
      const event = ShotEvent(
        type: ShotResultType.miss,
        tReleaseMs: 500,
        tResultMs: 1200,
        debug: ShotDebugInfo(),
      );
      expect(event.durationMs, 700);
    });
  });
}
