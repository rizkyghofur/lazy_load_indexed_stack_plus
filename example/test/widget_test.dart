import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazy_load_indexed_stack_example/main.dart';

void main() {
  testWidgets('lazy load page2 after bottom navigation item tapped',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MainApp());
    await tester.pump(); // Let post-frame callbacks complete

    // Verify that page1 is loaded (active) and page3 is preloaded (offstage).
    expect(find.text('page1'), findsOneWidget);
    expect(find.text('page2'), findsNothing);
    expect(find.text('page3', skipOffstage: false), findsOneWidget);
    expect(find.text('page3'), findsNothing); // offstage

    // Tap bottom navigation icon associated with page2 (index 1).
    await tester.tap(find.byIcon(Icons.today));
    await tester.pumpAndSettle();

    // Verify that page2 is now active/loaded, page1 is offstage but loaded, page3 is offstage but loaded.
    expect(find.text('page2'), findsOneWidget);
    expect(find.text('page1', skipOffstage: false), findsOneWidget);
    expect(find.text('page1'), findsNothing); // offstage now
    expect(find.text('page3', skipOffstage: false), findsOneWidget);
  });
}
