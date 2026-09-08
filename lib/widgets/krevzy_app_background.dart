import 'package:flutter/material.dart';

import '../services/krevzy_background_service.dart';
import 'krevzy_background.dart';

/// App-wide background host.
///
/// The KREVZY poster-inspired background is the default. A user-selected
/// gallery/camera background is persisted by [KrevzyBackgroundService] and
/// automatically appears across the app when changed.
class KrevzyAppBackgroundHost extends StatefulWidget {
  final Widget child;

  const KrevzyAppBackgroundHost({
    super.key,
    required this.child,
  });

  @override
  State<KrevzyAppBackgroundHost> createState() => _KrevzyAppBackgroundHostState();
}

class _KrevzyAppBackgroundHostState extends State<KrevzyAppBackgroundHost> {
  String? _photoUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    KrevzyBackgroundService.backgroundChanged.addListener(_reload);
    _reload();
  }

  Future<void> _reload() async {
    final type = await KrevzyBackgroundService.getAppBackgroundType();
    final url = type == 'photo'
        ? await KrevzyBackgroundService.getAppBackgroundUrl()
        : null;

    if (!mounted) return;
    setState(() {
      _photoUrl = url;
      _loading = false;
    });
  }

  @override
  void dispose() {
    KrevzyBackgroundService.backgroundChanged.removeListener(_reload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const KrevzyBackground(child: SizedBox.shrink()),
          widget.child,
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        KrevzyBackground(
          photoUrl: _photoUrl,
          overlayOpacity: _photoUrl == null ? .02 : .10,
          child: const SizedBox.shrink(),
        ),
        widget.child,
      ],
    );
  }
}
