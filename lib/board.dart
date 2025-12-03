import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'constants.dart';
import 'features/board/board_providers.dart';
import 'features/board/drawing/painter.dart';
import 'features/board/drawing/point.dart';
import 'features/board/swipe/swipe_config.dart';

class Board extends ConsumerStatefulWidget {
  const Board({Key? key}) : super(key: key);

  @override
  ConsumerState<Board> createState() => _BoardState();
}

class _BoardState extends ConsumerState<Board> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fadeController;
  final size = window.physicalSize / window.devicePixelRatio;
  
  // Track gesture state
  bool _isImprintDragging = false;
  Offset _dragStartPosition = Offset.zero;
  Offset _totalDragDelta = Offset.zero;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0,
      upperBound: 1,
    )..repeat()
     ..addListener(_updatePoints);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addStatusListener(_onFadeComplete);
  }

  void _updatePoints() {
    ref.read(boardNotifierProvider.notifier).updatePoints();
  }

  void _onFadeComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      ref.read(boardNotifierProvider.notifier).clearAllImprints();
      _fadeController.reset();
    }
  }

  // Helper: Check if pointer event is a right-click
  bool _isRightClick(PointerEvent event) {
    return event.kind == PointerDeviceKind.mouse && 
           event.buttons == kSecondaryMouseButton;
  }

  // Core action: Start imprint drag
  void _handleImprintDragStart(Offset position) {
    _isImprintDragging = true;
    _dragStartPosition = position;
    _totalDragDelta = Offset.zero;
    ref.read(boardNotifierProvider.notifier).startImprintDrag();
  }

  // Core action: Update imprint drag
  void _handleImprintDragUpdate(Offset position) {
    final delta = position - _dragStartPosition;
    ref.read(boardNotifierProvider.notifier).updateImprintOffset(delta - _totalDragDelta);
    _totalDragDelta = delta;
  }

  // Core action: End imprint drag
  void _handleImprintDragEnd({required double velocity}) {
    final distance = _totalDragDelta.distance;
    final direction = SwipeConfig.getDirection(_totalDragDelta);
    
    ref.read(boardNotifierProvider.notifier).endImprintDrag(
      velocity: velocity,
      distance: distance,
      screenSize: size,
      direction: direction,
    );
    
    // Check if deletion was triggered and start fade animation
    final state = ref.read(boardNotifierProvider);
    if (state.imprintOpacity == 0.0) {
      _fadeController.forward();
    }
    
    _isImprintDragging = false;
    _totalDragDelta = Offset.zero;
  }

  // Core action: Start drawing
  void _handleDrawStart(Offset position) {
    ref.read(boardNotifierProvider.notifier).startNewSegment();
    ref.read(boardNotifierProvider.notifier).addPoint(
      Point(position, force),
    );
  }

  // Core action: Update drawing
  void _handleDrawUpdate(Offset position) {
    ref.read(boardNotifierProvider.notifier).addPoint(
      Point(position, force),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(boardNotifierProvider);
    final segments = ref.watch(cappedSegmentsProvider);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        // Right-click on mouse/trackpad: immediately delete all imprints
        if (_isRightClick(event)) {
          ref.read(boardNotifierProvider.notifier).clearAllImprints();
        }
      },
      child: GestureDetector(
        // Use only Scale gestures to handle both 1-finger and 2-finger
        onScaleStart: (details) {
          if (details.pointerCount == 2) {
            // Two-finger: Start imprint drag
            _handleImprintDragStart(details.focalPoint);
          } else if (details.pointerCount == 1) {
            // One-finger: Start drawing
            _handleDrawStart(details.focalPoint);
          }
        },
        onScaleUpdate: (details) {
          if (_isImprintDragging && details.pointerCount == 2) {
            // Continue two-finger drag
            _handleImprintDragUpdate(details.focalPoint);
          } else if (!_isImprintDragging && details.pointerCount == 1) {
            // Continue drawing
            _handleDrawUpdate(details.focalPoint);
          }
        },
        onScaleEnd: (details) {
          if (_isImprintDragging) {
            // End two-finger drag with velocity check
            final velocity = details.velocity.pixelsPerSecond.distance;
            _handleImprintDragEnd(velocity: velocity);
          }
        },
        child: CustomPaint(
          size: size,
          painter: Painter(
            segments,
            state.imprintSegments,
            imprintOffset: state.imprintOffset,
            imprintOpacity: state.imprintOpacity,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}
