import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  final List<Map<String, String>> _trendingTags = [
    {'tag': '#CCTVInstall', 'posts': '14.2K posts'},
    {'tag': '#NightVision', 'posts': '9.8K posts'},
    {'tag': '#SmartHomeSecurity', 'posts': '24.5K posts'},
    {'tag': '#NVRSetup', 'posts': '5.1K posts'},
    {'tag': '#VidishaSecurity', 'posts': '1.2K posts'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = AppThemeNotifier.instance;

    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF181818) : Colors.grey[100],
          appBar: AppBar(
            backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF222222) : Colors.white,
            elevation: 0.5,
            title: TextField(
              controller: _searchController,
              style: TextStyle(color: themeNotifier.isDarkMode ? Colors.white : Colors.black87, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search creators, hardware, tags...',
                hintStyle: TextStyle(color: themeNotifier.isDarkMode ? Colors.white54 : Colors.grey),
                prefixIcon: Icon(Icons.search, color: themeNotifier.isDarkMode ? Colors.white54 : Colors.grey),
                filled: true,
                fillColor: themeNotifier.isDarkMode ? const Color(0xFF151515) : Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Trending Topics',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: themeNotifier.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _trendingTags.length,
                itemBuilder: (context, index) {
                  final item = _trendingTags[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: themeNotifier.isDarkMode ? const Color(0xFF222222) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: themeNotifier.primaryColor.withValues(alpha: 0.2),
                        child: Icon(Icons.trending_up, color: themeNotifier.primaryColor, size: 20),
                      ),
                      title: Text(
                        item['tag']!,
                        style: TextStyle(fontWeight: FontWeight.bold, color: themeNotifier.isDarkMode ? Colors.white : Colors.black87),
                      ),
                      subtitle: Text(item['posts']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: themeNotifier.isDarkMode ? Colors.white38 : Colors.grey),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Exploring ${item['tag']}...')),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}