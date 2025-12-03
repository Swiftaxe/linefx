import 'dart:ui';
import 'package:algrafx/features/board/drawing/point.dart';

class BoardState {
  final List<List<Point>> segments;
  final List<List<Point>> imprintSegments;
  final Offset imprintOffset;
  final double imprintOpacity;

  const BoardState({
    required this.segments,
    required this.imprintSegments,
    this.imprintOffset = Offset.zero,
    this.imprintOpacity = 1.0,
  });

  const BoardState.initial()
      : segments = const [[]],
        imprintSegments = const [[]],
        imprintOffset = Offset.zero,
        imprintOpacity = 1.0;

  BoardState copyWith({
    List<List<Point>>? segments,
    List<List<Point>>? imprintSegments,
    Offset? imprintOffset,
    double? imprintOpacity,
  }) {
    return BoardState(
      segments: segments ?? this.segments,
      imprintSegments: imprintSegments ?? this.imprintSegments,
      imprintOffset: imprintOffset ?? this.imprintOffset,
      imprintOpacity: imprintOpacity ?? this.imprintOpacity,
    );
  }
}