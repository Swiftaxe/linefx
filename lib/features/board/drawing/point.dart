import 'dart:ui';

class Point {
  final Offset offset;
  final Offset force;
  final bool active;

  static const zero = Point(Offset.zero, Offset.zero, false);

  const Point(this.offset, this.force, [this.active = true]);

  Point update({
    required double acceleration,
    required double maxHeight,
  }) {
    if (!active) return zero;
    
    final newOffset = offset + force;
    final newForce = force * acceleration;
    final stillActive = newOffset.dy < maxHeight;
    
    return Point(newOffset, newForce, stillActive);
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
