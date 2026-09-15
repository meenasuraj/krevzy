import 'package:flutter/material.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();

  // Simulated reels data
  final List<Map<String, dynamic>> _reels = [
    {
      'username': 'Suraj Meena',
      'handle': '@suraj_krevzy',
      'caption': 'Building the future of social media apps with Flutter! 🚀 #Krevzy #FlutterDev',
      'audioTitle': 'Original Audio - Suraj Meena',
      'likes': 1240,
      'comments': 84,
      'shares': 45,
      'isLiked': false,
      'bgGradient': [Colors.blue.shade900, Colors.indigo.shade600],
    },
    {
      'username': 'Priya Sharma',
      'handle': '@priya_designs',
      'caption': 'UI/UX design tips for next-gen mobile applications. Keep it clean! ✨',
      'audioTitle': 'Lo-Fi Chill Beat - Creator Hub',
      'likes': 3420,
      'comments': 156,
      'shares': 120,
      'isLiked': true,
      'bgGradient': [Colors.purple.shade900, Colors.deepPurple.shade500],
    },
    {
      'username': 'Tech Insider',
      'handle': '@techinsider',
      'caption': 'Why cross-platform frameworks are dominating tech stacks this year.',
      'audioTitle': 'Synthwave Energy - 2026 Mix',
      'likes': 5890,
      'comments': 310,
      'shares': 430,
      'isLiked': false,
      'bgGradient': [Colors.teal.shade900, Colors.blueGrey.shade800],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _reels.length,
        itemBuilder: (context, index) {
          final reel = _reels[index];

          return Stack(
            fit: StackFit.expand,
            children: [
              // Simulated Reel Video Background (Gradient container representing video frame)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: reel['bgGradient'],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_circle_outline, color: Colors.white54, size: 80),
                      const SizedBox(height: 12),
                      Text(
                        'REEL STREAM #${index + 1}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top Bar Header
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Krevzy Reels',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Open Reel Camera & Recorder.')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Overlay (Caption, Audio, Creator Info) & Right Action Buttons
              Positioned(
                left: 16,
                right: 70,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: Text(
                            reel['username'].substring(0, 2).toUpperCase(),
                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          reel['username'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            minimumSize: const Size(0, 28),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Followed ${reel['username']}!')),
                            );
                          },
                          child: const Text('Follow', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      reel['caption'],
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.music_note, color: Colors.white70, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            reel['audioTitle'],
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right-side Interactive Action Buttons (Like, Comment, Share)
              Positioned(
                right: 16,
                bottom: 30,
                child: Column(
                  children: [
                    // Like Button
                    IconButton(
                      icon: Icon(
                        reel['isLiked'] ? Icons.favorite : Icons.favorite_border,
                        color: reel['isLiked'] ? Colors.red : Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          reel['isLiked'] = !reel['isLiked'];
                          reel['isLiked'] ? reel['likes']++ : reel['likes']--;
                        });
                      },
                    ),
                    Text(
                      '${reel['likes']}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Comment Button
                    IconButton(
                      icon: const Icon(Icons.chat_bubble, color: Colors.white, size: 30),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opening comments for ${reel['username']}\'s reel.')),
                        );
                      },
                    ),
                    Text(
                      '${reel['comments']}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Share Button
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white, size: 30),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reel link copied to clipboard!')),
                        );
                      },
                    ),
                    Text(
                      '${reel['shares']}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Audio Disc Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54, width: 2),
                      ),
                      child: const Icon(Icons.music_note, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}