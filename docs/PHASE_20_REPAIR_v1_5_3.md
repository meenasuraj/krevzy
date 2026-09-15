KREVZY Phase 20 repair v1.5.3

This patch repairs the two remaining compile blockers reported by flutter analyze:
- lib/screens/subscription_screen.dart missing
- lib/screens/connected_experience_screen.dart incomplete/corrupted

It also includes safe cleanup for the unused rooms/search imports and the simple brace/underscore analyzer findings where the corresponding Phase 20 files were available in the patch source.

IMPORTANT: Copy these files into the existing project at the same paths. Do not create a lib/ERROR folder and do not delete lib/screens or lib/services.
