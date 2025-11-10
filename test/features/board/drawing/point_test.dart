@Tags(['unit'])
library;

import 'package:algrafx/features/board/drawing/point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Point', () {
    test('given active point when update then returns new point with updated offset',
        () {
      // given
      final point = Point(Offset(10, 20), Offset(5, 3));

      // when
      final result = point.update(acceleration: 1.0, maxHeight: 1000);

      // then
      expect(result.offset, equals(Offset(15, 23))); // 10+5, 20+3
    });

    test('given active point when update then returns new point with scaled force',
        () {
      // given
      final point = Point(Offset(10, 20), Offset(5, 3));

      // when
      final result = point.update(acceleration: 2.0, maxHeight: 1000);

      // then
      expect(result.force, equals(Offset(10, 6))); // 5*2, 3*2
    });

    test('given point above maxHeight when update then remains active', () {
      // given
      final point = Point(Offset(10, 50), Offset(0, 10));

      // when
      final result = point.update(acceleration: 1.0, maxHeight: 100);

      // then
      expect(result.active, isTrue);
      expect(result.offset.dy, equals(60)); // Still below maxHeight
    });

    test('given point at maxHeight boundary when update then becomes inactive',
        () {
      // given
      final point = Point(Offset(10, 90), Offset(0, 15));

      // when
      final result = point.update(acceleration: 1.0, maxHeight: 100);

      // then
      expect(result.active, isFalse);
      expect(result.offset.dy, equals(105)); // 90 + 15, exceeds maxHeight
    });

    test('given inactive point when update then returns zero point', () {
      // given
      final point = Point(Offset(10, 20), Offset(5, 3), false);

      // when
      final result = point.update(acceleration: 2.0, maxHeight: 1000);

      // then
      expect(result, equals(Point.zero));
      expect(result.offset, equals(Offset.zero));
      expect(result.force, equals(Offset.zero));
      expect(result.active, isFalse);
    });

    test('given point when update then does not mutate original', () {
      // given
      final point = Point(Offset(10, 20), Offset(5, 3));

      // when
      point.update(acceleration: 2.0, maxHeight: 1000);

      // then
      expect(point.offset, equals(Offset(10, 20)));
      expect(point.force, equals(Offset(5, 3)));
      expect(point.active, isTrue);
    });

    test('given identical points when compared then are equal', () {
      // given
      final point1 = Point(Offset(10, 20), Offset(5, 3));
      final point2 = Point(Offset(10, 20), Offset(5, 3));

      // when / then
      expect(point1, equals(point2));
      expect(point1.hashCode, equals(point2.hashCode));
    });

    test('given different points when compared then are not equal', () {
      // given
      final point1 = Point(Offset(10, 20), Offset(5, 3));
      final point2 = Point(Offset(15, 25), Offset(5, 3));

      // when / then
      expect(point1, isNot(equals(point2)));
    });

    test('given point when created with default active then is active', () {
      // given / when
      final point = Point(Offset(10, 20), Offset(5, 3));

      // then
      expect(point.active, isTrue);
    });

    test('given point when created with explicit inactive then is inactive', () {
      // given / when
      final point = Point(Offset(10, 20), Offset(5, 3), false);

      // then
      expect(point.active, isFalse);
    });
  });
}
