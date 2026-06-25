## 1.3.0
* Fix stale properties bug on offstage loaded child widgets.
* Support `const` constructor for `LazyLoadIndexedStack` and optimize default `unloadWidget` from `Container()` to `const SizedBox.shrink()`.
* Add lifecycle hooks: `onLoaded`, `onDisposed`, and `onIndexChanged`.
* Add programmatic controller `LazyLoadIndexedStackController`.
* Add transition animations support with `transitionDuration`, custom `transitionBuilder`, and custom `transitionCurve`.
* Add deferred/delay loading (debounce) support with `delayDuration`.
* Add index bounds validation assertions for `preloadIndexes` and `autoDisposeIndexes` to raise descriptive errors during development.
* Enable strict type checking analysis rules (`strict-casts`, `strict-inference`, `strict-raw-types`) in the codebase.

## 1.2.1
* Fix issue where non-preloaded children were loaded when index changed in [#12](https://github.com/okaryo/lazy_load_indexed_stack/pull/12)

## 1.2.0
* Add `autoDisposeIndexes` to dispose unused IndexedStack children and rebuild them when needed in [#7](https://github.com/okaryo/lazy_load_indexed_stack/pull/7)

## 1.1.0
* Add `preloadIndexes` Property for Advanced Element Preloading in [#6](https://github.com/okaryo/lazy_load_indexed_stack/pull/6)

## 1.0.1
* Fix dynamic generation of children causes  overflow in [#4](https://github.com/okaryo/lazy_load_indexed_stack/pull/4)

## 1.0.0
* Update required sdk version to `^3.0.0`

## 0.1.4
* FIX eager rebuilds

## 0.1.3
* Update README

## 0.1.2
* Add API description
* Modify unloadWidget initializer

## 0.1.1
* Add example code
* Modify property

## 0.1.0
* Beta Release

## 0.0.2
* Add Widget parameter
* Update README
* Update pubspec

## 0.0.1
* Initial Release
