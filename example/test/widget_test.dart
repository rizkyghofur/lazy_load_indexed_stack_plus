import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazy_load_indexed_stack_example/main.dart';

void main() {
  testWidgets('lazy load page2 after bottom navigation item tapped',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MainApp());
    await tester.pump(); // Let post-frame callbacks complete

    // Verify that page1 is loaded (active) and page2 & 3 are not loaded
    expect(find.text('This is Page 1 (Loaded and Active)'), findsOneWidget);
    expect(find.text('This is Page 2 (Loaded and Active)'), findsNothing);
    expect(find.text('This is Page 3 (Loaded and Active)'), findsNothing);

    // Tap bottom navigation icon associated with page2 (index 1).
    await tester.tap(find.byIcon(Icons.today));
    await tester.pumpAndSettle();

    // Verify that page2 is now active/loaded
    expect(find.text('This is Page 2 (Loaded and Active)'), findsOneWidget);
    expect(find.text('This is Page 1 (Loaded and Active)', skipOffstage: false), findsOneWidget);
    expect(find.text('This is Page 1 (Loaded and Active)'), findsNothing); // offstage now
  });
}
