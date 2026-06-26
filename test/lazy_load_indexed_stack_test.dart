import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazy_load_indexed_stack/lazy_load_indexed_stack.dart';

void main() {
  group('LazyLoadIndexedStack', () {
    group('default behavior', () {
      testWidgets('only the selected index is loaded', (tester) async {
        const key = Key('default_test');
        final lazyLoadIndexedStack = LazyLoadIndexedStack(
          key: key,
          index: 0,
          children: [
            _buildWidget(1),
            _buildWidget(2),
            _buildWidget(3),
            _buildWidget(4),
            _buildWidget(5),
          ],
        );

        // initial state index = 0
        await tester.pumpWidget(MaterialApp(home: lazyLoadIndexedStack));

        expect(find.text('page1', skipOffstage: false), findsOneWidget);
        expect(find.text('page2', skipOffstage: false), findsNothing);
        expect(find.text('page3', skipOffstage: false), findsNothing);
        expect(find.text('page4', skipOffstage: false), findsNothing);
        expect(find.text('page5', skipOffstage: false), findsNothing);

        // switch to index = 2
        await tester.pumpWidget(
          MaterialApp(
            home: LazyLoadIndexedStack(
              key: key,
              index: 2,
              children: [
                _buildWidget(1),
                _buildWidget(2),
                _buildWidget(3),
                _buildWidget(4),
                _buildWidget(5),
              ],
            ),
          ),
        );
        await tester.pump();

        expect(find.text('page1', skipOffstage: false), findsOneWidget);
        expect(find.text('page2', skipOffstage: false), findsNothing);
        expect(find.text('page3', skipOffstage: false), findsOneWidget);
        expect(find.text('page4', skipOffstage: false), findsNothing);
        expect(find.text('page5', skipOffstage: false), findsNothing);
      });
    });

    group('#preloadIndexes', () {
      testWidgets('Only indexes in preloadIndexes should be preloaded',
          (tester) async {
        const key = Key('preload_test');
        final lazyLoadIndexedStack = LazyLoadIndexedStack(
          key: key,
          index: 0,
          preloadIndexes: const [1, 3],
          children: [
            _buildWidget(1),
            _buildWidget(2),
            _buildWidget(3),
            _buildWidget(4),
            _buildWidget(5),
          ],
        );

        await tester.pumpWidget(MaterialApp(home: lazyLoadIndexedStack));

        expect(find.text('page1', skipOffstage: false), findsOneWidget);
        expect(find.text('page2', skipOffstage: false), findsOneWidget);
        expect(find.text('page3', skipOffstage: false), findsNothing);
        expect(find.text('page4', skipOffstage: false), findsOneWidget);
        expect(find.text('page5', skipOffstage: false), findsNothing);
      });
    });

    group('#autoDisposeIndexes', () {
      testWidgets(
          'Widgets in autoDisposeIndexes should be disposed when not visible',
          (tester) async {
        const key = Key('auto_dispose_test');
        final lazyLoadIndexedStack = LazyLoadIndexedStack(
          key: key,
          index: 0,
          autoDisposeIndexes: const [2, 4],
          children: [
            _buildWidget(1),
            _buildWidget(2),
            _buildWidgetWithKey(3),
            _buildWidget(4),
            _buildWidgetWithKey(5),
          ],
        );

        await tester.pumpWidget(MaterialApp(home: lazyLoadIndexedStack));

        // initial state index = 0
        expect(find.text('page1', skipOffstage: false), findsOneWidget);
        expect(find.text('page2', skipOffstage: false), findsNothing);
        expect(find.text('page3', skipOffstage: false), findsNothing);
        expect(find.text('page4', skipOffstage: false), findsNothing);
        expect(find.text('page5', skipOffstage: false), findsNothing);

        // switch to index = 2
        await tester.pumpWidget(
          MaterialApp(
            home: LazyLoadIndexedStack(
              key: key,
              index: 2,
              autoDisposeIndexes: const [2, 4],
              children: [
                _buildWidget(1),
                _buildWidget(2),
                _buildWidgetWithKey(3),
                _buildWidget(4),
                _buildWidgetWithKey(5),
              ],
            ),
          ),
        );
        await tester.pump();

        expect(find.text('page1', skipOffstage: false), findsOneWidget);
        expect(find.text('page2', skipOffstage: false), findsNothing);
        expect(find.text('page3', skipOffstage: false), findsOneWidget);
        expect(find.text('page4', skipOffstage: false), findsNothing);
        expect(find.text('page5', skipOffstage: false), findsNothing);

        // back to index = 0 (3 should be disposed)
        await tester.pumpWidget(
          MaterialApp(
            home: LazyLoadIndexedStack(
              key: key,
              index: 0,
              autoDisposeIndexes: const [2, 4],
              children: [
                _buildWidget(1),
                _buildWidget(2),
                _buildWidgetWithKey(3),
                _buildWidget(4),
                _buildWidgetWithKey(5),
              ],
            ),
          ),
        );
        await tester.pump();

        expect(find.text('page1', skipOffstage: false), findsOneWidget);
        expect(find.text('page2', skipOffstage: false), findsNothing);
        expect(find.text('page3', skipOffstage: false), findsNothing);
        expect(find.text('page4', skipOffstage: false), findsNothing);
        expect(find.text('page5', skipOffstage: false), findsNothing);

        // switch back to index = 2 (3 should be rebuilt)
        await tester.pumpWidget(
          MaterialApp(
            home: LazyLoadIndexedStack(
              key: key,
              index: 2,
              autoDisposeIndexes: const [2, 4],
              children: [
                _buildWidget(1),
                _buildWidget(2),
                _buildWidgetWithKey(3),
                _buildWidget(4),
                _buildWidgetWithKey(5),
              ],
            ),
          ),
        );
        await tester.pump();

        expect(find.text('page1', skipOffstage: false), findsOneWidget);
        expect(find.text('page2', skipOffstage: false), findsNothing);
        expect(find.text('page3', skipOffstage: false), findsOneWidget);
        expect(find.text('page4', skipOffstage: false), findsNothing);
        expect(find.text('page5', skipOffstage: false), findsNothing);
      });
    });

    group('Bug fix: stale props updates', () {
      testWidgets(
          'offstage loaded children receive new configs/props when parent rebuilds',
          (tester) async {
        const key = Key('stale_props_test');

        // Initial build: index 0 and 1 are loaded (1 is preloaded)
        await tester.pumpWidget(
          const MaterialApp(
            home: LazyLoadIndexedStack(
              key: key,
              index: 0,
              preloadIndexes: [1],
              children: [
                Center(child: Text('page1_old')),
                Center(child: Text('page2_old')),
              ],
            ),
          ),
        );

        expect(find.text('page1_old', skipOffstage: false), findsOneWidget);
        expect(find.text('page2_old', skipOffstage: false), findsOneWidget);

        // Parent rebuilds and updates the widget children list with new text
        await tester.pumpWidget(
          const MaterialApp(
            home: LazyLoadIndexedStack(
              key: key,
              index: 0,
              preloadIndexes: [1],
              children: [
                Center(child: Text('page1_new')),
                Center(child: Text('page2_new')),
              ],
            ),
          ),
        );
        await tester.pump();

        // Verify offstage loaded child (index 1) also updated
        expect(find.text('page1_new', skipOffstage: false), findsOneWidget);
        expect(find.text('page2_new', skipOffstage: false), findsOneWidget);
        expect(find.text('page1_old', skipOffstage: false), findsNothing);
        expect(find.text('page2_old', skipOffstage: false), findsNothing);
      });
    });

    group('Callbacks', () {
      testWidgets('triggers onLoaded, onDisposed, and onIndexChanged correctly',
          (tester) async {
        const key = Key('callbacks_test');
        final loaded = <int>[];
        final disposed = <int>[];
        final indexChanged = <int>[];

        await tester.pumpWidget(
          MaterialApp(
            home: LazyLoadIndexedStack(
              key: key,
              index: 0,
              preloadIndexes: const [1],
              autoDisposeIndexes: const [2],
              onLoaded: loaded.add,
              onDisposed: disposed.add,
              onIndexChanged: indexChanged.add,
              children: const [
                Center(child: Text('page1')),
                Center(child: Text('page2')),
                Center(child: Text('page3')),
              ],
            ),
          ),
        );

        await tester.pump();

        expect(loaded, containsAll([0, 1]));
        expect(indexChanged, [0]);
        expect(disposed, isEmpty);

        // Switch to index 2 (loads 2)
        await tester.pumpWidget(
          MaterialApp(
            home: LazyLoadIndexedStack(
              key: key,
              index: 2,
              preloadIndexes: const [1],
              autoDisposeIndexes: const [2],
              onLoaded: loaded.add,
              onDisposed: disposed.add,
              onIndexChanged: indexChanged.add,
              children: const [
                Center(child: Text('page1')),
                Center(child: Text('page2')),
                Center(child: Text('page3')),
              ],
            ),
          ),
        );
        await tester.pump();

        expect(loaded, containsAll([0, 1, 2]));
        expect(indexChanged, [0, 2]);
        expect(disposed, isEmpty);

        // Switch back to index 0 (disposes 2)
        await tester.pumpWidget(
          MaterialApp(
            home: LazyLoadIndexedStack(
              key: key,
              index: 0,
              preloadIndexes: const [1],
              autoDisposeIndexes: const [2],
              onLoaded: loaded.add,
              onDisposed: disposed.add,
              onIndexChanged: indexChanged.add,
              children: const [
                Center(child: Text('page1')),
                Center(child: Text('page2')),
                Center(child: Text('page3')),
              ],
            ),
          ),
        );
        await tester.pump();

        expect(disposed, [2]);
        expect(indexChanged, [0, 2, 0]);
      });
    });

    group('LazyLoadIndexedStackController', () {
      testWidgets('preloads, disposes, and queries index status',
          (tester) async {
        final controller = LazyLoadIndexedStackController();
        const key = Key('controller_test');

        await tester.pumpWidget(
          MaterialApp(
            home: LazyLoadIndexedStack(
              key: key,
              index: 0,
              controller: controller,
              children: const [
                Center(child: Text('page1')),
                Center(child: Text('page2')),
                Center(child: Text('page3')),
              ],
            ),
          ),
        );

        await tester.pump();

        expect(controller.isLoaded(0), isTrue);
        expect(controller.isLoaded(1), isFalse);
        expect(controller.isLoaded(2), isFalse);

        // Programmatically preload index 1
        controller.preloadIndex(1);
        await tester.pump();

        expect(controller.isLoaded(1), isTrue);
        expect(find.text('page2', skipOffstage: false), findsOneWidget);

        // Programmatically dispose index 1
        controller.disposeIndex(1);
        await tester.pump();

        expect(controller.isLoaded(1), isFalse);
        expect(find.text('page2', skipOffstage: false), findsNothing);

        // Try to dispose active index 0 (should not be allowed/effective)
        controller.disposeIndex(0);
        await tester.pump();
        expect(controller.isLoaded(0), isTrue);
      });
    });

    group('Transition Animations', () {
      testWidgets(
          'plays entry and exit transition animations with custom curve',
          (tester) async {
        const key = Key('transitions_test');

        await tester.pumpWidget(
          const MaterialApp(
            home: LazyLoadIndexedStack(
              key: key,
              index: 0,
              transitionDuration: Duration(milliseconds: 300),
              transitionCurve: Curves.bounceOut,
              children: [
                Center(child: Text('page1')),
                Center(child: Text('page2')),
              ],
            ),
          ),
        );

        await tester.pump();

        // page1 active, page2 not loaded
        expect(find.text('page1'), findsOneWidget);
        expect(find.text('page2', skipOffstage: false), findsNothing);

        // Switch index to 1
        await tester.pumpWidget(
          const MaterialApp(
            home: LazyLoadIndexedStack(
              key: key,
              index: 1,
              transitionDuration: Duration(milliseconds: 300),
              transitionCurve: Curves.bounceOut,
              children: [
                Center(child: Text('page1')),
                Center(child: Text('page2')),
              ],
            ),
          ),
        );

        // Start of transition (both pages should be onstage and animating)
        await tester.pump();
        expect(find.text('page1', skipOffstage: false), findsOneWidget);
        expect(find.text('page2', skipOffstage: false), findsOneWidget);

        // Let the animation complete
        await tester.pumpAndSettle();

        // page1 should now be offstage, page2 onstage
        expect(find.text('page1'), findsNothing);
        expect(find.text('page1', skipOffstage: false), findsOneWidget);
        expect(find.text('page2'), findsOneWidget);
      });
    });

    group('Deferred Loading (Debounce)', () {
      testWidgets(
          'delays loading and ignores intermediate fast page selections',
          (tester) async {
        const key = Key('deferred_test');
        final loaded = <int>[];

        await tester.pumpWidget(
          MaterialApp(
            home: LazyLoadIndexedStack(
              key: key,
              index: 0,
              delayDuration: const Duration(milliseconds: 300),
              onLoaded: loaded.add,
              children: const [
                Center(child: Text('page1')),
                Center(child: Text('page2')),
                Center(child: Text('page3')),
              ],
            ),
          ),
        );

        await tester.pump();
        expect(loaded, [0]);

        // Switch to index 1
        await tester.pumpWidget(
          MaterialApp(
            home: LazyLoadIndexedStack(
              key: key,
              index: 1,
              delayDuration: const Duration(milliseconds: 300),
              onLoaded: loaded.add,
              children: const [
                Center(child: Text('page1')),
                Center(child: Text('page2')),
                Center(child: Text('page3')),
              ],
            ),
          ),
        );

        // Fast switch to index 2 (100ms later)
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpWidget(
          MaterialApp(
            home: LazyLoadIndexedStack(
              key: key,
              index: 2,
              delayDuration: const Duration(milliseconds: 300),
              onLoaded: loaded.add,
              children: const [
                Center(child: Text('page1')),
                Center(child: Text('page2')),
                Center(child: Text('page3')),
              ],
            ),
          ),
        );

        // Let 350ms pass to ensure page 2 is loaded
        await tester.pump(const Duration(milliseconds: 350));

        // Page 1 and 3 should be loaded. Page 2 was never loaded due to debounce!
        expect(loaded, containsAllInOrder([0, 2]));
        expect(loaded, isNot(contains(1)));
      });
    });

    group('Assertions', () {
      testWidgets('throws assertion error for out of bounds active index',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: LazyLoadIndexedStack(
              index: 5,
              children: [
                Text('page1'),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isAssertionError);
      });

      testWidgets('throws assertion error for out of bounds preload index',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: LazyLoadIndexedStack(
              index: 0,
              preloadIndexes: [2],
              children: [
                Text('page1'),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isAssertionError);
      });
    });

    group('Disposal Policy (maxActivePages)', () {
      testWidgets('limits the number of loaded pages using LRU', (tester) async {
        const key = Key('max_active_pages_test');
        final disposed = <int>[];

        Widget buildStack(int index) => LazyLoadIndexedStack(
              key: key,
              index: index,
              maxActivePages: 2,
              onDisposed: disposed.add,
              children: [
                _buildWidget(1),
                _buildWidget(2),
                _buildWidget(3),
              ],
            );

        // Initially index 0 loaded
        await tester.pumpWidget(MaterialApp(home: buildStack(0)));
        expect(find.text('page1', skipOffstage: false), findsOneWidget);
        expect(find.text('page2', skipOffstage: false), findsNothing);
        expect(find.text('page3', skipOffstage: false), findsNothing);

        // Switch to index 1 (loaded: 0, 1. Count = 2)
        await tester.pumpWidget(MaterialApp(home: buildStack(1)));
        await tester.pump();
        expect(find.text('page1', skipOffstage: false), findsOneWidget);
        expect(find.text('page2', skipOffstage: false), findsOneWidget);
        expect(find.text('page3', skipOffstage: false), findsNothing);
        expect(disposed, isEmpty);

        // Switch to index 2 (loaded: 1, 2. Count = 2. Page 0 should be disposed as it is least recently used)
        await tester.pumpWidget(MaterialApp(home: buildStack(2)));
        await tester.pump();
        expect(find.text('page1', skipOffstage: false), findsNothing);
        expect(find.text('page2', skipOffstage: false), findsOneWidget);
        expect(find.text('page3', skipOffstage: false), findsOneWidget);
        expect(disposed, [0]);
      });
    });

    group('Disposal Policy (idleTimeout)', () {
      testWidgets('automatically disposes offstage pages after idle timeout', (tester) async {
        const key = Key('idle_timeout_test');
        final disposed = <int>[];

        Widget buildStack(int index) => LazyLoadIndexedStack(
              key: key,
              index: index,
              idleTimeout: const Duration(milliseconds: 100),
              onDisposed: disposed.add,
              children: [
                _buildWidget(1),
                _buildWidget(2),
              ],
            );

        // Initially index 0 loaded
        await tester.pumpWidget(MaterialApp(home: buildStack(0)));
        // Switch to index 1 (0 becomes offstage, timer starts for 100ms)
        await tester.pumpWidget(MaterialApp(home: buildStack(1)));
        await tester.pump();

        expect(find.text('page1', skipOffstage: false), findsOneWidget);
        expect(find.text('page2', skipOffstage: false), findsOneWidget);
        expect(disposed, isEmpty);

        // Wait for 150ms
        await tester.pump(const Duration(milliseconds: 150));
        // Verify index 0 is disposed
        expect(find.text('page1', skipOffstage: false), findsNothing);
        expect(find.text('page2', skipOffstage: false), findsOneWidget);
        expect(disposed, [0]);
      });
    });

    group('Page Guards (onBeforeIndexChanged / onIndexChangeRejected)', () {
      testWidgets('guards page transitions synchronously and asynchronously', (tester) async {
        const key = Key('guards_test');
        final rejected = <int>[];
        bool allowTransition = true;

        Widget buildStack(int index) => LazyLoadIndexedStack(
              key: key,
              index: index,
              onBeforeIndexChanged: (from, to) => allowTransition,
              onIndexChangeRejected: rejected.add,
              children: [
                _buildWidget(1),
                _buildWidget(2),
              ],
            );

        await tester.pumpWidget(MaterialApp(home: buildStack(0)));
        expect(find.text('page1', skipOffstage: false), findsOneWidget);

        // Allow transition to 1
        allowTransition = true;
        await tester.pumpWidget(MaterialApp(home: buildStack(1)));
        await tester.pump();
        expect(find.text('page2', skipOffstage: false), findsOneWidget);

        // Block transition back to 0
        allowTransition = false;
        await tester.pumpWidget(MaterialApp(home: buildStack(0)));
        await tester.pump();

        // Should still show page2 (transition was rejected)
        expect(find.text('page1'), findsNothing);
        expect(find.text('page2'), findsOneWidget);
        expect(rejected, [0]);
      });
    });

    group('directionalTransitionBuilder', () {
      testWidgets('uses directional transition builder', (tester) async {
        const key = Key('directional_transition_test');
        int? builtIndex;
        int? builtActiveIndex;

        await tester.pumpWidget(
          MaterialApp(
            home: LazyLoadIndexedStack(
              key: key,
              index: 0,
              transitionDuration: const Duration(milliseconds: 100),
              directionalTransitionBuilder: (context, animation, child, index, activeIndex) {
                builtIndex = index;
                builtActiveIndex = activeIndex;
                return FadeTransition(opacity: animation, child: child);
              },
              children: [
                _buildWidget(1),
                _buildWidget(2),
              ],
            ),
          ),
        );

        await tester.pump();
        expect(builtIndex, isNotNull);
        expect(builtActiveIndex, 0);
      });
    });

    group('unloadWidgetBuilder', () {
      testWidgets('renders custom unload widget using builder', (tester) async {
        const key = Key('unload_widget_builder_test');

        await tester.pumpWidget(
          MaterialApp(
            home: LazyLoadIndexedStack(
              key: key,
              index: 0,
              unloadWidgetBuilder: (context, index) => Text('custom_loading_$index'),
              children: [
                _buildWidget(1),
                _buildWidget(2),
              ],
            ),
          ),
        );

        await tester.pump();
        expect(find.text('custom_loading_1', skipOffstage: false), findsOneWidget);
      });
    });

    group('Enhanced Controller Methods', () {
      testWidgets('reloads, loads all, and disposes all except active', (tester) async {
        final controller = LazyLoadIndexedStackController();
        const key = Key('enhanced_controller_test');

        await tester.pumpWidget(
          MaterialApp(
            home: LazyLoadIndexedStack(
              key: key,
              index: 0,
              controller: controller,
              children: [
                _buildWidget(1),
                _buildWidget(2),
                _buildWidget(3),
              ],
            ),
          ),
        );

        await tester.pump();
        expect(controller.isLoaded(0), isTrue);
        expect(controller.isLoaded(1), isFalse);
        expect(controller.isLoaded(2), isFalse);

        // loadAll
        controller.loadAll();
        await tester.pump();
        expect(controller.isLoaded(0), isTrue);
        expect(controller.isLoaded(1), isTrue);
        expect(controller.isLoaded(2), isTrue);

        // disposeAllExceptActive
        controller.disposeAllExceptActive();
        await tester.pump();
        expect(controller.isLoaded(0), isTrue);
        expect(controller.isLoaded(1), isFalse);
        expect(controller.isLoaded(2), isFalse);

        // reloadIndex
        controller.preloadIndex(1);
        await tester.pump();
        expect(controller.isLoaded(1), isTrue);
        
        controller.reloadIndex(1);
        await tester.pump(); // Toggle false state
        await tester.pump(); // Frame when it turns true again
        expect(controller.isLoaded(1), isTrue);
      });
    });

    group('State Preservation (preserveState)', () {
      testWidgets('assigns key and PageStorageKey to children when preserveState is true', (tester) async {
        const key = Key('preserve_state_test');
        await tester.pumpWidget(
          MaterialApp(
            home: LazyLoadIndexedStack(
              key: key,
              index: 0,
              preserveState: true,
              children: [
                _buildWidget(1),
              ],
            ),
          ),
        );
        await tester.pump();
        
        // Find the KeyedSubtree widget wrapping the child
        expect(find.byType(KeyedSubtree), findsOneWidget);
        final KeyedSubtree keyedSubtree = tester.widget(find.byType(KeyedSubtree));
        expect(keyedSubtree.key, isA<PageStorageKey<int>>());
      });
    });

    group('LazyLoadIndexedStackTheme', () {
      testWidgets('falls back to global theme defaults when local settings are omitted', (tester) async {
        const key = Key('theme_test');
        final disposed = <int>[];

        await tester.pumpWidget(
          MaterialApp(
            home: LazyLoadIndexedStackTheme(
              data: const LazyLoadIndexedStackThemeData(
                maxActivePages: 2,
              ),
              child: Builder(
                builder: (context) {
                  return LazyLoadIndexedStack(
                    key: key,
                    index: 0,
                    onDisposed: disposed.add,
                    children: [
                      _buildWidget(1),
                      _buildWidget(2),
                      _buildWidget(3),
                    ],
                  );
                }
              ),
            ),
          ),
        );

        // Initially index 0 loaded.
        // Switch to index 1 (loaded: 0, 1. Count = 2)
        await tester.pumpWidget(
          MaterialApp(
            home: LazyLoadIndexedStackTheme(
              data: const LazyLoadIndexedStackThemeData(
                maxActivePages: 2,
              ),
              child: Builder(
                builder: (context) {
                  return LazyLoadIndexedStack(
                    key: key,
                    index: 1,
                    onDisposed: disposed.add,
                    children: [
                      _buildWidget(1),
                      _buildWidget(2),
                      _buildWidget(3),
                    ],
                  );
                }
              ),
            ),
          ),
        );
        await tester.pump();
        expect(disposed, isEmpty);

        // Switch to index 2 (loaded: 1, 2. Count = 2. Page 0 disposed via theme's maxActivePages limit)
        await tester.pumpWidget(
          MaterialApp(
            home: LazyLoadIndexedStackTheme(
              data: const LazyLoadIndexedStackThemeData(
                maxActivePages: 2,
              ),
              child: Builder(
                builder: (context) {
                  return LazyLoadIndexedStack(
                    key: key,
                    index: 2,
                    onDisposed: disposed.add,
                    children: [
                      _buildWidget(1),
                      _buildWidget(2),
                      _buildWidget(3),
                    ],
                  );
                }
              ),
            ),
          ),
        );
        await tester.pump();
        expect(disposed, [0]);
      });
    });

    group('Performance Metrics (onBuildDuration)', () {
      testWidgets('invokes onBuildDuration callback when page renders', (tester) async {
        const key = Key('build_duration_test');
        int? reportedIndex;
        Duration? reportedDuration;

        await tester.pumpWidget(
          MaterialApp(
            home: LazyLoadIndexedStack(
              key: key,
              index: 0,
              onBuildDuration: (index, duration) {
                reportedIndex = index;
                reportedDuration = duration;
              },
              children: [
                _buildWidget(1),
              ],
            ),
          ),
        );

        await tester.pump();
        expect(reportedIndex, 0);
        expect(reportedDuration, isNotNull);
      });
    });

    group('Const constructor', () {
      test('can be instantiated as const', () {
        const stack = LazyLoadIndexedStack(
          index: 0,
          children: [],
        );
        expect(stack, isNotNull);
      });
    });
  });
}

Widget _buildWidget(final int num) {
  return Center(
    child: Text('page$num'),
  );
}

Widget _buildWidgetWithKey(final int num) {
  return Center(
    key: ValueKey(num),
    child: Text('page$num'),
  );
}
