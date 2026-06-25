import 'dart:async';
import 'package:flutter/widgets.dart';

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
}

/// An extended IndexedStack that builds the required widget only when it is needed, and returns the pre-built widget when it is needed again.
class LazyLoadIndexedStack extends StatefulWidget {
  /// Widget to be built when not loaded. Default widget is [SizedBox.shrink].
  final Widget unloadWidget;

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

  /// The animation curve used when transition animations are active.
  /// Defaults to [Curves.easeInOut].
  final Curve transitionCurve;

  /// Optional duration to delay loading the child widget when the active index changes (debounce).
  /// This prevents loading intermediate pages during fast switching/swiping.
  final Duration? delayDuration;

  /// Creates LazyLoadIndexedStack that wraps IndexedStack.
  const LazyLoadIndexedStack({
    super.key,
    this.unloadWidget = const SizedBox.shrink(),
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
    this.transitionCurve = Curves.easeInOut,
    this.delayDuration,
  });

  @override
  LazyLoadIndexedStackState createState() => LazyLoadIndexedStackState();
}

class LazyLoadIndexedStackState extends State<LazyLoadIndexedStack> {
  late List<bool> _loaded;
  final _stackKey = GlobalKey();
  Timer? _debounceTimer;
  late int _activeIndex;

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
      if (isLoaded && widget.onLoaded != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onLoaded?.call(index);
          }
        });
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
  void didUpdateWidget(final LazyLoadIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _assertValidIndices();

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }

    if (widget.children.length != oldWidget.children.length) {
      _loaded = List.generate(widget.children.length, (index) {
        final isLoaded =
            index == widget.index || widget.preloadIndexes.contains(index);
        if (isLoaded && widget.onLoaded != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onLoaded?.call(index);
            }
          });
        }
        return isLoaded;
      });
      _activeIndex = widget.index;
    } else {
      if (widget.index != oldWidget.index) {
        _activeIndex = widget.index;
        if (widget.delayDuration != null &&
            widget.delayDuration! > Duration.zero) {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(widget.delayDuration!, () {
            if (mounted) {
              setState(() {
                _loadAndDisposeForIndex(_activeIndex);
              });
            }
          });
        } else {
          _loadAndDisposeForIndex(_activeIndex);
        }
      }
    }

    if (widget.index != oldWidget.index) {
      widget.onIndexChanged?.call(widget.index);
    }
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
  }

  void _disposeIndex(int index) {
    if (index >= 0 &&
        index < _loaded.length &&
        index != _activeIndex &&
        _loaded[index]) {
      setState(() {
        _loaded[index] = false;
      });
      widget.onDisposed?.call(index);
    }
  }

  void _preloadIndex(int index) {
    if (index >= 0 && index < _loaded.length && !_loaded[index]) {
      setState(() {
        _loaded[index] = true;
      });
      widget.onLoaded?.call(index);
    }
  }

  bool _isLoaded(int index) {
    if (index >= 0 && index < _loaded.length) {
      return _loaded[index];
    }
    return false;
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    // Make sure the active index is loaded
    if (!_loaded[_activeIndex]) {
      if (widget.delayDuration == null ||
          widget.delayDuration == Duration.zero ||
          _debounceTimer == null ||
          !_debounceTimer!.isActive) {
        _loaded[_activeIndex] = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onLoaded?.call(_activeIndex);
          }
        });
      }
    }

    final childrenWidgets = List.generate(widget.children.length, (index) {
      final isLoaded = _loaded[index];
      final child = isLoaded ? widget.children[index] : widget.unloadWidget;

      if (widget.transitionDuration > Duration.zero) {
        return _TransitionWidget(
          isActive: index == _activeIndex,
          duration: widget.transitionDuration,
          curve: widget.transitionCurve,
          transitionBuilder: widget.transitionBuilder,
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

    if (widget.transitionDuration > Duration.zero) {
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
  final Widget child;

  const _TransitionWidget({
    required this.isActive,
    required this.duration,
    required this.curve,
    required this.transitionBuilder,
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
    if (widget.transitionBuilder != null) {
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
