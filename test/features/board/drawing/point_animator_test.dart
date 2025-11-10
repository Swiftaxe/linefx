@Tags(['unit'])
library;

import 'package:algrafx/features/board/drawing/point.dart';
import 'package:algrafx/features/board/drawing/point_animator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PointAnimator', () {
    test('given active point when updatePoints then updates position and force',
        () {
      // given
      final point = Point(Offset(10, 20), Offset(5, 3));
      final segments = [
        [point]
      ];
      final animator = PointAnimator(acceleration: 2.0, maxHeight: 1000);

      // when
      final result = animator.updatePoints(segments);

      // then
      final updatedPoint = result[0][0];
      expect(updatedPoint.offset, equals(Offset(15, 23))); // 10+5, 20+3
      expect(updatedPoint.force, equals(Offset(10, 6))); // 5*2, 3*2
      expect(updatedPoint.active, isTrue);
    });

    test('given inactive points when updatePoints then filters them out', () {
      // given
      final activePoint = Point(Offset(10, 20), Offset(5, 3));
      final inactivePoint = Point(Offset(15, 25), Offset(2, 1), false);
      final segments = [
        [activePoint, inactivePoint]
      ];
      final animator = PointAnimator(acceleration: 1.0, maxHeight: 1000);

      // when
      final result = animator.updatePoints(segments);

      // then
      expect(result[0].length, equals(1));
      expect(result[0][0].offset, equals(Offset(15, 23)));
    });

    test('given point below maxHeight when updatePoints then deactivates it',
        () {
      // given
      final point = Point(Offset(10, 90), Offset(0, 15));
      final segments = [
        [point]
      ];
      final animator = PointAnimator(acceleration: 1.0, maxHeight: 100);

      // when
      final result = animator.updatePoints(segments);

      // then
      expect(result[0][0].active, isFalse);
      expect(result[0][0].offset.dy, greaterThan(100)); // 90 + 15 = 105
    });

    test('given segments when updatePoints then does not mutate input', () {
      // given
      final originalPoint = Point(Offset(10, 20), Offset(5, 3));
      final segments = [
        [originalPoint]
      ];
      final animator = PointAnimator(acceleration: 2.0, maxHeight: 1000);

      // when
      animator.updatePoints(segments);

      // then
      expect(segments[0][0].offset, equals(Offset(10, 20)));
      expect(segments[0][0].force, equals(Offset(5, 3)));
      expect(segments[0][0].active, isTrue);
    });

    test('given segments when updatePoints then preserves segment structure',
        () {
      // given
      final segment1 = [
        Point(Offset(1, 1), Offset(1, 1)),
        Point(Offset(2, 2), Offset(1, 1))
      ];
      final segment2 = [Point(Offset(3, 3), Offset(1, 1))];
      final segments = [segment1, segment2];
      final animator = PointAnimator(acceleration: 1.0, maxHeight: 1000);

      // when
      final result = animator.updatePoints(segments);

      // then
      expect(result.length, equals(2));
      expect(result[0].length, equals(2));
      expect(result[1].length, equals(1));
    });

    test('given empty segments when updatePoints then returns empty list', () {
      // given
      final segments = <List<Point>>[];
      final animator = PointAnimator(acceleration: 1.0, maxHeight: 1000);

      // when
      final result = animator.updatePoints(segments);

      // then
      expect(result, isEmpty);
    });

    test(
        'given segment with all inactive points when updatePoints then returns empty segment',
        () {
      // given
      final segments = [
        [
          Point(Offset(10, 20), Offset(5, 3), false),
          Point(Offset(15, 25), Offset(2, 1), false),
        ]
      ];
      final animator = PointAnimator(acceleration: 1.0, maxHeight: 1000);

      // when
      final result = animator.updatePoints(segments);

      // then
      expect(result[0], isEmpty);
    });

    test(
        'given segment with mixed active and inactive points when updatePoints then filters inactive',
        () {
      // given
      final segments = [
        [
          Point(Offset(10, 20), Offset(5, 3), true),
          Point(Offset(15, 25), Offset(2, 1), false),
          Point(Offset(20, 30), Offset(1, 2), true),
        ]
      ];
      final animator = PointAnimator(acceleration: 1.0, maxHeight: 1000);

      // when
      final result = animator.updatePoints(segments);

      // then
      expect(result[0].length, equals(2));
      expect(result[0][0].offset, equals(Offset(15, 23)));
      expect(result[0][1].offset, equals(Offset(21, 32)));
    });

    test(
        'given multiple segments when updatePoints then processes independently',
        () {
      // given
      final segment1 = [Point(Offset(10, 20), Offset(5, 3))];
      final segment2 = [Point(Offset(30, 40), Offset(2, 1))];
      final segments = [segment1, segment2];
      final animator = PointAnimator(acceleration: 2.0, maxHeight: 1000);

      // when
      final result = animator.updatePoints(segments);

      // then
      expect(result.length, equals(2));
      expect(result[0][0].offset, equals(Offset(15, 23)));
      expect(result[0][0].force, equals(Offset(10, 6)));
      expect(result[1][0].offset, equals(Offset(32, 41)));
      expect(result[1][0].force, equals(Offset(4, 2)));
    });

    test(
        'given no acceleration specified when constructor then uses default value',
        () {
      // given / when
      final animator = PointAnimator(maxHeight: 1000);
      final segments = [
        [Point(Offset(0, 0), Offset(10, 10))]
      ];

      // when
      final result = animator.updatePoints(segments);

      // then
      expect(result[0][0].force, equals(Offset(10.8, 10.8))); // 10 * 1.08
    });
  });
}
