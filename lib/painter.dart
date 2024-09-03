import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'point.dart';

class Painter extends CustomPainter {
  static final fill = Paint()..color = Colors.orange;
  static final stroke = Paint()
    ..color = Colors.orange
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6;

  final List<List<Point>> segments;

  const Painter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
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
  bool shouldRepaint(Painter oldDelegate) =>
      segments.isNotEmpty && !listEquals(segments, oldDelegate.segments);
}
