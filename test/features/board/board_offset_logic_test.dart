@Tags(['unit'])
library;

import 'package:algrafx/features/board/board_providers.dart';
import 'package:algrafx/features/board/drawing/point.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoardNotifier Offset Update Logic', () {
    test(
      'Given imprints exist, when setImprintOffset is called with different values, then state.imprintOffset should update each time',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(boardNotifierProvider.notifier);

        // Create some segments so we have imprints
        notifier.startNewSegment();
        notifier.addPoint(Point(const Offset(100, 100), const Offset(0, 1)));
        notifier.addPoint(Point(const Offset(150, 150), const Offset(0, 1)));

        // Start imprint drag
        notifier.startImprintDrag();

        var state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(Offset.zero),
            reason: 'Offset should be zero after startImprintDrag');

        // Simulate finger moving to the right by 50px
        notifier.setImprintOffset(const Offset(50, 0));

        state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(const Offset(50, 0)),
            reason: 'Offset should be 50px right after first update');
        print('After first update: offset = ${state.imprintOffset}');

        // Simulate finger continuing to move right and down
        notifier.setImprintOffset(const Offset(100, 30));

        state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(const Offset(100, 30)),
            reason: 'Offset should be 100px right, 30px down after second update');
        print('After second update: offset = ${state.imprintOffset}');

        // Simulate finger moving further
        notifier.setImprintOffset(const Offset(150, 50));

        state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(const Offset(150, 50)),
            reason: 'Offset should be 150px right, 50px down after third update');
        print('After third update: offset = ${state.imprintOffset}');
      },
    );

    test(
      'Given drag start position, when simulating progressive finger movement, then offset should match total displacement from start',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(boardNotifierProvider.notifier);

        // Create imprints
        notifier.startNewSegment();
        notifier.addPoint(Point(const Offset(200, 200), const Offset(0, 1)));
        notifier.addPoint(Point(const Offset(250, 250), const Offset(0, 1)));

        // Start drag at position (200, 200)
        notifier.startImprintDrag();
        final dragStartPosition = const Offset(200, 200);

        // Simulate finger positions and calculate expected offsets
        final fingerPositions = [
          const Offset(210, 200), // moved 10px right
          const Offset(225, 205), // moved 25px right, 5px down
          const Offset(250, 220), // moved 50px right, 20px down
          const Offset(280, 240), // moved 80px right, 40px down
        ];

        for (final fingerPos in fingerPositions) {
          final expectedOffset = fingerPos - dragStartPosition;
          notifier.setImprintOffset(expectedOffset);

          final state = container.read(boardNotifierProvider);
          expect(state.imprintOffset, equals(expectedOffset),
              reason: 'Offset should match displacement from start position');
          print('Finger at $fingerPos, offset = ${state.imprintOffset}, expected = $expectedOffset');
        }
      },
    );

    test(
      'Given setImprintOffset called, when reading state immediately, then offset should be updated synchronously',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(boardNotifierProvider.notifier);

        // Setup
        notifier.startNewSegment();
        notifier.addPoint(Point(const Offset(100, 100), const Offset(0, 1)));
        notifier.startImprintDrag();

        // Update and immediately read
        notifier.setImprintOffset(const Offset(75, 25));
        final state = container.read(boardNotifierProvider);

        expect(state.imprintOffset.dx, equals(75.0));
        expect(state.imprintOffset.dy, equals(25.0));
        print('Immediate read after setImprintOffset: offset = ${state.imprintOffset}');
      },
    );

    test(
      'Given multiple rapid offset updates, when setting different values, then each update should be reflected in state',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(boardNotifierProvider.notifier);

        notifier.startNewSegment();
        notifier.addPoint(Point(const Offset(100, 100), const Offset(0, 1)));
        notifier.startImprintDrag();

        // Rapid updates simulating smooth dragging
        final offsets = [
          const Offset(5, 0),
          const Offset(10, 2),
          const Offset(15, 5),
          const Offset(20, 8),
          const Offset(25, 12),
          const Offset(30, 15),
        ];

        for (final offset in offsets) {
          notifier.setImprintOffset(offset);
          final state = container.read(boardNotifierProvider);
          expect(state.imprintOffset, equals(offset),
              reason: 'Each rapid update should be reflected');
          print('Rapid update: offset = ${state.imprintOffset}');
        }
      },
    );
  });
}
