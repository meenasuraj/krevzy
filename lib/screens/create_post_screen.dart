import 'package:flutter/material.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  bool _hasMediaAttached = false;
  String _selectedCategory = 'General';

  final List<String> _categories = ['General', 'Security Systems', 'Flutter Dev', 'Digital Editing'];

  void _submitPost() {
    if (_contentController.text.trim().isNotEmpty) {
      Navigator.pop(context, {
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'hasMedia': _hasMediaAttached,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post published successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something before posting.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Create New Post'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                elevation: 0,
              ),
              onPressed: _submitPost,
              child: const Text('Publish', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Selector Dropdown
            Row(
              children: [
                const Text('Category: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: _categories.map((String cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Post Text Input Area
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Share your updates, project milestones, or media tips with the Krevzy community...',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Attached Media Preview Box (if enabled)
            if (_hasMediaAttached)
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 48, color: Colors.blue),
                          SizedBox(height: 8),
                          Text('High-Definition Media Attached', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 16,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 16),
                          onPressed: () {
                            setState(() {
                              _hasMediaAttached = false;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Attachment Tool Buttons
            Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                  onPressed: () {
                    setState(() {
                      _hasMediaAttached = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('HD Media attached successfully!')),
                    );
                  },
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Add Photo/Video'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.grey[700]),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tag location feature ready.')),
                    );
                  },
                  icon: const Icon(Icons.location_on_outlined),
                  label: const Text('Add Location'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}