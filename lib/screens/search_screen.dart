import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Sample creator network database for search
  final List<Map<String, dynamic>> _allCreators = [
    {'name': 'Rahul Sharma', 'handle': '@rahul_tech', 'role': 'Security Expert', 'isFollowing': true},
    {'name': 'Priya Verma', 'handle': '@priya_v', 'role': 'Photo Editor', 'isFollowing': false},
    {'name': 'Amit Kumar', 'handle': '@amit_cctv', 'role': 'Hardware Tech', 'isFollowing': false},
    {'name': 'Neha Singh', 'handle': '@neha_design', 'role': 'UI/UX Designer', 'isFollowing': true},
    {'name': 'Vikram Patel', 'handle': '@vikram_net', 'role': 'Network Admin', 'isFollowing': false},
  ];

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Filter creators based on search query
    final filteredCreators = _allCreators.where((creator) {
      final nameLower = creator['name'].toLowerCase();
      final handleLower = creator['handle'].toLowerCase();
      final roleLower = creator['role'].toLowerCase();
      final query = _searchQuery.toLowerCase();
      return nameLower.contains(query) || handleLower.contains(query) || roleLower.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Explore Creators'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name, handle, or creator role...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Search Results ListView
          Expanded(
            child: filteredCreators.isEmpty
                ? const Center(
                    child: Text(
                      'No creators found matching your search.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredCreators.length,
                    itemBuilder: (context, index) {
                      final creator = filteredCreators[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              creator['name'][0],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          title: Text(
                            creator['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(creator['handle'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(
                                creator['role'],
                                style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                                tooltip: 'Direct Message',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatDetailScreen(
                                        peerName: creator['name'],
                                        peerHandle: creator['handle'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: creator['isFollowing'] ? Colors.grey[200] : Colors.blue,
                                  foregroundColor: creator['isFollowing'] ? Colors.black87 : Colors.white,
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  setState(() {
                                    creator['isFollowing'] = !creator['isFollowing'];
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        creator['isFollowing']
                                            ? 'Now following ${creator['name']}'
                                            : 'Unfollowed ${creator['name']}',
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Text(creator['isFollowing'] ? 'Following' : 'Follow'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}