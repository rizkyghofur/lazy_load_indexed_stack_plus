# lazy_load_indexed_stack_plus

This package is a fork of [lazy_load_indexed_stack](https://github.com/okaryo/lazy_load_indexed_stack).

A package that extends IndexedStack to allow for lazy loading and provides enhanced control for reloading specific child widgets.

## Motivation

If you use the IndexedStack with bottom navigation, all the widgets specified in the children of the IndexedStack will be built.

Moreover, if the widget requires API requests or database access, or has a complex UI, the IndexedStack build time will be significant.

Therefore, we created an extended IndexedStack that builds the required widget only when it is needed and returns the pre-built widget when it is needed again.

## Features

- **Lazy Loading**: The main feature of `LazyLoadIndexedStack` is to build children widgets only when they are needed, reducing initial load time.
- **Preloading**: With the `preloadIndexes` parameter, you can specify indexes of children that should be built in advance, even if they are not currently visible.
- **Auto Disposal**: The `autoDisposeIndexes` parameter allows specific children to be automatically disposed of when they are no longer visible. When these children are accessed again, they will be rebuilt from scratch.
- **LRU Cache Limit**: Limit the number of loaded pages in memory automatically via `maxActivePages`.
- **Idle Timeout**: Set `idleTimeout` to automatically unload offstage pages that have been inactive for a given duration.
- **Page Guards**: Intercept index changes using `onBeforeIndexChanged` to validate or reject page transitions.
- **Lifecycle Callbacks**: Hooks for when children are loaded, disposed, index changes, or index changes are rejected.
- **Programmatic Controller**: Control page loading status, trigger reloads (`reloadIndex`), load all (`loadAll`), or clean memory (`disposeAllExceptActive`) via `LazyLoadIndexedStackController`.
- **Directional/Transition Animations**: Animate transitions between active indexes with custom durations, curves, and direction-aware custom builders (`directionalTransitionBuilder`).
- **Custom Placeholder Builders**: Customize the loading widget per-index via `unloadWidgetBuilder`.
- **State Preservation**: Automatically assign PageStorageKeys to offstage children to keep their scroll positions when unloaded via `preserveState`.
- **Global Theme/Configuration**: Configure settings like transition duration, curves, active limits, and timeouts globally for all stacks using `LazyLoadIndexedStackTheme`.
- **Performance Metrics**: Callback `onBuildDuration` to report how long each page takes to build and render.
- **Deferred Loading (Debounce)**: Prevent unnecessary loading during fast page switching/swiping.

## Usage

You can use `LazyLoadIndexedStack` in the same way as `IndexedStack`, with additional options.

### Basic Example

```dart
class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;

  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: LazyLoadIndexedStack(
          index: _index,
          preloadIndexes: [1, 2],
          autoDisposeIndexes: [2, 3],
          children: [
            Page1(), // Load by initial index
            Page2(), // Preloaded initially
            Page3(), // Preloaded initially but disposed when other index is selected
            Page4(), // Not preloaded and disposed when other index is selected
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          onTap: (index) {
            setState(() => _index = index);
          },
          currentIndex: _index,
          items: [
            BottomNavigationBarItem1(),
            BottomNavigationBarItem2(),
            BottomNavigationBarItem3(),
            BottomNavigationBarItem4(),
          ],
        ),
      ),
    );
  }
}
```

### Advanced Features Example

```dart
// 1. (Optional) Configure settings globally using LazyLoadIndexedStackTheme
LazyLoadIndexedStackTheme(
  data: LazyLoadIndexedStackThemeData(
    unloadWidget: Center(child: CircularProgressIndicator()),
    maxActivePages: 3, // Keep at most 3 pages in memory (LRU cache)
    idleTimeout: const Duration(minutes: 5), // Auto-dispose idle offstage pages
  ),
  child: MaterialApp(home: MyMainPage()),
);

// 2. Use inside your Page
final controller = LazyLoadIndexedStackController();

// Use the controller programmatically
controller.preloadIndex(2); // Force preload index 2
controller.disposeIndex(1); // Manually dispose loaded index 1
controller.reloadIndex(0);  // Recreate and reload index 0
controller.loadAll();       // Preload all children
controller.disposeAllExceptActive(); // Dispose all offstage pages from memory
bool loaded = controller.isLoaded(0); // Check if index 0 is loaded

LazyLoadIndexedStack(
  index: _index,
  controller: controller,
  // State preservation: automatically assign PageStorageKeys
  preserveState: true,
  // Performance metrics logging
  onBuildDuration: (index, duration) {
    print('Page $index rendered in ${duration.inMilliseconds}ms');
  },
  // Custom loader per index (falls back to global theme if omitted)
  unloadWidgetBuilder: (context, index) => ShimmerLoadingWidget(index: index),
  // Page guards
  onBeforeIndexChanged: (fromIndex, toIndex) {
    if (fromIndex == 1 && hasUnsavedChanges) {
      return false; // Prevent index change
    }
    return true;
  },
  onIndexChangeRejected: (rejectedIndex) => print('Index switch to $rejectedIndex blocked'),
  // Delay loading by 300ms to debounce fast navigation
  delayDuration: const Duration(milliseconds: 300),
  // Transition animations
  transitionDuration: const Duration(milliseconds: 300),
  transitionCurve: Curves.easeInOut,
  // Custom transition builder (direction-aware)
  directionalTransitionBuilder: (context, animation, child, index, activeIndex) {
    // Return custom direction-aware slide/fade transition
    return SlideTransition(
      position: animation.drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
      child: child,
    );
  },
  // Lifecycle hooks
  onLoaded: (index) => print('Page $index loaded'),
  onDisposed: (index) => print('Page $index disposed'),
  onIndexChanged: (index) => print('Active index changed to $index'),
  children: [
    Page1(),
    Page2(),
    Page3(),
  ],
)
```

See more details in [Example](https://pub.dev/packages/lazy_load_indexed_stack_plus/example) or [API reference](https://pub.dev/documentation/lazy_load_indexed_stack_plus/latest/lazy_load_indexed_stack/LazyLoadIndexedStack-class.html)!
