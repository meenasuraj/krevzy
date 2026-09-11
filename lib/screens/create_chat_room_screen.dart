import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';

class CreateChatRoomScreen extends StatefulWidget {
  const CreateChatRoomScreen({super.key});

  @override
  State<CreateChatRoomScreen> createState() => _CreateChatRoomScreenState();
}

class _CreateChatRoomScreenState extends State<CreateChatRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _roomTopicController = TextEditingController();
  bool _isPublicRoom = true;

  @override
  void dispose() {
    _roomNameController.dispose();
    _roomTopicController.dispose();
    super.dispose();
  }

  void _createRoom() {
    if (_formKey.currentState!.validate()) {
      final roomName = _roomNameController.text.trim();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat room "$roomName" created successfully! 🚀')),
      );
    }
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
            title: const Text('Create Chat Room', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: themeNotifier.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Room Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeNotifier.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Room Name Field
                  TextFormField(
                    controller: _roomNameController,
                    style: TextStyle(color: themeNotifier.isDarkMode ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Chat Room Name',
                      hintText: 'e.g., Flutter Developers India',
                      prefixIcon: const Icon(Icons.group),
                      filled: true,
                      fillColor: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a chat room name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Room Topic/Description Field
                  TextFormField(
                    controller: _roomTopicController,
                    maxLines: 3,
                    style: TextStyle(color: themeNotifier.isDarkMode ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Topic or Description',
                      hintText: 'What is this room about?',
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 48),
                        child: Icon(Icons.description),
                      ),
                      filled: true,
                      fillColor: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Privacy Toggle Card
                  Container(
                    decoration: BoxDecoration(
                      color: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      secondary: Icon(
                        _isPublicRoom ? Icons.public : Icons.lock,
                        color: themeNotifier.primaryColor,
                      ),
                      title: Text(
                        'Public Room',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: themeNotifier.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        _isPublicRoom ? 'Anyone on Krevzy can join' : 'Invite only',
                        style: TextStyle(fontSize: 12, color: themeNotifier.isDarkMode ? Colors.white70 : Colors.grey),
                      ),
                      value: _isPublicRoom,
                      onChanged: (val) {
                        setState(() {
                          _isPublicRoom = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeNotifier.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _createRoom,
                      child: const Text(
                        'Launch Chat Room',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}