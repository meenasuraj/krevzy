import 'package:flutter/material.dart';
import 'saved_posts_screen.dart';
import 'your_activity_screen.dart';
import 'account_privacy_screen.dart';
import 'time_management_screen.dart';
import 'close_friends_screen.dart';
import 'audience_controls_screen.dart';
import 'krevzy_people_list_screen.dart';
import 'like_share_count_screen.dart';
import 'language_settings_screen.dart';
import 'sound_settings_screen.dart';
import 'data_media_quality_screen.dart';
import 'app_website_permissions_screen.dart';

class KrevzyPreferencesScreen extends StatelessWidget {
  const KrevzyPreferencesScreen({super.key});

  void push(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Widget tile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Widget page,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => push(context, page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KREVZY preferences')),
      body: ListView(
        children: [
          const _Header('Your activity & content'),
          tile(
            context,
            'Saved posts',
            'View and unsave posts you saved',
            Icons.bookmark_outline,
            const SavedPostsScreen(),
          ),
          tile(
            context,
            'Your activity',
            'Review activity recorded by KREVZY',
            Icons.history,
            const YourActivityScreen(),
          ),
          const _Header('Privacy'),
          tile(
            context,
            'Account privacy',
            'Private account, activity status and receipts',
            Icons.lock_outline,
            const AccountPrivacyScreen(),
          ),
          tile(
            context,
            'Close Friends',
            'Add and remove your close friends',
            Icons.people_alt_outlined,
            const CloseFriendsScreen(),
          ),
          tile(
            context,
            'Message and story replies',
            'Control messages and story replies',
            Icons.reply_outlined,
            const MessageStoryRepliesScreen(),
          ),
          tile(
            context,
            'Tags and mentions',
            'Control tagging and @mentions',
            Icons.alternate_email,
            const TagsMentionsScreen(),
          ),
          tile(
            context,
            'Restricted accounts',
            'Manage restricted accounts',
            Icons.remove_circle_outline,
            const KrevzyPeopleListScreen(
              title: 'Restricted accounts',
              collection: 'restrictedAccounts',
              emptyText: 'No restricted accounts yet.',
            ),
          ),
          tile(
            context,
            'Limit interactions',
            'Temporarily limit unwanted interactions',
            Icons.shield_outlined,
            const LimitInteractionsScreen(),
          ),
          tile(
            context,
            'Favourites',
            'Add or remove favourite people',
            Icons.star_outline,
            const KrevzyPeopleListScreen(
              title: 'Favourites',
              collection: 'favourites',
              emptyText: 'No favourites yet.',
              icon: Icons.star,
            ),
          ),
          tile(
            context,
            'Muted accounts',
            'Manage muted accounts',
            Icons.volume_off_outlined,
            const KrevzyPeopleListScreen(
              title: 'Muted accounts',
              collection: 'mutedAccounts',
              emptyText: 'No muted accounts yet.',
              icon: Icons.volume_off_outlined,
            ),
          ),
          tile(
            context,
            'Like and share counts',
            'Hide or show public counts',
            Icons.visibility_off_outlined,
            const LikeShareCountScreen(),
          ),
          const _Header('App preferences'),
          tile(
            context,
            'Time management',
            'Set daily time limits and reminders',
            Icons.timer_outlined,
            const TimeManagementScreen(),
          ),
          tile(
            context,
            'Languages',
            'Choose KREVZY language',
            Icons.language,
            const LanguageSettingsScreen(),
          ),
          tile(
            context,
            'Sounds',
            'Stories, chats and favourite-person sounds',
            Icons.volume_up_outlined,
            const SoundSettingsScreen(),
          ),
          tile(
            context,
            'Data used and media quality',
            'Data saver, autoplay and upload quality',
            Icons.data_usage_outlined,
            const DataMediaQualityScreen(),
          ),
          tile(
            context,
            'App and website permissions',
            'Manage KREVZY feature permissions',
            Icons.admin_panel_settings_outlined,
            const AppWebsitePermissionsScreen(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
