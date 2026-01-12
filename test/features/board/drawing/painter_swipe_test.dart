@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:algrafx/features/board/drawing/painter.dart';
import 'package:algrafx/features/board/drawing/point.dart';

class MockCanvas extends Fake implements Canvas {
  final List<String> calls = [];
  Offset? lastTranslation;

  @override
  void save() {
    calls.add('save');
  }

  @override
  void restore() {
    calls.add('restore');
  }

  @override
  void translate(double dx, double dy) {
    lastTranslation = Offset(dx, dy);
    calls.add('translate($dx, $dy)');
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    calls.add('drawCircle($c, $radius, opacity:${paint.color.opacity})');
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    calls.add('drawLine($p1, $p2, opacity:${paint.color.opacity})');
  }
}

void main() {
  group('Painter Swipe', () {
    test('given imprints with offset when painting then applies canvas translation', () {
      // given
      final imprints = [
        [Point(const Offset(10, 20), Offset.zero)]
      ];
      final size = const Size(400, 800);
      final painter = Painter(
        [],
        imprints,
        imprintOffset: const Offset(50, 100),
        screenSize: size,
      );
      final canvas = MockCanvas();

      // when
      painter.paint(canvas, size);

      // then
      expect(canvas.calls, contains('save'));
      expect(canvas.calls, contains('translate(50.0, 100.0)'));
      expect(canvas.calls, contains('restore'));
      expect(canvas.lastTranslation, equals(const Offset(50, 100)));
    });

    test('given imprints with opacity less than 1.0 when painting then applies transparency', () {
      // given
      final imprints = [
        [Point(const Offset(10, 20), Offset.zero)]
      ];
      final size = const Size(400, 800);
      final painter = Painter(
        [],
        imprints,
        imprintOpacity: 0.5,
        screenSize: size,
      );
      final canvas = MockCanvas();

      // when
      painter.paint(canvas, size);

      // then - Check that calls include opacity information
      final circleCall = canvas.calls.firstWhere(
        (call) => call.startsWith('drawCircle'),
        orElse: () => '',
      );
      expect(circleCall, contains('opacity:0.5'));
    });

    test('given different offset or opacity when checking shouldRepaint then returns true', () {
      // given
      final segments = [
        [Point(const Offset(10, 20), Offset.zero)]
      ];
      final imprints = [
        [Point(const Offset(10, 20), Offset.zero)]
      ];

      final size = const Size(400, 800);
      final painter1 = Painter(segments, imprints, imprintOffset: const Offset(50, 100), screenSize: size);
      final painter2 = Painter(segments, imprints, imprintOffset: const Offset(60, 110), screenSize: size);
      final painter3 = Painter(segments, imprints, imprintOpacity: 0.5, screenSize: size);
      final painter4 = Painter(segments, imprints, imprintOpacity: 1.0, screenSize: size);

      // when/then - Different offset
      expect(painter1.shouldRepaint(painter2), isTrue);

      // when/then - Different opacity
      expect(painter3.shouldRepaint(painter4), isTrue);
    });
  });
}
