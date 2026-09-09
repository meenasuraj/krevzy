import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';
import 'creator_studio_hub_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            title: const Text('Suraj Meena', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: themeNotifier.primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
                tooltip: 'Settings',
              ),
            ],
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header Row (Avatar & Stats)
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.person, size: 50, color: Colors.white),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: const [
                                  _ProfileStatItem(count: '48', label: 'Posts'),
                                  _ProfileStatItem(count: '1.4k', label: 'Followers'),
                                  _ProfileStatItem(count: '320', label: 'Following'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Bio Info
                        const Text(
                          'Suraj Meena',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vidisha, Madhya Pradesh • Tech & Security Solutions 🔒',
                          style: TextStyle(color: themeNotifier.isDarkMode ? Colors.white70 : Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 16),

                        // Action Buttons (Edit Profile & Share Profile)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  side: BorderSide(color: Colors.grey.shade400),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit Profile tapped')));
                                },
                                child: Text('Edit Profile', style: TextStyle(color: themeNotifier.isDarkMode ? Colors.white : Colors.black87)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  side: BorderSide(color: Colors.grey.shade400),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share Profile link copied!')));
                                },
                                child: Text('Share Profile', style: TextStyle(color: themeNotifier.isDarkMode ? Colors.white : Colors.black87)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Creator Studio Hub Quick Access Banner (Live, Story, Reels, Ads)
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CreatorStudioHubScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [themeNotifier.primaryColor, themeNotifier.primaryColor.withValues(alpha: 0.7)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.video_collection, color: Colors.white, size: 28),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Creator Studio & Monetization', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text('Go Live, Stories, Edit Reels & In-Reel Ads', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Profile Content Tabs (Grid Posts, Reels, Tagged)
                        TabBar(
                          controller: _tabController,
                          labelColor: themeNotifier.primaryColor,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: themeNotifier.primaryColor,
                          tabs: const [
                            Tab(icon: Icon(Icons.grid_on), text: 'Posts'),
                            Tab(icon: Icon(Icons.movie_creation), text: 'Reels'),
                            Tab(icon: Icon(Icons.bookmark_border), text: 'Saved'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _ProfileGridContent(icon: Icons.grid_on, label: 'Posts Grid'),
                _ProfileGridContent(icon: Icons.movie, label: 'Reels Library'),
                _ProfileGridContent(icon: Icons.bookmark, label: 'Saved Bookmarks'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileStatItem extends StatelessWidget {
  final String count;
  final String label;
  const _ProfileStatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _ProfileGridContent extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ProfileGridContent({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeNotifier.instance.isDarkMode;
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return Container(
          color: isDark ? const Color(0xFF242424) : Colors.grey[300],
          child: Center(
            child: Icon(icon, color: isDark ? Colors.white30 : Colors.grey[600], size: 28),
          ),
        );
      },
    );
  }
}