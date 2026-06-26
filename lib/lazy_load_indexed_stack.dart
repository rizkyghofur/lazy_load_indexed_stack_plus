import 'dart:async';
import 'package:flutter/widgets.dart';

/// A theme to globally configure [LazyLoadIndexedStack] default settings.
class LazyLoadIndexedStackTheme extends InheritedWidget {
  /// The global configuration settings.
  final LazyLoadIndexedStackThemeData data;

  /// Creates a theme to globally configure [LazyLoadIndexedStack] default settings.
  const LazyLoadIndexedStackTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// Retrieve the [LazyLoadIndexedStackThemeData] from the closest ancestor.
  static LazyLoadIndexedStackThemeData? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<LazyLoadIndexedStackTheme>()
        ?.data;
  }

  @override
  bool updateShouldNotify(LazyLoadIndexedStackTheme oldWidget) {
    return data != oldWidget.data;
  }
}

/// Holds the configuration properties for [LazyLoadIndexedStackTheme].
class LazyLoadIndexedStackThemeData {
  /// Default widget to be built when not loaded.
  final Widget unloadWidget;

  /// Default duration of transition animations.
  final Duration transitionDuration;

  /// Default animation curve.
  final Curve transitionCurve;

  /// Default duration to delay loading child widgets.
  final Duration? delayDuration;

  /// Default maximum active pages allowed in memory.
  final int? maxActivePages;

  /// Default duration an offstage page is allowed to remain idle.
  final Duration? idleTimeout;

