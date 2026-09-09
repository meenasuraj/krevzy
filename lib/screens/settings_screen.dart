import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';
import 'language_settings_screen.dart';
import 'manage_accounts_screen.dart'; // Linked to the multi-account manager

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = AppThemeNotifier.instance;

    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF181818) : Colors.grey[100],
          appBar: AppBar(
            title: const Text('Settings and privacy', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: themeNotifier.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Search Bar for Settings
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search settings...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // SECTION 1: Account
              const _SectionHeader(title: 'Account'),
              _SettingsGroupCard(
                children: [
                  _SettingsTile(
                    icon: Icons.lock_outline,
                    color: Colors.blue,
                    title: 'Password and security',
                    subtitle: 'Two-factor auth, password reset & alerts',
                    onTap: () => _openSubScreen(context, 'Password and Security', 'Manage your account security, change passwords, and setup two-factor authentication.'),
                  ),
                  _SettingsTile(
                    icon: Icons.hub_outlined,
                    color: Colors.purple,
                    title: 'Connected experiences',
                    subtitle: 'Cross-platform sharing & linked profiles',
                    onTap: () => _openSubScreen(context, 'Connected Experiences', 'Control profile sharing and connections across connected services.'),
                  ),
                  _SettingsTile(
                    icon: Icons.admin_panel_settings_outlined,
                    color: Colors.teal,
                    title: 'Your permissions and information',
                    subtitle: 'Access data, downloads & app permissions',
                    onTap: () => _openSubScreen(context, 'Your Permissions and Information', 'Review and download your account data and privacy consents.'),
                  ),
                  _SettingsTile(
                    icon: Icons.ads_click,
                    color: Colors.orange,
                    title: 'Ad preferences',
                    subtitle: 'Manage topic interests and ad interactions',
                    onTap: () => _openSubScreen(context, 'Ad Preferences', 'Customize what kinds of ads and sponsored recommendations appear in your feeds.'),
                  ),
                  _SettingsTile(
                    icon: Icons.card_membership,
                    color: Colors.amber,
                    title: 'Subscription',
                    subtitle: 'Active badges, creator tiers & billing',
                    onTap: () => _openSubScreen(context, 'Subscription', 'Manage your active platform subscriptions and creator tier billing details.'),
                  ),
                  _SettingsTile(
                    icon: Icons.photo_library_outlined,
                    color: Colors.pink,
                    title: 'Your media gallery',
                    subtitle: 'Cloud cache, downloads and synced albums',
                    onTap: () => _openSubScreen(context, 'Your Media Gallery', 'Manage media storage caches, downloaded posts, and synchronized photo folders.'),
                  ),
                  _SettingsTile(
                    icon: Icons.manage_accounts_outlined,
                    color: Colors.indigo,
                    title: 'Manage accounts',
                    subtitle: 'Switch or add alternative profiles',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ManageAccountsScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // SECTION 2: How you use Krevzy
              const _SectionHeader(title: 'How you use Krevzy'),
              _SettingsGroupCard(
                children: [
                  _SettingsTile(
                    icon: Icons.bookmark_border,
                    color: Colors.blue,
                    title: 'Saved posts',
                    subtitle: 'View your bookmarked reels and posts',
                    onTap: () => _openSubScreen(context, 'Saved Posts', 'Your collection of saved items.'),
                  ),
                  _SettingsTile(
                    icon: Icons.archive_outlined,
                    color: Colors.orange,
                    title: 'Archive',
                    subtitle: 'Stories and posts you have archived',
                    onTap: () => _openSubScreen(context, 'Archive', 'Manage your archived stories & posts.'),
                  ),
                  _SettingsTile(
                    icon: Icons.history,
                    color: Colors.purple,
                    title: 'Your activity',
                    subtitle: 'Interaction history, likes, and comments',
                    onTap: () => _openSubScreen(context, 'Your Activity', 'Track time spent, interactions & history.'),
                  ),
                  _SettingsTile(
                    icon: Icons.timer_outlined,
                    color: Colors.teal,
                    title: 'Time management',
                    subtitle: 'Daily reminders and take-a-break alerts',
                    onTap: () => _openSubScreen(context, 'Time Management', 'Configure screen time limits.'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // SECTION 3: Who can see your content
              const _SectionHeader(title: 'Who can see your content'),
              _SettingsGroupCard(
                children: [
                  _SettingsTile(
                    icon: Icons.star_border,
                    color: Colors.amber,
                    title: 'Close friends',
                    subtitle: 'Manage list for exclusive stories',
                    onTap: () => _openSubScreen(context, 'Close Friends', 'Add or remove users from your close friends list.'),
                  ),
                  _SettingsTile(
                    icon: Icons.block,
                    color: Colors.red,
                    title: 'Blocking & restricted users',
                    subtitle: 'Accounts you have blocked or restricted',
                    onTap: () => _openSubScreen(context, 'Blocked Users', 'Manage blocked and restricted accounts.'),
                  ),
                  _SettingsTile(
                    icon: Icons.live_tv,
                    color: Colors.indigo,
                    title: 'Story, live and location',
                    subtitle: 'Sharing and privacy controls for live feeds',
                    onTap: () => _openSubScreen(context, 'Story & Live Privacy', 'Manage who can view your live broadcasts & stories.'),
                  ),
                  _SettingsTile(
                    icon: Icons.feed_outlined,
                    color: Colors.green,
                    title: 'Activity in friend feed',
                    subtitle: 'Control what appears about your activity',
                    onTap: () => _openSubScreen(context, 'Friend Feed Activity', 'Manage activity visibility in feeds.'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // SECTION 4: How others can interact with you
              const _SectionHeader(title: 'How others can interact with you'),
              _SettingsGroupCard(
                children: [
                  _SettingsTile(
                    icon: Icons.chat_bubble_outline,
                    color: Colors.blue,
                    title: 'Messages and story replies',
                    subtitle: 'Who can message you directly',
                    onTap: () => _openSubScreen(context, 'Messages & Replies', 'Control DM permissions.'),
                  ),
                  _SettingsTile(
                    icon: Icons.alternate_email,
                    color: Colors.purple,
                    title: 'Tags and mentions',
                    subtitle: 'Manage who can tag you in posts',
                    onTap: () => _openSubScreen(context, 'Tags & Mentions', 'Set who can @mention or tag you.'),
                  ),
                  _SettingsTile(
                    icon: Icons.comment_outlined,
                    color: Colors.pink,
                    title: 'Comments',
                    subtitle: 'Filter or block offensive comments',
                    onTap: () => _openSubScreen(context, 'Comments Control', 'Manage comment filters and permissions.'),
                  ),
                  _SettingsTile(
                    icon: Icons.repeat,
                    color: Colors.cyan,
                    title: 'Sharing and reuse',
                    subtitle: 'Allow sharing of your posts and reels',
                    onTap: () => _openSubScreen(context, 'Sharing & Reuse', 'Control remix and share rules.'),
                  ),
                  _SettingsTile(
                    icon: Icons.visibility_off_outlined,
                    color: Colors.brown,
                    title: 'Hidden words',
                    subtitle: 'Custom words filtered from comments/DMs',
                    onTap: () => _openSubScreen(context, 'Hidden Words', 'Add custom offensive words to auto-hide.'),
                  ),
                  _SettingsTile(
                    icon: Icons.person_add_alt,
                    color: Colors.green,
                    title: 'Follow and invite friends',
                    subtitle: 'Connect contacts and send invite links',
                    onTap: () => _openSubScreen(context, 'Invite Friends', 'Sync contacts and invite peers to Krevzy.'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // SECTION 5: Your app and media
              const _SectionHeader(title: 'Your app and media'),
              _SettingsGroupCard(
                children: [
                  _SettingsTile(
                    icon: Icons.star,
                    color: Colors.amber,
                    title: 'Favorites',
                    subtitle: 'Prioritize accounts in your feed',
                    onTap: () => _openSubScreen(context, 'Favorites', 'Manage your favorite creators list.'),
                  ),
                  _SettingsTile(
                    icon: Icons.volume_off,
                    color: Colors.grey,
                    title: 'Muted accounts',
                    subtitle: 'Posts and stories you have muted',
                    onTap: () => _openSubScreen(context, 'Muted Accounts', 'Manage muted profiles.'),
                  ),
                  _SettingsTile(
                    icon: Icons.tune,
                    color: Colors.indigo,
                    title: 'Content preferences',
                    subtitle: 'Sensitive content control and topics',
                    onTap: () => _openSubScreen(context, 'Content Preferences', 'Adjust sensitive content filter levels.'),
                  ),
                  _SettingsTile(
                    icon: Icons.favorite_border,
                    color: Colors.red,
                    title: 'Like and share counts',
                    subtitle: 'Hide or show engagement metrics',
                    onTap: () => _openSubScreen(context, 'Like Counts', 'Toggle visibility of like counters.'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // SECTION 6: Core App Settings
              const _SectionHeader(title: 'Core App Settings'),
              _SettingsGroupCard(
                children: [
                  _SettingsTile(
                    icon: Icons.devices,
                    color: Colors.blueGrey,
                    title: 'Device permissions',
                    subtitle: 'Camera, microphone, storage access',
                    onTap: () => _openSubScreen(context, 'Device Permissions', 'Manage app hardware permissions.'),
                  ),
                  _SettingsTile(
                    icon: Icons.download_outlined,
                    color: Colors.green,
                    title: 'Archiving and downloading',
                    subtitle: 'Auto-save original posts to device',
                    onTap: () => _openSubScreen(context, 'Downloading Options', 'Configure automated media saves.'),
                  ),
                  _SettingsTile(
                    icon: Icons.accessibility,
                    color: Colors.purple,
                    title: 'Accessibility',
                    subtitle: 'Captions, screen reader settings',
                    onTap: () => _openSubScreen(context, 'Accessibility', 'Font scaling and reader options.'),
                  ),
                  _SettingsTile(
                    icon: Icons.language,
                    color: Colors.orange,
                    title: 'Language and translations',
                    subtitle: themeNotifier.currentLanguage,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LanguageSettingsScreen()),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.data_usage,
                    color: Colors.blue,
                    title: 'Data usage and media quality',
                    subtitle: 'High-resolution uploads & data saver',
                    onTap: () => _openSubScreen(context, 'Data Usage', 'Cellular data saver and upload quality.'),
                  ),
                  _SettingsTile(
                    icon: Icons.security,
                    color: Colors.indigo,
                    title: 'App and website permissions',
                    subtitle: 'Connected apps and login sessions',
                    onTap: () => _openSubScreen(context, 'App Permissions', 'Manage authorized third-party app access.'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  void _openSubScreen(BuildContext context, String title, String subtitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _GenericSettingsDetailScreen(title: title, subtitle: subtitle),
      ),
    );
  }
}

// --- REUSABLE SUB-COMPONENTS ---

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeNotifier.instance.isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.blue.shade300 : Colors.blue.shade800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsGroupCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeNotifier.instance.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeNotifier.instance.isDarkMode;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class _GenericSettingsDetailScreen extends StatelessWidget {
  final String title;
  final String subtitle;

  const _GenericSettingsDetailScreen({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = AppThemeNotifier.instance;

    return Scaffold(
      backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF181818) : Colors.grey[100],
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: themeNotifier.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: themeNotifier.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: themeNotifier.isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: themeNotifier.primaryColor),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'This management preference is synchronized with your Krevzy account profile.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}