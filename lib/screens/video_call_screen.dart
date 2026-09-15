import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../services/call_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String callId;
  final String peerName;
  final bool isCaller;

  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.peerName,
    required this.isCaller,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _callSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _candidateSubscription;
  bool _isMuted = false;
  bool _cameraOn = true;
  bool _initializing = true;
  bool _ending = false;
  String _status = 'Connecting…';

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      _peerConnection = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
      });
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {'facingMode': 'user'},
      });
      _localRenderer.srcObject = _localStream;
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
      _peerConnection!.onTrack = (event) {
        if (event.streams.isNotEmpty) {
          _remoteRenderer.srcObject = event.streams.first;
          if (mounted) setState(() => _status = 'Connected');
        }
      };
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
            RTCPeerConnectionState.RTCPeerConnectionStateConnected =>
              'Connected',
            RTCPeerConnectionState.RTCPeerConnectionStateConnecting =>
              'Connecting…',
            RTCPeerConnectionState.RTCPeerConnectionStateDisconnected =>
              'Disconnected',
            RTCPeerConnectionState.RTCPeerConnectionStateFailed =>
              'Connection failed',
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
                debugPrint('Video ICE candidate failed: $e');
              }
            }
          });
      _callSubscription = CallService.instance
          .watchCall(widget.callId)
          .listen(_onCallChanged);

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
            RTCSessionDescription(
              offer['sdp'].toString(),
              offer['type']?.toString(),
            ),
          );
          final answer = await _peerConnection!.createAnswer();
          await _peerConnection!.setLocalDescription(answer);
          await CallService.instance.setAnswer(widget.callId, answer);
        }
      }
    } catch (e) {
      debugPrint('Video call start failed: $e');
      if (mounted) {
        setState(() {
          _status = 'Camera/microphone unavailable';
          _initializing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start video call: $e')),
        );
      }
      return;
    }
    if (mounted) setState(() => _initializing = false);
  }

  Future<void> _onCallChanged(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final data = snapshot.data();
    if (data == null) return;
    final answer = data['answer'];
    if (widget.isCaller && answer is Map && answer['sdp'] != null) {
      final current = await _peerConnection?.getRemoteDescription();
      if (current == null) {
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(
            answer['sdp'].toString(),
            answer['type']?.toString(),
          ),
        );
      }
    }
    if (data['status']?.toString() == 'ended') {
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
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _remoteRenderer.srcObject == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 46,
                            child: Text(
                              widget.peerName.isEmpty
                                  ? '?'
                                  : widget.peerName[0].toUpperCase(),
                              style: const TextStyle(fontSize: 34),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _status,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    )
                  : RTCVideoView(
                      _remoteRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  IconButton(
                    onPressed: _endCall,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.lock_rounded,
                    color: Colors.white70,
                    size: 15,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 64,
              right: 16,
              child: SizedBox(
                width: 108,
                height: 152,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ColoredBox(
                    color: Colors.black54,
                    child: _localRenderer.srcObject == null
                        ? const Center(child: CircularProgressIndicator())
                        : RTCVideoView(
                            _localRenderer,
                            mirror: true,
                            objectFit: RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitCover,
                          ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 118,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    widget.peerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 28,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _initializing
                        ? null
                        : () {
                            final track =
                                (_localStream?.getAudioTracks().isNotEmpty ==
                                    true)
                                ? _localStream!.getAudioTracks().first
                                : null;
                            if (track == null) return;
                            setState(() => _isMuted = !_isMuted);
                            track.enabled = !_isMuted;
                          },
                    icon: Icon(
                      _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _isMuted ? Colors.red : Colors.white24,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _initializing
                        ? null
                        : () {
                            final track =
                                (_localStream?.getVideoTracks().isNotEmpty ==
                                    true)
                                ? _localStream!.getVideoTracks().first
                                : null;
                            if (track == null) return;
                            setState(() => _cameraOn = !_cameraOn);
                            track.enabled = _cameraOn;
                          },
                    icon: Icon(
                      _cameraOn
                          ? Icons.videocam_rounded
                          : Icons.videocam_off_rounded,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _cameraOn ? Colors.white24 : Colors.red,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _endCall,
                    icon: const Icon(
                      Icons.call_end_rounded,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.all(19),
                    ),
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
