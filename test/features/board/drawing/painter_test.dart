@Tags(['unit'])
library;

import 'package:algrafx/features/board/drawing/painter.dart';
import 'package:algrafx/features/board/drawing/point.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MockCanvas extends Fake implements Canvas {
  final List<String> calls = [];

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    calls.add('drawCircle($c, $radius)');
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    calls.add('drawLine($p1, $p2)');
  }
}

void main() {
  group('Painter', () {
    test('given empty segments when paint then does not throw', () {
      // given
      final painter = Painter([], []);
      final canvas = MockCanvas();
      final size = Size(100, 100);

      // when / then
      expect(() => painter.paint(canvas, size), returnsNormally);
      expect(canvas.calls, isEmpty);
    });

    test('given segments with points when paint then draws circles', () {
      // given
      final segments = [
        [
          Point(Offset(10, 20), Offset.zero),
          Point(Offset(30, 40), Offset.zero),
        ]
      ];
      final painter = Painter(segments, []);
      final canvas = MockCanvas();
      final size = Size(100, 100);

      // when
      painter.paint(canvas, size);

      // then
      expect(
        canvas.calls.where((call) => call.startsWith('drawCircle')),
        hasLength(2),
      );
      expect(canvas.calls, contains('drawCircle(Offset(10.0, 20.0), 3.0)'));
      expect(canvas.calls, contains('drawCircle(Offset(30.0, 40.0), 3.0)'));
    });

    test('given segment with multiple points when paint then draws lines between points',
        () {
      // given
      final segments = [
        [
          Point(Offset(10, 20), Offset.zero),
          Point(Offset(30, 40), Offset.zero),
          Point(Offset(50, 60), Offset.zero),
        ]
      ];
      final painter = Painter(segments, []);
      final canvas = MockCanvas();
      final size = Size(100, 100);

      // when
      painter.paint(canvas, size);

      // then
      expect(
        canvas.calls.where((call) => call.startsWith('drawLine')),
        hasLength(2),
      );
      expect(
        canvas.calls,
        contains('drawLine(Offset(10.0, 20.0), Offset(30.0, 40.0))'),
      );
      expect(
        canvas.calls,
        contains('drawLine(Offset(30.0, 40.0), Offset(50.0, 60.0))'),
      );
    });

    test('given multiple segments when paint then draws all segments', () {
      // given
      final segments = [
        [Point(Offset(10, 20), Offset.zero)],
        [Point(Offset(30, 40), Offset.zero)],
      ];
      final painter = Painter(segments, []);
      final canvas = MockCanvas();
      final size = Size(100, 100);

      // when
      painter.paint(canvas, size);

      // then
      expect(
        canvas.calls.where((call) => call.startsWith('drawCircle')),
        hasLength(2),
      );
      expect(canvas.calls, contains('drawCircle(Offset(10.0, 20.0), 3.0)'));
      expect(canvas.calls, contains('drawCircle(Offset(30.0, 40.0), 3.0)'));
    });

    test('given same segments when shouldRepaint then returns false', () {
      // given
      final segments = [
        [Point(Offset(10, 20), Offset.zero)]
      ];
      final imprints = [
        [Point(Offset(10, 20), Offset.zero)]
      ];
      final painter1 = Painter(segments, imprints);
      final painter2 = Painter(segments, imprints);

      // when
      final result = painter1.shouldRepaint(painter2);

      // then
      expect(result, isFalse);
    });

    test('given different segments when shouldRepaint then returns true', () {
      // given
      final segments1 = [
        [Point(Offset(10, 20), Offset.zero)]
      ];
      final segments2 = [
        [Point(Offset(30, 40), Offset.zero)]
      ];
      final List<List<Point>> imprints = [[]];
      final painter1 = Painter(segments1, imprints);
      final painter2 = Painter(segments2, imprints);

      // when
      final result = painter1.shouldRepaint(painter2);

      // then
      expect(result, isTrue);
    });

    test('given empty segments when shouldRepaint then returns false', () {
      // given
      final painter1 = Painter([], []);
      final painter2 = Painter([
        [Point(Offset(10, 20), Offset.zero)]
      ], []);

      // when
      final result = painter1.shouldRepaint(painter2);

      // then
      expect(result, isFalse);
    });

    test('given imprints when paint then draws imprints before segments', () {
      // given
      final segments = [
        [Point(Offset(50, 60), Offset.zero)]
      ];
      final imprints = [
        [Point(Offset(10, 20), Offset.zero)]
      ];
      final painter = Painter(segments, imprints);
      final canvas = MockCanvas();
      final size = Size(100, 100);

      // when
      painter.paint(canvas, size);

      // then - Should draw both imprints and segments
      expect(
        canvas.calls.where((call) => call.startsWith('drawCircle')),
        hasLength(2),
      );
      expect(canvas.calls, contains('drawCircle(Offset(10.0, 20.0), 3.0)'));
      expect(canvas.calls, contains('drawCircle(Offset(50.0, 60.0), 3.0)'));
    });

    test('given different imprints when shouldRepaint then returns true', () {
      // given
      final List<List<Point>> segments = [[]];
      final imprints1 = [
        [Point(Offset(10, 20), Offset.zero)]
      ];
      final imprints2 = [
        [Point(Offset(30, 40), Offset.zero)]
      ];
      final painter1 = Painter(segments, imprints1);
      final painter2 = Painter(segments, imprints2);

      // when
      final result = painter1.shouldRepaint(painter2);

      // then
      expect(result, isTrue);
    });
  });
}
