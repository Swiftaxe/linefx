import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algrafx/features/board/board_state.dart';
import 'package:algrafx/features/board/drawing/point.dart';
import 'package:algrafx/features/board/drawing/point_animator.dart';
import 'package:algrafx/features/board/board_providers.dart';

class BoardNotifier extends Notifier<BoardState> {
  late PointAnimator _pointAnimator;
  final int _maxPoints = 500;

  @override
  BoardState build() {
    // Dependencies are accessed via ref in build()
    _pointAnimator = ref.watch(pointAnimatorProvider);
    return const BoardState.initial();
  }

  // Add a point to the current segment
  void addPoint(Point point) {
    final updatedSegments = <List<Point>>[];
    final imprintSegments = <List<Point>>[];
    for (int i = 0; i < state.segments.length; i++) {
      if (i == state.segments.length - 1) {
        // Last segment - add the point
        updatedSegments.add([...state.segments[i], point]);
        imprintSegments.add([...state.imprintSegments[i], point]);
      } else {
        updatedSegments.add(state.segments[i]);
        imprintSegments.add(state.imprintSegments[i]);
      }
    }
    state = BoardState(segments: updatedSegments, imprintSegments: imprintSegments);
  }

  void startNewSegment() {
    final updatedSegments = <List<Point>>[...state.segments, []];
    final imprintSegments = <List<Point>>[...state.imprintSegments, []];
    state = BoardState(segments: updatedSegments, imprintSegments: imprintSegments);
  }

  void updatePoints() {
    final updatedSegments = _pointAnimator.updatePoints(state.segments);
    // Imprints should NEVER animate - they stay frozen!
    state = BoardState(segments: updatedSegments, imprintSegments: state.imprintSegments);
  }

  List<List<Point>> getCappedSegments() {
    return state.segments
        .map((segment) =>
            segment.skip(max(0, segment.length - _maxPoints)).toList())
        .toList();
  }
}