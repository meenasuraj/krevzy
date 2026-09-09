import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';

class ReelEditorScreen extends StatefulWidget {
  const ReelEditorScreen({super.key});

  @override
  State<ReelEditorScreen> createState() => _ReelEditorScreenState();
}

class _ReelEditorScreenState extends State<ReelEditorScreen> {
  double _playbackSpeed = 1.0;
  String _selectedFilter = 'Normal';
  String _selectedMusic = 'Trending Tech Beat - 0:15';
  bool _isAdTagEnabled = true;

  final List<String> _filters = ['Normal', 'Cinematic', 'Vibrant', 'Monochrome', 'Cyberpunk'];

  @override
  Widget build(BuildContext context) {
    final themeNotifier = AppThemeNotifier.instance;

    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF181818) : Colors.grey[100],
          appBar: AppBar(
            title: const Text('Reel Editor Suite', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: themeNotifier.primaryColor,
            foregroundColor: Colors.white,
            actions: [
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reel successfully published with In-Reel Ad tag! 🚀')),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Publish', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Video Preview Mock Container
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_circle_fill, size: 64, color: Colors.white70),
                          const SizedBox(height: 8),
                          Text(
                            'Filter: $_selectedFilter • Speed: ${_playbackSpeed}x',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          const Icon(Icons.music_note, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _selectedMusic,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // SECTION: Music Selector
              const Text('Audio Track', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMusic,
                    isExpanded: true,
                    dropdownColor: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
                    items: [
                      'Trending Tech Beat - 0:15',
                      'Ambient Security Setup - 0:30',
                      'Upbeat Electronic Loop - 0:20',
                    ].map((String music) {
                      return DropdownMenuItem<String>(
                        value: music,
                        child: Text(music, style: TextStyle(color: themeNotifier.isDarkMode ? Colors.white : Colors.black87)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) setState(() => _selectedMusic = newValue);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // SECTION: Visual Filters
              const Text('Visual Filters & Color Grade', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        selectedColor: themeNotifier.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (themeNotifier.isDarkMode ? Colors.white70 : Colors.black87),
                          fontWeight: FontWeight.bold,
                        ),
                        backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
                        onSelected: (_) => setState(() => _selectedFilter = filter),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // SECTION: Playback Speed Slider
              const Text('Playback Speed', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('0.5x', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: _playbackSpeed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 3,
                      activeColor: themeNotifier.primaryColor,
                      label: '${_playbackSpeed}x',
                      onChanged: (value) => setState(() => _playbackSpeed = value),
                    ),
                  ),
                  const Text('2.0x', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),

              // SECTION: In-Reel Ad Tag Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Attach In-Reel Ad / Product Tag', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Allow viewers to purchase or inquire about featured items directly', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAdTagEnabled,
                      activeThumbColor: themeNotifier.primaryColor,
                      onChanged: (value) => setState(() => _isAdTagEnabled = value),
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