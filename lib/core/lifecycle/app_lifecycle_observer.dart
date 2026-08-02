import 'package:flutter/widgets.dart';

/// Keeps application lifecycle handling explicit and testable.
///
/// Pages with expensive resources can subscribe to this widget instead of
/// mixing lifecycle concerns into unrelated presentation code.
class AppLifecycleObserver extends StatefulWidget {
  const AppLifecycleObserver({
    super.key,
    required this.child,
    this.onResumed,
    this.onPaused,
  });

  final Widget child;
  final VoidCallback? onResumed;
  final VoidCallback? onPaused;

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        widget.onResumed?.call();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        widget.onPaused?.call();
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
