@Tags(['unit'])
library;

import 'package:algrafx/features/board/board_providers.dart';
import 'package:algrafx/features/board/drawing/point.dart';
import 'package:algrafx/features/board/swipe/swipe_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoardNotifier Offset Update Tests', () {
    test(
      'Given startImprintDrag called, when setImprintOffset is called with absolute offset, then state should reflect that offset',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(boardNotifierProvider.notifier);

        // Initialize with a segment so we have imprints
        notifier.startNewSegment();
        notifier.addPoint(Point(const Offset(100, 100), Offset.zero));
        notifier.addPoint(Point(const Offset(150, 150), Offset.zero));

        // Start imprint drag
        notifier.startImprintDrag();

        var state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(Offset.zero),
            reason: 'Offset should be zero after startImprintDrag');

        // Set absolute offset as if finger moved 50px right
        notifier.setImprintOffset(const Offset(50, 0));

        state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(const Offset(50, 0)),
            reason: 'Offset should be set to absolute value');
      },
    );

    test(
      'Given drag in progress, when setImprintOffset called multiple times, then offset should update to each new value',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(boardNotifierProvider.notifier);

        // Initialize
        notifier.startNewSegment();
        notifier.addPoint(Point(const Offset(100, 100), Offset.zero));
        notifier.addPoint(Point(const Offset(150, 150), Offset.zero));
        notifier.startImprintDrag();

        // Simulate finger moving incrementally
        notifier.setImprintOffset(const Offset(10, 0));
        var state = container.read(boardNotifierProvider);
        expect(state.imprintOffset.dx, equals(10.0));

        notifier.setImprintOffset(const Offset(25, 5));
        state = container.read(boardNotifierProvider);
        expect(state.imprintOffset.dx, equals(25.0));
        expect(state.imprintOffset.dy, equals(5.0));

        notifier.setImprintOffset(const Offset(50, 10));
        state = container.read(boardNotifierProvider);
        expect(state.imprintOffset.dx, equals(50.0));
        expect(state.imprintOffset.dy, equals(10.0));
      },
    );

    test(
      'Given offset set during drag, when endImprintDrag called with low velocity, then offset should reset to zero (snap back)',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(boardNotifierProvider.notifier);

        // Initialize
        notifier.startNewSegment();
        notifier.addPoint(Point(const Offset(100, 100), Offset.zero));
        notifier.addPoint(Point(const Offset(150, 150), Offset.zero));
        notifier.startImprintDrag();

        // Set offset (short distance)
        notifier.setImprintOffset(const Offset(20, 0));

        var state = container.read(boardNotifierProvider);
        expect(state.imprintOffset.dx, equals(20.0));

        // End drag with low velocity (should cancel/snap back)
        notifier.endImprintDrag(
          distance: 20.0,
          velocity: 0,
          screenSize: const Size(800, 600),
          direction: SwipeDirection.right,
        );

        state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(Offset.zero),
            reason: 'Should snap back to zero for short drag');
      },
    );

    test(
      'Given offset set during drag, when endImprintDrag called with high velocity/distance, then opacity should become 0 (fade)',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(boardNotifierProvider.notifier);

        // Initialize
        notifier.startNewSegment();
        notifier.addPoint(Point(const Offset(100, 100), Offset.zero));
        notifier.addPoint(Point(const Offset(150, 150), Offset.zero));
        notifier.startImprintDrag();

        // Set offset (long distance - more than 15% of screen width)
        notifier.setImprintOffset(const Offset(150, 0));

        var state = container.read(boardNotifierProvider);
        expect(state.imprintOffset.dx, equals(150.0));

        // End drag with high distance (should trigger fade)
        notifier.endImprintDrag(
          distance: 150.0,
          velocity: 0,
          screenSize: const Size(800, 600), // 150 > 0.15 * 800 = 120
          direction: SwipeDirection.right,
        );

        state = container.read(boardNotifierProvider);
        expect(state.imprintOpacity, equals(0.0),
            reason: 'Should fade (opacity to 0) for long drag');
      },
    );

    test(
      'Given imprint drag with offset, when cancelImprintDrag called, then offset should reset to zero',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(boardNotifierProvider.notifier);

        // Initialize
        notifier.startNewSegment();
        notifier.addPoint(Point(const Offset(100, 100), Offset.zero));
        notifier.addPoint(Point(const Offset(150, 150), Offset.zero));
        notifier.startImprintDrag();

        // Set offset
        notifier.setImprintOffset(const Offset(30, 15));

        var state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(const Offset(30, 15)));

        // Cancel drag
        notifier.cancelImprintDrag();

        state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(Offset.zero),
            reason: 'Cancel should reset offset to zero');
      },
    );
  });
}
