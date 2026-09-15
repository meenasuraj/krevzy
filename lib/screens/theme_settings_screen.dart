import 'package:flutter/material.dart';

import '../utils/app_theme_data.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Krevzy Blue', 'color': Colors.blue},
    {'name': 'Emerald Green', 'color': Colors.teal},
    {'name': 'Royal Purple', 'color': Colors.deepPurple},
    {'name': 'Sunset Orange', 'color': Colors.deepOrange},
    {'name': 'Midnight Indigo', 'color': Colors.indigo},
  ];

  final List<Map<String, dynamic>> _chatBgOptions = [
    {'name': 'Classic Light', 'color': Colors.grey.shade100},
    {'name': 'Soft Blue Tint', 'color': Colors.blue.shade50},
    {'name': 'Warm Amber', 'color': Colors.amber.shade50},
    {'name': 'Mint Green', 'color': Colors.green.shade50},
    {'name': 'Deep Dark Mode', 'color': const Color(0xFF121212)},
  ];

  @override
  Widget build(BuildContext context) {
    final themeNotifier = AppThemeNotifier.instance;

    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: themeNotifier.isDarkMode
              ? const Color(0xFF181818)
              : Colors.grey[100],
          appBar: AppBar(
            title: const Text(
              'Theme & Appearance',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: themeNotifier.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dark Mode Toggle Card
                Card(
                  elevation: 0,
                  color: themeNotifier.isDarkMode
                      ? const Color(0xFF242424)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SwitchListTile(
                    secondary: Icon(
                      Icons.dark_mode,
                      color: themeNotifier.primaryColor,
                    ),
                    title: Text(
                      'Dark Theme',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: themeNotifier.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      'Switch entire app to dark layout',
                      style: TextStyle(
                        fontSize: 11,
                        color: themeNotifier.isDarkMode
                            ? Colors.white70
                            : Colors.grey,
                      ),
                    ),
                    value: themeNotifier.isDarkMode,
                    onChanged: (val) {
                      themeNotifier.toggleDarkMode(val);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // App Primary Theme Colors
                const Text(
                  'App Primary Accent Color',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _colorOptions.map((item) {
                    final Color color = item['color'];
                    final bool isSelected = themeNotifier.primaryColor == color;

                    return GestureDetector(
                      onTap: () => themeNotifier.setPrimaryColor(color),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            if (isSelected) const SizedBox(width: 6),
                            Text(
                              item['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // Chat Background Customization
                const Text(
                  'Chat Background Style',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  itemCount: _chatBgOptions.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final bg = _chatBgOptions[index];
                    final Color color = bg['color'];
                    final bool isSelected =
                        themeNotifier.chatBackgroundColor == color;

                    return GestureDetector(
                      onTap: () => themeNotifier.setChatBackground(color),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? themeNotifier.primaryColor
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              bg['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: color == const Color(0xFF121212)
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: themeNotifier.primaryColor,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
