## 1.4.0

- Add `preserveState` parameter to automatically assign PageStorageKeys to offstage child widgets.
- Add `LazyLoadIndexedStackTheme` and `LazyLoadIndexedStackThemeData` to configure settings globally.
- Add `onBuildDuration` callback to monitor page building and rendering times.
- Add `maxActivePages` policy for LRU caching.
- Add `idleTimeout` for automatic disposal of idle offstage pages.
- Add `onBeforeIndexChanged` and `onIndexChangeRejected` for guarding and intercepting index changes.
- Add `directionalTransitionBuilder` for direction-aware transition animations.
- Add `unloadWidgetBuilder` for custom loader / placeholder UI per index.
- Add new methods to `LazyLoadIndexedStackController`: `reloadIndex`, `disposeAllExceptActive`, and `loadAll`.
- Update required sdk version to `>=2.17.0 <4.0.0`

## 1.3.0

- Fix stale properties bug on offstage loaded child widgets.
- Support `const` constructor for `LazyLoadIndexedStack` and optimize default `unloadWidget` from `Container()` to `const SizedBox.shrink()`.
- Add lifecycle hooks: `onLoaded`, `onDisposed`, and `onIndexChanged`.
- Add programmatic controller `LazyLoadIndexedStackController`.
- Add transition animations support with `transitionDuration`, custom `transitionBuilder`, and custom `transitionCurve`.
- Add deferred/delay loading (debounce) support with `delayDuration`.
- Add index bounds validation assertions for `preloadIndexes` and `autoDisposeIndexes` to raise descriptive errors during development.
- Enable strict type checking analysis rules (`strict-casts`, `strict-inference`, `strict-raw-types`) in the codebase.

## 1.2.1

- Fix issue where non-preloaded children were loaded when index changed

## 1.2.0

- Add `autoDisposeIndexes` to dispose unused IndexedStack children and rebuild them when needed

## 1.1.0

- Add `preloadIndexes` Property for Advanced Element Preloading

## 1.0.1

- Fix dynamic generation of children causes overflow in [#4](https://github.com/rizkyghofur/lazy_load_indexed_stack_plus/pull/4)

## 1.0.0

- Update required sdk version to `^3.0.0`

## 0.1.4

- FIX eager rebuilds

## 0.1.3

- Update README

## 0.1.2

- Add API description
- Modify unloadWidget initializer

## 0.1.1

- Add example code
- Modify property

## 0.1.0

- Beta Release

## 0.0.2

- Add Widget parameter
- Update README
- Update pubspec

## 0.0.1

- Initial Release
