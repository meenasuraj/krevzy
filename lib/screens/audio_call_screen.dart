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

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _candidateSubscription;

  final List<RTCIceCandidate> _pendingRemoteCandidates = [];

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _initializing = true;
  bool _remoteDescriptionSet = false;
  bool _answerCreated = false;
  bool _ending = false;

  String _status = 'Connecting…';

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
        'sdpSemantics': 'unified-plan',
      };

      final peerConnection = await createPeerConnection(configuration);

      _peerConnection = peerConnection;

      peerConnection.onConnectionState = (state) {
        if (!mounted) return;

        final text = switch (state) {
          RTCPeerConnectionState.RTCPeerConnectionStateConnected => 'Connected',
          RTCPeerConnectionState.RTCPeerConnectionStateConnecting =>
            'Connecting…',
          RTCPeerConnectionState.RTCPeerConnectionStateDisconnected =>
            'Disconnected',
          RTCPeerConnectionState.RTCPeerConnectionStateFailed =>
            'Connection failed',
          RTCPeerConnectionState.RTCPeerConnectionStateClosed => 'Call ended',
          _ => 'Connecting…',
        };

        setState(() {
          _status = text;
        });
      };

      peerConnection.onIceConnectionState = (state) {
        debugPrint('Audio ICE state: $state');

        if (!mounted) return;

        switch (state) {
          case RTCIceConnectionState.RTCIceConnectionStateChecking:
            setState(() => _status = 'Connecting…');
            break;

          case RTCIceConnectionState.RTCIceConnectionStateConnected:
          case RTCIceConnectionState.RTCIceConnectionStateCompleted:
            setState(() => _status = 'Connected');
            break;

          case RTCIceConnectionState.RTCIceConnectionStateFailed:
            setState(() => _status = 'Connection failed');
            break;

          case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
            setState(() => _status = 'Connection interrupted');
            break;

          default:
            break;
        }
      };

      /*
       * IMPORTANT:
       * Audio calls do not need an RTCVideoRenderer.
       * flutter_webrtc will receive the remote audio track through onTrack.
       */
      peerConnection.onTrack = (RTCTrackEvent event) {
        debugPrint(
          'Remote audio track received: '
          '${event.track.kind} '
          '${event.track.id}',
        );

        if (event.track.kind == 'audio') {
          event.track.enabled = true;

          if (mounted) {
            setState(() {
              _status = 'Connected';
            });
          }
        }
      };

      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });

      final localStream = _localStream!;

      for (final track in localStream.getTracks()) {
        track.enabled = true;
        await peerConnection.addTrack(track, localStream);
      }

      /*
       * Start with speakerphone enabled.
       * This is especially useful on Android where an active WebRTC
       * audio session can otherwise remain on the earpiece.
       */
      try {
        await Helper.setSpeakerphoneOn(true);
        _isSpeakerOn = true;
      } catch (e) {
        debugPrint('Could not enable speakerphone: $e');
      }

      peerConnection.onIceCandidate = (candidate) {
        if (candidate.candidate == null) return;

        unawaited(
          CallService.instance
              .addCandidate(
                callId: widget.callId,
                caller: widget.isCaller,
                candidate: candidate,
              )
              .catchError((error) {
                debugPrint('Audio ICE upload failed: $error');
              }),
        );
      };

      /*
       * Receive the OTHER user's ICE candidates.
       * Candidates can arrive before the remote SDP, so queue them.
       */
      _candidateSubscription = CallService.instance
          .watchCandidates(callId: widget.callId, caller: widget.isCaller)
          .listen(
            (snapshot) async {
              for (final change in snapshot.docChanges) {
                if (change.type != DocumentChangeType.added) continue;

                final data = change.doc.data();
                if (data == null) continue;

                final candidateString = data['candidate']?.toString();

                if (candidateString == null || candidateString.trim().isEmpty) {
                  continue;
                }

                final candidate = RTCIceCandidate(
                  candidateString,
                  data['sdpMid']?.toString(),
                  data['sdpMLineIndex'] is num
                      ? (data['sdpMLineIndex'] as num).toInt()
                      : null,
                );

                if (!_remoteDescriptionSet) {
                  _pendingRemoteCandidates.add(candidate);
                  debugPrint('Audio ICE candidate queued: ${change.doc.id}');
                  continue;
                }

                await _addRemoteCandidate(candidate);
              }
            },
            onError: (error) {
              debugPrint('Audio ICE listener error: $error');
            },
          );

      /*
       * Watch the call document for:
       * - caller -> answer
       * - receiver -> offer
       * - either side -> ended
       */
      _callSubscription = CallService.instance
          .watchCall(widget.callId)
          .listen(
            _onCallChanged,
            onError: (error) {
              debugPrint('Audio call listener error: $error');
            },
          );

      /*
       * Caller creates the offer.
       */
      if (widget.isCaller) {
        await _createOffer();
      } else {
        /*
         * Receiver may already have an offer, but we also rely on the
         * Firestore listener in case the offer arrives a little later.
         */
        final data = await CallService.instance.getCall(widget.callId);

        if (data != null) {
          await _handleIncomingOffer(data);
        }
      }

      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Audio call start failed: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _initializing = false;
        _status = 'Microphone/call unavailable';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not start audio call: $e')));
    }
  }

  Future<void> _createOffer() async {
    final pc = _peerConnection;
    if (pc == null) return;

    final offer = await pc.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });

    await pc.setLocalDescription(offer);

    await CallService.instance.setOffer(widget.callId, offer);

    if (mounted) {
      setState(() {
        _status = 'Ringing…';
      });
    }
  }

  Future<void> _handleIncomingOffer(Map<String, dynamic> data) async {
    if (widget.isCaller) return;

    final offer = data['offer'];

    if (offer is! Map) return;

    final sdp = offer['sdp']?.toString();
    final type = offer['type']?.toString();

    if (sdp == null || sdp.isEmpty) return;

    final pc = _peerConnection;
    if (pc == null) return;

    final currentRemote = await pc.getRemoteDescription();

    if (currentRemote == null) {
      await pc.setRemoteDescription(
        RTCSessionDescription(sdp, type ?? 'offer'),
      );

      _remoteDescriptionSet = true;

      await _flushPendingCandidates();

      if (!_answerCreated) {
        await _createAnswer();
      }
    }
  }

  Future<void> _createAnswer() async {
    if (_answerCreated) return;

    final pc = _peerConnection;
    if (pc == null) return;

    _answerCreated = true;

    try {
      final answer = await pc.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
      });

      await pc.setLocalDescription(answer);

      await CallService.instance.setAnswer(widget.callId, answer);

      if (mounted) {
        setState(() {
          _status = 'Connected';
        });
      }
    } catch (e) {
      _answerCreated = false;
      rethrow;
    }
  }

  Future<void> _onCallChanged(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    if (!snapshot.exists) return;

    final data = snapshot.data();
    if (data == null) return;

    final status = data['status']?.toString();

    if (status == 'ended') {
      await _endLocal();
      return;
    }

    /*
     * Receiver receives the caller's offer.
     */
    if (!widget.isCaller) {
      await _handleIncomingOffer(data);
      return;
    }

    /*
     * Caller receives the receiver's answer.
     */
    if (widget.isCaller) {
      final answer = data['answer'];

      if (answer is Map) {
        final sdp = answer['sdp']?.toString();
        final type = answer['type']?.toString();

        if (sdp != null && sdp.isNotEmpty) {
          final pc = _peerConnection;

          if (pc != null) {
            final currentRemote = await pc.getRemoteDescription();

            if (currentRemote == null) {
              await pc.setRemoteDescription(
                RTCSessionDescription(sdp, type ?? 'answer'),
              );

              _remoteDescriptionSet = true;

              await _flushPendingCandidates();

              if (mounted) {
                setState(() {
                  _status = 'Connected';
                });
              }
            }
          }
        }
      }
    }
  }

  Future<void> _addRemoteCandidate(RTCIceCandidate candidate) async {
    final pc = _peerConnection;
    if (pc == null) return;

    try {
      await pc.addCandidate(candidate);
    } catch (e) {
      debugPrint('Audio remote ICE failed: $e');
    }
  }

  Future<void> _flushPendingCandidates() async {
    if (!_remoteDescriptionSet) return;

    if (_pendingRemoteCandidates.isEmpty) return;

    final candidates = List<RTCIceCandidate>.from(_pendingRemoteCandidates);

    _pendingRemoteCandidates.clear();

    for (final candidate in candidates) {
      await _addRemoteCandidate(candidate);
    }
  }

  Future<void> _toggleMute() async {
    final stream = _localStream;
    if (stream == null) return;

    final tracks = stream.getAudioTracks();

    if (tracks.isEmpty) return;

    final track = tracks.first;

    final newMutedState = !_isMuted;

    setState(() {
      _isMuted = newMutedState;
    });

    track.enabled = !newMutedState;
  }

  Future<void> _toggleSpeaker() async {
    final newState = !_isSpeakerOn;

    try {
      await Helper.setSpeakerphoneOn(newState);

      if (mounted) {
        setState(() {
          _isSpeakerOn = newState;
        });
      }
    } catch (e) {
      debugPrint('Speakerphone toggle failed: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not change speaker: $e')));
    }
  }

  Future<void> _endCall() async {
    if (_ending) return;

    await CallService.instance.endCall(widget.callId);
    await _endLocal();
  }

  Future<void> _endLocal() async {
    if (_ending) return;

    _ending = true;

    try {
      await _callSubscription?.cancel();
    } catch (_) {}

    try {
      await _candidateSubscription?.cancel();
    } catch (_) {}

    _callSubscription = null;
    _candidateSubscription = null;

    _pendingRemoteCandidates.clear();

    try {
      for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
        track.stop();
      }
    } catch (_) {}

    try {
      await _peerConnection?.close();
    } catch (_) {}

    try {
      await _localStream?.dispose();
    } catch (_) {}

    _peerConnection = null;
    _localStream = null;

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    _candidateSubscription?.cancel();

    try {
      for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
        track.stop();
      }
    } catch (_) {}

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
                    onPressed: _ending ? null : _endCall,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.lock_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Secure call',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const Spacer(),

            CircleAvatar(
              radius: 58,
              backgroundColor: themeNotifier.primaryColor.withValues(
                alpha: .35,
              ),
              child: Text(
                widget.peerName.isEmpty
                    ? '?'
                    : widget.peerName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: 22),

            Text(
              widget.peerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              _initializing ? 'Starting microphone…' : _status,
              style: const TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 12),

            if (!_initializing && _status == 'Connected')
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.greenAccent,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Voice connected',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.only(left: 28, right: 28, bottom: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _initializing ? null : _toggleMute,
                    icon: Icon(
                      _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _isMuted ? Colors.red : Colors.white24,
                      padding: const EdgeInsets.all(17),
                    ),
                  ),

                  IconButton(
                    onPressed: _initializing ? null : _toggleSpeaker,
                    icon: Icon(
                      _isSpeakerOn
                          ? Icons.volume_up_rounded
                          : Icons.volume_down_rounded,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _isSpeakerOn
                          ? themeNotifier.primaryColor
                          : Colors.white24,
                      padding: const EdgeInsets.all(17),
                    ),
                  ),

                  IconButton(
                    onPressed: _ending ? null : _endCall,
                    icon: const Icon(
                      Icons.call_end_rounded,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.all(20),
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
