import 'point.dart';

class PointAnimator {
  const PointAnimator({
    this.acceleration = 1.08,
    required this.maxHeight,
  });

  final double acceleration;
  final double maxHeight;

  List<List<Point>> updatePoints(List<List<Point>> segments) {
    return segments
        .map((segment) => segment
          .where((point) => point.active)
          .map((point) => point.update(
                acceleration: acceleration,
                maxHeight: maxHeight,
              ))
          .toList())
        .toList();
  }
}