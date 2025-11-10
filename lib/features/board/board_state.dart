import 'package:algrafx/features/board/drawing/point.dart';

class BoardState {
  final List<List<Point>> segments;

  const BoardState({
    required this.segments,
  });

  const BoardState.initial() : segments = const [[]];

  BoardState copyWith({
    List<List<Point>>? segments,
  }) {
    return BoardState(
      segments: segments ?? this.segments,
    );
  }
}