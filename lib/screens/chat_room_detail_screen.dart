import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_theme_data.dart';

class ChatRoomDetailScreen extends StatefulWidget {
  final String roomName;
  const ChatRoomDetailScreen({super.key, required this.roomName});

  @override
  State<ChatRoomDetailScreen> createState() => _ChatRoomDetailScreenState();
}

class _ChatRoomDetailScreenState extends State<ChatRoomDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ImagePicker _picker = ImagePicker();

  void _sendMessage({File? attachmentFile, String? textContent}) {
    if ((textContent == null || textContent.trim().isEmpty) && attachmentFile == null) return;

    setState(() {
      _messages.add({
        'sender': 'Suraj Meena',
        'text': textContent ?? '',
        'file': attachmentFile,
        'time': TimeOfDay.now().format(context),
      });
    });
    _messageController.clear();
  }

  Future<void> _pickMedia(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      _sendMessage(attachmentFile: File(pickedFile.path), textContent: '[Photo Attachment]');
    }
  }

  void _showAttachmentBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemeNotifier.instance.isDarkMode ? const Color(0xFF242424) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 180,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _attachmentOption(Icons.camera_alt, Colors.purple, 'Camera', () {
              Navigator.pop(context);
              _pickMedia(ImageSource.camera);
            }),
            _attachmentOption(Icons.photo, Colors.blue, 'Gallery', () {
              Navigator.pop(context);
              _pickMedia(ImageSource.gallery);
            }),
            _attachmentOption(Icons.videocam, Colors.red, 'Video Call', () {
              Navigator.pop(context);
              _startVideoCall();
            }),
          ],
        ),
      ),
    );
  }

  Widget _attachmentOption(IconData icon, Color color, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 28, backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color, size: 26)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  void _startVideoCall() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VideoCallScreen(roomName: widget.roomName)),
    );
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
            title: Text(widget.roomName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: themeNotifier.primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.videocam),
                onPressed: _startVideoCall,
                tooltip: 'Start Video Room',
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Start the conversation!',
                          style: TextStyle(color: themeNotifier.isDarkMode ? Colors.white60 : Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final File? file = msg['file'];
                          return Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                              decoration: BoxDecoration(
                                color: themeNotifier.primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (file != null) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(file, height: 150, width: double.infinity, fit: BoxFit.cover),
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                  if (msg['text'].isNotEmpty && msg['text'] != '[Photo Attachment]')
                                    Text(
                                      msg['text'],
                                      style: TextStyle(fontSize: 14, color: themeNotifier.isDarkMode ? Colors.white : Colors.black87),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(msg['time'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Input bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                color: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: themeNotifier.primaryColor),
                      onPressed: _showAttachmentBottomSheet,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(color: themeNotifier.isDarkMode ? Colors.white : Colors.black87),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: themeNotifier.primaryColor),
                      onPressed: () => _sendMessage(textContent: _messageController.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// VIDEO CALL SCREEN COMPONENT
// ==========================================

class VideoCallScreen extends StatefulWidget {
  final String roomName;
  const VideoCallScreen({super.key, required this.roomName});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isMuted = false;
  bool _isVideoOff = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Simulated Remote Video Feed (Full Screen Background)
          Center(
            child: Container(
              color: Colors.grey[900],
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 40, backgroundColor: Colors.blue, child: Icon(Icons.person, size: 50, color: Colors.white)),
                    SizedBox(height: 12),
                    Text('Waiting for participants...', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),

          // Local Self-View Grid (Picture-in-Picture)
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              width: 100,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Center(
                child: Icon(_isVideoOff ? Icons.videocam_off : Icons.person, color: Colors.white, size: 30),
              ),
            ),
          ),

          // Top App Bar Details
          Positioned(
            top: 40,
            left: 20,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  widget.roomName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Bottom Control Actions Bar
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: 'mute',
                  backgroundColor: _isMuted ? Colors.red : Colors.grey[800],
                  child: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
                  onPressed: () => setState(() => _isMuted = !_isMuted),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  heroTag: 'endCall',
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  heroTag: 'video',
                  backgroundColor: _isVideoOff ? Colors.red : Colors.grey[800],
                  child: Icon(_isVideoOff ? Icons.videocam_off : Icons.videocam, color: Colors.white),
                  onPressed: () => setState(() => _isVideoOff = !_isVideoOff),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}