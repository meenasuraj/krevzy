import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';
import 'promotion_screen.dart'; // Import the new promotion screen

class CreatorStudioHubScreen extends StatelessWidget {
  const CreatorStudioHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = AppThemeNotifier.instance;

    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF181818) : Colors.grey[100],
          appBar: AppBar(
            title: const Text('Creator Studio', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: themeNotifier.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Creator Performance Overview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Channel Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Followers', '12.8K', themeNotifier.primaryColor),
                        _buildStatItem('Total Views', '452K', Colors.blue),
                        _buildStatItem('Est. Earnings', '₹18,400', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Studio Quick Actions Menu
              const Text('Studio Tools', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),

              _buildStudioActionTile(
                context,
                themeNotifier,
                icon: Icons.trending_up,
                title: 'Boost Reels & Products',
                subtitle: 'Promote CCTV security kits and product reels to local buyers',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PromotionScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),

              _buildStudioActionTile(
                context,
                themeNotifier,
                icon: Icons.analytics,
                title: 'Detailed Analytics',
                subtitle: 'Check audience retention, engagement spikes, and demographics',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Analytics Dashboard...')),
                  );
                },
              ),
              const SizedBox(height: 10),

              _buildStudioActionTile(
                context,
                themeNotifier,
                icon: Icons.monetization_on,
                title: 'Monetization & Payouts',
                subtitle: 'Manage bank accounts, brand deals, and revenue milestones',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Monetization Settings...')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStudioActionTile(
    BuildContext context,
    AppThemeNotifier themeNotifier, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: themeNotifier.primaryColor.withValues(alpha: 0.2),
          child: Icon(icon, color: themeNotifier.primaryColor),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: themeNotifier.isDarkMode ? Colors.white : Colors.black87)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}