  /// Creates configuration properties for [LazyLoadIndexedStackTheme].
  const LazyLoadIndexedStackThemeData({
    this.unloadWidget = const SizedBox.shrink(),
    this.transitionDuration = Duration.zero,
    this.transitionCurve = Curves.easeInOut,
    this.delayDuration,
    this.maxActivePages,
    this.idleTimeout,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LazyLoadIndexedStackThemeData &&
          runtimeType == other.runtimeType &&
          unloadWidget == other.unloadWidget &&
          transitionDuration == other.transitionDuration &&
          transitionCurve == other.transitionCurve &&
          delayDuration == other.delayDuration &&
          maxActivePages == other.maxActivePages &&
          idleTimeout == other.idleTimeout;

  @override
  int get hashCode =>
      unloadWidget.hashCode ^
      transitionDuration.hashCode ^
      transitionCurve.hashCode ^
      delayDuration.hashCode ^
      maxActivePages.hashCode ^
      idleTimeout.hashCode;
}

/// A controller to programmatically manage and query the loading states of a [LazyLoadIndexedStack].
class LazyLoadIndexedStackController extends ChangeNotifier {
  LazyLoadIndexedStackState? _state;

  void _attach(LazyLoadIndexedStackState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  /// Forces the child widget at [index] to be unloaded/disposed.
  /// Does not affect the currently active index.
  void disposeIndex(int index) {
    _state?._disposeIndex(index);
  }

  /// Forces the child widget at [index] to be preloaded.
  void preloadIndex(int index) {
    _state?._preloadIndex(index);
  }

  /// Check if the child widget at [index] is loaded.
  bool isLoaded(int index) {
    return _state?._isLoaded(index) ?? false;
  }

  /// Forces the child widget at [index] to be disposed and immediately re-loaded/rebuilt.
  void reloadIndex(int index) {
    _state?._reloadIndex(index);
  }

  /// Forces all offstage loaded child widgets to be disposed.
  void disposeAllExceptActive() {
    _state?._disposeAllExceptActive();
  }

  /// Preloads all children widgets.
  void loadAll() {
    _state?._loadAll();
  }
}

/// An extended IndexedStack that builds the required widget only when it is needed, and returns the pre-built widget when it is needed again.
class LazyLoadIndexedStack extends StatefulWidget {
  /// Widget to be built when not loaded. Default widget is [SizedBox.shrink].
  final Widget unloadWidget;

  /// A custom builder to return a placeholder widget for unloaded child at [index].
  /// Fallbacks to [unloadWidget] if not provided.
  final Widget Function(BuildContext context, int index)? unloadWidgetBuilder;

  /// The indexes of children that should be preloaded.
  final List<int> preloadIndexes;

  /// The indexes of children that should be automatically disposed and rebuilt when accessed again.
  final List<int> autoDisposeIndexes;

  /// Same as alignment attribute of original IndexedStack.
  final AlignmentGeometry alignment;

  /// Same as sizing attribute of original IndexedStack.
  final StackFit sizing;

  /// Same as textDirection attribute of original IndexedStack.
  final TextDirection? textDirection;

  /// The index of the child to show.
  final int index;

  /// The widgets below this widget in the tree.
  ///
  /// A child widget will not be built until the index associated with it is specified.
  /// When the index associated with the widget is specified again, the built widget is returned.
  final List<Widget> children;

  /// Called when a child at a specific index is loaded for the first time or re-loaded after being disposed.
  final ValueChanged<int>? onLoaded;

  /// Called when a child at a specific index is disposed/unloaded.
  final ValueChanged<int>? onDisposed;

  /// Called whenever the active index changes.
  final ValueChanged<int>? onIndexChanged;

  /// Controller to programmatically manage and query loading states.
  final LazyLoadIndexedStackController? controller;

  /// The duration of transition animations when switching active indexes.
  /// If set to [Duration.zero] (default), no transitions will be played.
  final Duration transitionDuration;

  /// Custom transition builder used when [transitionDuration] is greater than [Duration.zero].
  /// Defaults to a simple [FadeTransition] if not specified.
  final Widget Function(
          BuildContext context, Animation<double> animation, Widget child)?
      transitionBuilder;

  /// Custom directional transition builder. If provided, it overrides [transitionBuilder].
  /// Receives [index] of the child and [activeIndex] to allow directional animations.
  final Widget Function(
    BuildContext context,
    Animation<double> animation,
    Widget child,
    int index,
    int activeIndex,
  )? directionalTransitionBuilder;

  /// The animation curve used when transition animations are active.
  /// Defaults to [Curves.easeInOut].
  final Curve transitionCurve;

  /// Optional duration to delay loading the child widget when the active index changes (debounce).
  /// This prevents loading intermediate pages during fast switching/swiping.
  final Duration? delayDuration;

  /// The maximum number of active pages to keep in memory (LRU policy).
  /// If the number of loaded pages exceeds this limit, the least recently used offstage page will be disposed.
  final int? maxActivePages;

  /// The duration that an offstage page is allowed to remain idle before being automatically disposed.
  final Duration? idleTimeout;

  /// Callback before the active index changes.
  /// If it returns false (or resolves to false), the index change is rejected.
  final FutureOr<bool> Function(int fromIndex, int toIndex)? onBeforeIndexChanged;

  /// Called when a requested index change is rejected by [onBeforeIndexChanged].
  final ValueChanged<int>? onIndexChangeRejected;

  /// Whether to automatically preserve the state (e.g. scroll position) of offstage child widgets.
  /// Defaults to true.
  final bool preserveState;

  /// Called when a page finishes building/rendering for the first time or after reload, returning the duration taken to render.
  final void Function(int index, Duration duration)? onBuildDuration;

  /// Creates LazyLoadIndexedStack that wraps IndexedStack.
  const LazyLoadIndexedStack({
    super.key,
    this.unloadWidget = const SizedBox.shrink(),
    this.unloadWidgetBuilder,
    this.preloadIndexes = const [],
    this.autoDisposeIndexes = const [],
    this.alignment = AlignmentDirectional.topStart,
    this.sizing = StackFit.loose,
    this.textDirection,
    required this.index,
    required this.children,
    this.onLoaded,
    this.onDisposed,
    this.onIndexChanged,
    this.controller,
    this.transitionDuration = Duration.zero,
    this.transitionBuilder,
    this.directionalTransitionBuilder,
    this.transitionCurve = Curves.easeInOut,
    this.delayDuration,
    this.maxActivePages,
    this.idleTimeout,
    this.onBeforeIndexChanged,
    this.onIndexChangeRejected,
    this.preserveState = true,
    this.onBuildDuration,
  });

  @override
  LazyLoadIndexedStackState createState() => LazyLoadIndexedStackState();
}

class LazyLoadIndexedStackState extends State<LazyLoadIndexedStack> {
  late List<bool> _loaded;
  final _stackKey = GlobalKey();
  Timer? _debounceTimer;
  late int _activeIndex;

  // Track LRU history of page access
  final List<int> _lruList = [];

  // Track idle timers for offstage pages
  final Map<int, Timer> _idleTimers = {};

  // Holds theme config data from context
  LazyLoadIndexedStackThemeData? _themeData;

  // Resolved configuration properties falling back to Theme
  Widget get _effectiveUnloadWidget =>
      widget.unloadWidget != const SizedBox.shrink()
          ? widget.unloadWidget
          : (_themeData?.unloadWidget ?? const SizedBox.shrink());

  Duration get _effectiveTransitionDuration =>
      widget.transitionDuration != Duration.zero
          ? widget.transitionDuration
          : (_themeData?.transitionDuration ?? Duration.zero);

  Curve get _effectiveTransitionCurve =>
      widget.transitionCurve != Curves.easeInOut
          ? widget.transitionCurve
          : (_themeData?.transitionCurve ?? Curves.easeInOut);

  Duration? get _effectiveDelayDuration =>
      widget.delayDuration ?? _themeData?.delayDuration;

  int? get _effectiveMaxActivePages =>
      widget.maxActivePages ?? _themeData?.maxActivePages;

  Duration? get _effectiveIdleTimeout =>
      widget.idleTimeout ?? _themeData?.idleTimeout;

  void _assertValidIndices() {
    assert(widget.index >= 0 && widget.index < widget.children.length,
        'index must be within children bounds');
    for (final i in widget.preloadIndexes) {
      assert(i >= 0 && i < widget.children.length,
          'preloadIndexes contains an out-of-bounds index: $i');
    }
    for (final i in widget.autoDisposeIndexes) {
      assert(i >= 0 && i < widget.children.length,
          'autoDisposeIndexes contains an out-of-bounds index: $i');
    }
  }

  @override
  void initState() {
    super.initState();
    _assertValidIndices();
    widget.controller?._attach(this);
    _activeIndex = widget.index;

    _loaded = List.generate(widget.children.length, (index) {
      final isLoaded =
          index == _activeIndex || widget.preloadIndexes.contains(index);
      if (isLoaded) {
        _lruList.add(index);
        if (widget.onLoaded != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onLoaded?.call(index);
            }
          });
        }
      }
      return isLoaded;
    });

    if (widget.onIndexChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onIndexChanged?.call(_activeIndex);
        }
      });
    }

    final conflictingIndexes = widget.preloadIndexes
        .toSet()
        .intersection(widget.autoDisposeIndexes.toSet());
    if (conflictingIndexes.isNotEmpty) {
      debugPrint(
          '[LazyLoadIndexedStack] Warning: The same index is in both preloadIndexes and autoDisposeIndexes. '
          'It will be preloaded initially but disposed when not visible. Conflicting indexes: $conflictingIndexes');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newThemeData = LazyLoadIndexedStackTheme.of(context);
    if (_themeData != newThemeData) {
      _themeData = newThemeData;
      _applyMaxActivePagesLimit();
      _resetIdleTimers();
    }
  }

  @override
  void didUpdateWidget(final LazyLoadIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _assertValidIndices();

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }

    if (widget.children.length != oldWidget.children.length) {
      _lruList.clear();
      _loaded = List.generate(widget.children.length, (index) {
        final isLoaded =
            index == widget.index || widget.preloadIndexes.contains(index);
        if (isLoaded) {
          _lruList.add(index);
          if (widget.onLoaded != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                widget.onLoaded?.call(index);
              }
            });
          }
        }
        return isLoaded;
      });
      _activeIndex = widget.index;
      _applyMaxActivePagesLimit();
      _resetIdleTimers();
    } else {
      if (widget.index != oldWidget.index) {
        final oldIndex = _activeIndex;
        final newIndex = widget.index;

        if (widget.onBeforeIndexChanged != null) {
          final result = widget.onBeforeIndexChanged!(oldIndex, newIndex);
          if (result is Future<bool>) {
            result.then((allowed) {
              if (mounted) {
                if (allowed) {
                  _changeActiveIndex(newIndex);
                } else {
                  widget.onIndexChangeRejected?.call(newIndex);
                }
              }
            });
          } else {
            if (result) {
              _changeActiveIndex(newIndex);
            } else {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  widget.onIndexChangeRejected?.call(newIndex);
                }
              });
            }
          }
        } else {
          _changeActiveIndex(newIndex);
        }
      }
    }
  }

  void _changeActiveIndex(int nextIndex) {
    _activeIndex = nextIndex;
    final delay = _effectiveDelayDuration;
    if (delay != null && delay > Duration.zero) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(delay, () {
        if (mounted) {
          setState(() {
            _loadAndDisposeForIndex(_activeIndex);
          });
        }
      });
    } else {
      setState(() {
        _loadAndDisposeForIndex(_activeIndex);
      });
    }
    widget.onIndexChanged?.call(nextIndex);
  }

  void _loadAndDisposeForIndex(int activeIndex) {
    // Auto-dispose offstage children if needed
    for (final index in widget.autoDisposeIndexes) {
      if (index != activeIndex && _loaded[index]) {
        _loaded[index] = false;
        widget.onDisposed?.call(index);
      }
    }

    // Check if current index is newly loaded
    if (!_loaded[activeIndex]) {
      _loaded[activeIndex] = true;
      widget.onLoaded?.call(activeIndex);
    }

    _updateLru(activeIndex);
    _resetIdleTimers();
  }

  void _updateLru(int index) {
    _lruList.remove(index);
    _lruList.add(index);
    _applyMaxActivePagesLimit();
  }

  void _applyMaxActivePagesLimit() {
    final maxActive = _effectiveMaxActivePages;
    if (maxActive == null) return;

    int loadedCount = _loaded.where((loaded) => loaded).length;
    if (loadedCount > maxActive) {
      for (final index in _lruList) {
        if (index != _activeIndex && _loaded[index]) {
          _loaded[index] = false;
          widget.onDisposed?.call(index);
          break; // Dispose one at a time to stay under limit
        }
      }
    }
  }

  void _resetIdleTimers() {
    final timeout = _effectiveIdleTimeout;
    if (timeout == null) {
      // Cancel all existing timers if setting was removed
      for (final timer in _idleTimers.values) {
        timer.cancel();
      }
      _idleTimers.clear();
      return;
    }

    // Cancel timer for active index
    _idleTimers[_activeIndex]?.cancel();
    _idleTimers.remove(_activeIndex);

    // Start timers for all other loaded pages if not already running
    for (int i = 0; i < _loaded.length; i++) {
      if (i != _activeIndex && _loaded[i]) {
        if (!_idleTimers.containsKey(i)) {
          _idleTimers[i] = Timer(timeout, () {
            if (mounted) {
              setState(() {
                _loaded[i] = false;
              });
              widget.onDisposed?.call(i);
              _idleTimers.remove(i);
            }
          });
        }
      } else {
        _idleTimers[i]?.cancel();
        _idleTimers.remove(i);
      }
    }
  }

  void _disposeIndex(int index) {
    if (index >= 0 &&
        index < _loaded.length &&
        index != _activeIndex &&
        _loaded[index]) {
      setState(() {
        _loaded[index] = false;
      });
      _idleTimers[index]?.cancel();
      _idleTimers.remove(index);
      widget.onDisposed?.call(index);
    }
  }

  void _preloadIndex(int index) {
    if (index >= 0 && index < _loaded.length && !_loaded[index]) {
      setState(() {
        _loaded[index] = true;
      });
      widget.onLoaded?.call(index);
      _updateLru(index);
      _resetIdleTimers();
    }
  }

  bool _isLoaded(int index) {
    if (index >= 0 && index < _loaded.length) {
      return _loaded[index];
    }
    return false;
  }

  void _reloadIndex(int index) {
    if (index >= 0 && index < _loaded.length) {
      final wasLoaded = _loaded[index];
      setState(() {
        _loaded[index] = false;
      });
      if (wasLoaded) {
        widget.onDisposed?.call(index);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _loaded[index] = true;
          });
          widget.onLoaded?.call(index);
          _updateLru(index);
          _resetIdleTimers();
        }
      });
    }
  }

  void _disposeAllExceptActive() {
    setState(() {
      for (int i = 0; i < _loaded.length; i++) {
        if (i != _activeIndex && _loaded[i]) {
          _loaded[i] = false;
          _idleTimers[i]?.cancel();
          _idleTimers.remove(i);
          widget.onDisposed?.call(i);
        }
      }
    });
  }

  void _loadAll() {
    setState(() {
      for (int i = 0; i < _loaded.length; i++) {
        if (!_loaded[i]) {
          _loaded[i] = true;
          widget.onLoaded?.call(i);
          _updateLru(i);
        }
      }
      _resetIdleTimers();
    });
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _debounceTimer?.cancel();
    for (final timer in _idleTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    // Make sure the active index is loaded
    if (!_loaded[_activeIndex]) {
      final delay = _effectiveDelayDuration;
      if (delay == null ||
          delay == Duration.zero ||
          _debounceTimer == null ||
          !_debounceTimer!.isActive) {
        _loaded[_activeIndex] = true;
        _updateLru(_activeIndex);
        _resetIdleTimers();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onLoaded?.call(_activeIndex);
          }
        });
      }
    }

    final childrenWidgets = List.generate(widget.children.length, (index) {
      final isLoaded = _loaded[index];
      Widget child = isLoaded
          ? widget.children[index]
          : (widget.unloadWidgetBuilder?.call(context, index) ??
              _effectiveUnloadWidget);

      if (isLoaded) {
        if (widget.preserveState) {
          final childKey =
              widget.children[index].key ?? PageStorageKey<int>(index);
          child = KeyedSubtree(
            key: childKey,
            child: child,
          );
        }

        if (widget.onBuildDuration != null) {
          child = _MeasureBuildTimeWidget(
            index: index,
            onBuildDuration: widget.onBuildDuration!,
            child: child,
          );
        }
      }

      final duration = _effectiveTransitionDuration;
      final curve = _effectiveTransitionCurve;

      if (duration > Duration.zero) {
        return _TransitionWidget(
          isActive: index == _activeIndex,
          duration: duration,
          curve: curve,
          transitionBuilder: widget.transitionBuilder,
          directionalTransitionBuilder: widget.directionalTransitionBuilder,
          index: index,
          activeIndex: _activeIndex,
          child: child,
        );
      } else {
        return Offstage(
          offstage: index != _activeIndex,
          child: TickerMode(
            enabled: index == _activeIndex,
            child: child,
          ),
        );
      }
    });

    final duration = _effectiveTransitionDuration;

    if (duration > Duration.zero) {
      return Stack(
        key: _stackKey,
        alignment: widget.alignment,
        fit: widget.sizing,
        textDirection: widget.textDirection,
        children: childrenWidgets,
      );
    }

    return IndexedStack(
      key: _stackKey,
      index: _activeIndex,
      alignment: widget.alignment,
      textDirection: widget.textDirection,
      sizing: widget.sizing,
      children: childrenWidgets,
    );
  }
}

