import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/krevzy_background_service.dart';
import '../widgets/krevzy_background.dart';

class CustomizationScreen extends StatefulWidget {
  const CustomizationScreen({super.key});

  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen> {
  String _appType = 'krevzy';
  String? _appPhoto;
  String? _keyboardPhoto;
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final type = await KrevzyBackgroundService.getAppBackgroundType();
    final photo = await KrevzyBackgroundService.getAppBackgroundUrl();
    final keyboard = await KrevzyBackgroundService.getKeyboardBackgroundUrl();
    if (!mounted) return;
    setState(() {
      _appType = type;
      _appPhoto = photo;
      _keyboardPhoto = keyboard;
      _loading = false;
    });
  }

  Future<void> _pickApp(ImageSource source) async {
    setState(() => _uploading = true);
    try {
      final url = await KrevzyBackgroundService.pickAndUploadAppBackground(source: source);
      if (!mounted) return;
      if (url != null) setState(() { _appType = 'photo'; _appPhoto = url; });
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickKeyboard() async {
    setState(() => _uploading = true);
    try {
      final url = await KrevzyBackgroundService.pickAndUploadKeyboardBackground();
      if (!mounted) return;
      if (url != null) setState(() => _keyboardPhoto = url);
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _error(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Background upload failed: $e')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('KREVZY Appearance')),
      body: Stack(
        children: [
          const Positioned.fill(child: _PreviewBackground()),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const Text('Make KREVZY feel like yours', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Use the KREVZY pastel identity or your own photo.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 22),
              _section('App background'),
              _tile(Icons.auto_awesome, 'KREVZY default', 'Pink • lavender • sky gradient', _appType == 'krevzy', () async { await KrevzyBackgroundService.setAppPreset('krevzy'); setState(() { _appType = 'krevzy'; _appPhoto = null; }); }),
              _tile(Icons.photo_library_outlined, 'Use my photo', _appPhoto == null ? 'Choose a photo from your gallery' : 'Your custom photo is active', _appType == 'photo', () => _pickApp(ImageSource.gallery)),
              _tile(Icons.camera_alt_outlined, 'Take a photo', 'Use your camera as the app background', false, () => _pickApp(ImageSource.camera)),
              if (_appPhoto != null) _preview(_appPhoto!),
              const SizedBox(height: 24),
              _section('KREVZY chat'),
              _tile(Icons.chat_bubble_outline, 'Per-chat background', 'Each conversation can have its own background. Open a chat and choose Chat Theme.', false, null),
              const SizedBox(height: 24),
              _section('KREVZY composer / keyboard area'),
              _tile(Icons.keyboard_alt_outlined, 'My keyboard background', _keyboardPhoto == null ? 'Customizes the KREVZY message composer area' : 'Your custom composer background is active', _keyboardPhoto != null, _pickKeyboard),
              if (_keyboardPhoto != null) _preview(_keyboardPhoto!),
              const SizedBox(height: 16),
              const Text('Note: KREVZY can customize its own composer UI; it cannot change the system Gboard keyboard.', style: TextStyle(fontSize: 12)),
            ],
          ),
          if (_uploading) const Positioned.fill(child: ColoredBox(color: Color(0x66000000), child: Center(child: CircularProgressIndicator()))),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: Theme.of(context).colorScheme.primary)));

  Widget _tile(IconData icon, String title, String subtitle, bool selected, VoidCallback? onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white.withValues(alpha: .76),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: selected ? const Icon(Icons.check_circle_rounded) : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _preview(String url) => Padding(padding: const EdgeInsets.only(top: 4), child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(url, height: 150, width: double.infinity, fit: BoxFit.cover)));
}

class _PreviewBackground extends StatelessWidget {
  const _PreviewBackground();
  @override
  Widget build(BuildContext context) => const KrevzyBackground(child: SizedBox.shrink());
}
