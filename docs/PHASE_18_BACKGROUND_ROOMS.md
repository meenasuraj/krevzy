# KREVZY Phase 18 — Backgrounds + Rooms

## Files
- `lib/services/krevzy_background_service.dart` — Firebase Storage + Firestore + local preferences for app/chat/keyboard-composer backgrounds.
- `lib/widgets/krevzy_background.dart` — KREVZY pastel gradient background widgets.
- `lib/screens/customization_screen.dart` — Appearance/background UI.
- `lib/services/room_service.dart` — Room creation, join, membership and realtime messages.
- `lib/screens/rooms_screen.dart` — Discover public rooms.
- `lib/screens/create_room_screen.dart` — Create public/private rooms.
- `lib/screens/room_chat_screen.dart` — Realtime room chat.

## Copy location
Copy these files into the matching paths under:
`C:\Projects\KREVZY PROJECT\`

## Firebase
Deploy both rules from the project root:
`firebase deploy --only firestore:rules,storage`

## Important
- The custom keyboard background applies to KREVZY's own composer UI. Flutter apps cannot change Gboard's system keyboard theme.
- Room message timestamps use Firestore server timestamps; the rules intentionally require timestamps to be materialized. If a first message is rejected because `serverTimestamp()` is still null in a specific client/rules combination, change the create rule to validate the field type less strictly or write a client timestamp. Test this on your Firebase project before release.
- Storage upload requires an active Firebase Storage bucket and deployed rules.
