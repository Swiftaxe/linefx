import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algrafx/features/board/board_notifier.dart';
import 'package:algrafx/features/board/board_state.dart';
import 'package:algrafx/features/board/drawing/point.dart';
import 'package:algrafx/features/board/drawing/point_animator.dart';

final pointAnimatorProvider = Provider<PointAnimator>((ref) {
  final size = window.physicalSize / window.devicePixelRatio;
  return PointAnimator(maxHeight: size.height);
});

final boardNotifierProvider = NotifierProvider<BoardNotifier, BoardState>(() {
  return BoardNotifier();
});

final cappedSegmentsProvider = Provider<List<List<Point>>>((ref) {
  // Watch the state to trigger rebuilds when it changes
  ref.watch(boardNotifierProvider);
  // Use notifier to compute capped segments
  final notifier = ref.read(boardNotifierProvider.notifier);
  return notifier.getCappedSegments();
});
