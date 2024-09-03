import 'dart:ui';

final size = window.physicalSize / window.devicePixelRatio;
const maxPoints = 100;
const force = Offset(0, 0.2);
const acceleration = 1.08;
