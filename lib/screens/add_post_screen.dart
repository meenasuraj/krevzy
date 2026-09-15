import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  bool _isPosting = false;

  Future<void> _createNewPost() async {
    final String content = _captionController.text.trim();
    final String imageUrl = _imageUrlController.text.trim();
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (content.isEmpty && imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter text or an image URL')),
      );
      return;
    }

    if (currentUser == null) return;

    setState(() {
      _isPosting = true;
    });

    try {
      // Fetch user profile info
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userData = userDoc.data() ?? {};
      final String username = userData['username'] ?? 'KREVZY User';
      final String handle = userData['handle'] ?? '@user';

      // Create post in Firestore
      await FirebaseFirestore.instance.collection('posts').add({
        'userId': currentUser.uid,
        'username': username,
        'handle': handle,
        'content': content,
        'imageUrl': imageUrl,
        'likes': [],
        'commentCount': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _captionController.clear();
        _imageUrlController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post published successfully! 🎉')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish post: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'New Post',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isPosting
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: _createNewPost,
                    child: const Text(
                      'Share',
                      style: TextStyle(
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _captionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'What is on your mind? Write a caption...',
                border: InputBorder.none,
              ),
            ),
            const Divider(),
            const SizedBox(height: 12),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL (Optional)',
                hintText: 'https://example.com/image.png',
                prefixIcon: Icon(Icons.image_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (_imageUrlController.text.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _imageUrlController.text,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 100,
                    color: Colors.grey.shade200,
                    child: const Center(child: Text('Invalid Image URL')),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}