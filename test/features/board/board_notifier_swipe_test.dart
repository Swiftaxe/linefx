@Tags(['unit'])
library;

import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algrafx/features/board/board_notifier.dart';
import 'package:algrafx/features/board/board_providers.dart';
import 'package:algrafx/features/board/drawing/point.dart';
import 'package:algrafx/features/board/swipe/swipe_config.dart';

void main() {
  group('BoardNotifier Swipe', () {
    late ProviderContainer container;
    late BoardNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(boardNotifierProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('given initial state when two-finger drag starts then imprint offset becomes zero and tracking begins', () {
      // when
      notifier.startImprintDrag();

      // then
      final state = container.read(boardNotifierProvider);
      expect(state.imprintOffset, equals(Offset.zero));
    });

    test('given dragging when drag updates then imprint offset accumulates deltas', () {
      // given
      notifier.startImprintDrag();

      // when
      notifier.updateImprintOffset(const Offset(10, 20));
      var state = container.read(boardNotifierProvider);
      expect(state.imprintOffset, equals(const Offset(10, 20)));

      notifier.updateImprintOffset(const Offset(5, 10));
      state = container.read(boardNotifierProvider);

      // then
      expect(state.imprintOffset, equals(const Offset(15, 30)));
    });

    test('given fast/far swipe when drag ends then starts toss animation and clears imprints after fade', () {
      // given
      notifier.startImprintDrag();
      notifier.updateImprintOffset(const Offset(100, 0));
      const screenSize = Size(400, 800);

      // when - fast swipe
      notifier.endImprintDrag(
        velocity: 500.0, // High velocity
        distance: 100.0,
        screenSize: screenSize,
        direction: SwipeDirection.right,
      );

      // then - opacity set to 0 (fade started)
      var state = container.read(boardNotifierProvider);
      expect(state.imprintOpacity, equals(0.0));

      // Simulate animation complete
      notifier.clearAllImprints();
      state = container.read(boardNotifierProvider);
      expect(state.imprintSegments, equals([[]]));
      expect(state.imprintOffset, equals(Offset.zero));
      expect(state.imprintOpacity, equals(1.0));
    });

    test('given slow/short swipe when drag ends then resets offset and keeps imprints', () {
      // given
      notifier.startImprintDrag();
      notifier.updateImprintOffset(const Offset(20, 0));
      
      // Add some imprints
      notifier.addPoint(const Point(Offset(10, 10), Offset.zero));
      final imprintsBeforeCancel = container.read(boardNotifierProvider).imprintSegments;
      
      const screenSize = Size(400, 800);

      // when - slow and short swipe
      notifier.endImprintDrag(
        velocity: 50.0,  // Low velocity
        distance: 20.0,  // Short distance
        screenSize: screenSize,
        direction: SwipeDirection.right,
      );

      // then - offset reset, imprints unchanged
      final state = container.read(boardNotifierProvider);
      expect(state.imprintOffset, equals(Offset.zero));
      expect(state.imprintSegments, equals(imprintsBeforeCancel));
      expect(state.imprintOpacity, equals(1.0));
    });

    test('given drag primarily horizontal when calculating direction then returns LEFT or RIGHT', () {
      // given
      const deltaRight = Offset(100, 20);
      const deltaLeft = Offset(-100, 20);

      // when
      final directionRight = SwipeConfig.getDirection(deltaRight);
      final directionLeft = SwipeConfig.getDirection(deltaLeft);

      // then
      expect(directionRight, equals(SwipeDirection.right));
      expect(directionLeft, equals(SwipeDirection.left));
    });

    test('given drag primarily vertical when calculating direction then returns UP or DOWN', () {
      // given
      const deltaDown = Offset(20, 100);
      const deltaUp = Offset(20, -100);

      // when
      final directionDown = SwipeConfig.getDirection(deltaDown);
      final directionUp = SwipeConfig.getDirection(deltaUp);

      // then
      expect(directionDown, equals(SwipeDirection.down));
      expect(directionUp, equals(SwipeDirection.up));
    });
  });
}
