import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../utils/app_theme_data.dart';
import 'chat_screen.dart';
import 'messages_inbox_screen.dart';

class MessagesHubScreen extends StatefulWidget {
  const MessagesHubScreen({super.key});

  @override
  State<MessagesHubScreen> createState() => _MessagesHubScreenState();
}

class _MessagesHubScreenState extends State<MessagesHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  void _startNewChat() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please log in first.')));
      return;
    }

    const contactId = 'new_contact';

    final chatId = ChatService.getChatId(
      userId1: currentUser.uid,
      userId2: contactId,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chatId,
          name: 'New Contact',
          initialPinHash: null,
          onPinSet: (_) async {},
          onLockRemoved: () async {},
        ),
      ),
    );
  }

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
              'Messages & Calls Hub',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: themeNotifier.primaryColor,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Direct Chats'),
                Tab(text: 'Channels & Broadcasts'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              const MessagesInboxScreen(),
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildChannelCard(
                    context,
                    themeNotifier,
                    title: 'CCTV Installers Mastermind',
                    members: '1.4k members',
                    latestUpdate:
                        'New firmware guide shared for 4K PTZ cameras.',
                    icon: Icons.security,
                  ),
                  const SizedBox(height: 12),
                  _buildChannelCard(
                    context,
                    themeNotifier,
                    title: 'Vidisha Local Creators Group',
                    members: '320 members',
                    latestUpdate:
                        'Meetup scheduled this weekend at local tech hub.',
                    icon: Icons.group,
                  ),
                  const SizedBox(height: 12),
                  _buildChannelCard(
                    context,
                    themeNotifier,
                    title: 'Krevzy Official Announcements',
                    members: '45.2k followers',
                    latestUpdate:
                        'Monetization payout updates for Q3 now active!',
                    icon: Icons.verified,
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: themeNotifier.primaryColor,
            foregroundColor: Colors.white,
            onPressed: _startNewChat,
            child: const Icon(Icons.message_rounded),
          ),
        );
      },
    );
  }

  Widget _buildChannelCard(
    BuildContext context,
    AppThemeNotifier themeNotifier, {
    required String title,
    required String members,
    required String latestUpdate,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeNotifier.isDarkMode
            ? const Color(0xFF242424)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: themeNotifier.primaryColor.withValues(alpha: 0.15),
            child: Icon(icon, color: themeNotifier.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: themeNotifier.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  members,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text(
                  latestUpdate,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeNotifier.isDarkMode
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}
