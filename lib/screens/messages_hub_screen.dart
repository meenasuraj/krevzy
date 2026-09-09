import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';
import 'messages_inbox_screen.dart';
import 'chat_screen.dart';

class MessagesHubScreen extends StatefulWidget {
  const MessagesHubScreen({super.key});

  @override
  State<MessagesHubScreen> createState() => _MessagesHubScreenState();
}

class _MessagesHubScreenState extends State<MessagesHubScreen> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final themeNotifier = AppThemeNotifier.instance;

    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF181818) : Colors.grey[100],
          appBar: AppBar(
            title: const Text('Messages & Calls Hub', style: TextStyle(fontWeight: FontWeight.bold)),
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
              // Tab 1: Inbox view
              const MessagesInboxScreen(),

              // Tab 2: Creator Broadcast & Tech Support Channels
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildChannelCard(
                    context,
                    themeNotifier,
                    title: 'CCTV Installers Mastermind',
                    members: '1.4k members',
                    latestUpdate: 'New firmware guide shared for 4K PTZ cameras.',
                    icon: Icons.security,
                  ),
                  const SizedBox(height: 12),
                  _buildChannelCard(
                    context,
                    themeNotifier,
                    title: 'Vidisha Local Creators Group',
                    members: '320 members',
                    latestUpdate: 'Meetup scheduled this weekend at local tech hub.',
                    icon: Icons.group,
                  ),
                  const SizedBox(height: 12),
                  _buildChannelCard(
                    context,
                    themeNotifier,
                    title: 'Krevzy Official Announcements',
                    members: '45.2k followers',
                    latestUpdate: 'Monetization payout updates for Q3 now active!',
                    icon: Icons.verified,
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: themeNotifier.primaryColor,
            child: const Icon(Icons.message, color: Colors.white),
            onPressed: () {
              // Quick action to start a new chat session
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatScreen(peerName: 'New Contact'),
                ),
              );
            },
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
        color: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            radius: 24,
            backgroundColor: themeNotifier.primaryColor.withValues(alpha: 0.2),
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
                    color: themeNotifier.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  members,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text(
                  latestUpdate,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeNotifier.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}