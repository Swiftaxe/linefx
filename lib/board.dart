import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'constants.dart';
import 'painter.dart';
import 'point.dart';

class Board extends StatefulWidget {
  @override
  _BoardState createState() => _BoardState();
}

class _BoardState extends State<Board> with SingleTickerProviderStateMixin {
List<List<Point>> _segments = [[]];
final StreamController<List<List<Point>>> _streamer =
    StreamController<List<List<Point>>>.broadcast()..add([<Point>[]]);
Stream<List<List<Point>>> get _point$ => _streamer.stream;

  @override
  void initState() {
    // start a looped animation and add a listener : `_updatePoints`
    AnimationController(
        vsync: this,
        duration: Duration(seconds: 1),
        lowerBound: 0,
        upperBound: 1)
      ..repeat()
      ..addListener(_updatePoints);

    super.initState();
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
              CustomPaint(size: size, painter: Painter(stream.data)), // stream shall refer to current stream
        ),
  );

  // update the points and add them to the stream
  void _updatePoints() {
    _segments = _segments
      .map((segment) => segment
        .where((element) => element.active)
        // apply position and force
        .map((element) => element.update())
        .toList());
    _streamer.add(_segments);
  }

  @override
  void dispose() {
    _streamer.close();
    super.dispose();
  }
}
