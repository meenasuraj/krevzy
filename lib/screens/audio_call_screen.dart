import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../services/call_service.dart';
import '../utils/app_theme_data.dart';

class AudioCallScreen extends StatefulWidget {
  final String callId;
  final String peerName;
  final bool isCaller;

  const AudioCallScreen({
    super.key,
    required this.callId,
    required this.peerName,
    required this.isCaller,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _callSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _candidateSubscription;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _initializing = true;
  String _status = 'Connecting…';
  bool _ending = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final configuration = <String, dynamic>{
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
      };
      _peerConnection = await createPeerConnection(configuration);
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }

      _peerConnection!.onIceCandidate = (candidate) {
        if (candidate.candidate != null) {
          CallService.instance.addCandidate(
            callId: widget.callId,
            caller: widget.isCaller,
            candidate: candidate,
          );
        }
      };
      _peerConnection!.onConnectionState = (state) {
        if (!mounted) return;
        setState(() {
          _status = switch (state) {
            RTCPeerConnectionState.RTCPeerConnectionStateConnected => 'Connected',
            RTCPeerConnectionState.RTCPeerConnectionStateConnecting => 'Connecting…',
            RTCPeerConnectionState.RTCPeerConnectionStateDisconnected => 'Disconnected',
            RTCPeerConnectionState.RTCPeerConnectionStateFailed => 'Connection failed',
            RTCPeerConnectionState.RTCPeerConnectionStateClosed => 'Call ended',
            _ => 'Connecting…',
          };
        });
      };

      _candidateSubscription = CallService.instance
          .watchCandidates(callId: widget.callId, caller: widget.isCaller)
          .listen((snapshot) async {
        for (final change in snapshot.docChanges) {
          if (change.type != DocumentChangeType.added) continue;
          final data = change.doc.data();
          if (data == null) continue;
          try {
            await _peerConnection?.addCandidate(
              RTCIceCandidate(
                data['candidate']?.toString(),
                data['sdpMid']?.toString(),
                data['sdpMLineIndex'] is num
                    ? (data['sdpMLineIndex'] as num).toInt()
                    : null,
              ),
            );
          } catch (e) {
            debugPrint('Audio ICE candidate failed: $e');
          }
        }
      });

      _callSubscription = CallService.instance.watchCall(widget.callId).listen(_onCallChanged);

      if (widget.isCaller) {
        final offer = await _peerConnection!.createOffer();
        await _peerConnection!.setLocalDescription(offer);
        await CallService.instance.setOffer(widget.callId, offer);
        if (mounted) setState(() => _status = 'Ringing…');
      } else {
        final data = await CallService.instance.getCall(widget.callId);
        final offer = data?['offer'];
        if (offer is Map && offer['sdp'] != null) {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(offer['sdp'].toString(), offer['type']?.toString()),
          );
          final answer = await _peerConnection!.createAnswer();
          await _peerConnection!.setLocalDescription(answer);
          await CallService.instance.setAnswer(widget.callId, answer);
        }
      }
    } catch (e) {
      debugPrint('Audio call start failed: $e');
      if (mounted) {
        setState(() {
          _status = 'Microphone/call unavailable';
          _initializing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start audio call: $e')),
        );
      }
      return;
    }
    if (mounted) setState(() => _initializing = false);
  }

  Future<void> _onCallChanged(DocumentSnapshot<Map<String, dynamic>> snapshot) async {
    final data = snapshot.data();
    if (data == null) return;
    final answer = data['answer'];
    if (widget.isCaller && answer is Map && answer['sdp'] != null) {
      final current = await _peerConnection?.getRemoteDescription();
      if (current == null) {
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(answer['sdp'].toString(), answer['type']?.toString()),
        );
      }
    }
    final status = data['status']?.toString();
    if (!widget.isCaller && status == 'ended') {
      await _endLocal();
    } else if (status == 'ended' && mounted) {
      await _endLocal();
    }
  }

  Future<void> _endLocal() async {
    if (_ending) return;
    _ending = true;
    await _callSubscription?.cancel();
    await _candidateSubscription?.cancel();
    await _peerConnection?.close();
    await _localStream?.dispose();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _endCall() async {
    await CallService.instance.endCall(widget.callId);
    await _endLocal();
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    _candidateSubscription?.cancel();
    _peerConnection?.close();
    _localStream?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = AppThemeNotifier.instance;
    return Scaffold(
      backgroundColor: themeNotifier.isDarkMode
          ? const Color(0xFF121212)
          : const Color(0xFF262331),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _endCall,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  ),
                  const Spacer(),
                  const Icon(Icons.lock_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  const Text('Secure call', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Spacer(),
            CircleAvatar(
              radius: 58,
              backgroundColor: themeNotifier.primaryColor.withValues(alpha: .35),
              child: Text(
                widget.peerName.isEmpty ? '?' : widget.peerName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 22),
            Text(widget.peerName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(_initializing ? 'Starting microphone…' : _status, style: const TextStyle(color: Colors.white70)),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(left: 28, right: 28, bottom: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _initializing ? null : () {
                      final track = (_localStream?.getAudioTracks().isNotEmpty == true) ? _localStream!.getAudioTracks().first : null;
                      if (track == null) return;
                      setState(() => _isMuted = !_isMuted);
                      track.enabled = !_isMuted;
                    },
                    icon: Icon(_isMuted ? Icons.mic_off_rounded : Icons.mic_rounded, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: _isMuted ? Colors.red : Colors.white24, padding: const EdgeInsets.all(17)),
                  ),
                  IconButton(
                    onPressed: _initializing ? null : () async {
                      setState(() => _isSpeakerOn = !_isSpeakerOn);
                      await Helper.setSpeakerphoneOn(_isSpeakerOn);
                    },
                    icon: Icon(_isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: _isSpeakerOn ? themeNotifier.primaryColor : Colors.white24, padding: const EdgeInsets.all(17)),
                  ),
                  IconButton(
                    onPressed: _endCall,
                    icon: const Icon(Icons.call_end_rounded, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: Colors.red.shade700, padding: const EdgeInsets.all(20)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
