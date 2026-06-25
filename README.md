[![CI](https://github.com/okaryo/lazy_load_indexed_stack/actions/workflows/ci.yml/badge.svg)](https://github.com/okaryo/lazy_load_indexed_stack/actions/workflows/ci.yml)
[![Pub](https://img.shields.io/pub/v/lazy_load_indexed_stack)](https://pub.dev/packages/lazy_load_indexed_stack)

# lazy_load_indexed_stack

A package that extends IndexedStack to allow for lazy loading and provides enhanced control for reloading specific child widgets.

## Motivation

If you use the IndexedStack with bottom navigation, all the widgets specified in the children of the IndexedStack will be built.

Moreover, if the widget requires API requests or database access, or has a complex UI, the IndexedStack build time will be significant.

Therefore, we created an extended IndexedStack that builds the required widget only when it is needed and returns the pre-built widget when it is needed again.

## Features
* **Lazy Loading**: The main feature of `LazyLoadIndexedStack` is to build children widgets only when they are needed, reducing initial load time.
* **Preloading**: With the `preloadIndexes` parameter, you can specify indexes of children that should be built in advance, even if they are not currently visible.
* **Auto Disposal**: The `autoDisposeIndexes` parameter allows specific children to be automatically disposed of when they are no longer visible. When these children are accessed again, they will be rebuilt from scratch.
* **Lifecycle Callbacks**: Hooks for when children are loaded, disposed, or when the active index changes.
* **Programmatic Controller**: Control and check page loading status via `LazyLoadIndexedStackController`.
* **Transition Animations**: Animate transitions between active indexes with custom durations and builders.
* **Deferred Loading (Debounce)**: Prevent unnecessary loading during fast page switching/swiping.

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
final controller = LazyLoadIndexedStackController();

// Use the controller programmatically
controller.preloadIndex(2); // Force preload index 2
controller.disposeIndex(1); // Manually dispose loaded index 1
bool loaded = controller.isLoaded(0); // Check if index 0 is loaded

LazyLoadIndexedStack(
  index: _index,
  controller: controller,
  // Delay loading by 300ms to debounce fast navigation
  delayDuration: const Duration(milliseconds: 300),
  // Cross-fade animation transition (300ms)
  transitionDuration: const Duration(milliseconds: 300),
  // Optional: Custom curve for transition
  transitionCurve: Curves.bounceOut,
  // Optional: Custom transition builder (defaults to FadeTransition)
  transitionBuilder: (context, animation, child) {
    return FadeTransition(opacity: animation, child: child);
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

See more details in [Example](https://pub.dev/packages/lazy_load_indexed_stack/example) or [API reference](https://pub.dev/documentation/lazy_load_indexed_stack/latest/lazy_load_indexed_stack/LazyLoadIndexedStack-class.html)!
