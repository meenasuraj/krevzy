import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../services/call_service.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.peerName,
    required this.isCaller,
  });

  final String callId;
  final String peerName;
  final bool isCaller;

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with WidgetsBindingObserver {
  final CallService _callService = CallService.instance;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _callSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _remoteCandidatesSubscription;

  final List<RTCIceCandidate> _pendingRemoteCandidates = [];

  bool _remoteDescriptionSet = false;
  bool _answerCreated = false;
  bool _isEnding = false;
  bool _isMuted = false;
  bool _isCameraEnabled = true;
  bool _isSpeakerOn = true;
  bool _isFrontCamera = true;
  bool _switchingCamera = false;

  String _status = 'Connecting...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callSubscription?.cancel();
    _remoteCandidatesSubscription?.cancel();

    // IMPORTANT:
    // Dispose only when the call screen is actually removed.
    // The Back button does NOT call endCall anymore.
    _disposeMedia();

    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      await _startCall();
    } catch (e) {
      debugPrint('Video call initialization failed: $e');
      if (mounted) {
        setState(() => _status = 'Unable to start call');
        _showMessage('Could not start video call: $e');
      }
    }
  }

  Future<void> _startCall() async {
    final configuration = <String, dynamic>{
      'iceServers': [
        {
          'urls': [
            'stun:stun.l.google.com:19302',
            'stun:stun1.l.google.com:19302',
          ],
        },
      ],
      'sdpSemantics': 'unified-plan',
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;

      unawaited(
        _callService.addCandidate(
          callId: widget.callId,
          caller: widget.isCaller,
          candidate: candidate,
        ),
      );
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isEmpty) return;

      final stream = event.streams.first;
      _remoteRenderer.srcObject = stream;

      for (final track in stream.getAudioTracks()) {
        track.enabled = true;
      }

      if (mounted) {
        setState(() => _status = 'Connected');
      }
    };

    _peerConnection!.onConnectionState = (state) {
      debugPrint('Video call connection state: $state');

      if (!mounted) return;

      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          setState(() => _status = 'Connected');
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          setState(() => _status = 'Connecting...');
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          setState(() => _status = 'Reconnecting...');
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          setState(() => _status = 'Connection failed');
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          setState(() => _status = 'Call ended');
          break;
        default:
          break;
      }
    };

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
        'frameRate': {'ideal': 30},
      },
    });

    _localRenderer.srcObject = _localStream;

    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    await Helper.setSpeakerphoneOn(true);

    _listenForRemoteCandidates();
    _listenForCall();

    if (widget.isCaller) {
      await _createOffer();
    } else {
      final call = await _callService.getCall(widget.callId);
      final offer = call?['offer'];

      if (offer is Map) {
        await _handleIncomingOffer(Map<String, dynamic>.from(offer));
      }
    }
  }

  void _listenForRemoteCandidates() {
    _remoteCandidatesSubscription = _callService
        .watchCandidates(callId: widget.callId, caller: widget.isCaller)
        .listen((snapshot) {
          for (final change in snapshot.docChanges) {
            if (change.type != DocumentChangeType.added) continue;

            final data = change.doc.data();
            if (data == null) continue;

            final candidateValue = data['candidate'];
            if (candidateValue == null) continue;

            final candidate = RTCIceCandidate(
              candidateValue as String?,
              data['sdpMid'] as String?,
              (data['sdpMLineIndex'] as num?)?.toInt(),
            );

            if (_remoteDescriptionSet) {
              unawaited(_addRemoteCandidate(candidate));
            } else {
              _pendingRemoteCandidates.add(candidate);
            }
          }
        });
  }

  Future<void> _addRemoteCandidate(RTCIceCandidate candidate) async {
    try {
      await _peerConnection?.addCandidate(candidate);
    } catch (e) {
      debugPrint('Remote ICE candidate failed: $e');
    }
  }

  Future<void> _flushRemoteCandidates() async {
    if (!_remoteDescriptionSet) return;

    final candidates = List<RTCIceCandidate>.from(_pendingRemoteCandidates);
    _pendingRemoteCandidates.clear();

    for (final candidate in candidates) {
      await _addRemoteCandidate(candidate);
    }
  }

  void _listenForCall() {
    _callSubscription = _callService
        .watchCall(widget.callId)
        .listen(
          (snapshot) async {
            if (!snapshot.exists) return;

            final data = snapshot.data();
            if (data == null) return;

            final status = data['status'] as String?;

            if (status == 'ended') {
              if (mounted && !_isEnding) {
                setState(() => _status = 'Call ended');
                await _closeAfterRemoteEnd();
              }
              return;
            }

            if (!widget.isCaller) {
              final offer = data['offer'];

              if (offer is Map && !_remoteDescriptionSet) {
                await _handleIncomingOffer(Map<String, dynamic>.from(offer));
              }
            } else {
              final answer = data['answer'];

              if (answer is Map && !_remoteDescriptionSet) {
                await _handleIncomingAnswer(Map<String, dynamic>.from(answer));
              }
            }
          },
          onError: (Object error) {
            debugPrint('Video call signaling error: $error');
          },
        );
  }

  Future<void> _createOffer() async {
    final pc = _peerConnection;
    if (pc == null) return;

    final offer = await pc.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });

    await pc.setLocalDescription(offer);
    await _callService.setOffer(widget.callId, offer);
  }

  Future<void> _handleIncomingOffer(Map<String, dynamic> offer) async {
    if (_answerCreated || _peerConnection == null) return;

    final type = offer['type'] as String?;
    final sdp = offer['sdp'] as String?;

    if (type == null || sdp == null) return;

    final pc = _peerConnection!;

    await pc.setRemoteDescription(RTCSessionDescription(sdp, type));

    _remoteDescriptionSet = true;
    await _flushRemoteCandidates();

    await _createAnswer();
  }

  Future<void> _createAnswer() async {
    if (_answerCreated || _peerConnection == null) return;

    _answerCreated = true;

    try {
      final pc = _peerConnection!;

      final answer = await pc.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });

      await pc.setLocalDescription(answer);
      await _callService.setAnswer(widget.callId, answer);

      if (mounted) {
        setState(() => _status = 'Connected');
      }
    } catch (e) {
      _answerCreated = false;
      rethrow;
    }
  }

  Future<void> _handleIncomingAnswer(Map<String, dynamic> answer) async {
    if (_remoteDescriptionSet || _peerConnection == null) return;

    final type = answer['type'] as String?;
    final sdp = answer['sdp'] as String?;

    if (type == null || sdp == null) return;

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(sdp, type),
    );

    _remoteDescriptionSet = true;
    await _flushRemoteCandidates();

    if (mounted) {
      setState(() => _status = 'Connected');
    }
  }

  // ---------------------------------------------------------------------------
  // CAMERA
  // ---------------------------------------------------------------------------

  Future<void> _switchCamera() async {
    if (_switchingCamera || !_isCameraEnabled) return;

    final stream = _localStream;
    if (stream == null) return;

    final tracks = stream.getVideoTracks();
    if (tracks.isEmpty) {
      _showMessage('Camera is not available.');
      return;
    }

    setState(() => _switchingCamera = true);

    try {
      final track = tracks.first;

      // flutter_webrtc officially exposes Helper.switchCamera().
      // Passing the current stream lets the plugin replace the active camera
      // without rebuilding the PeerConnection.
      final switched = await Helper.switchCamera(track, null, stream);

      if (switched) {
        if (mounted) {
          setState(() {
            _isFrontCamera = !_isFrontCamera;
          });
        }
      } else {
        // Some platform versions return false even though the native switch
        // completed. Retry through the track API as a fallback.
        try {
          final fallbackSwitched = await Helper.switchCamera(
            track,
            null,
            stream,
          );

          if (mounted && fallbackSwitched) {
            setState(() {
              _isFrontCamera = !_isFrontCamera;
            });
          }
        } catch (fallbackError) {
          debugPrint('Fallback camera switch failed: $fallbackError');
          _showMessage('Could not switch camera.');
        }
      }
    } catch (e) {
      debugPrint('Camera switch failed: $e');

      // Fallback for platform implementations where track.switchCamera()
      // is the supported path.
      try {
        final fallback = await Helper.switchCamera(
          tracks.first,
          null,
          _localStream,
        );

        if (mounted && fallback) {
          setState(() {
            _isFrontCamera = !_isFrontCamera;
          });
        }
      } catch (fallbackError) {
        debugPrint('Camera fallback failed: $fallbackError');
        _showMessage('Could not switch camera.');
      }
    } finally {
      if (mounted) {
        setState(() => _switchingCamera = false);
      }
    }
  }

  void _toggleCamera() {
    final tracks = _localStream?.getVideoTracks();
    if (tracks == null || tracks.isEmpty) return;

    final enabled = !tracks.first.enabled;
    tracks.first.enabled = enabled;

    if (mounted) {
      setState(() => _isCameraEnabled = enabled);
    }
  }

  void _toggleMute() {
    final tracks = _localStream?.getAudioTracks();
    if (tracks == null || tracks.isEmpty) return;

    final enabled = !tracks.first.enabled;
    tracks.first.enabled = enabled;

    if (mounted) {
      setState(() => _isMuted = !enabled);
    }
  }

  Future<void> _toggleSpeaker() async {
    final next = !_isSpeakerOn;

    try {
      await Helper.setSpeakerphoneOn(next);

      if (mounted) {
        setState(() => _isSpeakerOn = next);
      }
    } catch (e) {
      debugPrint('Speaker toggle failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // BACK / END CALL
  // ---------------------------------------------------------------------------

  Future<void> _handleBackPressed() async {
    if (_isEnding) return;

    // IMPORTANT:
    // Do NOT call endCall() here.
    //
    // The previous implementation ended the Firestore call and then popped
    // the route, so Android/system back looked like "hang up".
    //
    // We intentionally keep the call alive and keep the call screen mounted.
    _showMessage('Call is active. Use the red button to end the call.');
  }

  Future<void> _endCall() async {
    if (_isEnding) return;

    setState(() {
      _isEnding = true;
      _status = 'Ending call...';
    });

    try {
      await _callService.endCall(widget.callId);
    } catch (e) {
      debugPrint('End call signaling failed: $e');
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _closeAfterRemoteEnd() async {
    if (_isEnding) return;

    _isEnding = true;

    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Do not end the call when the app goes to background/inactive.
    //
    // Keeping the PeerConnection alive here is important for a call that is
    // temporarily covered by another Android UI.
    if (state == AppLifecycleState.resumed && mounted) {
      _localRenderer.srcObject = _localStream;
    }
  }

  // ---------------------------------------------------------------------------
  // CLEANUP
  // ---------------------------------------------------------------------------

  Future<void> _disposeMedia() async {
    try {
      _callSubscription?.cancel();
      _remoteCandidatesSubscription?.cancel();
    } catch (_) {}

    try {
      _localRenderer.srcObject = null;
      _remoteRenderer.srcObject = null;
    } catch (_) {}

    try {
      for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
        await track.stop();
      }
    } catch (_) {}

    try {
      await _localStream?.dispose();
    } catch (_) {}

    try {
      await _peerConnection?.close();
    } catch (_) {}

    try {
      await _peerConnection?.dispose();
    } catch (_) {}

    try {
      await _localRenderer.dispose();
    } catch (_) {}

    try {
      await _remoteRenderer.dispose();
    } catch (_) {}
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  Widget _buildVideoView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        color: Colors.black,
        child: RTCVideoView(
          _remoteRenderer,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          mirror: false,
        ),
      ),
    );
  }

  Widget _buildLocalPreview() {
    return Positioned(
      top: 18,
      right: 18,
      width: 120,
      height: 170,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: RTCVideoView(
            _localRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            mirror: _isFrontCamera,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(
          children: [
            // Back button intentionally does NOT pop/end the call.
            _roundButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              onPressed: _handleBackPressed,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _status,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12,
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

  Widget _roundButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: Colors.white,
        icon: Icon(icon),
      ),
    );
  }

  Widget _buildControls() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            _callControl(
              icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              label: _isMuted ? 'Unmute' : 'Mute',
              onPressed: _toggleMute,
            ),
            _callControl(
              icon: _isCameraEnabled
                  ? Icons.videocam_rounded
                  : Icons.videocam_off_rounded,
              label: _isCameraEnabled ? 'Camera' : 'Camera off',
              onPressed: _toggleCamera,
            ),
            _callControl(
              icon: _isFrontCamera
                  ? Icons.flip_camera_ios_rounded
                  : Icons.flip_camera_ios_rounded,
              label: _switchingCamera ? 'Switching' : 'Flip',
              onPressed: _switchingCamera || !_isCameraEnabled
                  ? null
                  : _switchCamera,
            ),
            _callControl(
              icon: _isSpeakerOn
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
              onPressed: _toggleSpeaker,
            ),
            _callControl(
              icon: Icons.call_end_rounded,
              label: 'End',
              destructive: true,
              onPressed: _isEnding ? null : _endCall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _callControl({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool destructive = false,
  }) {
    return SizedBox(
      width: 68,
      child: Column(
        children: [
          Material(
            color: destructive
                ? Colors.red.shade600
                : Colors.white.withValues(alpha: 0.16),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: label,
              onPressed: onPressed,
              color: Colors.white,
              icon: _switchingCamera && label == 'Switching'
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          unawaited(_handleBackPressed());
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: _buildVideoView()),

            // Dark gradient improves readability of controls/text.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.42),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.58),
                      ],
                      stops: const [0, 0.45, 1],
                    ),
                  ),
                ),
              ),
            ),

            _buildTopBar(),
            _buildLocalPreview(),

            Positioned(left: 0, right: 0, bottom: 0, child: _buildControls()),

            if (_status != 'Connected')
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.52),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_status != 'Connection failed')
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      if (_status != 'Connection failed')
                        const SizedBox(width: 10),
                      Text(
                        _status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
