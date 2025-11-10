import 'dart:ui';

import 'package:algrafx/features/board/drawing/point_animator.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'constants.dart';
import 'features/board/drawing/painter.dart';
import 'features/board/drawing/point.dart';

class Board extends StatefulWidget {
  @override
  _BoardState createState() => _BoardState();
}

class _BoardState extends State<Board> with SingleTickerProviderStateMixin {
List<List<Point>> _segments = [[]];
final StreamController<List<List<Point>>> _streamer =
    StreamController<List<List<Point>>>.broadcast()..add([<Point>[]]);
Stream<List<List<Point>>> get _point$ => _streamer.stream;
late AnimationController _animationController;

final size = window.physicalSize / window.devicePixelRatio;

late final PointAnimator _pointAnimator;

  @override
  void initState() {
    super.initState();

    _pointAnimator = PointAnimator(
      maxHeight: size.height,
    );

    // start a looped animation and add a listener : `_updatePoints`
    _animationController = AnimationController(
        vsync: this,
        duration: Duration(seconds: 1),
        lowerBound: 0,
        upperBound: 1)
      ..repeat()
      ..addListener(_updatePoints);
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (details) {
          // create a new segment
          _segments.add([]);
          // add the first point to the segment
          _segments.last.add(Point(details.localPosition, force));
          _streamer.add(_segments);
        },
        onPointerMove: (details) {
            _segments.last.add(Point(details.localPosition, force));
            // _streamer shall refer to active/latest stream
            _streamer.add(_segments);
        },    
        onPointerUp: (details) {
          // End the current segment
          _segments.last.add(Point(details.localPosition, force));
          _streamer.add(_segments);
        },    
        child: StreamBuilder<List<List<Point>>>(
          initialData: _segments,
          stream: _point$.map(
              // cap number of points to maxPoints
              (segments) => _segments
                  .map((segment) =>
                      segment.skip(max(0, segment.length - maxPoints)).toList())
                  .toList()),
          builder: (_, stream) =>
              CustomPaint(size: size, painter: Painter(stream.data!)), // stream shall refer to current stream
        ),
  );

  // update the points and add them to the stream
  void _updatePoints() {
    _segments = _pointAnimator.updatePoints(_segments);
    _streamer.add(_segments);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _streamer.close();
    super.dispose();
  }
}
