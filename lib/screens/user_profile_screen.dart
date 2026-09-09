import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';
import '../utils/profile_share_helper.dart';
import 'edit_profile_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Local profile state variables
  String _profileName = 'Suraj Meena';
  String _handle = 'vidishasecurity';
  String _bio = '🛡️ CCTV & Security Hardware Creator\n📍 Vidisha, Madhya Pradesh\n⚡ Professional Installation & Night Vision Guides';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
            backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF222222) : Colors.white,
            elevation: 0,
            title: Text(
              _handle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: themeNotifier.isDarkMode ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            actions: [
              // Share Profile Button
              IconButton(
                icon: Icon(Icons.share, color: themeNotifier.isDarkMode ? Colors.white : Colors.black87),
                onPressed: () {
                  ProfileShareHelper.showShareProfileOptions(
                    context,
                    profileName: _profileName,
                    handle: _handle,
                  );
                },
              ),
              // Theme Toggle Action
              IconButton(
                icon: Icon(
                  themeNotifier.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: themeNotifier.isDarkMode ? Colors.amber : Colors.black87,
                ),
                onPressed: () {
                  themeNotifier.toggleTheme();
                },
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
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: themeNotifier.primaryColor.withValues(alpha: 0.2),
                              child: Text(
                                _profileName.isNotEmpty ? _profileName[0].toUpperCase() : 'S',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: themeNotifier.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatColumn('Posts', '42'),
                                  _buildStatColumn('Followers', '12.8K'),
                                  _buildStatColumn('Following', '340'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Name & Bio
                        Text(
                          _profileName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: themeNotifier.isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _bio,
                          style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                        ),
                        const SizedBox(height: 16),

                        // Edit Profile / Share Profile Action Row
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: themeNotifier.isDarkMode ? Colors.white : Colors.black87,
                                  side: BorderSide(color: themeNotifier.isDarkMode ? Colors.white24 : Colors.grey.shade400),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditProfileScreen(
                                        initialName: _profileName,
                                        initialHandle: _handle,
                                        initialBio: _bio,
                                      ),
                                    ),
                                  );
                                  if (result != null && result is Map<String, String>) {
                                    setState(() {
                                      _profileName = result['name']!;
                                      _handle = result['handle']!;
                                      _bio = result['bio']!;
                                    });
                                  }
                                },
                                child: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeNotifier.primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  ProfileShareHelper.showShareProfileOptions(
                                    context,
                                    profileName: _profileName,
                                    handle: _handle,
                                  );
                                },
                                child: const Text('Share Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: themeNotifier.primaryColor,
                      labelColor: themeNotifier.primaryColor,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(icon: Icon(Icons.grid_on), text: 'Reels & Posts'),
                        Tab(icon: Icon(Icons.security), text: 'Hardware Kits'),
                      ],
                    ),
                    themeNotifier.isDarkMode ? const Color(0xFF222222) : Colors.white,
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Posts Grid
                GridView.builder(
                  padding: const EdgeInsets.all(2),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    return Container(
                      color: themeNotifier.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.play_arrow, color: themeNotifier.primaryColor, size: 32),
                          Positioned(
                            bottom: 6,
                            left: 6,
                            child: Text(
                              '▶ ${index + 1}.2k',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Tab 2: Hardware Kits
                ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: themeNotifier.isDarkMode ? const Color(0xFF222222) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: themeNotifier.primaryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.videocam, color: themeNotifier.primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '4K PTZ Security Kit #${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: themeNotifier.isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Includes 4 Cameras, NVR, and 1TB Surveillance HDD',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 14, color: themeNotifier.isDarkMode ? Colors.white54 : Colors.black54),
                        ],
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

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar || backgroundColor != oldDelegate.backgroundColor;
  }
}