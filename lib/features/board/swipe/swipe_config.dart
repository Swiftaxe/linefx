import 'dart:ui';

enum SwipeDirection { left, right, up, down }

class SwipeConfig {
  // Distance as percentage of screen width
  static const double deleteThresholdDistancePercent = 0.15; // 15%
  
  // Velocity as percentage of screen width per second
  static const double deleteThresholdVelocityPercent = 1.0; // 100%
  
  static const Duration fadeDuration = Duration(milliseconds: 400);

  static double getDeleteDistance(Size screenSize) {
    return screenSize.width * deleteThresholdDistancePercent;
  }

  static double getDeleteVelocity(Size screenSize) {
    return screenSize.width * deleteThresholdVelocityPercent;
  }

  static bool shouldDelete({
    required double velocity,
    required double distance,
    required Size screenSize,
  }) {
    final velocityThreshold = getDeleteVelocity(screenSize);
    final distanceThreshold = getDeleteDistance(screenSize);
    
    return velocity > velocityThreshold || distance > distanceThreshold;
  }

  static SwipeDirection getDirection(Offset delta) {
    if (delta.dx.abs() > delta.dy.abs()) {
      return delta.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
    } else {
      return delta.dy > 0 ? SwipeDirection.down : SwipeDirection.up;
    }
  }
}
