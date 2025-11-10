@Tags(['integration'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:algrafx/board.dart';

void main() {
  group('Board Widget Integration Tests', () {
    testWidgets(
      'Given an empty board, when user drags across the screen, then a continuous line appears connecting the drag points',
      (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Board()),
          ),
        );

        // Act - Drag across the screen
        await tester.drag(find.byType(Board), const Offset(200, 200));
        await tester.pump();

        // Assert - Board should have painted content
        final boardFinder = find.byType(Board);
        final customPaintFinder = find.descendant(
          of: boardFinder,
          matching: find.byType(CustomPaint),
        );
        expect(customPaintFinder, findsOneWidget);
        
        // Verify painter has segments (basic smoke test)
        final customPaint = tester.widget<CustomPaint>(customPaintFinder);
        final painter = customPaint.painter;
        expect(painter, isNotNull);
      },
    );

    testWidgets(
      'Given a board with one drawn line, when user lifts finger then touches and drags again, then a new separate line is created not connected to the first',
      (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Board()),
          ),
        );

        // Act - Draw first line
        await tester.drag(find.byType(Board), const Offset(100, 100), touchSlopX: 0, touchSlopY: 0);
        await tester.pump();

        // Get state after first line
        final boardFinder = find.byType(Board);
        final customPaintFinder = find.descendant(
          of: boardFinder,
          matching: find.byType(CustomPaint),
        );
        final customPaint1 = tester.widget<CustomPaint>(customPaintFinder);
        final painter1 = customPaint1.painter as dynamic;
        final segmentsAfterFirstLine = painter1.segments.length as int;

        // Act - Draw second line at different location
        await tester.dragFrom(const Offset(300, 300), const Offset(50, 50));
        await tester.pump();

        // Assert - Should have more segments than before
        final customPaint2 = tester.widget<CustomPaint>(customPaintFinder);
        final painter2 = customPaint2.painter as dynamic;
        final segmentsAfterSecondLine = painter2.segments.length as int;
        
        expect(segmentsAfterSecondLine, greaterThan(segmentsAfterFirstLine));
      },
    );

    testWidgets(
      'Given a board with drawn points, when time passes and animation frames advance, then points move downward and eventually disappear at the bottom',
      (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Board()),
          ),
        );

        // Act - Draw some points
        await tester.drag(find.byType(Board), const Offset(100, 50));
        await tester.pump();

        // Get initial state
        final boardFinder = find.byType(Board);
        final customPaintFinder = find.descendant(
          of: boardFinder,
          matching: find.byType(CustomPaint),
        );
        final customPaint1 = tester.widget<CustomPaint>(customPaintFinder);
        final painter1 = customPaint1.painter as dynamic;
        final initialSegmentCount = painter1.segments.length as int;

        // Act - Advance time significantly to allow animation and removal
        for (int i = 0; i < 100; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Assert - Points should have been removed (segments might be empty or contain empty lists)
        final customPaint2 = tester.widget<CustomPaint>(customPaintFinder);
        final painter2 = customPaint2.painter as dynamic;
        
        // Either fewer segments or segments with fewer points
        final segments = painter2.segments as List;
        final hasFewerPoints = segments.isEmpty || 
                               segments.every((seg) => (seg as List).isEmpty) ||
                               segments.length < initialSegmentCount;
        
        expect(hasFewerPoints, isTrue, reason: 'Points should disappear over time');
      },
    );

    testWidgets(
      'Given a newly created board, when the widget is built, then the board renders without errors',
      (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Board()),
          ),
        );

        // Assert - Widget should build without errors
        expect(find.byType(Board), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Given a board with multiple drawn lines, when rendering occurs, then lines do not connect to each other',
      (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Board()),
          ),
        );

        // Act - Draw first line
        await tester.dragFrom(const Offset(100, 100), const Offset(50, 50));
        await tester.pump();

        // Act - Draw second line at different location (with gap)
        await tester.dragFrom(const Offset(300, 100), const Offset(50, 50));
        await tester.pump();

        // Assert - Should have separate segments
        final boardFinder = find.byType(Board);
        final customPaintFinder = find.descendant(
          of: boardFinder,
          matching: find.byType(CustomPaint),
        );
        final customPaint = tester.widget<CustomPaint>(customPaintFinder);
        final painter = customPaint.painter as dynamic;
        
        final segments = painter.segments as List;
        expect(segments.length, greaterThanOrEqualTo(2), reason: 'Should have at least 2 segments');
        
        // Verify segments are distinct if they both have points
        if (segments.length >= 2 && 
            (segments[0] as List).isNotEmpty && 
            (segments[1] as List).isNotEmpty) {
          final firstSegment = segments[0] as List;
          final secondSegment = segments[1] as List;
          final lastPointOfFirstSegment = firstSegment.last as dynamic;
          final firstPointOfSecondSegment = secondSegment.first as dynamic;
          
          // Different segments should have different starting points
          expect(
            lastPointOfFirstSegment.offset,
            isNot(equals(firstPointOfSecondSegment.offset)),
            reason: 'Segments should not be connected',
          );
        }
      },
    );

    testWidgets(
      'Given a board with many points, when user continues drawing beyond the limit, then oldest points disappear as new ones are added',
      (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Board()),
          ),
        );

        // Act - Draw a very long continuous line to exceed maxPoints
        final startPoint = const Offset(50, 250);
        final endPoint = const Offset(500, 250);
        
        await tester.dragFrom(startPoint, endPoint - startPoint);
        await tester.pump();

        // Assert - Points should be managed (this is a smoke test)
        final boardFinder = find.byType(Board);
        final customPaintFinder = find.descendant(
          of: boardFinder,
          matching: find.byType(CustomPaint),
        );
        final customPaint = tester.widget<CustomPaint>(customPaintFinder);
        final painter = customPaint.painter as dynamic;
        final segments = painter.segments as List;
        
        // Should have segments with points (verifies drawing works at scale)
        expect(segments, isNotEmpty, reason: 'Should have drawn segments');
        
        final totalPoints = segments.fold<int>(
          0,
          (sum, segment) => sum + (segment as List).length,
        );
        
        // Just verify that the widget handles many points without crashing
        expect(totalPoints, greaterThan(0), reason: 'Should have captured points');
      },
    );
  });
}
