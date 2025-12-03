@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:algrafx/features/board/swipe/swipe_config.dart';

void main() {
  group('SwipeConfig', () {
    test('given high velocity swipe when checking if should delete then returns true', () {
      // given
      const screenSize = Size(400, 800);
      const velocity = 500.0; // > 400 (100% of screen width)
      const distance = 20.0;  // < 60 (15% of screen width)

      // when
      final result = SwipeConfig.shouldDelete(
        velocity: velocity,
        distance: distance,
        screenSize: screenSize,
      );

      // then
      expect(result, isTrue);
    });

    test('given far distance swipe when checking if should delete then returns true', () {
      // given
      const screenSize = Size(400, 800);
      const velocity = 100.0; // < 400 (100% of screen width)
      const distance = 70.0;  // > 60 (15% of screen width)

      // when
      final result = SwipeConfig.shouldDelete(
        velocity: velocity,
        distance: distance,
        screenSize: screenSize,
      );

      // then
      expect(result, isTrue);
    });

    test('given slow and short swipe when checking if should delete then returns false', () {
      // given
      const screenSize = Size(400, 800);
      const velocity = 100.0; // < 400
      const distance = 20.0;  // < 60

      // when
      final result = SwipeConfig.shouldDelete(
        velocity: velocity,
        distance: distance,
        screenSize: screenSize,
      );

      // then
      expect(result, isFalse);
    });

    test('given swipe exactly at threshold when checking if should delete then returns false', () {
      // given
      const screenSize = Size(400, 800);
      const velocity = 400.0; // exactly at threshold
      const distance = 60.0;  // exactly at threshold

      // when
      final result = SwipeConfig.shouldDelete(
        velocity: velocity,
        distance: distance,
        screenSize: screenSize,
      );

      // then
      expect(result, isFalse);
    });

    test('given different screen sizes when calculating thresholds then scales proportionally', () {
      // given
      const smallScreen = Size(400, 800);
      const largeScreen = Size(800, 1600);

      // when
      final smallDistance = SwipeConfig.getDeleteDistance(smallScreen);
      final largeDistance = SwipeConfig.getDeleteDistance(largeScreen);
      final smallVelocity = SwipeConfig.getDeleteVelocity(smallScreen);
      final largeVelocity = SwipeConfig.getDeleteVelocity(largeScreen);

      // then
      expect(largeDistance, equals(smallDistance * 2));
      expect(largeVelocity, equals(smallVelocity * 2));
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
