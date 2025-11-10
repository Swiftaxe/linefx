import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'constants.dart';
import 'features/board/board_providers.dart';
import 'features/board/drawing/painter.dart';
import 'features/board/drawing/point.dart';

class Board extends ConsumerStatefulWidget {
  const Board({Key? key}) : super(key: key);

  @override
  ConsumerState<Board> createState() => _BoardState();
}

class _BoardState extends ConsumerState<Board> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final size = window.physicalSize / window.devicePixelRatio;

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
  }

  void _updatePoints() {
    ref.read(boardNotifierProvider.notifier).updatePoints();
  }

  @override
  Widget build(BuildContext context) {
    final segments = ref.watch(cappedSegmentsProvider);

    return Listener(
      onPointerDown: (details) {
        ref.read(boardNotifierProvider.notifier).startNewSegment();
        ref.read(boardNotifierProvider.notifier).addPoint(
          Point(details.localPosition, force),
        );
      },
      onPointerMove: (details) {
        ref.read(boardNotifierProvider.notifier).addPoint(
          Point(details.localPosition, force),
        );
      },
      onPointerUp: (details) {
        ref.read(boardNotifierProvider.notifier).addPoint(
          Point(details.localPosition, force),
        );
      },
      child: CustomPaint(
        size: size,
        painter: Painter(segments),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
