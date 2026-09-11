import 'package:flutter/widgets.dart';
import '../services/session_service.dart';

class SessionLifecycle extends StatefulWidget {
  final Widget child;
  const SessionLifecycle({super.key, required this.child});
  @override State<SessionLifecycle> createState() => _SessionLifecycleState();
}

class _SessionLifecycleState extends State<SessionLifecycle> with WidgetsBindingObserver {
  @override void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); SessionService.ensureSession(); }
  @override void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) { SessionService.setBackground(false); }
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) { SessionService.setBackground(true); }
  }
  @override Widget build(BuildContext context) => widget.child;
}
