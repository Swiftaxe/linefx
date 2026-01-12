import 'dart:ui';
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
  final Offset imprintOffset;
  final double imprintOpacity;
  final FragmentShader? crumbleShader;
  final Size screenSize;

  const Painter(
    this.segments,
    this.imprints, {
    this.imprintOffset = Offset.zero,
    this.imprintOpacity = 1.0,
    this.crumbleShader,
    required this.screenSize,
  });

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
    // Paint imprints with transform, opacity, and optional crumble shader
    if (imprints.isNotEmpty && imprintOpacity > 0) {
      canvas.save();
      canvas.translate(imprintOffset.dx, imprintOffset.dy);
      
      // Calculate crumple intensity for shader
      final distance = imprintOffset.distance;
      final thresholdDistance = screenSize.width * 0.15; // Same as deletion threshold
      final intensity = (distance / thresholdDistance).clamp(0.0, 1.0);
      
      // Apply shader effect as background if available and imprint is being dragged
      if (crumbleShader != null && intensity > 0) {
        // Set shader uniforms
        crumbleShader!
          ..setFloat(0, screenSize.width)   // uResolution.x
          ..setFloat(1, screenSize.height)  // uResolution.y
          ..setFloat(2, imprintOffset.dx)   // uOffset.x
          ..setFloat(3, imprintOffset.dy)   // uOffset.y
          ..setFloat(4, intensity);         // uIntensity
        
        // Calculate bounds of imprint to draw crumpled background
        final bounds = _calculateImprintBounds();
        if (bounds != null) {
          final shaderPaint = Paint()..shader = crumbleShader;
          canvas.drawRect(bounds, shaderPaint);
        }
      }
      
      final imprintFillWithOpacity = Paint()
        ..color = imprintFill.color.withOpacity(imprintOpacity);
      final imprintStrokeWithOpacity = Paint()
        ..color = imprintStroke.color.withOpacity(imprintOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;
      
      paintSegments(canvas, imprints, imprintFillWithOpacity, imprintStrokeWithOpacity);
      canvas.restore();
    }

    // Paint active segments (no transform)
    paintSegments(canvas, segments, fill, stroke);
  }
  
  Rect? _calculateImprintBounds() {
    if (imprints.isEmpty) return null;
    
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    
    for (final segment in imprints) {
      for (final point in segment) {
        if (point.offset.dx < minX) minX = point.offset.dx;
        if (point.offset.dy < minY) minY = point.offset.dy;
        if (point.offset.dx > maxX) maxX = point.offset.dx;
        if (point.offset.dy > maxY) maxY = point.offset.dy;
      }
    }
    
    // Add padding around the imprint
    const padding = 20.0;
    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }

  @override
  bool shouldRepaint(Painter oldDelegate) =>
      !listEquals(segments, oldDelegate.segments) ||
      !listEquals(imprints, oldDelegate.imprints) ||
      imprintOffset != oldDelegate.imprintOffset ||
      imprintOpacity != oldDelegate.imprintOpacity ||
      crumbleShader != oldDelegate.crumbleShader ||
      screenSize != oldDelegate.screenSize;
}
