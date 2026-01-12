import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isShiftPressed = false;

  // Shader for paper crumble effect
  FragmentShader? _crumbleShader;

  @override
  void initState() {
    super.initState();
    _loadShader();

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
    if (!mounted) return;
    try {
      ref.read(boardNotifierProvider.notifier).updatePoints();
    } catch (e) {
      // Provider container disposed - widget is being torn down
    }
  }

  void _onFadeComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (!mounted) return;
      try {
        ref.read(boardNotifierProvider.notifier).clearAllImprints();
        _fadeController.reset();
      } catch (e) {
        // Provider container disposed - widget is being torn down
      }
    }
  }

  Future<void> _loadShader() async {
    try {
      final program = await FragmentProgram.fromAsset('shaders/paper_crumble.frag');
      if (mounted) {
        setState(() {
          _crumbleShader = program.fragmentShader();
        });
      }
    } catch (e) {
      // Shader not available (e.g., in tests) - continue without it
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
    // Calculate total offset from start position and set it directly
    final totalOffset = position - _dragStartPosition;
    ref.read(boardNotifierProvider.notifier).setImprintOffset(totalOffset);
    _totalDragDelta = totalOffset;
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

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKeyboardKey.shiftLeft || 
            event.logicalKey == LogicalKeyboardKey.shiftRight) {
          setState(() {
            _isShiftPressed = event is KeyDownEvent || event is KeyRepeatEvent;
          });
        }
      },
      child: Listener(
      behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          // Right-click on mouse/trackpad: immediately delete all imprints
          if (_isRightClick(event)) {
            ref.read(boardNotifierProvider.notifier).clearAllImprints();
          }
        },
        child: GestureDetector(
        // Use only Scale gestures to handle touch 1-finger and 2-finger
          onScaleStart: (details) {
            // Skip if all imprints are empty (just cleared by right-click)
            final allImprintsEmpty = state.imprintSegments.every((seg) => seg.isEmpty);
            if (allImprintsEmpty && details.pointerCount == 1) return;
            
            if (details.pointerCount == 2) {
              // Touch: Two-finger detected - start imprint drag
              _handleImprintDragStart(details.focalPoint);
            } else if (details.pointerCount == 1) {
              if (_isShiftPressed && state.imprintSegments.any((seg) => seg.isNotEmpty)) {
                // Shift + drag: Start imprint manipulation
                _handleImprintDragStart(details.focalPoint);
              } else {
                // Normal drag: Start drawing
                ref.read(boardNotifierProvider.notifier).startNewSegment();
              }
            }
          },
          onScaleUpdate: (details) {
            if (_isImprintDragging) {
              // Continue imprint drag (either two-finger touch or Shift + drag)
              _handleImprintDragUpdate(details.focalPoint);
            } else if (details.pointerCount == 1 && !_isShiftPressed) {
              // Normal one-finger: Continue drawing
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
            crumbleShader: _crumbleShader,
            screenSize: size,
          ),
        ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.removeListener(_updatePoints);
    _animationController.dispose();
    _fadeController.removeStatusListener(_onFadeComplete);
    _fadeController.dispose();
    _crumbleShader?.dispose();
    super.dispose();
  }
}
