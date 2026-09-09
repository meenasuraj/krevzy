import 'package:flutter/material.dart';

class FollowersScreen extends StatelessWidget {
  const FollowersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> users = [
      {'name': 'Rahul Sharma', 'handle': '@rahul_tech'},
      {'name': 'Priya Verma', 'handle': '@priya_v'},
      {'name': 'Amit Kumar', 'handle': '@amit_cctv'},
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Connections'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Followers'),
              Tab(text: 'Following'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserList(users, 'Follower'),
            _buildUserList(users.reversed.toList(), 'Following'),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(List<Map<String, String>> list, String type) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text(list[index]['name']![0]),
          ),
          title: Text(list[index]['name']!),
          subtitle: Text(list[index]['handle']!),
          trailing: OutlinedButton(
            onPressed: () {},
            child: Text(type == 'Follower' ? 'Follow Back' : 'Following'),
          ),
        );
      },
    );
  }
}