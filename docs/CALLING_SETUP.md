# KREVZY 1:1 Audio & Video Calls

The user chat now has Audio Call and Video Call buttons. Calls use `flutter_webrtc` with Firestore signaling:

- `/calls/{callId}` stores caller/callee, type, offer, answer and status.
- `/calls/{callId}/callerCandidates/*` stores caller ICE candidates.
- `/calls/{callId}/calleeCandidates/*` stores callee ICE candidates.
- A chat screen listening for calls addressed to the signed-in user shows an incoming-call dialog.

## Firebase

Deploy the updated rules after reviewing them:

```bash
firebase deploy --only firestore:rules
```

## Android permissions

The manifest now requests Internet, microphone, camera and audio settings permissions.

## Network reliability

The included WebRTC configuration uses Google's public STUN server for basic NAT traversal. For reliable production calling across restrictive/mobile networks, add a TURN service and use your TURN credentials in the `iceServers` configuration.

## Important

The call UI is not a payment flow and does not change wallet balance. The client never credits wallet funds.
