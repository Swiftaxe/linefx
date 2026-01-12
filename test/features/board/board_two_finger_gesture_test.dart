@Tags(['integration'])
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algrafx/board.dart';
import 'package:algrafx/features/board/board_providers.dart';
import 'package:algrafx/features/board/drawing/point.dart';

void main() {
  group('Two-Finger Gesture Animation Tests', () {
    Future<void> addImprintsToBoard(WidgetTester tester, ProviderContainer container) async {
      final notifier = container.read(boardNotifierProvider.notifier);
      
      // Draw some segments that will become imprints
      notifier.startNewSegment();
      notifier.addPoint(const Point(Offset(100, 100), Offset.zero));
      notifier.addPoint(const Point(Offset(150, 150), Offset.zero));
      
      await tester.pump();
      
      // Wait for segments to fall and become imprints (simulate animation)
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      
      // Verify imprints exist
      final state = container.read(boardNotifierProvider);
      expect(state.imprintSegments.any((seg) => seg.isNotEmpty), isTrue,
          reason: 'Should have imprints before starting gesture');
    }

    testWidgets(
      'Given imprints exist, when user starts two-finger drag, then imprintOffset should immediately become zero',
      (tester) async {
        final container = ProviderContainer();
        
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(body: Board()),
            ),
          ),
        );

        await addImprintsToBoard(tester, container);

        // Start two-finger gesture
        final gesture1 = await tester.startGesture(const Offset(200, 200));
        final gesture2 = await tester.startGesture(const Offset(210, 210));
        await tester.pump();

        // Check that imprint drag started (offset should be zero at start)
        final state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(Offset.zero),
            reason: 'Imprint offset should be zero when two-finger drag starts');

        await gesture1.up();
        await gesture2.up();
        container.dispose();
      },
    );

    testWidgets(
      'Given two-finger drag in progress, when fingers move, then imprintOffset should update to follow the movement',
      (tester) async {
        final container = ProviderContainer();
        
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(body: Board()),
            ),
          ),
        );

        await addImprintsToBoard(tester, container);

        // Use TestPointer to simulate multi-touch
        final pointer1 = TestPointer(1);
        final pointer2 = TestPointer(2);
        
        // Start two-finger gesture at initial position
        final startPos1 = const Offset(200, 200);
        final startPos2 = const Offset(210, 210);
        
        await tester.sendEventToBinding(pointer1.down(startPos1));
        await tester.sendEventToBinding(pointer2.down(startPos2));
        await tester.pump();

        var state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(Offset.zero),
            reason: 'Offset should be zero at start');

        // Move fingers to the right by 50 pixels
        final movePos1 = const Offset(250, 200);
        final movePos2 = const Offset(260, 210);
        await tester.sendEventToBinding(pointer1.move(movePos1));
        await tester.sendEventToBinding(pointer2.move(movePos2));
        await tester.pump();

        // Check that offset updated
        state = container.read(boardNotifierProvider);
        expect(state.imprintOffset.dx, greaterThan(20),
            reason: 'Imprint should move horizontally with fingers');
        expect(state.imprintOffset.dx, lessThan(30),
            reason: 'Imprint offset should be approximately 25px horizontal (focal point movement)');
        
        // Move fingers further down by 30 pixels
        final movePos3 = const Offset(250, 230);
        final movePos4 = const Offset(260, 240);
        await tester.sendEventToBinding(pointer1.move(movePos3));
        await tester.sendEventToBinding(pointer2.move(movePos4));
        await tester.pump();

        // Check that offset updated vertically too
        state = container.read(boardNotifierProvider);
        expect(state.imprintOffset.dy, greaterThan(20),
            reason: 'Imprint should also move vertically with fingers (moved ~30px down)');

        await tester.sendEventToBinding(pointer1.up());
        await tester.sendEventToBinding(pointer2.up());
        container.dispose();
      },
    );

    testWidgets(
      'Given two-finger drag in progress, when fingers move incrementally, then imprintOffset should accumulate the deltas',
      (tester) async {
        final container = ProviderContainer();
        
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(body: Board()),
            ),
          ),
        );

        await addImprintsToBoard(tester, container);

        // Start gesture with TestPointer
        final pointer1 = TestPointer(1);
        final pointer2 = TestPointer(2);
        
        await tester.sendEventToBinding(pointer1.down(const Offset(200, 200)));
        await tester.sendEventToBinding(pointer2.down(const Offset(210, 210)));
        await tester.pump();

        // Move incrementally in small steps
        await tester.sendEventToBinding(pointer1.move(const Offset(210, 200)));
        await tester.sendEventToBinding(pointer2.move(const Offset(220, 210)));
        await tester.pump();
        
        var state = container.read(boardNotifierProvider);
        final offset1 = state.imprintOffset;
        expect(offset1.dx, greaterThan(0), reason: 'Should have moved right');

        // Move again
        await tester.sendEventToBinding(pointer1.move(const Offset(220, 200)));
        await tester.sendEventToBinding(pointer2.move(const Offset(230, 210)));
        await tester.pump();

        state = container.read(boardNotifierProvider);
        final offset2 = state.imprintOffset;
        expect(offset2.dx, greaterThan(offset1.dx),
            reason: 'Offset should accumulate (continue moving right)');

        await tester.sendEventToBinding(pointer1.up());
        await tester.sendEventToBinding(pointer2.up());
        container.dispose();
      },
    );

    testWidgets(
      'Given two-finger drag with short distance, when gesture ends, then imprints should snap back (offset becomes zero)',
      (tester) async {
        final container = ProviderContainer();
        
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(body: Board()),
            ),
          ),
        );

        await addImprintsToBoard(tester, container);

        final screenSize = tester.getSize(find.byType(Board));
        final shortDistance = screenSize.width * 0.05; // 5% - below 15% threshold

        // Start and move short distance with TestPointer
        final pointer1 = TestPointer(1);
        final pointer2 = TestPointer(2);
        
        await tester.sendEventToBinding(pointer1.down(const Offset(200, 200)));
        await tester.sendEventToBinding(pointer2.down(const Offset(210, 210)));
        await tester.pump();

        await tester.sendEventToBinding(pointer1.move(Offset(200 + shortDistance, 200)));
        await tester.sendEventToBinding(pointer2.move(Offset(210 + shortDistance, 210)));
        await tester.pump();

        var state = container.read(boardNotifierProvider);
        expect(state.imprintOffset.distance, greaterThan(0),
            reason: 'Should have offset during drag');

        // End gesture
        await tester.sendEventToBinding(pointer1.up());
        await tester.sendEventToBinding(pointer2.up());
        await tester.pump();

        // Should snap back
        state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(Offset.zero),
            reason: 'Short drag should cancel and snap back to zero');
        expect(state.imprintOpacity, equals(1.0),
            reason: 'Opacity should remain at 1.0 for cancelled drag');
        expect(state.imprintSegments.any((seg) => seg.isNotEmpty), isTrue,
            reason: 'Imprints should still exist after cancel');

        container.dispose();
      },
    );

    testWidgets(
      'Given two-finger drag with long distance, when gesture ends, then imprints should fade (opacity becomes 0)',
      (tester) async {
        final container = ProviderContainer();
        
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(body: Board()),
            ),
          ),
        );

        await addImprintsToBoard(tester, container);

        final screenSize = tester.getSize(find.byType(Board));
        final longDistance = screenSize.width * 0.7; // 70% - focal point moves ~35%, well above 15% threshold

        // Start and move long distance with TestPointer
        final pointer1 = TestPointer(1);
        final pointer2 = TestPointer(2);
        
        await tester.sendEventToBinding(pointer1.down(const Offset(200, 200)));
        await tester.sendEventToBinding(pointer2.down(const Offset(210, 210)));
        await tester.pump();

        await tester.sendEventToBinding(pointer1.move(Offset(200 + longDistance, 200)));
        await tester.sendEventToBinding(pointer2.move(Offset(210 + longDistance, 210)));
        await tester.pump();

        var state = container.read(boardNotifierProvider);
        // Focal point moves approximately half the distance of fingers
        expect(state.imprintOffset.distance, greaterThan(screenSize.width * 0.075),
            reason: 'Should have moved beyond half the threshold (focal point calculation)');

        // End gesture
        await tester.sendEventToBinding(pointer1.up());
        await tester.sendEventToBinding(pointer2.up());
        await tester.pump();

        // Should trigger fade
        state = container.read(boardNotifierProvider);
        expect(state.imprintOpacity, equals(0.0),
            reason: 'Long drag should trigger fade (opacity to 0)');

        // Wait for fade animation to complete
        await tester.pump(const Duration(milliseconds: 500));

        state = container.read(boardNotifierProvider);
        expect(state.imprintSegments.every((seg) => seg.isEmpty), isTrue,
            reason: 'Imprints should be cleared after fade animation');
        expect(state.imprintOffset, equals(Offset.zero),
            reason: 'Offset should reset after clearing');
        expect(state.imprintOpacity, equals(1.0),
            reason: 'Opacity should reset to 1.0 after clearing');

        container.dispose();
      },
    );
  });
}
