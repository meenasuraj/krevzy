import 'package:flutter/material.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  // Simulated social media posts
  final List<Map<String, dynamic>> _posts = [
    {
      'username': 'Suraj Meena',
      'handle': '@suraj_krevzy',
      'avatar': 'SM',
      'time': '2h ago',
      'content': 'Just pushed a major architecture update for Krevzy! Flutter Material 3 performance is looking butter smooth. 🚀🔥',
      'mediaUrl': null,
      'likes': 142,
      'comments': 28,
      'shares': 12,
      'isLiked': false,
    },
    {
      'username': 'Creator Hub India',
      'handle': '@creatorhub',
      'avatar': 'CH',
      'time': '5h ago',
      'content': 'Vidisha and Madhya Pradesh creators are scaling up fast this season. Check out the latest engagement trends on our dashboard!',
      'mediaUrl': 'assets/sample_post.png', // Placeholder indicator
      'likes': 854,
      'comments': 64,
      'shares': 45,
      'isLiked': true,
    },
    {
      'username': 'Tech Insider',
      'handle': '@techinsider',
      'avatar': 'TI',
      'time': 'Yesterday',
      'content': 'Cross-platform mobile development with Flutter continues to dominate startup tech stacks in 2026. What are you building?',
      'mediaUrl': null,
      'likes': 320,
      'comments': 19,
      'shares': 8,
      'isLiked': false,
    },
  ];

  void _showCreatePostSheet() {
    final TextEditingController postController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create New Post',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: postController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'What is happening in your creator world?',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Photo/Video attachment picker opened.')),
                      );
                    },
                    icon: const Icon(Icons.image, color: Colors.blue),
                    tooltip: 'Attach Image',
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tag location added.')),
                      );
                    },
                    icon: const Icon(Icons.location_on, color: Colors.red),
                    tooltip: 'Add Location',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final text = postController.text.trim();
                    if (text.isNotEmpty) {
                      setState(() {
                        _posts.insert(0, {
                          'username': 'Suraj Meena',
                          'handle': '@suraj_krevzy',
                          'avatar': 'SM',
                          'time': 'Just now',
                          'content': text,
                          'mediaUrl': null,
                          'likes': 1,
                          'comments': 0,
                          'shares': 0,
                          'isLiked': false,
                        });
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post published successfully!')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please write something before posting.')),
                      );
                    }
                  },
                  child: const Text('Post to Feed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Krevzy Feed', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search posts and creators.')),
              );
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12.0),
        itemCount: _posts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final post = _posts[index];

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author Header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(post['avatar'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(post['username'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(post['handle'], style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                          ],
                        ),
                      ),
                      Text(post['time'], style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Post Text Content
                  Text(
                    post['content'],
                    style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                  ),
                  const SizedBox(height: 12),

                  // Optional Media Placeholder
                  if (post['mediaUrl'] != null)
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Attached Media Preview', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  if (post['mediaUrl'] != null) const SizedBox(height: 12),

                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Action Bar (Like, Comment, Share)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            post['isLiked'] = !post['isLiked'];
                            post['isLiked'] ? post['likes']++ : post['likes']--;
                          });
                        },
                        icon: Icon(
                          post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                          color: post['isLiked'] ? Colors.red : Colors.grey,
                          size: 18,
                        ),
                        label: Text(
                          '${post['likes']}',
                          style: TextStyle(color: post['isLiked'] ? Colors.red : Colors.grey[700], fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Opening comments for ${post['username']}\'s post.')),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 18),
                        label: Text('${post['comments']}', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post link copied to clipboard!')),
                          );
                        },
                        icon: const Icon(Icons.share_outlined, color: Colors.grey, size: 18),
                        label: Text('${post['shares']}', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        onPressed: _showCreatePostSheet,
        icon: const Icon(Icons.add),
        label: const Text('New Post', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}