import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';
import '../utils/share_helper.dart';
import 'story_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final List<Map<String, dynamic>> _posts = [
    {
      'creatorName': 'Vidisha Security Solutions',
      'creatorHandle': '@vidishasecurity',
      'avatarText': 'V',
      'timeAgo': '2h ago',
      'caption': 'Testing out the new 4K PTZ Dome Camera night vision in low light environments. Incredible clarity and motion tracking! 🛡️📹',
      'mediaType': 'video',
      'likes': 1240,
      'comments': 84,
      'isLiked': false,
    },
    {
      'creatorName': 'Rahul Tech Creator',
      'creatorHandle': '@rahul_tech',
      'avatarText': 'R',
      'timeAgo': '5h ago',
      'caption': 'Quick tutorial on setting up NVR remote access via mobile app for homeowners. Drop your security questions below! 👇',
      'mediaType': 'image',
      'likes': 892,
      'comments': 45,
      'isLiked': true,
    },
  ];

  final List<Map<String, String>> _stories = [
    {'name': 'Your Story', 'handle': '@you', 'initial': 'S', 'isUser': 'true'},
    {'name': 'Pooja Tech', 'handle': '@poojatech', 'initial': 'P', 'isUser': 'false'},
    {'name': 'CCTV Pro', 'handle': '@cctvpro', 'initial': 'C', 'isUser': 'false'},
    {'name': 'Amit Guard', 'handle': '@amitguard', 'initial': 'A', 'isUser': 'false'},
    {'name': 'Tech Hub', 'handle': '@techhub', 'initial': 'T', 'isUser': 'false'},
  ];

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
            elevation: 0.5,
            title: Text(
              'Krevzy',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: themeNotifier.primaryColor,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: themeNotifier.isDarkMode ? Colors.white : Colors.black87),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new notifications')),
                  );
                },
              ),
            ],
          ),
          body: ListView(
            children: [
              // Stories Row Section
              Container(
                height: 100,
                color: themeNotifier.isDarkMode ? const Color(0xFF222222) : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _stories.length,
                  itemBuilder: (context, index) {
                    final story = _stories[index];
                    final isUser = story['isUser'] == 'true';
                    return GestureDetector(
                      onTap: () {
                        if (isUser) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Upload new story feature coming soon!')),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StoryScreen(
                                creatorName: story['name']!,
                                creatorHandle: story['handle']!,
                                avatarText: story['initial']!,
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: isUser
                                        ? null
                                        : const LinearGradient(
                                            colors: [Colors.purple, Colors.orange, Colors.amber],
                                            begin: Alignment.topRight,
                                            end: Alignment.bottomLeft,
                                          ),
                                    color: isUser ? Colors.grey : null,
                                  ),
                                  child: CircleAvatar(
                                    radius: 26,
                                    backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF333333) : Colors.white,
                                    child: Text(
                                      story['initial']!,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: themeNotifier.isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                                if (isUser)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: CircleAvatar(
                                      radius: 10,
                                      backgroundColor: themeNotifier.primaryColor,
                                      child: const Icon(Icons.add, size: 14, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              story['name']!,
                              style: TextStyle(
                                fontSize: 11,
                                color: themeNotifier.isDarkMode ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Posts Feed Builder
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: themeNotifier.isDarkMode ? const Color(0xFF222222) : Colors.white,
                      border: Border(
                        top: BorderSide(color: themeNotifier.isDarkMode ? Colors.white10 : Colors.grey.shade200),
                        bottom: BorderSide(color: themeNotifier.isDarkMode ? Colors.white10 : Colors.grey.shade200),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Post Header (Creator Info)
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: themeNotifier.primaryColor.withValues(alpha: 0.2),
                            child: Text(
                              post['avatarText'],
                              style: TextStyle(color: themeNotifier.primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            post['creatorName'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: themeNotifier.isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            '${post['creatorHandle']} • ${post['timeAgo']}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          trailing: const Icon(Icons.more_vert, color: Colors.grey),
                        ),

                        // Post Media Placeholder / Showcase
                        Container(
                          height: 280,
                          width: double.infinity,
                          color: themeNotifier.isDarkMode ? const Color(0xFF151515) : Colors.grey.shade300,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                post['mediaType'] == 'video' ? Icons.play_circle_fill : Icons.image,
                                size: 64,
                                color: themeNotifier.primaryColor.withValues(alpha: 0.8),
                              ),
                              Positioned(
                                bottom: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    post['mediaType'] == 'video' ? '▶ CCTV Security Reel' : '📷 Hardware Snapshot',
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Post Action Buttons Toolbar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                                      color: post['isLiked'] ? Colors.red : (themeNotifier.isDarkMode ? Colors.white70 : Colors.black54),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        post['isLiked'] = !post['isLiked'];
                                        if (post['isLiked']) {
                                          post['likes'] += 1;
                                        } else {
                                          post['likes'] -= 1;
                                        }
                                      });
                                    },
                                  ),
                                  Text('${post['likes']}', style: TextStyle(color: themeNotifier.isDarkMode ? Colors.white70 : Colors.black87, fontSize: 13)),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: Icon(Icons.chat_bubble_outline, color: themeNotifier.isDarkMode ? Colors.white70 : Colors.black54),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Opening comments section...')),
                                      );
                                    },
                                  ),
                                  Text('${post['comments']}', style: TextStyle(color: themeNotifier.isDarkMode ? Colors.white70 : Colors.black87, fontSize: 13)),
                                ],
                              ),
                              // Share Button triggering ShareHelper
                              IconButton(
                                icon: Icon(Icons.share_outlined, color: themeNotifier.isDarkMode ? Colors.white70 : Colors.black54),
                                onPressed: () {
                                  ShareHelper.showShareOptions(
                                    context,
                                    postTitle: post['caption'],
                                    postUrl: 'https://krevzy.app/posts/${index + 1}',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // Post Caption
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: Text(
                            post['caption'],
                            style: TextStyle(
                              fontSize: 13,
                              color: themeNotifier.isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}