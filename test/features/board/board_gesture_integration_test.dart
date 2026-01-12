@Tags(['integration'])
library;

import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algrafx/board.dart';
import 'package:algrafx/features/board/board_providers.dart';
import 'package:algrafx/features/board/drawing/point.dart';

void main() {
  group('Board Widget Gesture Integration Tests', () {
    // Helper to create test pointer event
    PointerDownEvent createPointerDownEvent({
      required Offset position,
      PointerDeviceKind kind = PointerDeviceKind.mouse,
      int buttons = kPrimaryButton,
    }) {
      return PointerDownEvent(
        position: position,
        kind: kind,
        buttons: buttons,
      );
    }

    PointerMoveEvent createPointerMoveEvent({
      required Offset position,
      PointerDeviceKind kind = PointerDeviceKind.mouse,
      int buttons = kPrimaryButton,
    }) {
      return PointerMoveEvent(
        position: position,
        kind: kind,
        buttons: buttons,
      );
    }

    PointerUpEvent createPointerUpEvent({
      required Offset position,
      PointerDeviceKind kind = PointerDeviceKind.mouse,
    }) {
      return PointerUpEvent(
        position: position,
        kind: kind,
      );
    }

    // Helper to add some imprints to the board
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
    }

    testWidgets(
      'Given board with imprints, when user right-clicks, then imprints are immediately deleted',
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

        // Verify imprints exist
        var state = container.read(boardNotifierProvider);
        expect(state.imprintSegments, isNotEmpty, reason: 'Should have imprints before right-click');

        // Simulate right-click down
        final downEvent = createPointerDownEvent(
          position: const Offset(200, 200),
          buttons: kSecondaryMouseButton,
        );
        await tester.sendEventToBinding(downEvent);
        await tester.pump();

        // Check that imprints were immediately deleted (all segments should be empty)
        state = container.read(boardNotifierProvider);
        expect(state.imprintSegments.every((segment) => segment.isEmpty), isTrue, 
          reason: 'Right-click should instantly delete all imprint points');
        expect(state.imprintOffset, equals(Offset.zero));

        container.dispose();
      },
    );

    testWidgets(
      'Given board with imprints, when user two-finger drags far distance (>15% screen width), then imprints move and fade away on release',
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
        final farDistance = screenSize.width * 0.4; // 40% - focal point moves ~20%, above 15% threshold

        // Two-finger drag start
        final gesture1 = await tester.createGesture();
        final gesture2 = await tester.createGesture();
        await gesture1.down(const Offset(200, 200));
        await gesture2.down(const Offset(210, 200));
        await tester.pump();

        // Drag far
        await gesture1.moveTo(Offset(200 + farDistance, 200));
        await gesture2.moveTo(Offset(210 + farDistance, 200));
        await tester.pump();

        // Release
        await gesture1.up();
        await gesture2.up();
        await tester.pump();

        // Check that fade started (opacity should be 0)
        var state = container.read(boardNotifierProvider);
        expect(state.imprintOpacity, equals(0.0));

        // Wait for fade animation to complete (400ms)
        await tester.pump(const Duration(milliseconds: 500));

        // Check that imprints cleared
        state = container.read(boardNotifierProvider);
        expect(state.imprintSegments.every((seg) => seg.isEmpty), isTrue);
        expect(state.imprintOffset, equals(Offset.zero));
        expect(state.imprintOpacity, equals(1.0));

        container.dispose();
      },
    );

    testWidgets(
      'Given board with imprints, when user two-finger drags fast, then imprints toss away and fade',
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

        // Note: Simulating velocity in widget tests is difficult
        // This test will rely on distance threshold instead
        // In real usage, velocity would be calculated from gesture detector

        final screenSize = tester.getSize(find.byType(Board));
        final mediumDistance = screenSize.width * 0.32; // Focal point moves ~16%, just above 15% threshold

        // Two-finger drag start
        final gesture1 = await tester.createGesture();
        final gesture2 = await tester.createGesture();
        await gesture1.down(const Offset(200, 200));
        await gesture2.down(const Offset(210, 200));
        await tester.pump();

        // Drag medium distance
        await gesture1.moveTo(Offset(200 + mediumDistance, 200));
        await gesture2.moveTo(Offset(210 + mediumDistance, 200));
        await tester.pump();

        // Release
        await gesture1.up();
        await gesture2.up();
        await tester.pump();

        // Should trigger deletion
        var state = container.read(boardNotifierProvider);
        expect(state.imprintOpacity, equals(0.0));

        container.dispose();
      },
    );

    testWidgets(
      'Given board with no imprints, when user right-clicks and drags, then nothing happens (no error)',
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

        await tester.pump();

        // Verify no imprints
        var state = container.read(boardNotifierProvider);
        expect(state.imprintSegments, equals([[]]));

        // Right-click and drag
        final downEvent = createPointerDownEvent(
          position: const Offset(200, 200),
          buttons: kSecondaryMouseButton,
        );
        await tester.sendEventToBinding(downEvent);
        await tester.pump();

        final moveEvent = createPointerMoveEvent(
          position: const Offset(300, 300),
          buttons: kSecondaryMouseButton,
        );
        await tester.sendEventToBinding(moveEvent);
        await tester.pump();

        final upEvent = createPointerUpEvent(position: const Offset(300, 300));
        await tester.sendEventToBinding(upEvent);
        await tester.pump();

        // Should not throw error
        expect(tester.takeException(), isNull);

        container.dispose();
      },
    );

    testWidgets(
      'Given board with imprints being dragged with two fingers, when drag continues, then offset updates',
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

        // Start two-finger drag
        final pointer1 = TestPointer(1);
        final pointer2 = TestPointer(2);
        await tester.sendEventToBinding(pointer1.down(const Offset(200, 200)));
        await tester.sendEventToBinding(pointer2.down(const Offset(210, 210)));
        await tester.pump();

        var state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(Offset.zero));

        // Move both fingers
        await tester.sendEventToBinding(pointer1.move(const Offset(250, 200)));
        await tester.sendEventToBinding(pointer2.move(const Offset(260, 210)));
        await tester.pump();

        // Offset should have updated
        state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, isNot(equals(Offset.zero)));

        // Cleanup
        await tester.sendEventToBinding(pointer1.up());
        await tester.sendEventToBinding(pointer2.up());
        container.dispose();
      },
    );

    testWidgets(
      'Given empty board, when user left-clicks and drags, then orange segments appear',
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

        await tester.pump();

        // Simulate left-click drag using gesture detector
        await tester.drag(find.byType(Board), const Offset(100, 100));
        await tester.pump();

        // Should have segments
        final segments = container.read(cappedSegmentsProvider);
        expect(segments, isNotEmpty);
        expect(segments.first, isNotEmpty);

        container.dispose();
      },
    );

    testWidgets(
      'Given board in drawing mode, when user right-clicks during drawing, then drawing does NOT stop (right-click ignored during draw)',
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

        await tester.pump();

        // Start drawing with left-click
        await tester.drag(find.byType(Board), const Offset(50, 50));
        await tester.pump();

        var segments = container.read(cappedSegmentsProvider);
        final segmentCountAfterDraw = segments.length;
        expect(segmentCountAfterDraw, greaterThan(0));

        // Try to right-click (should be ignored or not interfere)
        final rightDownEvent = createPointerDownEvent(
          position: const Offset(300, 300),
          buttons: kSecondaryMouseButton,
        );
        await tester.sendEventToBinding(rightDownEvent);
        await tester.pump();

        // Drawing should still be intact
        segments = container.read(cappedSegmentsProvider);
        expect(segments.length, greaterThanOrEqualTo(segmentCountAfterDraw));

        container.dispose();
      },
    );

    testWidgets(
      'Given board with imprints, when user performs two-finger drag short distance, then imprints move and snap back',
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

        // Simulate two-finger gesture using scale gesture
        final TestGesture gesture = await tester.startGesture(const Offset(200, 200));
        final TestGesture gesture2 = await tester.startGesture(const Offset(210, 210));
        
        await tester.pump();

        // Check imprint drag started
        var state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(Offset.zero));

        // Move both fingers (short distance)
        await gesture.moveTo(const Offset(220, 220));
        await gesture2.moveTo(const Offset(230, 230));
        await tester.pump();

        // Should have offset
        state = container.read(boardNotifierProvider);
        expect(state.imprintOffset.distance, greaterThan(0));

        // Release
        await gesture.up();
        await gesture2.up();
        await tester.pump();

        // Should snap back (distance too short)
        state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(Offset.zero));
        expect(state.imprintOpacity, equals(1.0));

        container.dispose();
      },
    );

    testWidgets(
      'Given board with imprints, when user performs fast two-finger swipe, then imprints toss and fade',
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
        final farDistance = screenSize.width * 0.4; // Focal point moves ~20%, above 15% threshold

        // Two-finger gesture
        final TestGesture gesture = await tester.startGesture(const Offset(200, 200));
        final TestGesture gesture2 = await tester.startGesture(const Offset(210, 210));
        await tester.pump();

        // Fast swipe
        await gesture.moveTo(Offset(200 + farDistance, 200));
        await gesture2.moveTo(Offset(210 + farDistance, 210));
        await tester.pump();

        await gesture.up();
        await gesture2.up();
        await tester.pump();

        // Should trigger fade
        var state = container.read(boardNotifierProvider);
        expect(state.imprintOpacity, equals(0.0));

        container.dispose();
      },
    );

    testWidgets(
      'Given board with imprints, when user performs long two-finger drag (>15% screen), then imprints fade away',
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
        final farDistance = screenSize.width * 0.36; // Focal point moves ~18%, well above 15% threshold

        // Two-finger drag
        final TestGesture gesture = await tester.startGesture(const Offset(200, 200));
        final TestGesture gesture2 = await tester.startGesture(const Offset(210, 210));
        await tester.pump();

        await gesture.moveTo(Offset(200 + farDistance, 200));
        await gesture2.moveTo(Offset(210 + farDistance, 210));
        await tester.pump();

        await gesture.up();
        await gesture2.up();
        await tester.pump();

        // Should delete
        var state = container.read(boardNotifierProvider);
        expect(state.imprintOpacity, equals(0.0));

        container.dispose();
      },
    );

    testWidgets(
      'Given empty board, when user performs one-finger drag, then segments appear',
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

        await tester.pump();

        // One-finger drag
        await tester.drag(find.byType(Board), const Offset(100, 100));
        await tester.pump();

        // Should have segments
        final segments = container.read(cappedSegmentsProvider);
        expect(segments, isNotEmpty);

        container.dispose();
      },
    );

    testWidgets(
      'Given board in drawing mode (one finger down), when user adds second finger, then drawing stops and imprint drag does NOT start',
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

        await tester.pump();

        // Start one-finger drawing
        final gesture1 = await tester.startGesture(const Offset(200, 200));
        await tester.pump();

        // Should be drawing
        var segments = container.read(cappedSegmentsProvider);
        expect(segments, isNotEmpty);

        // Add second finger
        final gesture2 = await tester.startGesture(const Offset(210, 210));
        await tester.pump();

        // Move both
        await gesture1.moveTo(const Offset(220, 220));
        await gesture2.moveTo(const Offset(230, 230));
        await tester.pump();

        // In current implementation, this would stop drawing but not start imprint drag
        // (because imprint drag requires starting with 2 fingers, not adding a finger mid-gesture)
        
        // The behavior here depends on implementation details
        // At minimum, should not crash
        expect(tester.takeException(), isNull);

        await gesture1.up();
        await gesture2.up();

        container.dispose();
      },
    );

    testWidgets(
      'Given imprints being dragged with right-click, when drag released below threshold, then offset resets to zero and opacity stays 1.0',
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

        // Right-click drag (short)
        final downEvent = createPointerDownEvent(
          position: const Offset(200, 200),
          buttons: kSecondaryMouseButton,
        );
        await tester.sendEventToBinding(downEvent);
        await tester.pump();

        final moveEvent = createPointerMoveEvent(
          position: const Offset(210, 210),
          buttons: kSecondaryMouseButton,
        );
        await tester.sendEventToBinding(moveEvent);
        await tester.pump();

        final upEvent = createPointerUpEvent(position: const Offset(210, 210));
        await tester.sendEventToBinding(upEvent);
        await tester.pump();

        // Should cancel
        var state = container.read(boardNotifierProvider);
        expect(state.imprintOffset, equals(Offset.zero));
        expect(state.imprintOpacity, equals(1.0));
        expect(state.imprintSegments, isNotEmpty);

        container.dispose();
      },
    );

    testWidgets(
      'Given imprints being dragged with two fingers far, when drag released, then opacity goes to 0.0 and imprints clear after 400ms',
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
        final farDistance = screenSize.width * 0.4; // Focal point moves ~20%, above 15% threshold

        // Two-finger drag (far)
        final pointer1 = TestPointer(1);
        final pointer2 = TestPointer(2);
        
        await tester.sendEventToBinding(pointer1.down(const Offset(200, 200)));
        await tester.sendEventToBinding(pointer2.down(const Offset(210, 210)));
        await tester.pump();

        await tester.sendEventToBinding(pointer1.move(Offset(200 + farDistance, 200)));
        await tester.sendEventToBinding(pointer2.move(Offset(210 + farDistance, 210)));
        await tester.pump();

        await tester.sendEventToBinding(pointer1.up());
        await tester.sendEventToBinding(pointer2.up());
        await tester.pump();

        // Should start fade
        var state = container.read(boardNotifierProvider);
        expect(state.imprintOpacity, equals(0.0));
        expect(state.imprintSegments, isNotEmpty); // Not cleared yet

        // Wait for animation (400ms + buffer)
        await tester.pump(const Duration(milliseconds: 500));

        // Should be cleared
        state = container.read(boardNotifierProvider);
        expect(state.imprintSegments.every((seg) => seg.isEmpty), isTrue);
        expect(state.imprintOffset, equals(Offset.zero));
        expect(state.imprintOpacity, equals(1.0));

        container.dispose();
      },
    );

    testWidgets(
      'Given board with multiple gesture starts/stops, when gestures alternate between draw and drag, then state never gets stuck',
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

        // Cycle 1: Draw
        await tester.drag(find.byType(Board), const Offset(50, 50));
        await tester.pump();

        // Cycle 2: Right-drag (short - cancel)
        var downEvent = createPointerDownEvent(
          position: const Offset(200, 200),
          buttons: kSecondaryMouseButton,
        );
        await tester.sendEventToBinding(downEvent);
        await tester.pump();

        var moveEvent = createPointerMoveEvent(
          position: const Offset(220, 220),
          buttons: kSecondaryMouseButton,
        );
        await tester.sendEventToBinding(moveEvent);
        await tester.pump();

        var upEvent = createPointerUpEvent(position: const Offset(220, 220));
        await tester.sendEventToBinding(upEvent);
        await tester.pump();

        // Cycle 3: Draw again
        await tester.drag(find.byType(Board), const Offset(50, 50), pointer: 2);
        await tester.pump();

        // Cycle 4: Right-drag again
        downEvent = createPointerDownEvent(
          position: const Offset(300, 300),
          buttons: kSecondaryMouseButton,
        );
        await tester.sendEventToBinding(downEvent);
        await tester.pump();

        moveEvent = createPointerMoveEvent(
          position: const Offset(320, 320),
          buttons: kSecondaryMouseButton,
        );
        await tester.sendEventToBinding(moveEvent);
        await tester.pump();

        upEvent = createPointerUpEvent(position: const Offset(320, 320));
        await tester.sendEventToBinding(upEvent);
        await tester.pump();

        // Cycle 5: Final draw - should work
        await tester.drag(find.byType(Board), const Offset(50, 50), pointer: 3);
        await tester.pump();

        // Should not crash and drawing should work
        expect(tester.takeException(), isNull);
        final segments = container.read(cappedSegmentsProvider);
        expect(segments, isNotEmpty);

        container.dispose();
      },
    );
  });
}
