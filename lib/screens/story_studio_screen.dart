import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';

class StoryStudioScreen extends StatefulWidget {
  const StoryStudioScreen({super.key});

  @override
  State<StoryStudioScreen> createState() => _StoryStudioScreenState();
}

class _StoryStudioScreenState extends State<StoryStudioScreen> {
  final TextEditingController _captionController = TextEditingController();
  Color _selectedBgColor = const Color(0xFF2C3E50);
  bool _hasPollSticker = false;
  final String _pollQuestion = 'Are you upgrading your security system?';

  final List<Color> _bgColors = [
    const Color(0xFF2C3E50),
    const Color(0xFF8E44AD),
    const Color(0xFFC0392B),
    const Color(0xFFD35400),
    const Color(0xFF16A085),
    const Color(0xFF27AE60),
  ];

  @override
  Widget build(BuildContext context) {
    final themeNotifier = AppThemeNotifier.instance;

    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Story Creation Studio', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Story published successfully for 24 hours! 📸')),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Share Story', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          body: Column(
            children: [
              // Interactive Story Canvas Preview
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedBgColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Center Camera / Media Placeholder text
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt, size: 64, color: Colors.white54),
                            const SizedBox(height: 12),
                            const Text(
                              'Tap to capture or upload photo/video',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                      // Optional Poll Sticker Overlay
                      if (_hasPollSticker)
                        Positioned(
                          top: 100,
                          left: 24,
                          right: 24,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.poll, color: Colors.blue, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _pollQuestion,
                                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                  child: const Text('👍 Yes, definitely', style: TextStyle(color: Colors.black87, fontSize: 12)),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                  child: const Text('👎 Not right now', style: TextStyle(color: Colors.black87, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Bottom Caption Preview overlay if text entered
                      Positioned(
                        bottom: 24,
                        left: 24,
                        right: 24,
                        child: TextField(
                          controller: _captionController,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            hintText: 'Add a caption or link...',
                            hintStyle: TextStyle(color: Colors.white60),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Customization Controls Toolbar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Background Color Palette', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _bgColors.length,
                        itemBuilder: (context, index) {
                          final color = _bgColors[index];
                          return GestureDetector(
                            onTap: () => setState(() => _selectedBgColor = color),
                            child: Container(
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedBgColor == color ? Colors.white : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasPollSticker ? Colors.red.shade100 : Colors.blue.shade100,
                            foregroundColor: _hasPollSticker ? Colors.red.shade800 : Colors.blue.shade800,
                          ),
                          onPressed: () => setState(() => _hasPollSticker = !_hasPollSticker),
                          icon: Icon(_hasPollSticker ? Icons.remove_circle_outline : Icons.poll),
                          label: Text(_hasPollSticker ? 'Remove Poll' : 'Add Poll Sticker'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location & Product tag picker opened!')));
                          },
                          icon: const Icon(Icons.location_on, size: 16),
                          label: const Text('Add Location'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}