class _TransitionWidget extends StatefulWidget {
  final bool isActive;
  final Duration duration;
  final Curve curve;
  final Widget Function(
          BuildContext context, Animation<double> animation, Widget child)?
      transitionBuilder;
  final Widget Function(
    BuildContext context,
    Animation<double> animation,
    Widget child,
    int index,
    int activeIndex,
  )? directionalTransitionBuilder;
  final int index;
  final int activeIndex;
  final Widget child;

  const _TransitionWidget({
    required this.isActive,
    required this.duration,
    required this.curve,
    required this.transitionBuilder,
    required this.directionalTransitionBuilder,
    required this.index,
    required this.activeIndex,
    required this.child,
  });

  @override
  _TransitionWidgetState createState() => _TransitionWidgetState();
}

class _TransitionWidgetState extends State<_TransitionWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _isOffstage = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _isOffstage = !widget.isActive;
    if (widget.isActive) {
      _controller.value = 1.0;
    }

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() {
          _isOffstage = true;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant _TransitionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        setState(() {
          _isOffstage = false;
        });
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget animatedChild;
    if (widget.directionalTransitionBuilder != null) {
      animatedChild = widget.directionalTransitionBuilder!(
        context,
        _animation,
        widget.child,
        widget.index,
        widget.activeIndex,
      );
    } else if (widget.transitionBuilder != null) {
      animatedChild =
          widget.transitionBuilder!(context, _animation, widget.child);
    } else {
      animatedChild = FadeTransition(
        opacity: _animation,
        child: widget.child,
      );
    }

    return Offstage(
      offstage: _isOffstage,
      child: TickerMode(
        enabled: !_isOffstage,
        child: animatedChild,
      ),
    );
  }
}

class _MeasureBuildTimeWidget extends StatefulWidget {
  final Widget child;
  final int index;
  final void Function(int index, Duration duration) onBuildDuration;

  const _MeasureBuildTimeWidget({
    required this.child,
    required this.index,
    required this.onBuildDuration,
  });

  @override
  State<_MeasureBuildTimeWidget> createState() =>
      _MeasureBuildTimeWidgetState();
}

class _MeasureBuildTimeWidgetState extends State<_MeasureBuildTimeWidget> {
  late final Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stopwatch.stop();
      widget.onBuildDuration(widget.index, _stopwatch.elapsed);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
