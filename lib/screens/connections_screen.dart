import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _followers = [
    {'name': 'Rahul Sharma', 'handle': '@rahul_tech', 'role': 'Security Expert', 'isFollowingBack': true},
    {'name': 'Priya Verma', 'handle': '@priya_v', 'role': 'Photo Editor', 'isFollowingBack': false},
    {'name': 'Amit Kumar', 'handle': '@amit_cctv', 'role': 'Hardware Tech', 'isFollowingBack': true},
  ];

  final List<Map<String, dynamic>> _following = [
    {'name': 'Rahul Sharma', 'handle': '@rahul_tech', 'role': 'Security Expert'},
    {'name': 'Neha Singh', 'handle': '@neha_design', 'role': 'UI/UX Designer'},
  ];

  final List<Map<String, dynamic>> _suggestions = [
    {'name': 'Vikram Patel', 'handle': '@vikram_net', 'role': 'Network Admin', 'isFollowing': false},
    {'name': 'Anjali Gupta', 'handle': '@anjali_dev', 'role': 'Flutter Developer', 'isFollowing': false},
  ];

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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Creator Connections'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Followers (1.8K)'),
            Tab(text: 'Following (320)'),
            Tab(text: 'Suggestions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Followers Tab
          _buildUserListView(_followers, showFollowBack: true),
          // Following Tab
          _buildUserListView(_following, isFollowingTab: true),
          // Suggestions Tab
          _buildUserListView(_suggestions, showFollowButton: true),
        ],
      ),
    );
  }

  Widget b(List<Map<String, dynamic>> users, {bool showFollowBack = false, bool isFollowingTab = false, bool showFollowButton = false}) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                user['name'][0],
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
            title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['handle'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 2),
                Text(user['role'], style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          peerName: user['name'],
                          peerHandle: user['handle'],
                        ),
                      ),
                    );
                  },
                ),
                if (showFollowBack)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: user['isFollowingBack'] ? Colors.grey[200] : Colors.blue,
                      foregroundColor: user['isFollowingBack'] ? Colors.black87 : Colors.white,
                      elevation: 0,
                    ),
                    onPressed: () {
                      setState(() {
                        user['isFollowingBack'] = !user['isFollowingBack'];
                      });
                    },
                    child: Text(user['isFollowingBack'] ? 'Following' : 'Follow Back'),
                  ),
                if (isFollowingTab)
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        users.removeAt(index);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unfollowed user.')),
                      );
                    },
                    child: const Text('Unfollow'),
                  ),
                if (showFollowButton)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: user['isFollowing'] ? Colors.grey[200] : Colors.blue,
                      foregroundColor: user['isFollowing'] ? Colors.black87 : Colors.white,
                      elevation: 0,
                    ),
                    onPressed: () {
                      setState(() {
                        user['isFollowing'] = !user['isFollowing'];
                      });
                    },
                    child: Text(user['isFollowing'] ? 'Following' : 'Follow'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserListView(List<Map<String, dynamic>> users, {bool showFollowBack = false, bool isFollowingTab = false, bool showFollowButton = false}) {
    return b(users, showFollowBack: showFollowBack, isFollowingTab: isFollowingTab, showFollowButton: showFollowButton);
  }
}