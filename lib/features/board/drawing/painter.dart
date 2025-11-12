import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'point.dart';

class Painter extends CustomPainter {
  static final fill = Paint()..color = Colors.orange;
  static final stroke = Paint()
    ..color = fill.color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6;

  static final imprintFill = Paint()..color = const Color.fromARGB(255, 222, 222, 222);
  static final imprintStroke = Paint()
    ..color = imprintFill.color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6;

  final List<List<Point>> segments;
  final List<List<Point>> imprints;

  const Painter(this.segments, this.imprints);

  void paintSegments(Canvas canvas, List<List<Point>> segments, Paint fill, Paint stroke) {
    if (segments.isEmpty) return;

    for (final segment in segments) {
      if (segment.isEmpty) continue;
      for (final point in segment) canvas.drawCircle(point.offset, 3, fill);
      for (int i = 0; i < segment.length - 1; i++) {
        canvas.drawLine(segment[i].offset, segment[i + 1].offset, stroke);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    paintSegments(canvas, imprints, imprintFill, imprintStroke);
    paintSegments(canvas, segments, fill, stroke);
  }

  @override
  bool shouldRepaint(Painter oldDelegate) =>
      segments.isNotEmpty && !listEquals(segments, oldDelegate.segments) || imprints.isNotEmpty && !listEquals(imprints, oldDelegate.imprints);

}
