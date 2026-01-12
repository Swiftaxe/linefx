import 'dart:math';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algrafx/features/board/board_state.dart';
import 'package:algrafx/features/board/drawing/point.dart';
import 'package:algrafx/features/board/drawing/point_animator.dart';
import 'package:algrafx/features/board/board_providers.dart';
import 'package:algrafx/features/board/swipe/swipe_config.dart';

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
        // Only add to imprints if they exist (might be cleared)
        if (i < state.imprintSegments.length) {
          imprintSegments.add([...state.imprintSegments[i], point]);
        } else {
          imprintSegments.add([point]);
        }
      } else {
        updatedSegments.add(state.segments[i]);
        // Only copy imprints if they exist
        if (i < state.imprintSegments.length) {
          imprintSegments.add(state.imprintSegments[i]);
        } else {
          imprintSegments.add([]);
        }
      }
    }
    state = state.copyWith(segments: updatedSegments, imprintSegments: imprintSegments);
  }

  void startNewSegment() {
    final updatedSegments = <List<Point>>[...state.segments, []];
    final imprintSegments = <List<Point>>[...state.imprintSegments, []];
    state = state.copyWith(segments: updatedSegments, imprintSegments: imprintSegments);
  }

  void updatePoints() {
    final updatedSegments = _pointAnimator.updatePoints(state.segments);
    // Imprints should NEVER animate - they stay frozen!
    state = state.copyWith(segments: updatedSegments);
  }

  List<List<Point>> getCappedSegments() {
    return state.segments
        .map((segment) =>
            segment.skip(max(0, segment.length - _maxPoints)).toList())
        .toList();
  }

  // Two-finger swipe: Start dragging imprints
  void startImprintDrag() {
    state = state.copyWith(imprintOffset: Offset.zero);
  }

  // Two-finger swipe: Update imprint offset
  void updateImprintOffset(Offset delta) {
    // Delta is incremental - add it to current offset
    final newOffset = state.imprintOffset + delta;
    state = state.copyWith(imprintOffset: newOffset);
  }
  
  // Set absolute imprint offset (used during drag)
  void setImprintOffset(Offset offset) {
    state = state.copyWith(imprintOffset: offset);
  }

  // Two-finger swipe: End drag - delete or cancel
  void endImprintDrag({
    required double velocity,
    required double distance,
    required Size screenSize,
    required SwipeDirection direction,
  }) {
    if (SwipeConfig.shouldDelete(
      velocity: velocity,
      distance: distance,
      screenSize: screenSize,
    )) {
      tossAndFadeImprints();
    } else {
      cancelImprintDrag();
    }
  }

  // Animate toss and fade, then clear imprints
  void tossAndFadeImprints() {
    // Start fade animation
    state = state.copyWith(imprintOpacity: 0.0);
    
    // Clear imprints after fade completes
    // Note: This will be handled by AnimationController in Board widget
    // which will call clearAllImprints() after animation completes
  }

  // Clear all imprints
  void clearAllImprints() {
    // Reset imprints to match current segments structure (empty segments)
    final emptyImprints = List.generate(
      state.segments.length,
      (_) => <Point>[],
    );
    
    state = state.copyWith(
      imprintSegments: emptyImprints,
      imprintOffset: Offset.zero,
      imprintOpacity: 1.0,
    );
  }

  // Cancel drag - reset offset
  void cancelImprintDrag() {
    state = state.copyWith(imprintOffset: Offset.zero);
  }
}