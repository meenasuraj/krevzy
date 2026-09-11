import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../utils/app_theme_data.dart';

class AudioCallScreen extends StatefulWidget {
  final String peerName;
  const AudioCallScreen({super.key, required this.peerName});

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  MediaStream? _localStream;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
final bool _isCallConnected = true;

  @override
  void initState() {
    super.initState();
    _initAudioSession();
  }

  Future<void> _initAudioSession() async {
    final Map<String, dynamic> constraints = {
      'audio': true,
      'video': false,
    };
    try {
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      setState(() {});
    } catch (e) {
      debugPrint('Error accessing microphone: $e');
    }
  }

  @override
  void dispose() {
    _localStream?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = AppThemeNotifier.instance;

    return Scaffold(
      backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF121212) : const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar (Encryption Status & Back)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: const [
                      Icon(Icons.lock, color: Colors.green, size: 14),
                      SizedBox(width: 6),
                      Text('End-to-End Encrypted', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(width: 40),
                ],
              ),

              // Center Profile Avatar & Connection Status
              Column(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: themeNotifier.primaryColor.withValues(alpha: 0.3),
                    child: Text(
                      widget.peerName.isNotEmpty ? widget.peerName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.peerName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isCallConnected ? '04:12 • Secure Audio Link' : 'Connecting...',
                    style: const TextStyle(fontSize: 13, color: Colors.white60),
                  ),
                ],
              ),

              // Bottom Call Action Controls
              Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Speaker Toggle
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isSpeakerOn = !_isSpeakerOn;
                          // Optional: _localStream?.getAudioTracks()[0] toggle speaker routing if supported
                        });
                      },
                      icon: Icon(
                        _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: _isSpeakerOn ? themeNotifier.primaryColor : Colors.white24,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    // Mute Toggle
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isMuted = !_isMuted;
                          if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
                            _localStream!.getAudioTracks()[0].enabled = !_isMuted;
                          }
                        });
                      },
                      icon: Icon(
                        _isMuted ? Icons.mic_off : Icons.mic,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: _isMuted ? Colors.red : Colors.white24,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    // End Call Button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.call_end, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.all(18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}