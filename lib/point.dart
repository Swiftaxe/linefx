import 'dart:ui';
import 'constants.dart';

class Point {
  final Offset offset;
  final Offset force;
  final bool active;

  static const zero = Point(Offset.zero, Offset.zero, false);

  const Point(this.offset, this.force, [this.active = true]);

  Point update() {
    return active
        ? Point(offset + force, force * acceleration, offset.dy < size.height)
        : zero;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point &&
          runtimeType == other.runtimeType &&
          offset == other.offset &&
          force == other.force &&
          active == other.active;
  @override
  int get hashCode => offset.hashCode ^ force.hashCode ^ active.hashCode;
}
