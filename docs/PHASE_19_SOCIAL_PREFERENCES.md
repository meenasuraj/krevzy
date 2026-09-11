# KREVZY Phase 19 — Social Preferences

Features added:
1. Saved Posts entry
2. Your Activity
3. Account Privacy
4. Time Management
5. Close Friends
6. Message & Story Replies
7. Tags & Mentions
8. Restricted Accounts
9. Limit Interactions
10. Favourites
11. Muted Accounts
12. Hide/Show Like & Share Counts
13. Languages
14. Sounds (Stories/Chats/Favourite Person)
15. Data Used & Media Quality
16. App & Website Permissions

Firestore paths:
- users/{uid}/settings/social
- users/{uid}/activity/{activityId}
- users/{uid}/closeFriends/{targetUid}
- users/{uid}/restrictedAccounts/{targetUid}
- users/{uid}/mutedAccounts/{targetUid}
- users/{uid}/favourites/{targetUid}

After copying the patch:
flutter clean
flutter pub get
flutter analyze
flutter test
firebase deploy --only firestore:rules
