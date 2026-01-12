@Tags(['unit'])
library;

import 'package:algrafx/features/board/board_providers.dart';
import 'package:algrafx/features/board/drawing/point.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoardNotifier State Preservation Tests', () {
    test(
      'Given imprintOffset is set, when addPoint is called, then imprintOffset should be preserved',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(boardNotifierProvider.notifier);

        // Setup: Create segment and set offset
        notifier.startNewSegment();
        notifier.startImprintDrag();
        notifier.setImprintOffset(const Offset(100, 50));

        var state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(const Offset(100, 50)));

        // Add a point (this used to reset offset to zero)
        notifier.addPoint(Point(const Offset(200, 200), const Offset(0, 1)));

        // Verify offset is still preserved
        state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(const Offset(100, 50)),
            reason: 'imprintOffset should be preserved after addPoint');
      },
    );

    test(
      'Given imprintOffset and imprintOpacity are set, when updatePoints is called, then both should be preserved',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(boardNotifierProvider.notifier);

        // Setup
        notifier.startNewSegment();
        notifier.addPoint(Point(const Offset(100, 100), const Offset(0, 1)));
        notifier.startImprintDrag();
        notifier.setImprintOffset(const Offset(75, 25));
        notifier.tossAndFadeImprints(); // Sets opacity to 0

        var state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(const Offset(75, 25)));
        expect(state.imprintOpacity, equals(0.0));

        // Call updatePoints (this is called every animation frame)
        notifier.updatePoints();

        // Verify both offset and opacity are preserved
        state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(const Offset(75, 25)),
            reason: 'imprintOffset should be preserved after updatePoints');
        expect(state.imprintOpacity, equals(0.0),
            reason: 'imprintOpacity should be preserved after updatePoints');
      },
    );

    test(
      'Given imprintOffset is set, when startNewSegment is called, then imprintOffset should be preserved',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(boardNotifierProvider.notifier);

        // Setup
        notifier.startNewSegment();
        notifier.addPoint(Point(const Offset(100, 100), const Offset(0, 1)));
        notifier.startImprintDrag();
        notifier.setImprintOffset(const Offset(50, 30));

        var state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(const Offset(50, 30)));

        // Start a new segment (user starts drawing again)
        notifier.startNewSegment();

        // Verify offset is preserved
        state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(const Offset(50, 30)),
            reason: 'imprintOffset should be preserved after startNewSegment');
      },
    );

    test(
      'Given imprintOffset set during drag, when multiple rapid updates occur (simulating animation frames), then offset should remain stable',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(boardNotifierProvider.notifier);

        // Setup: Create initial drawing
        notifier.startNewSegment();
        notifier.addPoint(Point(const Offset(100, 100), const Offset(0, 1)));
        notifier.addPoint(Point(const Offset(150, 150), const Offset(0, 1)));

        // Start drag and set offset
        notifier.startImprintDrag();
        notifier.setImprintOffset(const Offset(120, 60));

        var state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(const Offset(120, 60)));

        // Simulate rapid updates (animation frames + adding points)
        for (int i = 0; i < 10; i++) {
          notifier.updatePoints(); // Animation frame
          if (i % 3 == 0) {
            // Occasionally add a point (drawing continues)
            notifier.addPoint(Point(Offset(200.0 + i * 10, 200.0), const Offset(0, 1)));
          }
        }

        // Verify offset is STILL preserved after all those updates
        state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(const Offset(120, 60)),
            reason: 'imprintOffset should survive multiple updatePoints and addPoint calls');
      },
    );

    test(
      'Given imprintOffset and imprintOpacity set, when copyWith is called with only segments, then offset and opacity should be preserved',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(boardNotifierProvider.notifier);

        // Setup
        notifier.startNewSegment();
        notifier.addPoint(Point(const Offset(100, 100), const Offset(0, 1)));
        notifier.setImprintOffset(const Offset(200, 100));
        notifier.tossAndFadeImprints();

        var state = container.read(boardNotifierProvider);
        
        expect(state.imprintOffset, equals(const Offset(200, 100)));
        expect(state.imprintOpacity, equals(0.0));

        // Update only segments using copyWith
        final newSegments = [[Point(const Offset(300, 300), const Offset(0, 1))]];
        notifier.state = state.copyWith(segments: newSegments);

        // Verify offset and opacity are preserved
        state = container.read(boardNotifierProvider);
        expect(state.segments, equals(newSegments));
        expect(state.imprintOffset, equals(const Offset(200, 100)),
            reason: 'imprintOffset should be preserved when copyWith updates only segments');
        expect(state.imprintOpacity, equals(0.0),
            reason: 'imprintOpacity should be preserved when copyWith updates only segments');
      },
    );
  });
}
