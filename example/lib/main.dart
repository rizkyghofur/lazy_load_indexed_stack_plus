import 'package:flutter/material.dart';
import 'package:lazy_load_indexed_stack/lazy_load_indexed_stack.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(final BuildContext context) {
    // Set up global configuration for LazyLoadIndexedStack in our application
    return const LazyLoadIndexedStackTheme(
      data: LazyLoadIndexedStackThemeData(
        unloadWidget: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading from global theme default...'),
            ],
          ),
        ),
        transitionDuration: Duration(milliseconds: 300),
        maxActivePages: 2, // Default LRU limit of 2 loaded pages
        idleTimeout: Duration(seconds: 15), // Auto-dispose offstage page if idle for 15s
      ),
      child: MaterialApp(home: MainPage()),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<StatefulWidget> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;
  final _controller = LazyLoadIndexedStackController();

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lazy Load Indexed Stack Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Current Page',
            onPressed: () => _controller.reloadIndex(_index),
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Dispose Offstage Pages',
            onPressed: () => _controller.disposeAllExceptActive(),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Load All Pages',
            onPressed: () => _controller.loadAll(),
          ),
        ],
      ),
      body: LazyLoadIndexedStack(
        index: _index,
        controller: _controller,
        // Optional override: we let it inherit the settings from the global theme defined in MainApp
        onBeforeIndexChanged: (fromIndex, toIndex) {
          debugPrint('Guard: Trying to change index from $fromIndex to $toIndex');
          return true;
        },
        onIndexChangeRejected: (rejectedIndex) {
          debugPrint('Guard rejected: $rejectedIndex');
        },
        onBuildDuration: (index, duration) {
          debugPrint('Performance: Page $index built/rendered in ${duration.inMilliseconds}ms');
        },
        directionalTransitionBuilder: (context, animation, child, index, activeIndex) {
          // Slide from right to left if target index is larger, slide left to right otherwise
          final isIncoming = index == activeIndex;
          final begin = isIncoming ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
          final tween = Tween(begin: begin, end: Offset.zero).chain(
            CurveTween(curve: Curves.easeInOut),
          );
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        onLoaded: (index) => debugPrint('Page $index loaded'),
        onDisposed: (index) => debugPrint('Page $index disposed'),
        onIndexChanged: (index) => debugPrint('Index changed to $index'),
        children: const [
          Page1(),
          Page2(),
          Page3(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          setState(() => _index = index);
        },
        currentIndex: _index,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.email),
            label: 'Page 1',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: 'Page 2',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Page 3',
          ),
        ],
      ),
    );
  }
}

class Page1 extends StatelessWidget {
  const Page1({super.key});

  @override
  Widget build(final BuildContext context) {
    return const Center(
      child: Text('This is Page 1 (Loaded and Active)'),
    );
  }
}

class Page2 extends StatelessWidget {
  const Page2({super.key});

  @override
  Widget build(final BuildContext context) {
    return const Center(
      child: Text('This is Page 2 (Loaded and Active)'),
    );
  }
}

class Page3 extends StatelessWidget {
  const Page3({super.key});

  @override
  Widget build(final BuildContext context) {
    return const Center(
      child: Text('This is Page 3 (Loaded and Active)'),
    );
  }
}
