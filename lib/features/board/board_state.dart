import 'package:algrafx/features/board/drawing/point.dart';

class BoardState {
  final List<List<Point>> segments;
  final List<List<Point>> imprintSegments;

  const BoardState({
    required this.segments,
    required this.imprintSegments,
  });

  const BoardState.initial() : segments = const [[]], imprintSegments = const [[]];

  BoardState copyWith({
    List<List<Point>>? segments,
    List<List<Point>>? imprintSegments,
  }) {
    return BoardState(
      segments: segments ?? this.segments,
      imprintSegments: imprintSegments ?? this.imprintSegments,
    );
  }
}